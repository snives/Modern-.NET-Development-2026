# Docker Compose

## Chapter Purpose

Chapter 10 showed how to package and run one application container. Real
development rarely stops at one process.

An ASP.NET Core API usually needs dependencies: SQL Server, Redis, a message
broker, a mock identity provider, a local storage emulator, or another
service. Before containers, every developer might install these dependencies
directly, point at a shared development server, or maintain a long setup
document. Those approaches work until they do not: versions drift, ports
conflict, credentials differ, shared databases get messy, and onboarding slows
down.

Docker Compose exists to describe and run a multi-container application with
one configuration file and a small set of commands. It lets a team say, "For
local development, this API runs with this SQL Server container, this Redis
container, these environment variables, these ports, these volumes, and this
private network."

Compose was not created specifically for .NET. It became popular across the
container ecosystem because developers needed a simple local orchestration
tool before reaching for full platforms such as Kubernetes. Modern .NET fits
well into that model because ASP.NET Core reads configuration from environment
variables, logs to console, and runs cleanly in Linux containers.

This chapter introduces Docker Compose, application configuration, local SQL
Server, networking, and development environments. It focuses on local and team
development. Production deployment comes later.

## Where This Fits

Docker Compose sits above individual containers and below production
orchestration.

```text
compose.yaml
    |
    +-- api service
    |     +-- ASP.NET Core container
    |     +-- environment variables
    |     +-- exposed host port
    |
    +-- sql service
    |     +-- SQL Server container
    |     +-- password from development config
    |     +-- named volume for data
    |
    +-- redis service
          +-- Redis container
          +-- internal network name

Docker Compose
    |
    v
Local Docker host
```

Chapter 11 completes the Linux and container development section. Chapter 12
then moves toward deploying ASP.NET Core outside the local machine. Later
chapters discuss cloud platforms, observability, distributed applications, and
Kubernetes.

Compose is important because it creates a realistic local system without
requiring cloud infrastructure on day one.

## Connection to the Reader's Existing Model

Think back to a traditional development environment.

You might have installed SQL Server Developer Edition locally, configured IIS
Express, used a shared test database, installed a Windows service dependency,
and kept a setup checklist in a wiki. A senior developer knew the order:
install this, set that port, change this connection string, run that script,
restart that service.

Docker Compose turns much of that setup into a versioned file.

A Compose service is roughly like a named local server process. One service
might run the API. Another might run SQL Server. Another might run Redis.

A Compose network is like a private development network where those services
can reach each other by name. The API does not need to know the SQL Server
container's changing IP address. It can connect to `sql`.

A Compose volume is like a named local disk managed by Docker. It lets SQL
Server data survive container replacement during development.

Environment variables in Compose are like application settings supplied by the
host. They are especially important because ASP.NET Core can bind environment
variables into its configuration system.

The analogy breaks down if you treat Compose as a production cluster. Compose
is excellent for local development, demos, integration testing, and simple
single-host scenarios. It is not a full production orchestrator with
multi-node scheduling, self-healing, policy, ingress, autoscaling, and
platform operations.

## Layer 1 — Conceptual Model

Docker Compose is a tool for defining and running multi-container
applications.

It solves these problems:

- starting multiple related containers together;
- giving services stable names on a private network;
- describing local ports and environment variables;
- attaching volumes for local persistence;
- reducing setup drift between developers;
- making local integration testing more repeatable.

It does not solve these problems by itself:

- it does not replace production orchestration;
- it does not make local secrets production-safe;
- it does not guarantee cloud parity;
- it does not remove the need for database migrations;
- it does not make distributed systems simple;
- it does not automatically wait until dependencies are truly ready unless
  readiness is designed.

The conceptual model is:

```text
Service: one container definition
Project: a group of services
Network: how services find each other
Volume: data that survives container replacement
Environment: configuration supplied to containers
Compose file: versioned description of the local system
```

The most important idea is service names. Inside a Compose network, one
service can usually reach another by its service name. An API service can use
`Server=sql` in its SQL Server connection string because `sql` is the Compose
service name.

## Layer 2 — System Relationships

The Compose file is the source-controlled description of the local container
system. It is commonly named `compose.yaml` or `docker-compose.yml`.

The Compose CLI reads that file and asks the Docker engine to create networks,
volumes, and containers.

Each service describes one container role: image, build context, ports,
environment variables, volumes, dependencies, health checks, and command
overrides.

The Docker network connects services. By default, Compose creates a network
for the project and attaches services to it. Services can resolve each other
by name on that network.

The host port mapping exposes selected container ports to the developer's
machine. A SQL Server container might listen on port `1433` internally, while
the host maps it to `14333` to avoid conflicts with an installed SQL Server.

The named volume stores data outside the container writable layer. This is
useful for a local SQL Server database that should survive `docker compose
down` unless volumes are removed.

The application configuration receives values from Compose environment
variables. ASP.NET Core uses double underscores, such as
`ConnectionStrings__Orders`, to represent nested configuration keys in
environment variables.

Failure boundaries include incorrect indentation, wrong image tags, port
conflicts, missing environment variables, weak local passwords, dependency
containers that start but are not ready, volume state that hides migration
problems, network name mistakes, and assuming a Compose setup is identical to
production.

## Layer 3 — Core Mechanics

A small Compose file for an ASP.NET Core API and SQL Server might look like
this:

```yaml
services:
  api:
    build:
      context: ./Chapter11.Api
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      ASPNETCORE_URLS: "http://+:8080"
      ASPNETCORE_ENVIRONMENT: "Development"
      ConnectionStrings__Orders: "Server=sql,1433;Database=Orders;User Id=sa;Password=${SQL_PASSWORD};TrustServerCertificate=True"
    depends_on:
      sql:
        condition: service_healthy

  sql:
    image: mcr.microsoft.com/mssql/server:2022-latest
    ports:
      - "14333:1433"
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "${SQL_PASSWORD}"
    volumes:
      - sql-data:/var/opt/mssql
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"$${MSSQL_SA_PASSWORD}\" -C -Q \"select 1\" || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10

volumes:
  sql-data:
```

The `api` service builds from a local Dockerfile.

The `sql` service uses Microsoft's SQL Server container image.

The `ports` entry for the API maps host port `8080` to container port `8080`.
The SQL Server mapping exposes host port `14333` to avoid colliding with a
local SQL Server using `1433`.

The `ConnectionStrings__Orders` environment variable becomes the ASP.NET Core
configuration key `ConnectionStrings:Orders`.

The SQL Server password is read from an environment variable named
`SQL_PASSWORD`. In local development, that can come from a `.env` file:

```text
SQL_PASSWORD=Your_strong_password123
```

Do not commit real secrets. For teaching and local-only development, a `.env`
file may be acceptable if it contains disposable values and the team agrees on
the risk. Production secrets require a different mechanism.

Start the environment:

```bash
docker compose up --build
```

Run in the background:

```bash
docker compose up --build -d
```

Inspect services:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs api
docker compose logs sql
```

Stop containers:

```bash
docker compose down
```

Stop and remove volumes:

```bash
docker compose down -v
```

That last command deletes the named volume and therefore local SQL Server data.
Use it deliberately.

## Layer 4 — Developer Workflow

A practical Compose workflow begins with deciding which dependencies belong
locally.

For an ASP.NET Core API, a good first Compose setup might include:

```text
api
sql
redis later, if caching is being developed
```

Create the API:

```bash
dotnet new webapi -n Chapter11.Api
```

Add or reuse the Dockerfile from Chapter 10.

Create `compose.yaml` at the repository root.

Create a local `.env` file if needed:

```bash
SQL_PASSWORD=Your_strong_password123
```

Start the stack:

```bash
docker compose up --build
```

Call the API:

```bash
curl http://localhost:8080/weatherforecast
```

Connect to SQL Server from the host using port `14333` if you have a local SQL
tool:

```text
Server: localhost,14333
User: sa
Password: value from SQL_PASSWORD
Trust server certificate: true for local development
```

When you change C# code, rebuild the image unless your setup uses bind mounts
or a development container workflow:

```bash
docker compose up --build
```

When the database state gets messy during development:

```bash
docker compose down -v
docker compose up --build
```

That reset should feel a little like recreating a local development database,
not like touching production.

## Layer 5 — Production Usage

Compose is often used in local development, demos, integration tests, and
small single-host deployments. For this book, treat it primarily as a
development tool.

Configuration should be explicit and environment-specific. Local Compose
values should not be copied into production blindly. Development passwords,
trusted certificates, broad ports, and debug logging are convenient locally
and dangerous in production.

Secrets should not live in source-controlled Compose files. Compose supports
environment variables and secret-related features, but production secret
handling should be designed with the target platform: cloud secret stores,
managed identities, Kubernetes secrets with proper controls, or CI/CD secret
injection.

Security requires careful port exposure. Services that only the API needs do
not always need host ports. SQL Server can be reachable inside the Compose
network without being exposed to the developer machine unless a local tool
needs it.

Reliability in Compose is limited. `depends_on` controls startup ordering and,
with health checks, can wait for a healthy dependency, but it is not a
complete resilience strategy. The application should still handle dependency
failures.

Deployment to production should use the concepts Compose teaches: explicit
services, environment configuration, networks, volumes, and health. The tool
used in production may be different.

Observability should follow container habits. Logs should go to standard
output. Compose can show logs locally, while production platforms collect logs
centrally.

Scaling with Compose is limited to a single Docker environment. It can run
multiple replicas in some scenarios, but it does not provide the full
multi-node scheduling and service management expected from Kubernetes or
managed container platforms.

Persistence through volumes is useful locally, but production persistence
needs backup, restore, encryption, monitoring, and capacity planning. A named
Docker volume on a developer laptop is not a production data strategy.

Cost is mostly local machine resource cost: CPU, memory, disk, battery, and
developer time. SQL Server and other containers can be heavy. Keep the local
stack useful without making every developer run the entire company on a
laptop.

## Layer 6 — Tradeoffs and Alternatives

Use Docker Compose when a developer needs several containers to work together:
an API and database, API and cache, web frontend and backend, or a small
service set for integration tests.

Do not use Compose when a single process is enough, when a managed development
environment already supplies dependencies, or when the team needs production
orchestration features.

Alternatives include direct local installation, shared development servers,
Dev Containers, GitHub Codespaces, Microsoft Dev Box, Testcontainers for
integration tests, Kubernetes-based development environments, and managed
cloud resources.

Direct local installation can be simpler for one dependency but becomes harder
to standardize across a team.

Shared development servers reduce laptop load but create coupling between
developers and often accumulate state that is hard to reset.

Dev Containers and Codespaces can use Compose under the hood while also
standardizing editor and tool setup.

Testcontainers is useful when tests should start disposable dependencies
programmatically rather than relying on a manually started Compose stack.

Kubernetes is more advanced and appears later. It is a production-grade
orchestration model, not the natural first step for local .NET development.

Common overengineering mistakes:

- putting every company service into one local Compose file;
- exposing every container port to the host;
- treating `.env` files as safe secret storage;
- forgetting that named volumes preserve old database state;
- using `depends_on` as a substitute for retry and health-aware application
  logic;
- making local startup so heavy that developers avoid it;
- assuming Compose is the same as production.

The state-of-the-art direction is focused local environments: enough
dependencies to develop and test the feature, disposable where possible,
configured through environment variables, and close enough to production to
catch meaningful integration problems.

## Layer 7 — Interview Perspective

Interviewers use Compose questions to test whether you understand
multi-container development without confusing it with production
orchestration.

Concepts commonly tested:

- service definitions;
- default networks and service-name DNS;
- host port versus container port;
- environment variables;
- named volumes;
- health checks;
- `depends_on`;
- local SQL Server containers;
- Compose versus Docker;
- Compose versus Kubernetes.

Representative questions:

- "What problem does Docker Compose solve?"
- "How does one service reach another service in Compose?"
- "What is the difference between `8080:8080` and an internal container port?"
- "Why use a named volume for SQL Server?"
- "What happens when you run `docker compose down -v`?"
- "Why is `depends_on` not a complete readiness strategy?"
- "Would you use Compose for production?"

A strong answer distinguishes local composition from production operations:

> "Compose is great for defining a local multi-container environment. The API
> can reach SQL Server by the service name `sql`, and SQL Server can persist
> local data in a named volume. But Compose does not replace production
> orchestration, secret management, backup, monitoring, or resilience design."

Common misconceptions:

- "Compose is just a longer Dockerfile."
- "Compose networking uses localhost between containers."
- "A container is ready when it starts."
- "A named volume is the same as a production database backup."
- "If Compose works locally, production will work the same way."
- "Kubernetes is required for local multi-container development."

Small design scenario:

Your ASP.NET Core order API needs SQL Server and Redis for local development.
New developers spend half a day installing dependencies and often point at the
wrong shared database.

A good Compose setup would define `api`, `sql`, and `redis` services, provide
development-only configuration through environment variables, attach services
to the default network, store SQL Server data in a named volume, expose only
the ports developers need, and document reset commands.

The strong answer improves developer repeatability without pretending local
containers are production.

## Hands-On Lab

Objective:

Run an ASP.NET Core API and SQL Server together with Docker Compose.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- Docker Desktop or another Compose-compatible Docker environment.
- Basic Docker knowledge from Chapter 10.

Steps:

1. Create an API:

   ```bash
   dotnet new webapi -n Chapter11.Api
   ```

2. Add a Dockerfile to `Chapter11.Api` using the pattern from Chapter 10.

3. Create `compose.yaml` next to the `Chapter11.Api` folder.

4. Add an `api` service that builds `Chapter11.Api`.

5. Add a `sql` service using `mcr.microsoft.com/mssql/server:2022-latest`.

6. Add a named volume for SQL Server data.

7. Add environment variables:

   ```yaml
   ConnectionStrings__Orders: "Server=sql,1433;Database=Orders;User Id=sa;Password=${SQL_PASSWORD};TrustServerCertificate=True"
   ```

8. Create a local `.env` file with a strong development password:

   ```text
   SQL_PASSWORD=Your_strong_password123
   ```

9. Start the stack:

   ```bash
   docker compose up --build
   ```

10. Call the API:

    ```bash
    curl http://localhost:8080/weatherforecast
    ```

11. Inspect services and logs:

    ```bash
    docker compose ps
    docker compose logs sql
    ```

12. Stop the stack:

    ```bash
    docker compose down
    ```

Expected results:

- Compose starts the API and SQL Server containers.
- The API is reachable from the host.
- The API can be configured with a SQL Server connection string using the
  Compose service name `sql`.
- SQL Server data is stored in a named volume.

Validation commands:

```bash
docker compose config
docker compose up --build
docker compose ps
docker compose logs api
docker compose logs sql
docker compose down
```

Troubleshooting notes:

- If YAML parsing fails, check indentation.
- If SQL Server exits, check password complexity and license acceptance.
- If the API cannot connect to SQL Server, confirm it uses `sql`, not
  `localhost`, inside the Compose network.
- If the host port is already in use, change the left side of the port mapping.
- If old database state causes confusion, run `docker compose down -v` to
  remove volumes, understanding that this deletes local container data.

## Knowledge Check

1. What problem does Docker Compose solve that `docker run` alone does not?
2. What is a Compose service?
3. How does the API container find the SQL Server container?
4. Why does `localhost` mean different things inside and outside a container?
5. What is the difference between a host port and a container port?
6. Why use a named volume for SQL Server in local development?
7. What does `docker compose down -v` remove?
8. Why are local `.env` files not a production secret-management strategy?
9. What does a health check add to a Compose setup?
10. Why should Compose not be confused with Kubernetes?

## Summary

Docker Compose lets a team describe and run a local multi-container
environment. Instead of every developer hand-installing SQL Server, Redis, and
other dependencies, the repository can define services, networks, volumes,
ports, and environment variables.

For modern .NET development, Compose is especially useful because ASP.NET Core
configuration maps cleanly to environment variables, containers provide
repeatable runtime boundaries, and dependencies such as SQL Server can run
locally without becoming permanent machine state.

Compose is a development and local integration tool first. It teaches the
service, network, volume, and configuration concepts that production platforms
also use, but it does not replace production orchestration, secret management,
backup, monitoring, or resilience.

The next chapter moves from local containers to deploying ASP.NET Core,
including publishing, reverse proxies, hosting choices, configuration, and
production deployment concerns.

## Sources

- [Docker Compose overview](https://docs.docker.com/compose/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker Compose networks](https://docs.docker.com/reference/compose-file/networks/)
- [Docker Compose volumes](https://docs.docker.com/reference/compose-file/volumes/)
- [Docker Compose environment variables](https://docs.docker.com/compose/environment-variables/)
- [Run SQL Server Linux container images with Docker](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17)
- [Configure ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-10.0)

## Further Reading

- [Docker Compose quickstart](https://docs.docker.com/compose/gettingstarted/)
- [Docker Compose command-line reference](https://docs.docker.com/reference/cli/docker/compose/)
- [Docker healthcheck reference](https://docs.docker.com/reference/dockerfile/#healthcheck)
- [Microsoft SQL Server container images](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-configure?view=sql-server-ver17)
- [Use Docker Compose with Visual Studio](https://learn.microsoft.com/en-us/visualstudio/containers/tutorial-multicontainer?view=vs-2022)
