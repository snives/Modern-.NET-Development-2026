# Data Access

## Chapter Purpose

Most business applications eventually become data applications.

Chapter 5 introduced ASP.NET Core as the HTTP boundary. That boundary is useful
only when the application can read and change durable state: customers,
orders, invoices, users, permissions, audit records, product catalogs, and
workflow history. Chapter 6 explains how modern .NET applications usually
reach that data.

For a returning Windows, SQL Server, and C# developer, this chapter begins
from familiar ground. SQL Server is still a major enterprise database. T-SQL,
indexes, transactions, constraints, query plans, backup, restore, and security
still matter. Modern .NET did not make relational thinking obsolete.

What changed is the application side of the boundary.

Modern .NET applications usually do not treat database access as a few
connection strings hidden in `web.config` and a set of ad hoc ADO.NET calls
spread through pages or controllers. They tend to use explicit data-access
libraries, dependency injection, environment-based configuration, migrations,
async APIs, source-controlled schema changes, and production observability.

Entity Framework Core, or EF Core, is Microsoft's modern object-relational
mapper for .NET. It exists to let developers work with database-backed data
through .NET objects while still using a relational database underneath.
Dapper is a popular micro-ORM originally developed for Stack Overflow. It
exists for teams that want to write SQL directly while avoiding repetitive
mapping code.

This chapter introduces SQL Server, EF Core, Dapper, migrations, and
performance from a modern .NET perspective. It does not try to teach database
administration or every ORM feature. The goal is to help you place data access
correctly in an ASP.NET Core application and understand the tradeoffs.

## Where This Fits

Data access sits behind the HTTP layer and inside the application boundary.

```text
HTTP client
   |
   v
ASP.NET Core endpoint or controller
   |
   v
Application service
   |
   v
Data access boundary
   |
   +-- EF Core DbContext
   |
   +-- Dapper query object
   |
   +-- raw ADO.NET when needed
   |
   v
SQL Server or another database
```

The endpoint should not need to know every table, join, transaction detail, or
connection-management rule. It should coordinate request handling. The
application service should express the business operation. The data-access
layer should own the database conversation.

This chapter prepares for several later chapters. Chapter 7 adds security.
Chapter 8 validates code with tests and CI. Chapter 11 uses Docker Compose to
run multi-container development environments, including local SQL Server.
Chapter 12 discusses deployment. Chapter 14 covers diagnostics. Chapter 15
adds caching and distributed application patterns.

## Connection to the Reader's Existing Model

You already understand SQL Server as a durable system of record.

You know that tables, keys, constraints, indexes, transactions, stored
procedures, views, and query plans are not implementation trivia. They are the
shape of business data. You also know that a database is not just a file the
application happens to use. It has its own lifecycle, permissions, backups,
capacity, and operational failure modes.

That knowledge remains valuable.

The modern shift is how the application describes and reaches the database.
Instead of connection strings in `web.config`, ASP.NET Core usually reads
connection strings from configuration providers. In local development, that may
be `appsettings.Development.json` or user secrets. In production, it should be
a secret store, environment variable, or managed platform setting.

Instead of creating `SqlConnection` everywhere, modern applications usually
centralize data access through dependency injection. EF Core uses a `DbContext`
as the unit that tracks entities, builds queries, and saves changes. Dapper
uses an open database connection and extension methods such as `QueryAsync`
and `ExecuteAsync`.

Instead of manually remembering which schema changes were applied to which
database, EF Core migrations can record schema evolution in source control.
This does not remove the need for DBA judgment. It gives the team a repeatable
artifact to review, test, script, and deploy.

The analogy to stored procedures is useful. Stored procedures centralize
database behavior close to the data. EF Core centralizes database mapping and
query generation close to the application model. Dapper centralizes explicit
SQL close to application code. Each style chooses a different place for
database knowledge to live.

The analogy breaks down when an ORM is treated as if the relational database
disappeared. It did not. EF Core still produces SQL. SQL Server still executes
queries. Indexes still determine performance. Transactions still define
consistency. The database is still real.

## Layer 1 — Conceptual Model

Data access is the boundary between application behavior and durable or shared
state.

It solves these problems:

- connecting to a database;
- translating application operations into database operations;
- querying data efficiently;
- saving changes consistently;
- managing transactions;
- evolving schema over time;
- keeping data-access details out of HTTP endpoints;
- making database behavior testable and observable.

It does not solve these problems by itself:

- it does not design a correct data model;
- it does not make slow queries fast automatically;
- it does not remove the need for indexes;
- it does not make distributed transactions simple;
- it does not protect secrets unless configuration is handled correctly;
- it does not replace backup, restore, monitoring, or operational planning.

The main modern .NET data-access choices are:

```text
EF Core
  Higher-level object-relational mapping
  Strong integration with LINQ, DbContext, migrations, and change tracking

Dapper
  SQL-first micro-ORM
  Strong control over SQL with lightweight object mapping

ADO.NET
  Lowest-level database API
  Maximum explicit control with more repetitive code
```

EF Core is often the default starting point for modern .NET applications
because it integrates well with .NET, ASP.NET Core dependency injection,
LINQ, migrations, and multiple database providers.

Dapper is often chosen when SQL control is more important than ORM modeling,
when queries are highly tuned, or when a team already thinks naturally in
SQL.

ADO.NET remains underneath both approaches and is still available when direct
control matters.

## Layer 2 — System Relationships

The application sends data-access intent. It asks to create an order, load a
customer, check a permission, search products, or record an audit event.

The data-access code turns that intent into database commands. With EF Core,
LINQ queries and tracked entity changes become SQL commands. With Dapper,
explicit SQL text and parameters become commands. With ADO.NET, the developer
builds the command directly.

The database provider owns the database-specific connection and translation
details. EF Core supports multiple providers, including SQL Server, SQLite,
PostgreSQL, MySQL, and others. Dapper works through ADO.NET connections, so it
can work with many databases that expose .NET data providers.

The database owns durable state, constraints, query execution, locking,
transactions, indexes, storage, backup, and recovery.

The configuration system owns connection information. The application should
not hard-code production connection strings. The connection string is an input
to the application, not part of the compiled binary.

The dependency injection container owns service lifetimes. In ASP.NET Core,
EF Core `DbContext` instances are commonly registered with a scoped lifetime,
meaning one context instance is used for a request scope. Dapper-based designs
often register a connection factory or data-access service rather than a
single shared connection.

The migration history owns schema evolution. EF Core migrations generate C#
files that describe schema changes and a model snapshot used to detect later
changes. Those files should be reviewed and committed like other source files.

Failure boundaries include connection failures, authentication failures,
missing permissions, deadlocks, blocking, timeouts, migration mistakes,
transaction conflicts, inefficient queries, model/schema drift, missing
indexes, connection pool exhaustion, and serialization problems when data is
returned through an API.

One practical rule helps: the database is a dependency, but it is not a minor
dependency. It is often the most important production boundary in the system.

## Layer 3 — Core Mechanics

Start with a small entity:

```csharp
public sealed class Order
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = "";
    public decimal Total { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
```

In EF Core, a `DbContext` represents a session with the database:

```csharp
using Microsoft.EntityFrameworkCore;

public sealed class OrdersDbContext : DbContext
{
    public OrdersDbContext(DbContextOptions<OrdersDbContext> options)
        : base(options)
    {
    }

    public DbSet<Order> Orders => Set<Order>();
}
```

The ASP.NET Core application registers the context:

```csharp
builder.Services.AddDbContext<OrdersDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("Orders"));
});
```

An endpoint or service can then query:

```csharp
app.MapGet("/orders/{id:int}", async (
    int id,
    OrdersDbContext db) =>
{
    var order = await db.Orders.FindAsync(id);

    return order is null
        ? Results.NotFound()
        : Results.Ok(order);
});
```

For creation:

```csharp
app.MapPost("/orders", async (
    CreateOrderRequest request,
    OrdersDbContext db) =>
{
    var order = new Order
    {
        CustomerName = request.CustomerName,
        Total = request.Total,
        CreatedAt = DateTimeOffset.UtcNow
    };

    db.Orders.Add(order);
    await db.SaveChangesAsync();

    return Results.Created($"/orders/{order.Id}", order);
});

public sealed record CreateOrderRequest(
    string CustomerName,
    decimal Total);
```

This is useful for learning, but production code often moves business rules
out of the endpoint and into application services.

With Dapper, the SQL is explicit:

```csharp
using Dapper;
using Microsoft.Data.SqlClient;

public sealed class OrderQueries
{
    private readonly string _connectionString;

    public OrderQueries(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("Orders")
            ?? throw new InvalidOperationException(
                "Missing Orders connection string.");
    }

    public async Task<Order?> GetOrderAsync(int id)
    {
        const string sql = """
            select Id, CustomerName, Total, CreatedAt
            from dbo.Orders
            where Id = @Id;
            """;

        await using var connection =
            new SqlConnection(_connectionString);

        return await connection.QuerySingleOrDefaultAsync<Order>(
            sql,
            new { Id = id });
    }
}
```

Notice the tradeoff. EF Core hides most SQL generation and gives change
tracking, LINQ, and migrations. Dapper keeps SQL visible and gives lightweight
mapping.

Migrations describe schema changes:

```bash
dotnet tool install --global dotnet-ef
dotnet ef migrations add InitialCreate
dotnet ef database update
```

For production, do not blindly apply migrations because a command exists.
Microsoft recommends generating SQL scripts for production deployment so they
can be reviewed and adjusted before being applied.

```bash
dotnet ef migrations script -o migrations.sql
```

Performance begins with query awareness. EF Core LINQ is not magic; it is
translated to SQL. Dapper SQL is not automatically fast; it still needs good
indexes, parameters, and query plans. The database engine always has the final
say.

## Layer 4 — Developer Workflow

A typical EF Core workflow in an ASP.NET Core API looks like this:

```text
Define entity and DbContext
        |
        v
Add provider package
        |
        v
Configure connection string
        |
        v
Register DbContext with dependency injection
        |
        v
Create migration
        |
        v
Apply migration to local database
        |
        v
Write endpoint or service
        |
        v
Run and test
```

Create a web API:

```bash
dotnet new webapi -n Orders.Api
cd Orders.Api
```

Add EF Core packages for SQL Server:

```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
```

Install or restore EF Core tools:

```bash
dotnet new tool-manifest
dotnet tool install dotnet-ef
dotnet tool restore
```

Create a migration:

```bash
dotnet ef migrations add InitialCreate
```

Apply it to a local development database:

```bash
dotnet ef database update
```

List migrations:

```bash
dotnet ef migrations list
```

Check whether model changes are missing a migration:

```bash
dotnet ef migrations has-pending-model-changes
```

For Dapper:

```bash
dotnet add package Dapper
dotnet add package Microsoft.Data.SqlClient
```

Dapper usually does not manage schema. Teams using Dapper often manage schema
with SQL scripts, a migration tool, database projects, Flyway, Liquibase,
DbUp, RoundhousE, or another database-change process.

Local development may use SQL Server installed directly, SQL Server in a
container, LocalDB on Windows, or a shared development instance. Chapter 11
returns to local multi-container environments.

The important workflow habit is that schema changes, code changes, and tests
move together. A pull request that changes data shape should include the
application change, migration or SQL script, test evidence, and deployment
notes.

## Layer 5 — Production Usage

Production data access is where small shortcuts become expensive.

Configuration should keep connection strings out of source control. Local
development can use user secrets or local settings. Production should use a
secret store, environment variable, managed identity pattern, or hosting
platform configuration.

Security includes database authentication, least-privilege database users,
encrypted connections, parameterized queries, secret rotation, auditing, and
careful handling of personally identifiable or regulated data. Dapper and EF
Core both support parameterized commands; string-concatenated SQL remains a
security risk.

Reliability depends on timeouts, retries, transaction boundaries, connection
pooling, idempotent operations where possible, and clear behavior when the
database is unavailable. Retrying every failure is not wisdom. Some failures
are transient. Some indicate bad data, deadlocks, or broken design.

Deployment must respect schema and application compatibility. A database
migration can break older application versions if columns are renamed,
constraints are changed, or data is transformed in one step. Safer production
changes often use expand-and-contract patterns: add compatible schema, deploy
application changes, backfill data, then remove old schema later.

Observability should include slow queries, command failures, connection pool
pressure, timeout rates, migration history, and database health. Application
logs should contain enough context to diagnose failures without logging
secrets or sensitive data.

Scaling data access is often harder than scaling web servers. Adding more API
instances can increase database load. Caching, read replicas, query tuning,
pagination, background processing, and data partitioning can help, but each
adds tradeoffs.

Persistence is the point of the database. Do not treat cache or in-memory data
as durable. SQL Server remains the system of record unless the architecture
explicitly defines another durable store.

Cost is affected by database tier, storage, backup retention, DTUs or vCores,
IO, memory, licensing, managed-service choices, inefficient queries, and
over-eager logging. A slow query can become a cloud bill.

Local development optimizes for convenience and reset capability. Production
optimizes for durability, backup, auditability, security, tested schema
changes, and predictable performance.

## Layer 6 — Tradeoffs and Alternatives

EF Core is a strong default when the application has a rich domain model,
needs LINQ queries, benefits from change tracking, wants migrations, and fits
well with a model-first or code-first workflow.

Dapper is strong when SQL control is central, queries are hand-tuned, stored
procedures are important, the data model is close to result shapes, or the
team wants minimal abstraction over SQL.

ADO.NET is appropriate when maximum control matters, when avoiding extra
dependencies is important, or when building infrastructure-level libraries. It
requires more repetitive code.

Stored procedures remain valid. They can centralize data rules, support
security patterns, improve plan stability in some cases, and align with DBA-led
database ownership. They can also hide behavior from application source
control if not managed carefully.

SQL Server competes with PostgreSQL, MySQL, Oracle, SQLite, MariaDB, cloud
relational databases, document databases, key-value stores, and analytical
systems. According to DB-Engines in July 2026, Microsoft SQL Server ranked
third among relational database management systems, behind Oracle and MySQL
and just ahead of PostgreSQL. That ranking does not decide your architecture,
but it confirms SQL Server remains a major professional database.

PostgreSQL is a major open-source alternative and is especially prominent in
cloud-native and open-source-heavy systems. SQLite is excellent for embedded,
local, test, and single-file scenarios. Document databases fit data that is
naturally document-shaped. Analytical stores fit reporting and large-scale
analysis. Redis fits fast in-memory state, not relational truth.

Common overengineering mistakes:

- creating a repository abstraction over EF Core that adds no useful boundary;
- putting all queries directly in controllers or Minimal API handlers;
- treating migrations as production-safe without review;
- ignoring generated SQL because the LINQ looks clean;
- loading entire tables and filtering in memory;
- using lazy loading without understanding query volume;
- adding Redis before fixing obvious query and index problems;
- treating database changes as less important than C# changes.

State-of-the-art .NET data access in 2026 is pragmatic: use EF Core where its
modeling and migrations help, use Dapper where explicit SQL is clearer, review
schema changes, observe query behavior, and respect the database as a
production system.

## Layer 7 — Interview Perspective

Interviewers use data-access questions to test whether you understand both
.NET and databases.

Concepts commonly tested:

- EF Core `DbContext`;
- entity classes and `DbSet<T>`;
- LINQ-to-SQL translation;
- change tracking;
- migrations;
- Dapper versus EF Core;
- parameterized queries;
- connection strings and secrets;
- transactions;
- indexes and query performance;
- avoiding business logic in controllers.

Representative questions:

- "What problem does EF Core solve?"
- "When would you choose Dapper instead of EF Core?"
- "What is a migration?"
- "Why should generated migration SQL be reviewed before production?"
- "What is the risk of lazy loading?"
- "How do you avoid SQL injection?"
- "What should not go in an ASP.NET Core endpoint handler?"
- "Why can adding more web servers make database performance worse?"

A strong answer keeps the database visible:

> "EF Core lets us work with entities and LINQ, but it still generates SQL that
> the database must execute. I use it where change tracking and migrations
> help, inspect generated SQL for important paths, use indexes and pagination,
> and review migrations before production."

Common misconceptions:

- "EF Core means I do not need to understand SQL."
- "Dapper is always faster, therefore always better."
- "Migrations are just development convenience."
- "A repository layer automatically makes data access clean."
- "Redis can replace SQL Server for ordinary business data."
- "Async database calls make slow queries fast."
- "If an endpoint is simple, data access can stay in the controller forever."

Small design scenario:

You are building an order API. The first version needs to create orders, read
orders by ID, list recent orders, and update order status.

A good design might use SQL Server as the system of record, EF Core for
ordinary CRUD and migrations, application services for business operations,
and carefully indexed queries for common reads. If a reporting endpoint later
needs a tuned join, Dapper can be introduced for that query without replacing
EF Core everywhere.

The strong answer chooses tools per boundary instead of turning one data-access
style into a religion.

## Hands-On Lab

Objective:

Add EF Core data access to a small ASP.NET Core API and understand the shape of
a migration.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- A SQL Server development database, SQL Server container, LocalDB on Windows,
  or another SQL Server-compatible development option.
- Basic familiarity with Chapter 5's ASP.NET Core API.

Steps:

1. Create a new API:

   ```bash
   dotnet new webapi -n Chapter06.Api
   cd Chapter06.Api
   ```

2. Add EF Core packages:

   ```bash
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Microsoft.EntityFrameworkCore.Design
   ```

3. Create a local tool manifest and install EF Core tools:

   ```bash
   dotnet new tool-manifest
   dotnet tool install dotnet-ef
   ```

4. Add an `Order` entity and `OrdersDbContext`.

5. Add a development connection string named `Orders`.

6. Register the context:

   ```csharp
   builder.Services.AddDbContext<OrdersDbContext>(options =>
   {
       options.UseSqlServer(
           builder.Configuration.GetConnectionString("Orders"));
   });
   ```

7. Add a migration:

   ```bash
   dotnet ef migrations add InitialCreate
   ```

8. Inspect the generated migration files before applying them.

9. Apply the migration to the local database:

   ```bash
   dotnet ef database update
   ```

10. Add one endpoint to create an order and one endpoint to retrieve an order.

11. Build and run:

    ```bash
    dotnet build
    dotnet run
    ```

Expected results:

- The project builds.
- EF Core packages are referenced.
- A migration is generated and visible in source.
- The local database schema is created or updated.
- The API can save and retrieve an order.

Validation commands:

```bash
dotnet build
dotnet ef migrations list
dotnet ef migrations has-pending-model-changes
dotnet ef database update
dotnet run
```

Troubleshooting notes:

- If `dotnet ef` is not found, run `dotnet tool restore`.
- If the connection fails, verify the connection string and SQL Server
  instance.
- If the migration cannot be created, confirm the `DbContext` is registered and
  the design package is referenced.
- If `has-pending-model-changes` reports changes, create a migration or review
  whether the model changed unintentionally.
- If the API runs but database calls fail, check database permissions and
  whether the migration was applied.

## Knowledge Check

1. Why is data access a boundary rather than just a utility function?
2. What does EF Core's `DbContext` represent?
3. Why does EF Core not remove the need to understand SQL Server?
4. When is Dapper a better fit than EF Core?
5. What problem do migrations solve?
6. Why should migrations be reviewed before production deployment?
7. What is the risk of putting database code directly in endpoint handlers?
8. Why can adding more application instances increase database pressure?
9. What is the difference between durable state and cached state?
10. How should connection strings and secrets be handled differently in local
    development and production?

## Summary

Modern .NET data access begins with the same truth experienced SQL Server
developers already know: the database is a durable, operationally important
system. Tables, indexes, transactions, constraints, and query plans still
matter.

EF Core adds a modern object-relational mapping layer with `DbContext`,
entities, LINQ, change tracking, providers, and migrations. Dapper offers a
lighter SQL-first path for teams that want explicit queries and simple object
mapping. ADO.NET remains available underneath both.

The modern practice is not to hide the database. It is to create a clear,
testable, observable boundary between application behavior and persistent
state. Schema changes should be source-controlled, reviewed, tested, and
deployed deliberately. Query performance should be measured against the real
database, not assumed from clean C#.

The next chapter adds authentication and security, because once an API can
read and write data, the next question is who is allowed to do so.

## Sources

- [What is SQL Server?](https://learn.microsoft.com/en-us/sql/sql-server/what-is-sql-server?view=sql-server-ver17)
- [Overview of Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/)
- [Managing Database Schemas](https://learn.microsoft.com/en-us/ef/core/managing-schemas/)
- [Migrations Overview](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/)
- [Managing Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/managing)
- [Applying Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)
- [Efficient Querying](https://learn.microsoft.com/en-us/ef/core/performance/efficient-querying)
- [What's New in EF Core 10](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew)
- [Dapper GitHub repository](https://github.com/DapperLib/Dapper)
- [DB-Engines Ranking of Relational DBMS](https://db-engines.com/en/ranking/relational%2Bdbms/all)

## Further Reading

- [Entity Framework Core documentation](https://learn.microsoft.com/en-us/ef/core/)
- [SQL Server documentation](https://learn.microsoft.com/en-us/sql/sql-server/)
- [Dapper documentation repository](https://github.com/DapperLib/Dapper)
- [EF Core performance documentation](https://learn.microsoft.com/en-us/ef/core/performance/)
- [Connection strings and configuration in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-10.0)
