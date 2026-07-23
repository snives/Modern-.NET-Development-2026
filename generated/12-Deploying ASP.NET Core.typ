= Deploying ASP.NET Core
<deploying-asp.net-core>
== Chapter Purpose
<chapter-purpose>
The previous chapters taught how to build, secure, test, and
containerize an ASP.NET Core application. This chapter asks the next
question: how does that application leave the developer machine and run
somewhere users can reach it?

Deployment exists because a running local application is not the same
thing as a production system. A deployed application needs a supported
runtime, a host, configuration, secrets, network exposure, TLS, process
management, logging, health, rollback strategy, and a clear way to know
which version is running.

For a developer with an IIS background, deployment may bring back
familiar ideas: publish output, application pools, site bindings,
reverse proxies, configuration files, Windows services, and load
balancers. ASP.NET Core keeps many of those concerns, but the hosting
choices are broader. The same application can run behind IIS, behind
Nginx on Linux, in a container, in a managed app platform, or later
under Kubernetes.

This chapter introduces publishing, reverse proxies, hosting options,
configuration, and production deployment concerns. It does not teach
every cloud provider or full CI/CD release automation. Chapter 13 covers
cloud platforms, and Chapter 16 covers deployment pipelines.

== Where This Fits
<where-this-fits>
Deployment sits between validated code and production operation.

```text
Source code
    |
    v
Build and test
    |
    v
Publish output or container image
    |
    v
Hosting environment
    |
    +-- process manager
    +-- reverse proxy or load balancer
    +-- configuration and secrets
    +-- TLS and networking
    +-- logs and health checks
    |
    v
Users and dependent systems
```

Chapter 12 is the bridge from local container development to
cloud-native deployment. It explains the deployment vocabulary before
Chapter 13 introduces Azure, AWS, Google Cloud, managed databases,
storage, networking, and identity.

The central distinction is:

```text
Publishing prepares files or images.
Deployment places a specific artifact into a runtime environment.
Operations keeps that environment healthy.
```

Confusing those three steps is a common source of fragile releases.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
Traditional IIS deployment gives a useful starting point.

You may have published a web application, copied files to a server,
configured an IIS site, set an application pool, updated `web.config`,
checked bindings, installed certificates, and restarted the site or app
pool. You knew that deployment was more than compilation.

ASP.NET Core preserves the idea of a published application, but it
changes who owns the process.

In classic ASP.NET, IIS was deeply tied to the request pipeline. In
ASP.NET Core, the application runs as a \.NET process using Kestrel. IIS
can still host ASP.NET Core through the ASP.NET Core Module, but it
usually acts as a front end that forwards requests to the app process.

The same pattern appears on Linux. Nginx or Apache commonly receives
public traffic and forwards requests to Kestrel. In cloud platforms, a
managed load balancer, app gateway, ingress, or platform proxy may play
that role.

An IIS application pool maps conceptually to process ownership and
restart behavior. On Linux, that might be `systemd`. In containers, it
might be the container runtime or orchestrator. In a managed platform,
it might be hidden behind platform settings.

`web.config` maps partly to ASP.NET Core configuration and partly to
hosting configuration. ASP.NET Core can read JSON files, environment
variables, command-line values, user secrets, and external providers.
Production should not depend on hand-editing files on the server.

The analogy breaks down when deployment is treated as server mutation.
Modern deployment prefers identifiable artifacts: a publish folder,
package, or container image built from a known commit and moved through
environments.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Deploying ASP.NET Core means preparing an application artifact and
running it under a host that can serve traffic reliably and securely.

It solves these problems:

- creating deployable output;
- selecting a hosting model;
- starting and restarting the app process;
- exposing HTTP traffic safely;
- supplying environment-specific configuration;
- protecting secrets;
- enabling logs, health, and diagnostics;
- making releases repeatable and traceable.

It does not solve these problems by itself:

- it does not make bad code reliable;
- it does not replace tests or CI;
- it does not choose the right cloud service;
- it does not automatically secure secrets;
- it does not make database migrations safe;
- it does not remove the need for monitoring and rollback.

ASP.NET Core deployment has several common forms:

```text
Framework-dependent publish
  App files depend on a compatible .NET runtime installed on the host.

Self-contained publish
  App carries the .NET runtime for a specific OS and architecture.

Container image
  App and runtime environment are packaged as an OCI image.

Managed platform deployment
  Platform accepts code, package, or image and manages more hosting details.
```

The right model depends on who owns the host, how repeatable the
environment must be, how patching is handled, and what operational
skills the team has.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The build system creates the artifact. For folder-based deployment, it
runs `dotnet publish`. For container deployment, it builds or publishes
a container image. The output should be tied to a source commit and
build record.

The artifact contains application files. A `dotnet publish` output
commonly includes assemblies, dependencies, a `.deps.json` file, a
`.runtimeconfig.json` file, configuration files, and content files
needed by the app.

The runtime host executes the artifact. It might be Windows Server with
IIS, Linux with Nginx and `systemd`, a container host, Azure App
Service, AWS Elastic Beanstalk, Google Cloud Run, or another platform.

Kestrel serves the ASP.NET Core application. In production, Kestrel
commonly runs behind a reverse proxy or load balancer that handles
public edge concerns.

The reverse proxy receives client traffic and forwards it to the app. It
may terminate TLS, enforce request size limits, serve static files, add
forwarded headers, and provide buffering or routing.

The configuration system supplies environment-specific settings:
connection strings, feature flags, logging levels, allowed origins,
external URLs, and identity-provider settings.

The secret system supplies sensitive settings: passwords, certificates,
API keys, client secrets, signing keys, and connection strings.

The operations layer observes and controls the deployment: logs,
metrics, health checks, restarts, alerts, backup coordination, rollback,
and incident response.

Failure boundaries include missing runtimes, wrong runtime identifier,
bad publish output, file permission errors, port conflicts, TLS
misconfiguration, forwarded-header mistakes, missing environment
variables, unavailable databases, failed migrations, unhealthy
instances, and unclear rollback.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
The primary publish command is:

```bash
dotnet publish -c Release
```

Microsoft describes `dotnet publish` as the command that compiles the
application, reads project dependencies, and publishes files to a
directory for deployment to a hosting system.

A framework-dependent publish relies on a compatible \.NET runtime on
the host:

```bash
dotnet publish -c Release --self-contained false
```

A self-contained publish includes the runtime for a target platform:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

A container publish can create an image through the \.NET SDK:

```bash
dotnet publish /t:PublishContainer
```

Or the team can use a Dockerfile, as shown in Chapter 10:

```bash
docker build -t orders-api:2026.07.22 .
```

Kestrel listens on configured URLs. In containers, a common pattern is:

```bash
ASPNETCORE_URLS=http://+:8080
```

When a reverse proxy terminates HTTPS, the request reaching Kestrel may
appear as HTTP. ASP.NET Core needs forwarded headers so features such as
redirects, link generation, authentication callbacks, and client IP
handling can use the original request information.

In non-IIS reverse proxy scenarios, configure forwarded headers
deliberately:

```csharp
using Microsoft.AspNetCore.HttpOverrides;

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders =
        ForwardedHeaders.XForwardedFor |
        ForwardedHeaders.XForwardedProto;
});

var app = builder.Build();

app.UseForwardedHeaders();
```

Only trusted proxies should be allowed to forward headers. Otherwise, a
client could spoof values such as original IP address or scheme.

A Linux service might be managed by `systemd`:

```ini
[Unit]
Description=Orders API

[Service]
WorkingDirectory=/opt/orders-api
ExecStart=/usr/bin/dotnet /opt/orders-api/Orders.Api.dll
Restart=always
RestartSec=10
User=orders
Environment=ASPNETCORE_URLS=http://localhost:5000

[Install]
WantedBy=multi-user.target
```

That file is not the only deployment model. It simply shows the
production concepts: working directory, startup command, restart policy,
user, and environment.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
A basic deployment workflow begins locally:

```bash
dotnet restore
dotnet build -c Release
dotnet test -c Release
dotnet publish -c Release -o ./artifacts/orders-api
```

Inspect the output:

```bash
ls ./artifacts/orders-api
```

Run the published app locally:

```bash
dotnet ./artifacts/orders-api/Orders.Api.dll
```

For a Linux target from a Windows or macOS machine, publish with a
runtime identifier when needed:

```bash
dotnet publish -c Release -r linux-x64 --self-contained false
```

For a container target:

```bash
docker build -t orders-api:dev .
docker run --rm -p 8080:8080 \
  -e ASPNETCORE_URLS=http://+:8080 \
  orders-api:dev
```

Before deploying anywhere shared, answer these questions:

```text
Which commit produced this artifact?
Which .NET version does it target?
Which host will run it?
How is configuration supplied?
Where are secrets stored?
Which port does Kestrel listen on?
Which proxy or load balancer fronts it?
How are logs collected?
How is health checked?
How do we roll back?
```

This workflow still can be manual for learning. In a team, Chapter 16's
deployment pipelines should automate the repeatable parts.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production deployment begins with supported platform choices.

Use a supported \.NET version. Use a supported operating system or
container base image. Know whether the runtime is installed on the host,
included in the artifact, or supplied by a container image.

Configuration should be external to the artifact. The same artifact
should move through environments with different settings supplied by the
platform. Avoid editing published files to create staging or production
variants.

Secrets should come from managed secret systems, secure platform
settings, or short-lived identity mechanisms. Do not deploy secrets in
source, Docker image layers, zip packages, or shell scripts.

Security includes TLS, forwarded headers, trusted proxies,
least-privilege process identities, patched runtimes, restricted
filesystem permissions, secure cookies, CORS configuration,
authentication settings, and dependency updates.

Reliability requires process management. The app should start
automatically, restart after failure when appropriate, stop gracefully,
report health, and fail clearly when configuration or dependencies are
missing.

Deployment should be repeatable. Prefer immutable artifacts and
identifiable versions. Avoid manual server changes that cannot be traced
back to source control or deployment records.

Observability should be present before the first serious release. Logs
should reach a place the team can search. Health endpoints should
support platform checks. Basic metrics and diagnostics arrive in Chapter
14, but deployment should already prepare for them.

Scaling affects deployment shape. A single VM can be enough for a small
internal app. Multiple instances require stateless application design,
shared configuration, centralized logs, load balancing, and careful
database capacity planning.

Persistence must not depend on local app instance storage unless that is
an explicit design. Uploaded files, logs, and user data need durable
storage, databases, or mounted volumes with backup.

Cost depends on hosting choice, runtime size, instance count, logging
volume, network traffic, managed services, and operational labor. A
simple managed platform can be cheaper than a custom VM setup once
maintenance is counted.

Local development optimizes for fast feedback. Production deployment
optimizes for repeatability, security, supportability, and recovery.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use IIS hosting when the organization has strong Windows Server
operations, existing IIS infrastructure, Windows-specific integration,
or a gradual modernization path from older ASP.NET systems.

Use Linux with Nginx or Apache when the team wants direct VM control and
is comfortable owning Linux operations, patching, service management,
TLS, and reverse proxy configuration.

Use containers when repeatable runtime packaging matters and the
deployment target accepts container images.

Use managed app platforms when the team wants to reduce server
management. Azure App Service, Azure Container Apps, AWS Elastic
Beanstalk, AWS App Runner, Google App Engine, and Google Cloud Run are
examples. Chapter 13 compares cloud platform concepts.

Use Kubernetes only when orchestration complexity is justified by scale,
platform standardization, or operational requirements. It is not
required just to deploy an ASP.NET Core API.

Framework-dependent deployment is smaller and lets the host patch shared
runtimes centrally. Self-contained deployment is more isolated and does
not require a preinstalled runtime, but it is larger and shifts runtime
patching responsibility toward the application artifact.

Common overengineering mistakes:

- building a Kubernetes platform for one small app;
- copying files manually and calling it modern deployment;
- storing production configuration in the artifact;
- ignoring reverse proxy forwarded headers;
- using `latest` container tags in production;
- deploying database schema changes with no compatibility plan;
- creating deployment automation before the manual deployment steps are
  understood;
- treating health checks as optional.

The state-of-the-art direction is not one universal host. It is
artifact-based deployment, platform-supplied configuration and secrets,
trusted proxy setup, observable releases, and simple hosting choices
that match the application's risk and scale.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use deployment questions to test whether you understand the
path from code to production.

Concepts commonly tested:

- `dotnet publish`\;
- framework-dependent versus self-contained deployment;
- Kestrel;
- IIS, Nginx, and reverse proxies;
- forwarded headers;
- environment-specific configuration;
- secret handling;
- process management;
- container deployment;
- rollback and health checks.

Representative questions:

- "What does `dotnet publish` produce?"
- "How is deploying ASP.NET Core different from classic ASP.NET?"
- "Why is Kestrel often behind a reverse proxy?"
- "What are forwarded headers and why do they matter?"
- "When would you choose self-contained deployment?"
- "How should production configuration be supplied?"
- "What should you know before deploying a database-backed API?"
- "How would you roll back a bad deployment?"

A strong answer separates publish, deploy, and operate:

#quote(block: true)[
"`dotnet publish` prepares files. Deployment moves a known artifact to a
host and supplies configuration and secrets. Operations keeps it
running, observes health, and supports rollback. For ASP.NET Core, I
also need to understand how Kestrel is exposed, usually through IIS,
Nginx, a load balancer, or a managed platform."
]

Common misconceptions:

- "Publishing is the same as deployment."
- "Kestrel means no reverse proxy is ever needed."
- "Self-contained deployment is always better."
- "Environment variables make secrets automatically safe."
- "If the app runs locally in Docker, deployment is solved."
- "Forwarded headers are only a networking detail."
- "A restart policy replaces health checks and observability."

Small design scenario:

You have an ASP.NET Core order API with SQL Server. The team wants the
first production deployment but does not yet have a full platform team.

A good answer might choose a managed app platform or a simple IIS/Linux
host, publish a Release artifact or container image, externalize
configuration, store secrets in the platform, configure TLS and
forwarded headers, add a basic health endpoint, run database migrations
through a reviewed process, and define rollback before the first
release.

The strong answer keeps the first deployment boring and traceable.

== Hands-On Lab
<hands-on-lab>
Objective:

Publish an ASP.NET Core API and run the published output locally as if
it were a deployment artifact.

Prerequisites:

- \.NET 10 SDK installed, or another currently supported \.NET SDK.
- Basic ASP.NET Core knowledge from Chapter 5.
- Optional Docker knowledge from Chapter 10.

Steps:

+ Create an API:

  ```bash
  dotnet new webapi -n Chapter12.Api
  cd Chapter12.Api
  ```

+ Build and test:

  ```bash
  dotnet build -c Release
  dotnet test -c Release
  ```

  If the project has no tests, note that as a validation gap.

+ Publish to an artifacts folder:

  ```bash
  dotnet publish -c Release -o ../artifacts/chapter12-api
  ```

+ Inspect the publish output:

  ```bash
  ls ../artifacts/chapter12-api
  ```

  On Windows PowerShell:

  ```powershell
  Get-ChildItem ..\artifacts\chapter12-api
  ```

+ Run the published application:

  ```bash
  dotnet ../artifacts/chapter12-api/Chapter12.Api.dll
  ```

+ In another terminal, call the API using the URL printed by the app:

  ```bash
  curl http://localhost:5000/weatherforecast
  ```

+ Publish for Linux x64 as a framework-dependent artifact:

  ```bash
  dotnet publish -c Release -r linux-x64 --self-contained false -o ../artifacts/chapter12-api-linux
  ```

+ Optional: build and run a container image using the Dockerfile pattern
  from Chapter 10.

Expected results:

- The API builds in Release configuration.
- A publish folder is created.
- The published app runs outside the project source folder.
- You can explain what still must be supplied by a real production host.

Validation commands:

```bash
dotnet build -c Release
dotnet publish -c Release
dotnet ../artifacts/chapter12-api/Chapter12.Api.dll
```

Troubleshooting notes:

- If `dotnet test` fails because no test project exists, continue and
  record the gap.
- If the published app cannot find configuration, check copied files and
  environment variables.
- If the app listens on an unexpected port, inspect launch settings
  versus runtime environment variables.
- If publishing to a folder inside the project creates nested publish
  output, publish outside the project directory.

== Knowledge Check
<knowledge-check>
+ Why is publishing not the same as deployment?
+ What does `dotnet publish` prepare?
+ What is the difference between framework-dependent and self-contained
  deployment?
+ Why is Kestrel commonly placed behind a reverse proxy?
+ What information do forwarded headers preserve?
+ Why should production configuration live outside the artifact?
+ What makes a deployment artifact traceable?
+ Why does database migration strategy matter during deployment?
+ What should a health check prove?
+ When is a managed hosting platform simpler than a VM?

== Summary
<summary>
Deploying ASP.NET Core means preparing a known artifact and running it
in a hosted environment with configuration, secrets, networking, process
management, logs, health, and rollback.

`dotnet publish` creates deployable output. Framework-dependent
deployment relies on a shared runtime. Self-contained deployment carries
the runtime. Container deployment packages the application and runtime
environment as an image. Hosting may involve IIS, Nginx, Apache,
containers, managed platforms, or eventually Kubernetes.

The most important deployment habit is to keep artifacts and
environments separate. Build the artifact once. Supply
environment-specific configuration and secrets through the host. Know
which version is running. Make the release observable and reversible.

The next chapter expands the hosting discussion into cloud platforms:
Azure, AWS, Google Cloud, managed databases, storage, networking, and
identity.

== Sources
<sources>
- #link("https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-publish")[dotnet publish command]
- #link("https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/?view=aspnetcore-10.0")[ASP.NET Core host and deploy overview]
- #link("https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-10.0")[Configure ASP.NET Core to work with proxy servers and load balancers]
- #link("https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/linux-nginx?view=aspnetcore-10.0")[Host ASP.NET Core on Linux with Nginx]
- #link("https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/building-net-docker-images?view=aspnetcore-10.0")[Run an ASP.NET Core app in Docker containers]
- #link("https://dotnet.microsoft.com/en-us/learn/aspnet/what-is-aspnet-core")[What is ASP.NET Core?]

== Further Reading
<further-reading>
- #link("https://learn.microsoft.com/en-us/dotnet/core/deploying/")[\.NET application publishing overview]
- #link("https://learn.microsoft.com/en-us/dotnet/core/runtime-config/")[Runtime configuration options for \.NET]
- #link("https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-10.0")[Host ASP.NET Core on Windows with IIS]
- #link("https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments?view=aspnetcore-10.0")[ASP.NET Core environments]
- #link("https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-10.0")[ASP.NET Core configuration]
