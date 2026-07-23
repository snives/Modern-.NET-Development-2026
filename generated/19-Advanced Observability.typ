= Advanced Observability
<advanced-observability>
== Chapter Purpose
<chapter-purpose>
Chapter 14 introduced observability as the replacement for
server-centered diagnostics. Chapter 18 showed why Kubernetes makes that
shift unavoidable: the application may run as many short-lived pods
across multiple nodes, and the specific process that handled a failed
request may be gone by the time someone investigates.

Advanced observability exists because modern systems fail across
boundaries. An ASP.NET Core API may call another API, publish a message,
query a database, read from a cache, and run inside Kubernetes behind
cloud networking. A user sees one slow checkout request, but the cause
may be a retry storm, a saturated connection pool, a bad deployment, an
overloaded pod, a slow SQL query, or a third-party dependency.

Older monitoring tools often focused on a machine or a process. Advanced
observability focuses on a service, a request path, and the system
behavior around it. The goal is not just to know that something is
broken. The goal is to move from symptom to likely cause quickly enough
to protect users.

OpenTelemetry is the central modern standard in this space. It grew out
of the need for portable instrumentation across vendors and languages,
combining ideas from earlier tracing and metrics projects into a common
set of APIs, SDKs, semantic conventions, and protocols. It is not a
monitoring product by itself. It is the instrumentation and transport
layer that lets \.NET applications emit telemetry to systems such as
Azure Monitor, Grafana, Prometheus-compatible backends, Jaeger, Zipkin,
Datadog, New Relic, Honeycomb, Elastic, and other observability
platforms.

This chapter extends the earlier diagnostics chapter into production
observability for cloud-native and distributed systems. You will learn
how metrics, traces, logs, dashboards, alerts, and multi-service
monitoring work together.

== Where This Fits
<where-this-fits>
Advanced observability sits across the whole running system.

```text
Users
  |
  v
Gateway or ingress
  |
  v
ASP.NET Core API ----> database
  |       |
  |       +---------> cache
  |
  +----------------> message broker
                           |
                           v
                    background worker

Each component emits:
  logs    -> what happened?
  metrics -> how much, how fast, how many?
  traces  -> where did this request go?

Telemetry pipeline:
  application instrumentation
        |
        v
  OpenTelemetry SDK or automatic instrumentation
        |
        v
  collector or cloud agent
        |
        v
  observability backend
        |
        v
  dashboards, alerts, investigations
```

Chapter 19 belongs after Kubernetes because orchestration increases the
number of moving parts. A single request can cross pods, services,
nodes, queues, and managed dependencies. Local logs are no longer
enough.

It also prepares for the AI chapters because AI-enabled systems often
add expensive external calls, prompt pipelines, embeddings, vector
stores, and background processing. Those systems require measurement and
traceability from the beginning.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
The familiar model is a production support call for an IIS application.

You might check IIS logs, Windows Event Viewer, Performance Monitor
counters, SQL Server activity, and application log files. If one server
was misbehaving, you could log in, compare it with another server,
recycle an application pool, or inspect the process.

Advanced observability keeps the same investigative intent but changes
the unit of analysis.

Metrics are the modern equivalent of performance counters and SQL Server
wait-stat trends. They show rates, latency, saturation, errors, and
resource usage over time.

Traces are like a request timeline that follows the work across
services. A trace can show that the API received a request, called
another service, waited on SQL Server, retried a cache call, and
returned an error.

Logs remain the event record, but they become more useful when
correlated with trace identifiers, service names, deployment versions,
user-safe business identifiers, and infrastructure metadata.

Dashboards are like operational consoles. They show whether the system
is healthy and where to look next.

Alerts are like paging rules and service monitors, but the best alerts
are tied to user impact rather than every low-level symptom.

The analogy breaks down when you expect one server to contain the
answer. In a distributed system, the evidence is spread across services
and collected after the fact. If telemetry is inconsistent, missing, too
expensive, or uncorrelated, the team may know there was an incident
without being able to explain it.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Advanced observability is the practice of designing a system so
production behavior can be understood across service, infrastructure,
and dependency boundaries.

It solves these problems:

- connecting one user request across multiple services;
- separating application failures from infrastructure failures;
- detecting regressions after deployment;
- understanding latency and error distribution;
- finding dependency bottlenecks;
- supporting incident response;
- measuring service reliability;
- creating feedback for architecture and operations.

It does not solve these problems automatically:

- it does not replace good error handling;
- it does not make unreliable dependencies reliable;
- it does not remove the need for tests;
- it does not tell the team which reliability goals matter;
- it does not make every collected signal worth storing;
- it does not protect sensitive data unless telemetry is designed
  carefully.

The core model is:

```text
Logs explain notable events.
Metrics quantify behavior over time.
Traces connect work across boundaries.
Dashboards organize signals for humans.
Alerts turn user-impacting signals into action.
```

The advanced part is correlation. Logs, metrics, and traces should not
live as three unrelated piles of data. They should share enough context
that an investigator can move from an error-rate spike to an example
trace to the logs for the same operation.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The application emits telemetry. ASP.NET Core, the \.NET runtime, HTTP
clients, database clients, messaging libraries, and application code can
all emit signals.

Instrumentation is the code or agent behavior that creates telemetry.
Manual instrumentation is written by the team. Automatic instrumentation
comes from framework and library integrations.

The OpenTelemetry SDK receives telemetry from instrumentation and
prepares it for export. In \.NET, OpenTelemetry supports traces,
metrics, and logs for supported \.NET versions.

The OpenTelemetry Protocol, commonly shortened to OTLP, defines how
telemetry is sent from applications or collectors to telemetry backends.
This helps avoid hard-wiring application code to one vendor.

The collector is an optional but common pipeline component. It can
receive telemetry, enrich it with Kubernetes or cloud metadata, filter
it, sample it, batch it, and export it to one or more backends.

The backend stores, indexes, queries, visualizes, and alerts on
telemetry. This may be a cloud-native platform, an open-source stack, or
a commercial observability product.

Ownership boundaries matter:

- application teams own meaningful application instrumentation;
- platform teams often own collectors, agents, cluster metadata, and
  routing;
- operations or SRE teams own alert policies, incident processes, and
  service reliability goals;
- security teams influence retention, redaction, access control, and
  audit requirements.

Failure boundaries include missing instrumentation, broken context
propagation, high-cardinality labels, excessive telemetry volume,
sampling that hides rare failures, dashboards that do not match user
journeys, alerts that page on symptoms instead of impact, and telemetry
pipelines that fail during the same incident they should explain.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
OpenTelemetry organizes telemetry into signals.

A trace represents one logical operation, often one request. A trace
contains spans. A span represents a timed unit of work, such as handling
an HTTP request, calling another API, executing a SQL command, or
processing a message.

```text
Trace: checkout request
  Span: POST /checkout
    Span: validate cart
    Span: call pricing-api
    Span: write order to SQL
    Span: publish OrderSubmitted message
```

Metrics are numeric measurements over time. Common metric types include
counters, gauges, and histograms. For production services, the most
useful starting metrics usually describe request rate, error rate,
duration, resource usage, dependency latency, queue depth, and
saturation.

Logs are timestamped records of events. Logs are most useful when they
include structured fields and correlation identifiers instead of
unstructured text alone.

A small ASP.NET Core OpenTelemetry setup may look like this:

```csharp
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(
            serviceName: "orders-api",
            serviceVersion: "2026.07.23"))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddOtlpExporter());

var app = builder.Build();

app.MapGet("/orders/{id:int}", async (int id, HttpClient http) =>
{
    var response = await http.GetAsync($"https://inventory-api/items/{id}");
    return Results.Ok(new { OrderId = id, InventoryStatus = response.StatusCode });
});

app.Run();
```

The service name is important. Without consistent service names,
environment names, versions, and instance metadata, telemetry becomes
difficult to group and compare.

Manual spans are useful when the framework cannot infer the business
operation:

```csharp
using System.Diagnostics;

private static readonly ActivitySource ActivitySource =
    new("Orders.Checkout");

using var activity = ActivitySource.StartActivity("ReserveInventory");
activity?.SetTag("order.id", orderId);
activity?.SetTag("inventory.items", itemCount);

await inventory.ReserveAsync(orderId, items);
```

Use tags carefully. A tag such as `order.id` can help with
investigation, but high-cardinality or sensitive values can create cost,
privacy, and performance problems. Do not put secrets, tokens,
passwords, full payment information, or unnecessary personal data into
telemetry.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
The developer workflow starts with a question, not a tool.

```text
What should we be able to know in production?
        |
        v
Choose signals: logs, metrics, traces
        |
        v
Instrument application and dependencies
        |
        v
Run locally and verify telemetry
        |
        v
Deploy to test environment
        |
        v
Build dashboard and alert from real behavior
```

For a \.NET service, start by adding OpenTelemetry packages for tracing,
metrics, exporters, and the instrumentation libraries your app uses.
Then verify that local requests produce traces and metrics before you
deploy.

Local validation can use a development collector, console exporter, or a
local observability stack. The exact backend is less important than
proving that the service emits coherent telemetry with a service name,
environment, version, and trace correlation.

Useful investigation flow:

```text
Alert fires
  |
  v
Open user-impact dashboard
  |
  v
Identify affected service and time window
  |
  v
Find a representative trace
  |
  v
Inspect slow or failed span
  |
  v
Open correlated logs
  |
  v
Compare deployment, dependency, and infrastructure signals
```

For Kubernetes-hosted services, include pod, namespace, node, container,
image, and deployment metadata when possible. That lets you answer
questions such as "Did only the new version fail?", "Was the problem
isolated to one node?", and "Did this begin during rollout?"

Developer-owned instrumentation should focus on business and dependency
boundaries:

- order creation;
- payment authorization;
- inventory reservation;
- message publishing;
- background job processing;
- calls to external systems;
- retries, timeouts, and circuit-breaker decisions.

Avoid logging every line of code. The goal is a useful map of the
system, not a transcript of the process.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production observability begins with reliability goals. A dashboard
should show whether users are being served successfully, not merely
whether servers are busy.

Common service-level indicators include:

- request success rate;
- request latency;
- availability;
- queue age or lag;
- background job success rate;
- dependency error rate;
- saturation of CPU, memory, threads, connections, and storage.

Dashboards should be organized by user journey and service ownership. A
useful dashboard answers:

- Is the service healthy?
- Are users affected?
- What changed recently?
- Which dependency is slow or failing?
- Is the problem isolated to one version, region, node, or tenant?
- Where should the responder look next?

Alerting should be actionable. Page humans for user impact, fast-moving
failure, data loss risk, security concerns, or exhausted capacity. Send
lower priority signals to tickets, daily review, or dashboards.

Configuration should separate local, test, and production telemetry
endpoints. Use environment variables, platform configuration, managed
identity, or secret systems rather than hard-coded exporter credentials.

Security and privacy are production concerns. Telemetry may contain
URLs, headers, user identifiers, exception details, and business data.
Redact or drop sensitive values before export. Limit access to telemetry
backends. Define retention based on business, legal, and cost needs.

Reliability of the telemetry pipeline matters. Use batching, retries,
and backpressure-aware exporters. Avoid making request handling fail
just because telemetry export is unavailable.

Scaling affects telemetry volume. More pods, more requests, and more
dependencies produce more data. Sampling traces, reducing noisy logs,
limiting high-cardinality attributes, and setting retention policies are
normal production practices.

Persistence appears in two places. First, telemetry backends store large
amounts of operational data. Second, traces and logs often point to
persistent systems such as SQL Server, queues, and object storage.
Observability should show both the application and the dependency
behavior.

Cost is real. Logs are often the most expensive signal because they can
be large and unbounded. Traces can become expensive under high traffic.
Metrics are usually efficient, but high-cardinality labels can make them
costly. Measure telemetry value the same way you measure application
value.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use advanced observability when the system has multiple services,
containers, background workers, queues, managed dependencies, cloud
networking, or a production reliability obligation.

Do not start by instrumenting everything. Start with user journeys,
service boundaries, dependencies, and the failure modes that would
trigger an incident.

OpenTelemetry is a strong default because it is vendor-neutral and has
broad ecosystem support. It reduces the risk of writing application code
that only works with one backend.

Simpler alternatives include built-in cloud monitoring, ASP.NET Core
logging, health checks, platform metrics, and a single logging provider.
These may be enough for a small app or early prototype.

Open-source observability stacks commonly include Prometheus for
metrics, Grafana for dashboards, Loki or Elasticsearch for logs, and
Jaeger or Tempo for tracing. They can be powerful, but someone must
operate, secure, scale, upgrade, and pay for the infrastructure.

Commercial and cloud-managed platforms reduce operational burden and
often provide better integrated alerting, retention, search,
correlation, anomaly detection, and support. They can also create cost
and vendor-dependence concerns.

Common overengineering mistakes:

- collecting telemetry without defining investigation questions;
- paging on CPU instead of user impact;
- logging sensitive data;
- creating high-cardinality metric labels such as user IDs;
- sampling away the rare failures the team needs;
- building dashboards no one uses during incidents;
- treating OpenTelemetry as a backend instead of an instrumentation
  standard;
- ignoring telemetry cost until the bill arrives.

The state-of-the-art direction is correlated telemetry with
OpenTelemetry, managed collection pipelines, service-level objectives,
automatic instrumentation where appropriate, manual spans for business
operations, trace-to-log correlation, policy-based redaction, and
dashboards organized around user experience rather than server
inventory.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use advanced observability questions to test whether you
can operate distributed systems, not just write application code.

Concepts commonly tested:

- logs, metrics, and traces;
- spans and trace context;
- distributed tracing;
- OpenTelemetry;
- OTLP;
- collectors;
- dashboards;
- alerting;
- service-level indicators and objectives;
- cardinality;
- sampling;
- correlation;
- Kubernetes metadata;
- privacy and retention.

Representative questions:

- "How would you diagnose a slow request across three services?"
- "What is the difference between logs, metrics, and traces?"
- "What does OpenTelemetry provide?"
- "What is a span?"
- "Why does context propagation matter?"
- "What makes a dashboard useful?"
- "What should trigger a production alert?"
- "Why can high-cardinality metrics be dangerous?"
- "How do you avoid leaking sensitive data through telemetry?"

A strong answer connects signals:

#quote(block: true)[
"I would start with user-impact metrics to confirm scope and time
window, then inspect traces from the affected service to find where
latency or errors appear. From a failing span I would open correlated
logs, compare the deployment version and Kubernetes metadata, and check
dependency metrics. I would alert on symptoms users feel, not every
internal warning."
]

Common misconceptions:

- "Logs are enough if they are detailed."
- "Distributed tracing replaces metrics."
- "OpenTelemetry is a dashboard product."
- "More telemetry is always better."
- "Every error log should page someone."
- "CPU alerts prove user impact."
- "Sampling means observability is unreliable."

Small design scenario:

You have an order system with an ASP.NET Core API, payment API,
inventory API, SQL Server, Redis, and a background worker that processes
messages. Users report intermittent slow checkout.

A good observability design would include request duration and error
metrics for each service, distributed tracing across HTTP and messaging
boundaries, structured logs correlated with trace IDs, dependency
metrics for SQL Server and Redis, dashboard views for checkout success
and latency, deployment version metadata, Kubernetes pod metadata, and
alerts based on checkout error rate or latency objectives.

The strong answer does not begin by logging into a pod. It begins by
finding the affected user journey and following correlated telemetry to
the failing boundary.

== Hands-On Lab
<hands-on-lab>
Objective:

Add basic OpenTelemetry tracing and metrics to an ASP.NET Core service
and verify that one request can be followed through telemetry.

Prerequisites:

- A small ASP.NET Core API.
- \.NET SDK installed.
- A local telemetry destination, development collector, or console
  exporter.
- Familiarity with the health endpoint and Docker workflow from earlier
  chapters.

Steps:

+ Add OpenTelemetry packages for ASP.NET Core instrumentation, HTTP
  client instrumentation, metrics, tracing, and an exporter suitable for
  your local environment.

+ Configure a service name and service version.

+ Enable ASP.NET Core and HTTP client tracing.

+ Enable ASP.NET Core, HTTP client, and runtime metrics.

+ Create one endpoint that calls another HTTP endpoint or a small local
  test service.

+ Send several requests to the endpoint.

+ Confirm that telemetry includes:

  ```text
  service name
  request duration
  HTTP status code
  trace ID
  span ID
  dependency call span
  runtime metrics
  ```

+ Add one structured log message during the request and confirm that it
  can be correlated with the trace when your backend supports log
  correlation.

+ Create a simple dashboard or query showing request rate, error rate,
  and latency for the service.

Expected results:

- Requests produce traces.
- The trace shows at least one server span and one dependency span.
- Metrics show request count and duration.
- Logs include useful structured values without sensitive data.
- The service name and version are visible in telemetry.

Validation commands:

```bash
dotnet run
curl http://localhost:5000/health
curl http://localhost:5000/orders/42
```

If using Kubernetes:

```bash
kubectl logs deployment/orders-api
kubectl get pods
kubectl port-forward service/orders-api 8080:80
curl http://localhost:8080/orders/42
```

Troubleshooting notes:

- If traces are missing, check instrumentation registration and exporter
  configuration.
- If service names are missing, check resource configuration.
- If dependency spans are missing, check whether the client library is
  instrumented.
- If metrics are noisy, review labels and cardinality.
- If telemetry export fails, check endpoint URLs, credentials, network
  access, and collector logs.
- If sensitive data appears, fix instrumentation before increasing
  retention or access.

== Knowledge Check
<knowledge-check>
+ Why do distributed systems need more than local logs?
+ How do logs, metrics, and traces answer different diagnostic
  questions?
+ What is a span, and how does it relate to a trace?
+ Why is OpenTelemetry useful even when a team has already chosen a
  backend?
+ What role does an OpenTelemetry Collector play?
+ Why does context propagation matter for multi-service monitoring?
+ What makes a production dashboard useful during an incident?
+ Why should alerts usually focus on user impact?
+ How can high-cardinality labels increase cost and reduce usefulness?
+ What telemetry should you add for a checkout flow that uses APIs, SQL
  Server, Redis, and a background worker?

== Summary
<summary>
Advanced observability is the production discipline of understanding a
modern system across service and infrastructure boundaries. It builds on
the basic signals from Chapter 14 and becomes essential once
applications run as containers, Kubernetes workloads, distributed
services, and cloud-managed dependencies.

The key shift is correlation. Logs describe events, metrics quantify
behavior, and traces show how one operation moved through the system.
When those signals share service names, versions, trace context, and
infrastructure metadata, a team can move from a user-impact alert to a
dashboard, then to an example trace, then to correlated logs and
dependency metrics.

OpenTelemetry provides the modern vendor-neutral foundation for this
work. It does not replace observability backends, dashboards, incident
response, or engineering judgment. It gives \.NET applications a
standard way to emit telemetry that can survive changes in hosting
platform and monitoring vendor.

The next chapter shifts from operating distributed systems to designing
AI-enabled application architecture. The observability habits from this
chapter will continue to matter because AI workflows add new
dependencies, latency patterns, costs, and failure modes.

== Sources
<sources>
- #link("https://opentelemetry.io/docs/languages/dotnet/")[OpenTelemetry \.NET documentation]
- #link("https://opentelemetry.io/docs/specs/otel/overview/")[OpenTelemetry specification overview]
- #link("https://opentelemetry.io/docs/specs/status/")[OpenTelemetry specification status summary]
- #link("https://opentelemetry.io/docs/specs/otel/metrics/")[OpenTelemetry Metrics specification]
- #link("https://opentelemetry.io/docs/specs/otel/logs/")[OpenTelemetry Logs specification]
- #link("https://opentelemetry.io/docs/specs/otlp/")[OpenTelemetry Protocol specification]
- #link("https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel")[Observability in \.NET]
- #link("https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging/")[ASP.NET Core logging documentation]

== Further Reading
<further-reading>
- #link("https://github.com/open-telemetry/opentelemetry-dotnet")[OpenTelemetry \.NET GitHub repository]
- #link("https://opentelemetry.io/docs/collector/")[OpenTelemetry Collector documentation]
- #link("https://opentelemetry.io/docs/specs/semconv/")[OpenTelemetry semantic conventions]
- #link("https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-overview")[Azure Monitor OpenTelemetry documentation]
- #link("https://grafana.com/docs/opentelemetry/")[Grafana OpenTelemetry documentation]
