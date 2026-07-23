# Observability Basics and Production Diagnostics

## Chapter Purpose

Chapter 13 showed that modern .NET applications often run on cloud platforms,
managed hosts, containers, and services the team does not log into directly.
That changes how production problems are understood.

In a traditional IIS environment, diagnostics often began with Remote Desktop,
Event Viewer, IIS logs, Windows Performance Monitor, SQL Server Management
Studio, and maybe a shared logging folder. Those tools were useful because the
server was visible and relatively stable.

Modern production systems are less server-centered. An ASP.NET Core API may
run in several instances, inside containers, behind a load balancer, connected
to managed databases, using cloud identity, and writing logs to a centralized
system. A failed request may not be reproducible on a single machine. The
container that handled it may already be gone.

Observability exists so teams can understand a running system from the outside
using signals the system emits: logs, metrics, health checks, traces, events,
alerts, and diagnostics artifacts. This chapter introduces the basics:
ASP.NET Core logging, health checks, structured logging, basic metrics, local
diagnostics, and production monitoring concepts.

Advanced distributed tracing and multi-service monitoring come later in
Chapter 19. This chapter gives you enough observability knowledge to understand
a deployed application before the system becomes distributed.

## Where This Fits

Observability sits beside the running application and feeds information back
to the team.

```text
Users and clients
        |
        v
ASP.NET Core application
        |
        +-- logs: what happened?
        +-- health checks: can it serve traffic?
        +-- metrics: how much, how fast, how many errors?
        +-- diagnostics: what is happening inside the process?
        |
        v
Monitoring and alerting system
        |
        v
Developers and operators
```

Chapter 14 follows cloud platforms because deployed applications need
visibility immediately. It prepares for Chapter 15 on distributed applications,
where failures can involve caches, queues, and background services, and for
Chapter 19 on advanced observability.

The goal is not to install every monitoring product. The goal is to understand
which signals a modern .NET application should emit and how those signals help
the team diagnose production behavior.

## Connection to the Reader's Existing Model

You already know production diagnostics in older environments.

Windows Event Log recorded system and application events. IIS logs recorded
requests. SQL Server had query plans, wait stats, and error logs. Performance
Monitor exposed counters. A load balancer could show whether a node was
healthy. Remote Desktop gave direct access to a server.

Modern observability keeps the same intent but changes the collection model.

ASP.NET Core logging maps to Event Log and application logs, but it is
provider-based and often writes to console, cloud logging systems, or
third-party sinks. In containers, console output is usually the right default
because the platform collects it.

Health checks map to load balancer probes and service-monitor checks. They
answer whether an instance should receive traffic or whether a dependency is
available.

Metrics map to performance counters, but they are usually collected by
monitoring systems and visualized in dashboards. They answer rate, duration,
count, and resource questions.

Structured logging improves on plain text logs by preserving named values such
as `OrderId`, `UserId`, `StatusCode`, or `ElapsedMilliseconds`. That makes
logs searchable and aggregatable.

Local diagnostics tools such as `dotnet-counters`, `dotnet-dump`,
`dotnet-trace`, and `dotnet-monitor` map to the familiar idea of inspecting a
process. The tools are different, but the question is the same: what is the
process doing right now?

The analogy breaks down when you assume you can always inspect the server
after the fact. In cloud and container systems, instances are replaceable and
ephemeral. If the application did not emit useful signals while the problem
happened, the evidence may be gone.

## Layer 1 — Conceptual Model

Observability is the ability to understand a system's behavior from the
signals it produces.

It solves these problems:

- discovering whether the application is healthy;
- diagnosing failures after deployment;
- detecting slow responses and error spikes;
- understanding dependency failures;
- alerting humans when action is needed;
- supporting rollback and incident response;
- creating feedback for future development.

It does not solve these problems by itself:

- it does not prevent bugs;
- it does not replace tests;
- it does not make logs useful if the app logs the wrong things;
- it does not fix performance problems automatically;
- it does not remove the need for security and privacy discipline;
- it does not make every alert actionable.

The basic observability model is:

```text
Logs explain events.
Health checks report readiness or liveness.
Metrics quantify behavior over time.
Diagnostics tools inspect process internals.
Alerts turn important signals into action.
```

.NET documentation commonly describes logs, metrics, and distributed traces as
the three pillars of observability. This chapter emphasizes logs, health, and
metrics first. Distributed tracing becomes more important once requests cross
multiple services.

## Layer 2 — System Relationships

The application emits signals. ASP.NET Core produces framework logs, request
metrics, and health check responses. Application code adds business-specific
logs and measurements.

The logging provider decides where logs go. Built-in providers include console
and debug output. Other providers can send logs to Azure, Application
Insights, OpenTelemetry collectors, files, or third-party systems.

The health check endpoint responds to probes. Load balancers, container
platforms, cloud services, uptime monitors, and deployment systems can call
that endpoint.

The metrics pipeline collects numeric measurements. Metrics can come from
ASP.NET Core, the .NET runtime, libraries, and application code. Monitoring
systems store and graph those measurements.

The diagnostics tool connects to a running .NET process. Tools can collect
counters, dumps, traces, stacks, and other artifacts. These are especially
useful when logs and metrics show a problem but not the cause.

The alerting system evaluates signals against thresholds, anomaly rules, or
service-level objectives. It notifies people or automation when the signal
requires action.

The operations process owns response. A dashboard is not enough. Someone must
know what the alert means, how to investigate it, and when to escalate.

Failure boundaries include missing logs, overbroad log levels, sensitive data
in logs, health checks that always return healthy, metrics with high
cardinality, alerts that are too noisy, dashboards no one uses, local-only
diagnostics, and telemetry costs that grow without review.

## Layer 3 — Core Mechanics

ASP.NET Core logging uses `ILogger<T>`:

```csharp
public sealed class OrderService
{
    private readonly ILogger<OrderService> _logger;

    public OrderService(ILogger<OrderService> logger)
    {
        _logger = logger;
    }

    public void MarkShipped(int orderId)
    {
        _logger.LogInformation(
            "Order {OrderId} was marked shipped",
            orderId);
    }
}
```

`{OrderId}` is a structured property. A logging backend can search or filter
by `OrderId` more reliably than it can parse arbitrary text.

Log levels communicate severity:

```text
Trace       very detailed diagnostics
Debug       development and troubleshooting detail
Information normal application events
Warning     unexpected but handled situations
Error       failures in an operation
Critical    severe failures requiring immediate attention
```

Health checks are registered and mapped:

```csharp
builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapHealthChecks("/health");
```

A basic health endpoint proves the app can respond. More advanced checks can
probe dependencies such as SQL Server, queues, or external services. Do not
make every health check depend on every downstream service unless that is
really the desired traffic-routing behavior.

ASP.NET Core includes built-in metrics. Examples include request duration,
request counts, and response status information. Metrics answer questions such
as:

```text
How many requests are arriving?
How long do requests take?
How many fail?
Which status codes are increasing?
Is memory rising?
Is the thread pool saturated?
```

Local diagnostics tools provide process-level insight:

```bash
dotnet-counters monitor --process-id <pid>
dotnet-dump collect --process-id <pid>
dotnet-trace collect --process-id <pid>
```

`dotnet-monitor` can collect diagnostic artifacts such as dumps, traces, logs,
and metrics from .NET applications, including production environments when
configured carefully.

Use these tools with care in production. Dumps and traces can contain
sensitive data and can affect performance.

## Layer 4 — Developer Workflow

Start with local visibility before production visibility.

Create an API:

```bash
dotnet new webapi -n Chapter14.Api
cd Chapter14.Api
```

Add a health check endpoint:

```csharp
builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapHealthChecks("/health");
```

Run the app:

```bash
dotnet run
```

Call the health endpoint:

```bash
curl http://localhost:5000/health
```

Add structured logging to an endpoint:

```csharp
app.MapGet("/orders/{id:int}", (
    int id,
    ILogger<Program> logger) =>
{
    logger.LogInformation("Loading order {OrderId}", id);

    return Results.Ok(new { id });
});
```

Run and inspect console logs.

Find the process ID:

```bash
dotnet-trace ps
```

Monitor counters:

```bash
dotnet-counters monitor --process-id <pid>
```

For a deployed app, the workflow changes:

```text
Check health endpoint
        |
        v
Check recent logs
        |
        v
Check request rate, duration, and error metrics
        |
        v
Check dependency status
        |
        v
Collect deeper diagnostics only if needed
```

This order matters. Do not collect a memory dump before checking whether the
app is simply missing a connection string.

## Layer 5 — Production Usage

Production observability starts before deployment.

Configuration should set appropriate log levels per environment. Development
can use more verbose logs. Production should default to useful information,
warnings, errors, and targeted debugging when needed.

Secrets must not appear in logs, metrics tags, health responses, dumps shared
carelessly, or exception messages shown to clients. Treat telemetry as data
that requires security review.

Security monitoring should include authentication failures, authorization
failures, suspicious request patterns, administrative actions, and unexpected
configuration changes. Avoid logging full tokens, passwords, or sensitive
claims.

Reliability depends on health checks that mean something. A liveness check can
answer "is the process alive?" A readiness check can answer "should this
instance receive traffic?" Those are different questions.

Deployment needs observability. A release should be watched through health,
error rate, request duration, and key business indicators. A rollback decision
should be based on signals, not vibes.

Observability data should be centralized for multi-instance applications. If
each instance keeps local logs only, diagnosis becomes slow and incomplete.

Scaling requires metrics. Autoscaling decisions often use CPU, memory,
request rate, queue length, or custom metrics. Bad metrics can cause bad
scaling behavior.

Persistence matters because logs and metrics need retention rules. Keeping
everything forever is expensive. Keeping too little makes incidents impossible
to investigate.

Cost must be managed. High-volume logs, high-cardinality metrics, long
retention, and verbose traces can become expensive. Observability should be
designed like any other production dependency.

Local diagnostics optimize for detail. Production monitoring optimizes for
continuous, secure, actionable signals.

## Layer 6 — Tradeoffs and Alternatives

Use built-in ASP.NET Core logging and health checks for nearly every
production application. They are foundational.

Use provider-native monitoring when running on a cloud platform and the team
benefits from integration: Azure Monitor and Application Insights, Amazon
CloudWatch, or Google Cloud Observability.

Use open standards such as OpenTelemetry when the team wants portability
across backends or needs consistent instrumentation across languages and
services.

Use third-party platforms such as Datadog, New Relic, Splunk, Elastic,
Grafana, Honeycomb, or Sentry when their workflow, querying, alerting, error
tracking, or organizational standard fits better.

Use local diagnostics tools when investigating process-level behavior:
memory, CPU, thread pool, deadlocks, dumps, and traces.

Common overengineering mistakes:

- adding a monitoring platform before deciding what questions must be answered;
- logging every request body;
- using `Error` for ordinary business validation;
- creating health checks that always return healthy;
- creating health checks that fail whenever any optional dependency is slow;
- adding user IDs, email addresses, or tenant names as high-cardinality metric
  tags without understanding cost;
- alerting on everything until everyone ignores alerts;
- collecting dumps without protecting sensitive contents.

The state-of-the-art direction is practical observability: structured logs,
meaningful health checks, built-in and custom metrics, secure telemetry,
OpenTelemetry-compatible instrumentation, and alerts tied to user impact.

## Layer 7 — Interview Perspective

Interviewers use observability questions to test whether you understand
production responsibility.

Concepts commonly tested:

- logs versus metrics versus traces;
- structured logging;
- log levels;
- health checks;
- liveness versus readiness;
- basic ASP.NET Core metrics;
- local .NET diagnostics tools;
- alerting;
- sensitive data in telemetry;
- production troubleshooting sequence.

Representative questions:

- "What would you log for a failed API request?"
- "What is structured logging?"
- "How is a metric different from a log?"
- "What should a health check prove?"
- "Why are liveness and readiness different?"
- "How would you diagnose high CPU in a .NET app?"
- "What should trigger an alert?"
- "What telemetry should not contain?"

A strong answer connects signals to action:

> "I would start with health, recent errors, request duration, request rate,
> and dependency failures. Logs explain specific events, metrics show trends,
> and diagnostics tools help inspect the process when the higher-level signals
> point to CPU, memory, or thread-pool issues."

Common misconceptions:

- "Logging is observability."
- "More logs are always better."
- "A health check should test every dependency."
- "Metrics are only for infrastructure teams."
- "Alerts should fire for every exception."
- "A dump is safe because it is only diagnostic data."
- "If the cloud platform has monitoring, the app does not need instrumentation."

Small design scenario:

You deploy an ASP.NET Core order API to a cloud app platform. Users report
intermittent slow responses after a release.

A good investigation would check health status, request duration metrics,
error rates, recent logs around the release, database dependency failures,
connection timeouts, instance resource usage, and deployment version. If those
signals suggest CPU, memory, or thread pool issues, collect deeper diagnostics.

The strong answer starts broad, uses signals, and avoids guessing.

## Hands-On Lab

Objective:

Add basic observability to an ASP.NET Core API with structured logs, a health
endpoint, and local diagnostics.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- Basic ASP.NET Core knowledge from Chapter 5.

Steps:

1. Create an API:

   ```bash
   dotnet new webapi -n Chapter14.Api
   cd Chapter14.Api
   ```

2. Add health checks in `Program.cs`:

   ```csharp
   builder.Services.AddHealthChecks();
   ```

3. Map the health endpoint:

   ```csharp
   app.MapHealthChecks("/health");
   ```

4. Add an endpoint that writes a structured log:

   ```csharp
   app.MapGet("/orders/{id:int}", (
       int id,
       ILogger<Program> logger) =>
   {
       logger.LogInformation("Loading order {OrderId}", id);

       return Results.Ok(new { id });
   });
   ```

5. Run the app:

   ```bash
   dotnet run
   ```

6. Call the endpoints:

   ```bash
   curl http://localhost:5000/health
   curl http://localhost:5000/orders/42
   ```

7. Find the process:

   ```bash
   dotnet-trace ps
   ```

8. Monitor counters:

   ```bash
   dotnet-counters monitor --process-id <pid>
   ```

Expected results:

- The health endpoint returns a healthy response.
- The order endpoint writes a structured log containing `OrderId`.
- The console shows ASP.NET Core request and application logs.
- `dotnet-counters` shows runtime counters for the running process.

Validation commands:

```bash
dotnet build
dotnet run
curl http://localhost:5000/health
curl http://localhost:5000/orders/42
dotnet-trace ps
dotnet-counters monitor --process-id <pid>
```

Troubleshooting notes:

- If the port differs, use the URL printed by `dotnet run`.
- If `dotnet-counters` is not installed, install it as a .NET tool or skip the
  local diagnostics step.
- If the health endpoint returns 404, confirm `MapHealthChecks` appears after
  `builder.Build()`.
- If logs do not show your message, confirm the endpoint is being called and
  the production log level has not filtered it out.

## Knowledge Check

1. Why is observability more important in cloud and container environments?
2. What is the difference between a log and a metric?
3. Why is structured logging useful?
4. What should a basic health check prove?
5. How are liveness and readiness different?
6. Why can too much logging be harmful?
7. What kinds of data should never appear in telemetry?
8. How do metrics support scaling decisions?
9. When would you use `dotnet-counters`, `dotnet-dump`, or `dotnet-trace`?
10. Why should alerts be tied to action?

## Summary

Observability is how a team understands a running system from the signals it
emits. For ASP.NET Core applications, the first signals are logs, health
checks, metrics, and local diagnostics.

Logs explain events. Structured logs preserve named values so production
systems can search and group them. Health checks tell platforms whether an
instance should receive traffic. Metrics show behavior over time: request
rate, duration, errors, CPU, memory, and other measurements. Diagnostics tools
inspect process internals when higher-level signals are not enough.

The goal is not to collect everything. The goal is to collect the signals that
help the team detect, diagnose, and respond to real problems without leaking
secrets or creating unmanageable noise.

The next chapter introduces distributed applications, where observability
becomes even more important because requests begin crossing caches, queues,
background services, and other system boundaries.

## Sources

- [Logging in .NET and ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging/?view=aspnetcore-10.0)
- [Health checks in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-10.0)
- [ASP.NET Core metrics](https://learn.microsoft.com/en-us/aspnet/core/log-mon/metrics/metrics?view=aspnetcore-10.0)
- [Diagnostics in .NET](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/)
- [Diagnostic monitoring and collection utility dotnet-monitor](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-monitor)

## Further Reading

- [dotnet-counters diagnostic tool](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-counters)
- [dotnet-dump diagnostic tool](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-dump)
- [dotnet-trace diagnostic tool](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-trace)
- [OpenTelemetry .NET](https://opentelemetry.io/docs/languages/dotnet/)
- [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)
