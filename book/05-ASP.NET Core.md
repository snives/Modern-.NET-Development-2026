# ASP.NET Core

## Chapter Purpose

Modern .NET becomes most visible when it is used to build web applications and
HTTP APIs. ASP.NET Core is the framework that makes that happen.

If your previous web development model was ASP.NET MVC or Web API hosted in
IIS, ASP.NET Core will feel familiar in some places and very different in
others. It still handles HTTP requests, routing, controllers, configuration,
dependency injection, logging, authentication, and responses. But it is no
longer built around System.Web, IIS, or a Windows-only hosting model.

ASP.NET Core exists because the classic ASP.NET stack had become too tightly
coupled to Windows, IIS, and a large framework surface. The industry had moved
toward lightweight HTTP services, Linux hosting, containers, reverse proxies,
cloud platforms, and high-throughput APIs. Frameworks such as Node.js Express,
Ruby on Rails, Spring Boot, Django, FastAPI, and Go's HTTP ecosystem shaped
developer expectations around simple startup, explicit routing, middleware,
and portable hosting.

ASP.NET Core was Microsoft's answer: a redesigned, cross-platform,
high-performance web framework for modern .NET. By 2026, it is the standard
web framework for current .NET applications.

This chapter introduces ASP.NET Core's place in the system and its core
building blocks: Minimal APIs, controllers, dependency injection,
configuration, middleware, and logging. Later chapters go deeper into data,
security, testing, deployment, observability, and cloud hosting.

## Where This Fits

ASP.NET Core sits between users or clients and the rest of the application
system.

```text
Browser, mobile app, service client, or integration partner
        |
        v
HTTP request
        |
        v
ASP.NET Core host
        |
        +-- Middleware pipeline
        |
        +-- Routing
        |
        +-- Minimal API endpoint or controller action
        |
        +-- Application services through dependency injection
        |
        +-- Configuration and logging
        |
        v
Database, cache, queue, file storage, external API, or AI service
```

This chapter is the first point where the book turns the platform concepts
from Chapters 1-4 into a running server application. It prepares for Chapter 6
on data access, Chapter 7 on authentication and security, Chapter 8 on testing
and CI, and later deployment chapters.

ASP.NET Core is not the whole application. It is the HTTP boundary. A good
ASP.NET Core application still needs clear business logic, data access,
validation, security, deployment, and observability. The framework gives the
request-processing structure where those concerns meet.

## Connection to the Reader's Existing Model

Classic ASP.NET applications were naturally understood through IIS.

IIS received the request, selected the site and application pool, loaded the
application, applied modules, handed the request into ASP.NET, and wrote the
response. Configuration often lived in `web.config`. The application pool
identity affected file and database access. IIS logs and Windows Event Log
were primary diagnostic tools.

ASP.NET Core changes the center.

An ASP.NET Core application is a .NET process. That process contains a web
host, configuration, services, middleware, routes, endpoints, and logging. IIS
can still be involved, especially on Windows, but it is often a reverse proxy
or hosting integration layer rather than the conceptual owner of the
application.

The analogy to IIS application pools is still useful for process isolation.
The analogy breaks down because ASP.NET Core can run behind IIS, Nginx, Apache,
a cloud load balancer, a container platform, or directly through Kestrel.
Kestrel is ASP.NET Core's cross-platform web server.

HTTP modules and handlers from classic ASP.NET map conceptually to middleware
and endpoints. Middleware handles cross-cutting request behavior such as
exception handling, HTTPS redirection, static files, routing, authentication,
authorization, compression, and custom request processing. Endpoints handle the
application-specific request.

Controllers remain familiar if you used ASP.NET MVC or Web API. They group
related actions into classes, use attributes for routing and behavior, and
work well for larger APIs with conventions, filters, and model binding.

Minimal APIs are newer. They let you define HTTP endpoints directly in code
with less ceremony. They are especially useful for small APIs, microservices,
and services where endpoint behavior is easier to read inline or in small
route groups.

Configuration files still matter, but configuration is broader than files.
ASP.NET Core can read configuration from JSON files, environment variables,
command-line arguments, user secrets, and external providers. This matches
modern deployment where production settings often come from the hosting
platform.

Dependency injection is built in. If you previously used a third-party IoC
container or manually constructed services, ASP.NET Core makes service
registration and constructor injection part of the default application model.

Logging is built in as a framework abstraction. Instead of writing only to a
local file or Windows Event Log, the application can emit structured events
that local tools, cloud platforms, or observability systems can collect.

## Layer 1 — Conceptual Model

ASP.NET Core is a framework for building HTTP-based applications on modern
.NET.

It solves these problems:

- accepting HTTP requests;
- routing requests to application code;
- binding request data to .NET types;
- producing HTTP responses;
- composing cross-cutting request behavior;
- managing application services through dependency injection;
- reading configuration from multiple sources;
- emitting logs and diagnostics;
- hosting on Windows, Linux, containers, and cloud platforms.

It does not solve these problems by itself:

- it does not design your domain model;
- it does not choose your database strategy;
- it does not make endpoints secure unless security is configured;
- it does not guarantee API usability;
- it does not replace tests;
- it does not remove deployment and operations concerns;
- it does not make distributed systems simple.

The conceptual center is the request pipeline.

```text
Request -> Middleware -> Routing -> Endpoint -> Response
```

Middleware is software assembled into a pipeline. Each middleware component can
work before the next component, work after the next component, pass the request
forward, or stop the pipeline early. Microsoft calls this stopping behavior
short-circuiting.

An endpoint is the application code selected to handle a request. In ASP.NET
Core APIs, the endpoint is often a Minimal API handler or a controller action.

Services are application dependencies registered with the dependency injection
container. Endpoints, controllers, middleware, and other services can request
those dependencies through constructors or parameters.

Configuration provides values the application needs without hard-coding them:
connection strings, feature flags, external service URLs, logging levels,
security settings, and environment-specific behavior.

Logging provides a record of what the application is doing. In modern systems,
logs are part of production visibility, not just debugging.

## Layer 2 — System Relationships

ASP.NET Core interacts with several surrounding components.

The client sends an HTTP request. The client might be a browser, mobile app,
JavaScript frontend, another service, a scheduled job, a webhook provider, or
an integration partner. The request includes method, path, headers, body,
query string, cookies, and connection information.

The host starts the application process. It loads configuration, sets up
logging, registers services, builds the middleware pipeline, maps endpoints,
and begins listening for requests. In the minimal hosting model, this startup
code usually lives in `Program.cs`.

The web server receives HTTP traffic. Kestrel is the built-in cross-platform
web server used by ASP.NET Core. In production, Kestrel is often placed behind
a reverse proxy, load balancer, or platform ingress that handles internet
edge concerns.

The middleware pipeline owns cross-cutting HTTP behavior. Inputs include the
request and current application state. Outputs include a modified request,
response, logs, authentication state, errors, or an early response.

Routing selects the endpoint. It compares the HTTP method and path with mapped
routes. It may also consider route constraints and endpoint metadata.

Minimal API handlers or controller actions own request-specific application
behavior. They should validate input, call application services, and return
clear responses. They should not become dumping grounds for database and
business logic.

Application services own business operations. They are registered with
dependency injection and consumed by endpoints. This keeps HTTP details from
swallowing the entire application design.

Configuration providers own environment-specific values. Local development may
use `appsettings.Development.json` and user secrets. Production may use
environment variables, secret stores, or cloud configuration services.

Logging providers own output destinations. The application writes through the
ASP.NET Core logging abstraction. Providers send those events to console,
debug output, files, cloud systems, or observability backends.

Failure boundaries include startup failure, missing configuration, dependency
registration errors, middleware ordering mistakes, route conflicts, model
binding failures, invalid input, unhandled exceptions, downstream service
failures, thread-pool exhaustion, connection limits, and incomplete logging.

The most common learning mistake is treating ASP.NET Core as one object called
"the web app." It is better understood as a host, pipeline, endpoint model,
service container, configuration system, and logging system working together.

## Layer 3 — Core Mechanics

The smallest useful ASP.NET Core application is a Minimal API.

```csharp
var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () => "Hello from ASP.NET Core");

app.Run();
```

This small program contains the basic shape.

`WebApplication.CreateBuilder(args)` creates the builder. The builder gathers
configuration, logging, services, and host settings.

`builder.Services` is where application services are registered:

```csharp
builder.Services.AddSingleton<Clock>();
```

`builder.Build()` creates the application.

`app.MapGet("/", ...)` maps an HTTP GET request for `/` to an endpoint handler.

`app.Run()` starts the application and blocks until shutdown.

Middleware is added before the application starts:

```csharp
app.UseHttpsRedirection();

app.MapGet("/time", (Clock clock) =>
{
    return new { utc = clock.GetUtcNow() };
});
```

The order matters. Middleware runs in the order it is registered. A middleware
component can affect everything after it.

A simple service might look like this:

```csharp
public sealed class Clock
{
    public DateTimeOffset GetUtcNow() => DateTimeOffset.UtcNow;
}
```

ASP.NET Core can provide that service to the endpoint because it was
registered with dependency injection.

Controllers use a class-based model:

```csharp
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public sealed class TimeController : ControllerBase
{
    private readonly Clock _clock;

    public TimeController(Clock clock)
    {
        _clock = clock;
    }

    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { utc = _clock.GetUtcNow() });
    }
}
```

To use controllers, the app registers controller services and maps controller
endpoints:

```csharp
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();
```

Minimal APIs and controllers are not enemies. They are two endpoint styles.
Microsoft currently recommends Minimal APIs for new HTTP API projects because
they provide a simplified, high-performance approach with minimal code and
configuration. Controllers remain useful for larger APIs, MVC conventions,
filters, and teams that prefer class-based organization.

Configuration is available through `builder.Configuration`:

```csharp
var connectionString = builder.Configuration.GetConnectionString("Orders");
```

Logging is available through `ILogger<T>`:

```csharp
public sealed class OrderReporter
{
    private readonly ILogger<OrderReporter> _logger;

    public OrderReporter(ILogger<OrderReporter> logger)
    {
        _logger = logger;
    }

    public void ReportCreated(int orderId)
    {
        _logger.LogInformation("Order {OrderId} was created", orderId);
    }
}
```

The `{OrderId}` placeholder is a structured logging property. This is more
useful than building one long string because logging systems can preserve the
property as searchable data.

## Layer 4 — Developer Workflow

Create a new ASP.NET Core web API:

```bash
dotnet new webapi -n Orders.Api
cd Orders.Api
dotnet run
```

The template creates an ASP.NET Core project using the web SDK:

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
```

Run the app and look for the listening URLs in the console output. Local
development typically uses HTTPS and a development certificate.

Inspect the available project templates:

```bash
dotnet new list web
```

Build the project:

```bash
dotnet build
```

Run with automatic rebuild during development:

```bash
dotnet watch
```

`dotnet watch` is useful because web development often involves small edits
and fast feedback.

Call an endpoint from another terminal. The exact URL and endpoint depend on
the template and launch profile:

```bash
curl https://localhost:5001/weatherforecast
```

On Windows PowerShell, use:

```powershell
Invoke-RestMethod https://localhost:5001/weatherforecast
```

If the template uses a different port, use the URL printed by `dotnet run`.

Add a small endpoint in `Program.cs`:

```csharp
app.MapGet("/health/basic", () => Results.Ok(new { status = "ok" }));
```

Run again and call the endpoint:

```bash
curl https://localhost:5001/health/basic
```

The developer workflow is intentionally simple at this stage:

```text
Create project -> run locally -> add endpoint -> call endpoint -> inspect logs
```

Later chapters add data access, authentication, tests, containers, deployment,
and observability.

## Layer 5 — Production Usage

Production ASP.NET Core begins with hosting clarity.

Kestrel is the ASP.NET Core web server. In production it may run behind IIS,
Nginx, Apache, a cloud load balancer, or a container ingress. The outer server
or platform often handles TLS termination, request forwarding, static edge
concerns, and network exposure. The ASP.NET Core app handles application
routing and behavior.

Configuration should be environment-specific. Local development can use
`appsettings.Development.json` and user secrets. Production should use
environment variables, managed configuration, secret stores, or platform
settings. Never commit production secrets.

Security includes more than login. HTTPS, forwarded headers, CORS,
authentication, authorization, anti-forgery for browser forms, secure cookies,
rate limiting, input validation, dependency patching, and safe error handling
all matter. Chapter 7 covers authentication and authorization in detail.

Reliability depends on startup behavior, health checks, timeouts, cancellation
tokens, retry policy, graceful shutdown, and clear failure modes when
dependencies are unavailable. An API that hangs under dependency failure is
harder to operate than one that fails clearly.

Deployment should use a repeatable artifact. ASP.NET Core apps can be
published as framework-dependent deployments, self-contained deployments,
container images, or platform-specific packages. Chapter 12 covers deployment
more fully.

Observability starts with logs. ASP.NET Core emits framework logs and lets the
application emit structured logs through `ILogger<T>`. Production systems
should also expose health and later add metrics and tracing. Chapter 14 covers
observability basics.

Scaling requires statelessness where possible. A load-balanced ASP.NET Core
API should not assume that all requests from one user reach the same process.
Session-like data, cache data, background work, and file storage need explicit
design.

Persistence belongs behind clear service and data-access boundaries. Do not
put SQL queries, migrations, and transaction logic directly into endpoint
handlers unless the application is deliberately tiny. Chapter 6 covers data
access.

Cost is affected by hosting choice, memory use, request volume, logging
volume, dependency calls, and scaling settings. An inefficient endpoint can
cost money in cloud environments even if it seems harmless locally.

Local development optimizes for fast iteration and clear debugging. Production
optimizes for secure configuration, predictable startup, repeatable deployment,
visibility, reliability, and controlled scale.

## Layer 6 — Tradeoffs and Alternatives

Use ASP.NET Core when you need to build HTTP APIs, web applications,
server-rendered pages, real-time services, gRPC services, backend-for-frontend
services, or cloud-hosted .NET workloads.

Do not use ASP.NET Core when a simpler process is enough. A scheduled job,
command-line import, Windows service, worker service, or serverless function
may be a better fit if there is no HTTP boundary.

Minimal APIs are a strong default for new HTTP APIs, especially when endpoints
are small, routing is explicit, and the team values low ceremony.

Controllers are strong when the API benefits from class-based organization,
filters, conventions, attribute-heavy behavior, shared base controller
patterns, or a team already has a mature controller-based style.

Razor Pages, MVC views, and Blazor are alternatives for applications that
render user interfaces rather than only HTTP APIs. They are part of the
ASP.NET Core family, but this chapter focuses on APIs because later samples
build from API foundations.

Competing web frameworks include Spring Boot for Java, Express and Fastify for
Node.js, Django and FastAPI for Python, Ruby on Rails, Laravel for PHP, and Go
HTTP frameworks. ASP.NET Core is especially strong for C# teams that need
performance, mature tooling, enterprise integration, and cloud-ready APIs.
Stack Overflow's 2025 Developer Survey lists ASP.NET Core among the web
frameworks and technologies used by professional developers, though JavaScript
and Python web ecosystems remain very common across the broader industry.

State-of-the-art ASP.NET Core development in 2026 emphasizes Minimal APIs,
OpenAPI descriptions, built-in dependency injection, structured logging,
configuration from the host environment, container-friendly hosting,
health-oriented operations, and careful security defaults.

Common overengineering mistakes:

- creating controllers, services, repositories, factories, and wrappers before
  the endpoint has real complexity;
- putting all business logic directly in Minimal API lambdas;
- treating middleware order as incidental;
- using global mutable state for request-specific behavior;
- returning inconsistent error shapes from related endpoints;
- logging secrets or entire request bodies in production;
- assuming local HTTPS, ports, and configuration match production hosting.

The right choice is usually staged: start with clear endpoints, simple service
boundaries, good configuration, useful logs, and tests. Add framework features
when they solve an actual pressure.

## Layer 7 — Interview Perspective

Interviewers use ASP.NET Core questions to test whether you understand the
modern web application model.

Concepts commonly tested:

- Kestrel and hosting;
- middleware pipeline and ordering;
- routing and endpoints;
- Minimal APIs versus controllers;
- dependency injection lifetimes;
- configuration providers;
- logging and structured logging;
- environment-specific behavior;
- production concerns such as HTTPS, health checks, and reverse proxies.

Representative questions:

- "How is ASP.NET Core different from classic ASP.NET?"
- "What is middleware?"
- "Why does middleware order matter?"
- "When would you choose Minimal APIs versus controllers?"
- "How does dependency injection work in ASP.NET Core?"
- "Where should configuration come from in production?"
- "What is Kestrel?"
- "How would you structure a small API so business logic does not live entirely
  in endpoint handlers?"

A strong answer connects the request pipeline to application boundaries:

> "ASP.NET Core receives a request through the host and passes it through an
> ordered middleware pipeline. Routing selects an endpoint, such as a Minimal
> API handler or controller action. That endpoint should coordinate application
> services through dependency injection rather than contain all business and
> data-access logic directly."

Common misconceptions:

- "ASP.NET Core requires IIS."
- "Minimal APIs are only for toy applications."
- "Controllers are obsolete."
- "Middleware order rarely matters."
- "Dependency injection is optional plumbing with no design impact."
- "Logging is only for debugging locally."
- "Configuration files are the only configuration source."
- "A passing local request proves the API is production-ready."

Small design scenario:

You need to build an internal order-status API. It has five endpoints, calls
SQL Server, and will later require authentication.

A good first design might use Minimal APIs with route groups, a small
application service for order status operations, configuration for the database
connection, structured logging, and simple health reporting. It would avoid
Kubernetes, custom middleware, caching, or complex architecture until the API
has a real need.

If the API grows to dozens of endpoints with shared filters, complex request
models, and strong team conventions around controller organization,
controllers may become the more natural endpoint style.

## Hands-On Lab

Objective:

Create a small ASP.NET Core API, add an endpoint, register a service, and call
the endpoint locally.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- A terminal.
- A browser, `curl`, or PowerShell.

Steps:

1. Create the API:

   ```bash
   dotnet new webapi -n Chapter05.Api
   cd Chapter05.Api
   ```

2. Run the application:

   ```bash
   dotnet run
   ```

3. Note the HTTPS URL printed in the console.

4. In another terminal, call the default endpoint. Adjust the URL and path to
   match the template output:

   ```bash
   curl https://localhost:5001/weatherforecast
   ```

5. Stop the application.

6. Add this service class:

   ```csharp
   public sealed class SystemClock
   {
       public DateTimeOffset GetUtcNow() => DateTimeOffset.UtcNow;
   }
   ```

7. Register the service in `Program.cs` before `builder.Build()`:

   ```csharp
   builder.Services.AddSingleton<SystemClock>();
   ```

8. Add an endpoint after the app is built:

   ```csharp
   app.MapGet("/time", (SystemClock clock) =>
   {
       return Results.Ok(new { utc = clock.GetUtcNow() });
   });
   ```

9. Run the application again:

   ```bash
   dotnet run
   ```

10. Call the new endpoint:

    ```bash
    curl https://localhost:5001/time
    ```

11. On Windows PowerShell, use:

    ```powershell
    Invoke-RestMethod https://localhost:5001/time
    ```

Expected results:

- The API starts locally.
- The default endpoint responds.
- The `/time` endpoint returns a JSON response containing a UTC timestamp.
- The service is provided through dependency injection.
- The console shows ASP.NET Core logging output.

Validation commands:

```bash
dotnet build
dotnet run
curl https://localhost:5001/time
```

Troubleshooting notes:

- If the port is different, use the URL printed by `dotnet run`.
- If HTTPS fails locally, trust the development certificate or use the HTTP URL
  printed by the application.
- If dependency injection fails, confirm the service was registered before
  `builder.Build()`.
- If the endpoint returns 404, confirm the route string and that the app was
  restarted after editing.

## Knowledge Check

1. Why is ASP.NET Core better understood as a request-processing framework than
   as "IIS for modern .NET"?
2. What role does Kestrel play?
3. What is middleware, and why does order matter?
4. How is a Minimal API endpoint different from a controller action?
5. When might controllers be a better fit than Minimal APIs?
6. Why should application services be separated from endpoint handlers as an
   API grows?
7. What kinds of values belong in configuration rather than code?
8. Why is structured logging more useful than string-only logging?
9. What production concerns appear before data access or authentication are
   added?
10. How does ASP.NET Core's hosting model support Windows, Linux, containers,
    and cloud platforms?

## Summary

ASP.NET Core is the modern .NET framework for HTTP applications. It replaced
the old System.Web-centered mental model with a cross-platform host, Kestrel,
an ordered middleware pipeline, endpoint routing, built-in dependency
injection, flexible configuration, and integrated logging.

Minimal APIs provide a low-ceremony way to build HTTP APIs and are the modern
default for many new API projects. Controllers remain valuable for larger APIs
and teams that benefit from class-based organization and conventions.

The most important idea is the pipeline: requests enter the host, pass through
middleware, route to endpoints, use services through dependency injection, and
return responses while emitting logs and diagnostics.

The next chapter adds the data layer. With ASP.NET Core as the HTTP boundary,
the application now needs durable state, queries, migrations, and performance
discipline.

## Sources

- [ASP.NET documentation](https://learn.microsoft.com/en-us/aspnet/core/?view=aspnetcore-10.0)
- [ASP.NET Core fundamentals overview](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/?view=aspnetcore-10.0)
- [Tutorial: Create a Minimal API with ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/tutorials/min-web-api?view=aspnetcore-10.0)
- [APIs overview](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis?view=aspnetcore-10.0)
- [ASP.NET Core Middleware](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-10.0)
- [Overview of OpenAPI support in ASP.NET Core API apps](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0)
- [Stack Overflow 2025 Developer Survey: Technology](https://survey.stackoverflow.co/2025/technology/)

## Further Reading

- [Understand ASP.NET Core fundamentals](https://learn.microsoft.com/en-us/training/paths/aspnet-core-fundamentals/)
- [Configure services with dependency injection in ASP.NET Core](https://learn.microsoft.com/en-us/training/modules/configure-dependency-injection/)
- [Customize ASP.NET Core behavior with middleware](https://learn.microsoft.com/en-us/training/modules/customize-aspnet-core-middleware/)
- [Create web APIs with ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/web-api/?view=aspnetcore-10.0)
