= Distributed Applications
<distributed-applications>
== Chapter Purpose
<chapter-purpose>
So far, the book has built toward a deployable ASP.NET Core application
with data access, security, containers, cloud hosting, and basic
observability. Chapter 15 introduces what happens when one application
process is no longer the whole system.

Distributed applications exist because some work does not fit cleanly
inside a single request to a single process and a single database. A web
request may need cached data. A long-running task may need to continue
after the user gets a response. A spike in traffic may need buffering. A
dependency may fail temporarily. A background service may need to
process messages independently from the API.

If your existing model is a load-balanced IIS application with SQL
Server, scheduled tasks, Windows services, and maybe MSMQ, the ideas are
not entirely new. You already know that systems can have more than one
moving part. Modern \.NET uses different tools and cloud-native
patterns, but the core questions remain: where does work happen, where
does state live, what happens when a component fails, and how does the
team know?

This chapter introduces caching, Redis, messaging, background services,
queues, and resilience. It does not teach microservices architecture in
full. That comes later. The goal here is to understand the first
production boundaries that make a \.NET system distributed.

== Where This Fits
<where-this-fits>
A distributed \.NET application adds more runtime components around the
API.

```text
Client
  |
  v
ASP.NET Core API
  |
  +-- SQL Server for durable business data
  |
  +-- Redis for cache or fast shared state
  |
  +-- Queue for work that can happen later
  |
  +-- Background worker for queued processing
  |
  +-- External HTTP service
  |
  v
Logs, metrics, health checks, and alerts
```

Chapter 14 matters here because distributed systems are harder to
understand without observability. Chapter 16 follows with deployment
pipelines, because more moving parts require safer release practices.
Chapter 19 later returns to advanced observability, including
distributed tracing.

This chapter's theme is simple: every new component solves a problem and
adds a failure mode.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
Several older Windows concepts translate well.

A Redis cache is conceptually similar to using ASP.NET cache, memory
cache, or a shared lookup table to avoid repeated expensive work. The
difference is that Redis runs as an external process and can be shared
across application instances.

A background service maps to a Windows service or scheduled task. It
runs outside the immediate request/response path and performs work over
time. Modern \.NET uses hosted services and worker services for this
pattern.

A queue maps to MSMQ or a SQL-backed work table. It stores work until a
consumer is ready. The sender and receiver do not need to run at the
same moment.

Resilience patterns map to the judgment you already used when a
database, file share, or downstream service was unavailable. The
difference is that modern \.NET provides explicit libraries for
timeouts, retries, circuit breakers, rate limiting, fallback, and
related strategies.

The analogy breaks down when distributed components are treated as
invisible plumbing. A cache has memory limits and eviction behavior. A
queue can build a backlog. A background worker can fail. Retries can
duplicate work. A message can be processed twice. A downstream
dependency can throttle you.

Distributed does not mean safer by default. It means the failure
boundaries are more explicit.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
A distributed application is an application system whose behavior
depends on multiple processes, services, or networked components.

It solves these problems:

- reducing repeated expensive reads with caching;
- sharing temporary state across multiple app instances;
- moving slow work out of the request path;
- buffering spikes with queues;
- processing work asynchronously;
- surviving transient dependency failures;
- scaling parts of the system independently.

It does not solve these problems automatically:

- it does not remove the need for durable data design;
- it does not guarantee consistency;
- it does not make failures disappear;
- it does not make debugging easier;
- it does not eliminate the need for idempotency;
- it does not replace observability.

The basic model is:

```text
Cache: fast temporary data
Queue: durable or semi-durable work buffer
Worker: process that performs background work
Message: data describing work or an event
Resilience policy: planned response to expected failure
```

The key distinction is durable truth versus derived or temporary state.
SQL Server is usually the system of record for business data. Redis
might hold a cached copy. A queue might hold work to perform. A worker
might update durable state after processing. Confusing those roles
creates bugs.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The API receives client requests and coordinates application behavior.
It should keep request latency reasonable and avoid doing long-running
work inline when the user does not need to wait.

SQL Server owns durable business state. It remains the source of truth
for orders, users, invoices, and other critical records unless the
architecture explicitly assigns that role elsewhere.

Redis owns fast shared state. It may store cached query results,
session-like data, counters, locks, or pub/sub messages. It can improve
performance, but it is a network dependency with its own memory,
persistence, and availability settings.

The queue owns pending work. It receives messages from producers and
exposes them to consumers. Azure Service Bus, Amazon SQS, RabbitMQ,
Kafka, Redis Streams, and database-backed queues can all play queue-like
roles with different tradeoffs.

The background worker owns asynchronous processing. It reads messages or
performs scheduled work, calls services, updates databases, and emits
logs and metrics.

The external dependency owns behavior outside your process: payment,
email, identity, search, shipping, AI, or another internal API. Network
calls can fail even when your code is correct.

The resilience layer owns planned failure behavior: timeouts, retries,
circuit breakers, fallback, rate limiting, and cancellation.

Failure boundaries include stale cache entries, cache stampedes, queue
backlogs, duplicate messages, poison messages, worker crashes, partial
updates, retries that repeat side effects, slow dependencies, missing
timeouts, and insufficient telemetry to know which component is failing.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
Caching begins with a key and a value.

```csharp
public sealed class ProductLookup
{
    private readonly IDistributedCache _cache;

    public ProductLookup(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task<string?> GetNameAsync(int productId)
    {
        var key = $"product:{productId}:name";

        return await _cache.GetStringAsync(key);
    }
}
```

`IDistributedCache` is a \.NET abstraction for distributed caching.
Microsoft documents Redis as one available implementation through
`Microsoft.Extensions.Caching.StackExchangeRedis`.

Register Redis caching:

```csharp
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration =
        builder.Configuration.GetConnectionString("Redis");
});
```

A background service uses `BackgroundService`:

```csharp
public sealed class ShipmentWorker : BackgroundService
{
    private readonly ILogger<ShipmentWorker> _logger;

    public ShipmentWorker(ILogger<ShipmentWorker> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("Checking for shipment work");

            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }
}
```

Register it:

```csharp
builder.Services.AddHostedService<ShipmentWorker>();
```

This is useful for learning, but production workers usually read from a
queue or scheduled source instead of polling blindly.

Resilience for HTTP calls uses explicit policies. Modern \.NET provides
`Microsoft.Extensions.Http.Resilience`, built on Polly:

```csharp
builder.Services.AddHttpClient<ShippingClient>()
    .AddStandardResilienceHandler();
```

That one line is not a design. It is a starting point. You still need to
understand timeouts, retries, idempotency, and what happens when the
downstream service remains unavailable.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
Start by identifying the pressure.

```text
Repeated expensive reads -> consider cache
Slow noninteractive work -> consider background processing
Traffic bursts -> consider queue
Transient dependency failure -> consider resilience policy
Independent scale needs -> consider separate worker or service
```

Add Redis for local development with Docker Compose:

```yaml
services:
  redis:
    image: redis:8
    ports:
      - "6379:6379"
```

Configure the app:

```text
ConnectionStrings__Redis=redis:6379
```

Add the package:

```bash
dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis
```

Create a worker project:

```bash
dotnet new worker -n Orders.Worker
```

Run it locally:

```bash
dotnet run --project Orders.Worker
```

For queue-backed work, choose a real queue before production. For early
local learning, a bounded in-memory channel can teach the
producer/consumer shape, but it is not durable and does not survive
process restart.

The workflow habit is to document the new boundary:

```text
What component owns the data?
Is the data durable?
Can work be processed twice?
What happens if the dependency is down?
How is backlog measured?
How is failure alerted?
How is local development configured?
```

If you cannot answer those questions, the distributed design is not
ready.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production distributed systems require explicit ownership.

Configuration should separate cache endpoints, queue names, retry
settings, timeouts, and worker concurrency by environment. Development
settings should not leak into production.

Secrets include Redis passwords, queue credentials, service bus
connection strings, API keys, and managed identity settings. Use the
platform secret system or managed identity where possible.

Security includes network isolation, TLS, authentication to Redis and
queues, least-privilege worker identities, message validation, and
avoiding sensitive data in messages unless protection is designed.

Reliability depends on timeouts, retries, idempotent handlers,
dead-letter queues, poison-message handling, graceful shutdown,
backpressure, and clear recovery procedures.

Deployment must coordinate producers and consumers. A new API version
may send messages that an old worker cannot understand. Message
contracts need version discipline.

Observability is essential. Monitor cache hit rate, cache latency, queue
length, oldest message age, worker success/failure counts, retry counts,
dead-letter counts, and downstream dependency latency.

Scaling changes bottlenecks. More API instances can increase queue
volume. More workers can increase database load. More cache usage can
hide database pressure until cache failure.

Persistence must be designed. Redis can be configured for persistence,
but it is often used for temporary data. Queues may be durable, but they
are not databases. SQL Server remains the system of record unless the
design says otherwise.

Cost includes managed cache tiers, queue operations, worker compute,
database load, retries, logging volume, and idle infrastructure.

Local development optimizes for ease of reset. Production optimizes for
durability, controlled failure, backpressure, and visibility.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use caching when repeated reads are expensive, data can tolerate
staleness, and the cache behavior is observable.

Do not use caching to hide a broken data model, missing indexes, or
inefficient queries before those basics have been addressed.

Use Redis when the application needs shared cache state across
instances, fast counters, distributed coordination, pub/sub, streams, or
data structures beyond simple in-memory caching.

Use in-memory cache for single-instance, noncritical local optimization.
Do not rely on it for load-balanced consistency.

Use queues when work can happen asynchronously, when bursts need
buffering, or when producers and consumers should be decoupled.

Do not use queues when the user truly needs an immediate result or when
the team is not prepared to handle duplicate, delayed, or failed
processing.

Messaging alternatives include Azure Service Bus, RabbitMQ, Amazon SQS,
Apache Kafka, Redis Streams, NATS, and database-backed queues. Kafka is
strong for event streams and high-throughput log-like data. RabbitMQ is
strong for brokered messaging patterns. Service Bus and SQS are managed
cloud queue options. SQL-backed queues can be simple but may add load to
the database.

Use background services for long-running processes, scheduled work, and
queue consumers. Use platform-native jobs, serverless functions, or
managed schedulers when they fit better.

Common overengineering mistakes:

- adding Redis before measuring database performance;
- using cache as the source of truth;
- sending huge messages instead of references to durable data;
- ignoring duplicate message delivery;
- retrying non-idempotent operations;
- running background work inside the API process when it needs
  independent scale;
- creating microservices before understanding queues, workers, and
  failure.

The state-of-the-art direction is measured distribution: add a cache,
queue, worker, or resilience policy when it solves a specific boundary,
then observe that boundary in production.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use distributed application questions to test whether you
respect failure.

Concepts commonly tested:

- cache versus database;
- Redis use cases;
- cache invalidation;
- queues and asynchronous work;
- background services;
- message idempotency;
- retries and timeouts;
- circuit breakers;
- dead-letter queues;
- observability for distributed components.

Representative questions:

- "When would you add Redis to a \.NET application?"
- "Why is cache invalidation hard?"
- "What problem does a queue solve?"
- "What is a poison message?"
- "Why must message handlers be idempotent?"
- "How do retries make systems worse?"
- "When should background work run outside the API process?"
- "What metrics matter for a queue-backed worker?"

A strong answer names the tradeoff:

#quote(block: true)[
"A queue decouples the API from slow work and buffers spikes, but it
means work may be delayed, duplicated, or fail later. The handler must
be idempotent, failures need a dead-letter path, and we need metrics for
queue depth and message age."
]

Common misconceptions:

- "Redis is just a faster SQL Server."
- "A queue guarantees exactly-once processing."
- "Retries are always safe."
- "Background services are just scheduled tasks with a new name."
- "Distributed systems improve reliability automatically."
- "If a message is small, it does not need a contract."
- "Observability can be added after distribution."

Small design scenario:

An order API sends confirmation emails during the request. When the
email provider is slow, checkout slows down. When the provider fails,
orders are created but users see errors.

A better design would commit the order to SQL Server, enqueue an email
command or event, return a successful response, and let a worker send
the email. The worker should retry transient failures, avoid duplicate
emails, dead-letter poison messages, and emit metrics for queue length
and failures.

The strong answer improves user latency while making delayed failure
visible.

== Hands-On Lab
<hands-on-lab>
Objective:

Add Redis caching and a simple background worker concept to a \.NET
solution.

Prerequisites:

- \.NET 10 SDK installed, or another currently supported \.NET SDK.
- Docker or Docker Compose.
- Basic ASP.NET Core experience.

Steps:

+ Create an API:

  ```bash
  dotnet new webapi -n Chapter15.Api
  cd Chapter15.Api
  ```

+ Add Redis distributed cache support:

  ```bash
  dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis
  ```

+ Register Redis caching:

  ```csharp
  builder.Services.AddStackExchangeRedisCache(options =>
  {
      options.Configuration =
          builder.Configuration.GetConnectionString("Redis");
  });
  ```

+ Add an endpoint that reads and writes a cache value using
  `IDistributedCache`.

+ Run Redis locally:

  ```bash
  docker run --rm -p 6379:6379 redis:8
  ```

+ Set a local connection string:

  ```bash
  dotnet user-secrets init
  dotnet user-secrets set "ConnectionStrings:Redis" "localhost:6379"
  ```

+ Run the API:

  ```bash
  dotnet run
  ```

+ Create a worker project:

  ```bash
  cd ..
  dotnet new worker -n Chapter15.Worker
  dotnet run --project Chapter15.Worker
  ```

+ Observe worker logs and stop it with `Ctrl+C`.

Expected results:

- Redis runs locally.
- The API can use `IDistributedCache`.
- The worker service starts and writes logs.
- You can explain why this local setup is not yet a production queue
  design.

Validation commands:

```bash
docker run --rm -p 6379:6379 redis:8
dotnet build
dotnet run
dotnet run --project Chapter15.Worker
```

Troubleshooting notes:

- If Redis connection fails, confirm the container is running and the
  port is mapped.
- If user secrets are not read, run the command from the API project
  folder.
- If the worker exits immediately, inspect `ExecuteAsync` and logging
  output.
- If cache values seem stale, check expiration settings and keys.

== Knowledge Check
<knowledge-check>
+ Why is SQL Server usually the system of record while Redis is not?
+ What problem does a distributed cache solve in a load-balanced app?
+ Why is cache invalidation a design issue?
+ What problem does a queue solve?
+ Why can queue consumers receive the same work more than once?
+ What does idempotency mean for a message handler?
+ When should background work run outside the API process?
+ Why are timeouts important for external dependencies?
+ How can retries make an outage worse?
+ What metrics would you monitor for a queue-backed worker?

== Summary
<summary>
Distributed applications begin when behavior crosses process or service
boundaries. Caches, queues, background workers, and external services
all solve real problems, but each introduces new failure modes.

Redis can provide fast shared state and distributed caching. Queues
decouple producers from consumers and buffer work. Background services
process work outside the request path. Resilience policies help
applications respond to transient failures with timeouts, retries,
circuit breakers, and related strategies.

The discipline is to keep ownership clear. SQL Server holds durable
truth. Caches hold temporary or derived data. Queues hold pending work.
Workers perform asynchronous processing. Observability tells you whether
those boundaries are healthy.

The next chapter turns back to delivery, showing how CI/CD deployment
pipelines safely move validated changes into production environments.

== Sources
<sources>
- #link("https://learn.microsoft.com/en-us/dotnet/core/extensions/caching")[Caching in \.NET]
- #link("https://learn.microsoft.com/en-us/aspnet/core/performance/caching/distributed?view=aspnetcore-10.0")[Distributed caching in ASP.NET Core]
- #link("https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-10.0")[Background tasks with hosted services in ASP.NET Core]
- #link("https://learn.microsoft.com/en-us/dotnet/core/resilience/")[Introduction to resilient app development]
- #link("https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience")[Build resilient HTTP apps]
- #link("https://redis.io/docs/latest/")[Redis documentation]
- #link("https://redis.io/docs/latest/develop/get-started/")[What is Redis?]

== Further Reading
<further-reading>
- #link("https://learn.microsoft.com/en-us/dotnet/core/extensions/workers")[Worker Service template]
- #link("https://stackexchange.github.io/StackExchange.Redis/")[StackExchange.Redis documentation]
- #link("https://learn.microsoft.com/en-us/azure/service-bus-messaging/")[Azure Service Bus documentation]
- #link("https://docs.aws.amazon.com/sqs/")[Amazon SQS documentation]
- #link("https://www.rabbitmq.com/tutorials")[RabbitMQ tutorials]
- #link("https://www.pollydocs.org/")[Polly documentation]
