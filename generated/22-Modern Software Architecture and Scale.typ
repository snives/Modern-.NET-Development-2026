= Modern Software Architecture and Scale
<modern-software-architecture-and-scale>
== Chapter Purpose
<chapter-purpose>
Modern software architecture is the discipline of choosing a system
shape that fits the business problem, team structure, reliability needs,
data model, deployment model, and cost constraints.

The reason this chapter exists near the end of the book is deliberate.
It is easy to talk about monoliths, microservices, Kubernetes, caching,
and scale as abstract preferences. It is harder, and more useful, to
discuss them after you understand ASP.NET Core, data access,
authentication, testing, containers, cloud hosting, distributed
applications, CI/CD, infrastructure as code, observability, Kubernetes,
and AI integration.

Architecture became a central topic in modern \.NET because deployment
changed. Traditional enterprise applications often ran as one IIS
application backed by one SQL Server database. That model could work for
years. As teams moved to cloud hosting, containers, elastic capacity,
managed services, multiple frontends, background workers, and faster
deployment cycles, the question changed from "How do we deploy the
application?" to "What shape should the system have so it can change and
operate safely?"

Microservices became popular because large organizations needed
independent deployment, scaling, and team ownership around business
capabilities. But they also added distributed-system complexity. The
current state of the art is not "everything should be microservices." It
is fit-for-purpose architecture: modular monoliths when a single
deployable unit is enough, microservices when independent ownership and
scaling justify the cost, managed cloud services where they simplify
operations, and observability everywhere.

This chapter teaches how to choose among monoliths, modular monoliths,
microservices, and distributed designs, and how to reason about
horizontal scaling, statelessness, caching, performance, reliability,
and cost.

== Where This Fits
<where-this-fits>
Architecture sits above individual implementation choices and below
business strategy.

```text
Business goals and constraints
        |
        v
Architecture style
        |
        +-- monolith
        +-- modular monolith
        +-- microservices
        +-- distributed system
        |
        v
Application components
        |
        +-- ASP.NET Core APIs
        +-- background workers
        +-- SQL Server and other data stores
        +-- queues
        +-- caches
        +-- AI services
        |
        v
Deployment and operations
        |
        +-- cloud hosting
        +-- containers
        +-- CI/CD
        +-- infrastructure as code
        +-- observability
```

Architecture decisions shape how the system is built, deployed,
monitored, scaled, and paid for. A microservice boundary is not just a
code boundary. It affects source control, builds, deployments,
databases, transactions, monitoring, incident response, security, and
team ownership.

Chapter 23 will go deeper into specific patterns such as repository,
CQRS, event-driven systems, background processing, and domain events.
This chapter sets the larger decision frame.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
The familiar model is a single enterprise application deployed to IIS
with a SQL Server database.

That application might have multiple projects in one Visual Studio
solution: web UI, business logic, data access, shared libraries, and
tests. It might use stored procedures, scheduled tasks, Windows
services, and a load-balanced IIS farm. Scaling often meant adding
servers, increasing SQL Server capacity, moving background work
elsewhere, or tuning queries.

A monolith is the modern name for a system deployed as one application
unit. It is not automatically bad. Many successful systems are monoliths
because the business domain, team size, and deployment needs fit a
single deployable unit.

A modular monolith is closer to a well-structured enterprise
application. It is still deployed as one unit, but the code is divided
into clear modules with internal boundaries. Each module owns a business
area and limits direct coupling to other modules.

Microservices split the application into multiple independently
deployable services. Each service owns a business capability and usually
owns its data. This can resemble separate IIS applications or Windows
services, but the operational expectations are much higher: independent
pipelines, service communication, observability, versioning, failure
handling, and data consistency.

Horizontal scaling is like adding more IIS servers behind a load
balancer. The modern difference is that instances may be containers,
platform-managed app instances, Kubernetes pods, or serverless workers.

Stateless applications are like web applications that do not keep
important session state in process memory. If any instance can handle
the next request, the system can scale and recover more easily.

The analogy breaks down when distributed data enters the picture. In a
traditional application, one SQL Server transaction could protect
several business changes. In microservices, data may be split across
services, so consistency requires events, retries, compensation,
idempotency, and careful workflow design.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Architecture is the set of important decisions that are expensive to
change later.

It solves these problems:

- organizing code around business capabilities;
- deciding deployment boundaries;
- assigning team ownership;
- scaling the right parts of the system;
- controlling reliability and failure isolation;
- managing data consistency;
- supporting change over time;
- balancing performance, cost, security, and operational complexity.

It does not solve these problems automatically:

- it does not fix unclear requirements;
- it does not make poor code maintainable;
- it does not remove the need for tests;
- it does not make distributed systems simple;
- it does not guarantee performance;
- it does not reduce cost unless cost is designed for;
- it does not replace team communication.

The core model is:

```text
Choose boundaries.
Assign ownership.
Define communication.
Control data.
Observe behavior.
Evolve deliberately.
```

A good architecture is not the most fashionable shape. It is the shape
whose tradeoffs match the workload.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
A monolith has one deployable application boundary. Internal components
may be well organized or messy, but deployment happens together. The
main inputs are user requests, jobs, messages, files, or API calls. The
main outputs are database changes, responses, messages, files, and
integrations.

A modular monolith keeps the single deployment boundary but strengthens
internal ownership. Modules communicate through explicit interfaces,
events, or application services rather than arbitrary shared access. The
database may be shared physically, but modules should avoid casually
modifying each other's tables.

A microservice architecture creates multiple deployment boundaries. Each
service owns a business capability and communicates through APIs,
messages, or events. Ideally, each service owns its data, which reduces
coupling but makes cross-service workflows harder.

A distributed system is any system where work and state are spread
across multiple processes or machines. Microservices are distributed
systems, but so are many monoliths that rely on queues, caches, search
indexes, cloud storage, AI providers, and third-party APIs.

Ownership boundaries should match change boundaries. If the billing
logic, data, team, release cycle, and scaling needs differ from order
entry, billing may deserve a separate module or service. If they always
change together, a separate microservice may create coordination cost
without benefit.

Lifecycle boundaries include build, test, deploy, monitor, scale,
version, roll back, and retire. A boundary that cannot be independently
built, tested, deployed, and observed is not really an independent
service boundary.

Failure boundaries include process crashes, database outages, slow
dependencies, network partitions, bad deployments, cache failures, queue
backlogs, rate limits, and partial data updates. Architecture decides
whether a failure is contained or spreads through the system.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
The simplest architecture comparison is:

```text
Monolith
  one deployable unit
  often one primary database
  simple calls in process
  simple deployment
  harder to scale or deploy pieces independently

Modular monolith
  one deployable unit
  explicit internal modules
  strong code boundaries
  simpler operations than microservices
  requires discipline to preserve boundaries

Microservices
  many deployable units
  services own capabilities and often data
  independent deployment and scaling
  failure isolation potential
  requires distributed operations maturity
```

Horizontal scaling means adding more instances of a component instead of
only making one instance larger.

```text
          load balancer
              |
      +-------+-------+
      |       |       |
      v       v       v
   API-1   API-2   API-3
      \       |       /
       \      |      /
        v     v     v
          SQL Server
```

This helps when the application tier is the bottleneck. It does not help
if all instances are waiting on the same overloaded database.

Statelessness makes horizontal scaling possible. If request state is
stored in process memory, the next request must return to the same
instance. If state is stored in a database, distributed cache, signed
token, queue, or durable workflow, any healthy instance can continue.

Caching stores a copy of data or computation results so later requests
can be served faster or with less dependency load.

Common cache locations:

- in-process memory;
- distributed cache such as Redis;
- HTTP response cache;
- CDN or edge cache;
- database query cache;
- application-specific computed cache.

Caching improves performance when reads repeat and stale data is
acceptable for a defined period. It creates bugs when invalidation,
freshness, ownership, or tenant isolation are unclear.

Performance is the behavior users feel: latency, throughput,
responsiveness, and consistency under load. Scaling is one way to
improve performance, but query tuning, connection pooling, async I/O,
caching, batching, indexing, payload reduction, and removing unnecessary
remote calls often matter more.

Reliability is the ability to meet commitments despite failures. Modern
reliability assumes failure will happen and designs to reduce impact.

Cost is an architectural constraint. More services, more databases, more
clusters, more telemetry, more caches, and more redundancy all have
ongoing cost.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
Architectural work should start with forces, not diagrams.

```text
What must change independently?
What must scale independently?
What data must stay consistent?
Who owns each capability?
What failures are acceptable?
What latency is acceptable?
What can the team operate?
What can the business afford?
```

For a new \.NET application, a conservative workflow is:

+ Start with a clear domain model and use cases.
+ Build a modular monolith unless there is a strong reason not to.
+ Define module boundaries around business capabilities.
+ Keep application services, data access, and external integrations
  behind explicit interfaces.
+ Add tests around module behavior.
+ Add observability before scale becomes urgent.
+ Extract a service only when independent deployment, scaling, data
  ownership, or team ownership justifies the cost.

For an existing monolith:

+ Identify pain points with evidence.
+ Find modules that change for different reasons.
+ Remove accidental coupling inside the codebase.
+ Separate read-heavy, background, or integration-heavy workloads where
  useful.
+ Introduce queues for work that does not need to finish during the
  request.
+ Improve observability so service extraction can be measured.
+ Extract one boundary at a time.

Useful repository inspection commands:

```bash
dotnet sln list
dotnet list package
dotnet test
dotnet build
```

Useful architecture questions during code review:

- Does this change cross module boundaries?
- Does this call need to be synchronous?
- Does this data need one transaction?
- Can this operation be retried safely?
- What happens if the dependency is slow?
- What metric or trace would show failure?

The workflow is evolutionary. Architecture is not a poster made once at
the beginning. It is a set of decisions that should be revisited as the
business, traffic, team, and reliability needs change.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production architecture has to survive real traffic, real incidents, and
real budgets.

Configuration should be environment-specific and centralized enough to
manage safely. In a monolith, configuration may be simpler. In
microservices, configuration sprawl becomes a risk unless naming,
ownership, secret handling, and rollout are standardized.

Secrets should be owned by the platform and exposed only to components
that need them. Service boundaries can reduce blast radius, but only if
credentials and permissions are scoped correctly.

Security architecture includes authentication, authorization, network
boundaries, API gateways, service-to-service identity, least privilege,
audit, data classification, and secure defaults. More services mean more
endpoints to protect.

Reliability requires redundancy, timeouts, retries with backoff, circuit
breakers, idempotency, graceful degradation, health checks, backups,
disaster recovery, and clear ownership during incidents.

Deployment differs by style. A monolith has fewer deployment artifacts
but larger releases. A modular monolith can keep deployment simple while
improving code ownership. Microservices allow smaller independent
deployments, but they require versioning, compatibility testing,
deployment orchestration, and rollback strategy.

Observability is mandatory for distributed systems. Logs, metrics,
traces, dashboards, and alerts must show user journeys, service health,
dependency behavior, deployment versions, and cost signals.

Scaling should target the bottleneck. Scale the web tier when CPU or
request concurrency is the problem. Scale reads with replicas, caches,
or read models when data access is the bottleneck. Scale background work
with queues and workers when processing can be asynchronous.

Persistence is the hardest boundary. A shared database simplifies
reporting and transactions but couples services. Separate databases
improve ownership but require eventual consistency and integration
patterns.

Cost includes compute, storage, databases, network traffic, queues,
caches, load balancers, telemetry, CI/CD, environments, licenses, and
operations labor. Microservices can optimize cost at scale, but they
often increase cost early.

Local development should remain convenient. A system that requires every
developer to run twenty services, three databases, a message broker, a
cache, and Kubernetes just to change one screen will slow the team
unless tooling and defaults are excellent.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use a monolith when the team is small, the domain is still changing, the
system has one primary deployment cadence, data consistency is
important, and the operational cost of distributed systems is not
justified.

Use a modular monolith when the application is significant enough to
need clear boundaries but not yet complex enough to need independently
deployable services. This is often the best default for modern business
applications.

Use microservices when independent deployment, independent scaling, data
ownership, team autonomy, resilience isolation, or technology diversity
provides enough value to pay for distributed-system complexity.

Use a distributed architecture deliberately when the workload naturally
involves queues, background processing, external APIs, search, caching,
AI providers, or cloud-managed services. Do not pretend a system is
simple just because the application code is in one repository.

Simpler alternatives include one ASP.NET Core application, one SQL
Server database, background services in the same deployment, managed
PaaS hosting, and careful modular code.

More advanced alternatives include microservices, event-driven
architecture, CQRS, event sourcing, Kubernetes, service mesh,
multi-region deployment, serverless workflows, and platform engineering.

Common overengineering mistakes:

- starting with microservices before boundaries are known;
- splitting services while sharing the same database tables casually;
- using queues to hide unclear ownership;
- adding caches without invalidation rules;
- optimizing for theoretical scale before real bottlenecks exist;
- treating Kubernetes as architecture;
- ignoring local developer experience;
- measuring service count instead of business outcomes;
- designing for reliability without funding operations.

Architecture always trades one kind of complexity for another. A
monolith centralizes complexity. Microservices distribute it. Modular
monoliths try to keep deployment simple while making code boundaries
explicit.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use architecture questions to test judgment.

Concepts commonly tested:

- monolith;
- modular monolith;
- microservices;
- bounded contexts;
- distributed systems;
- horizontal scaling;
- stateless services;
- caching;
- eventual consistency;
- reliability;
- performance;
- cost;
- operational complexity.

Representative questions:

- "When would you choose a monolith?"
- "What is a modular monolith?"
- "What are the tradeoffs of microservices?"
- "How do you scale an ASP.NET Core API?"
- "Why is statelessness important?"
- "What can go wrong with caching?"
- "How do microservices affect data consistency?"
- "How would you decompose an existing application?"
- "What should you measure before changing architecture?"

A strong answer resists fashion:

#quote(block: true)[
"I would start by looking at change boundaries, data ownership, scaling
needs, team ownership, reliability goals, and operational maturity. A
modular monolith is often the right starting point. I would extract
services when a boundary has clear ownership and independent deployment
or scaling value, and I would plan for observability, versioning, data
consistency, and operations before splitting."
]

Common misconceptions:

- "Monolith means bad design."
- "Microservices are automatically more scalable."
- "Kubernetes means we have a microservice architecture."
- "A shared database is harmless if services are separate."
- "Caching fixes performance without tradeoffs."
- "Horizontal scaling fixes database bottlenecks."
- "Architecture is decided once at project kickoff."

Small design scenario:

An order-management system has one ASP.NET Core application, SQL Server,
background invoice generation, shipment integration, and a new AI
support assistant. The team has six developers. Deployments happen
weekly. The main pain points are slow invoice generation and fragile
shipment integration.

A strong design might keep the core application as a modular monolith,
move invoice generation to background processing, isolate shipment
integration behind an anti-corruption layer or separate worker, add
caching only for read-heavy safe data, and improve observability. It
would not immediately split orders, customers, invoices, shipments, and
AI into five microservices unless ownership, scaling, and deployment
needs justify the cost.

== Hands-On Lab
<hands-on-lab>
Objective:

Evaluate the architecture style for an existing or imagined \.NET
business application.

Prerequisites:

- Familiarity with ASP.NET Core, SQL Server, cloud hosting, distributed
  applications, and observability.
- A candidate application to analyze.

Steps:

+ List the main business capabilities:

  ```text
  orders
  customers
  billing
  shipment
  reporting
  support
  ```

+ For each capability, answer:

  ```text
  Who owns it?
  How often does it change?
  Does it need separate scaling?
  Does it own data?
  Does it need one transaction with another capability?
  What happens if it fails?
  ```

+ Identify current bottlenecks with evidence:

  ```text
  slow requests
  SQL waits
  deployment conflicts
  queue backlog
  high error rate
  team coordination delay
  ```

+ Choose an architecture style:

  ```text
  monolith
  modular monolith
  selected service extraction
  microservices
  ```

+ Draw the proposed system.

+ Mark synchronous calls, asynchronous messages, databases, caches, and
  external dependencies.

+ List reliability risks and how they will be observed.

+ List expected cost increases and cost reductions.

+ Decide what should not change yet.

+ Write one paragraph defending the choice.

Expected results:

- A capability map.
- A recommended architecture style.
- A list of boundaries that should stay together.
- A list of boundaries that may deserve separation.
- A reliability and observability plan.
- A cost tradeoff summary.

Validation commands:

If analyzing an existing \.NET solution, use:

```bash
dotnet sln list
dotnet build
dotnet test
```

If the application is only hypothetical, validation is architectural:
the design should explain why its boundaries match business
capabilities, data ownership, scaling needs, reliability goals, team
ownership, and cost.

Troubleshooting notes:

- If every module needs the same database transaction, microservices may
  be too early.
- If one background job causes user-facing slowness, separate processing
  before splitting the whole system.
- If teams frequently block each other, examine ownership boundaries.
- If no one can operate the proposed design, simplify it.
- If the design only says "microservices for scale," identify the actual
  bottleneck first.

== Knowledge Check
<knowledge-check>
+ Why is a monolith not automatically a bad architecture?
+ How is a modular monolith different from an unstructured monolith?
+ What costs do microservices introduce?
+ Why does data ownership matter when splitting services?
+ How does statelessness support horizontal scaling?
+ Why might adding more API instances fail to improve performance?
+ What risks does caching introduce?
+ When should work move to a background process?
+ How do observability requirements change as systems become
  distributed?
+ What evidence would justify extracting a service from a monolith?

== Summary
<summary>
Modern architecture is not a contest between old and new labels. It is
the practice of choosing boundaries that match the workload. A monolith
can be the right answer when one deployable unit fits the team and
domain. A modular monolith improves maintainability while keeping
operations simple. Microservices help when independent ownership,
deployment, scaling, and failure isolation justify distributed
complexity.

Scale also has layers. Horizontal scaling works best when applications
are stateless and the bottleneck is the application tier. Caching helps
when data can be reused safely. Background processing helps when work
does not need to block the user. Reliability comes from designing for
failure, not pretending failure can be avoided.

The architectural habit is to ask what should change independently,
scale independently, fail independently, and be owned independently.
Then choose the simplest system shape that satisfies those forces.

The next chapter narrows from broad architecture styles to common
patterns: repository, CQRS, event-driven systems, background processing,
and domain events.

== Sources
<sources>
- #link("https://learn.microsoft.com/en-us/azure/architecture/microservices/")[Azure Architecture Center: Microservices architecture style]
- #link("https://learn.microsoft.com/en-us/azure/architecture/microservices/design/patterns")[Azure Architecture Center: Design patterns for microservices]
- #link("https://learn.microsoft.com/en-us/azure/architecture/patterns/")[Azure Architecture Center: Cloud design patterns]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/")[Azure Well-Architected Framework]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework")[What is the Azure Well-Architected Framework?]
- #link("https://martinfowler.com/bliki/MonolithFirst.html")[Martin Fowler: Monolith First]

== Further Reading
<further-reading>
- #link("https://learn.microsoft.com/en-us/azure/architecture/")[Azure Architecture Center]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/reliability/")[Azure Well-Architected Framework reliability pillar]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/performance-efficiency/")[Azure Well-Architected Framework performance efficiency pillar]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/cost-optimization/")[Azure Well-Architected Framework cost optimization pillar]
- #link("https://martinfowler.com/microservices/")[Martin Fowler: Microservices Guide]
