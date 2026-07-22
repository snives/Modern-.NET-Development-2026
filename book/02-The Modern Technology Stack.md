# The Modern Technology Stack

## Chapter Purpose

Chapter 1 rebuilt the map. This chapter labels the major landmarks.

The modern .NET stack is not a single product. It is a working combination of
runtime, web framework, operating system, packaging model, deployment platform,
data stores, source-control system, delivery pipeline, and increasingly AI
services.

If you come from a Windows, IIS, SQL Server, and Visual Studio background, the
older stack may have felt vertically integrated. Microsoft supplied the
language, runtime, IDE, web server integration, database, operating system, and
deployment target. You could build a serious enterprise application while
staying almost entirely inside one vendor ecosystem.

That world still exists, but the center widened.

Modern .NET remains a Microsoft-led ecosystem, but professional .NET work now
commonly touches Linux, Docker, Kubernetes, Redis, GitHub, cloud platforms,
open-source libraries, managed services, and AI providers. Some of these tools
were adopted because they solved problems Microsoft products already faced.
Some became industry standards outside the Microsoft ecosystem and .NET had to
meet developers where the industry had moved. That is not a weakness. It is
one of the reasons modern .NET is viable in cloud-native systems.

The purpose of this chapter is to introduce the major technologies without
teaching their implementation details yet. You should finish this chapter able
to explain what each technology is for, how it relates to the technologies
around it, and where it fits in a complete application system.

This chapter deliberately stays at the map level. Later chapters teach the
mechanics.

## Where This Fits

Chapter 1 described the shift from server-centered development to
platform-centered development. Chapter 2 turns that platform into named
components.

A typical modern .NET application stack might look like this:

```text
Users
  |
  v
Web or API edge
  |
  v
ASP.NET Core application
  |
  +-- SQL Server or managed relational database
  |
  +-- Redis cache
  |
  +-- Queue, background worker, or external service
  |
  +-- AI service when the application needs model behavior
  |
  v
Logs, metrics, traces, and alerts

Source code -> GitHub -> CI/CD -> package or container image -> host platform
```

The technologies in the roadmap do not all sit at the same layer:

- .NET is the runtime and developer platform.
- ASP.NET Core is the web and API framework.
- Linux is a common operating-system host.
- Docker is a packaging and local runtime tool for containers.
- Kubernetes is an orchestration platform for running containers at scale.
- SQL Server is the relational database many enterprise .NET systems already
  know.
- Redis is a fast in-memory data store often used for caching and coordination.
- Cloud platforms provide managed compute, databases, identity, networking, and
  operations.
- GitHub is commonly the source-control and collaboration hub.
- CI/CD is the automated path from code change to validated artifact and,
  eventually, deployment.
- AI services provide model-backed behavior that applications can call like
  other external dependencies.

This chapter introduces all of them together so later chapters can zoom in
without forcing you to learn the system vocabulary from scratch.

## Connection to the Reader's Existing Model

The easiest way to understand the modern stack is to compare each layer to
something familiar.

.NET is still the platform you write C# against. The difference is that modern
.NET is cross-platform, SDK-centered, open-source, and released on a regular
cadence. It is less tied to a particular Windows installation than .NET
Framework felt.

ASP.NET Core still handles HTTP requests, routing, application services,
configuration, logging, and responses. The familiar IIS mental model helps, but
ASP.NET Core is not just "classic ASP.NET with new project files." It can run
behind IIS, behind a Linux reverse proxy, inside a container, or on a managed
cloud platform.

Linux is the operating system you are most likely to encounter when .NET code
runs outside Windows. Think of it as another production host with different
filesystem, process, permission, service, and shell conventions. You do not
need to become a Linux administrator to be productive, but you do need enough
fluency to read paths, inspect processes, understand permissions, and interpret
logs.

Docker is closest to a disciplined deployment package plus a lightweight
process boundary. It is not a virtual machine in the traditional Hyper-V sense.
It packages an application and its runtime dependencies as an image, then runs
that image as an isolated process called a container.

Kubernetes is closest to a large-scale operations control plane. If a
load-balanced IIS farm answers "which server receives the request?",
Kubernetes also asks "which containers should exist, where should they run, how
should they be replaced, how are they reached, and how is desired state
maintained?" That analogy is useful, but Kubernetes is broader and more
abstract than a web farm.

SQL Server is already familiar. The modern shift is not that relational
databases disappeared. It is that SQL Server may run on Windows, Linux, in a
container for development, in Azure SQL Database, in Azure SQL Managed
Instance, or on a VM. The database remains a strong consistency and persistence
boundary.

Redis is not a replacement for SQL Server. Think of it as a very fast
in-memory structure server that can hold cached data, counters, distributed
locks, session-like state, streams, or temporary coordination data. It solves a
different class of problems from a relational database.

Cloud platforms are the modern equivalent of renting a data center where many
infrastructure concerns are exposed as APIs and managed services. They replace
some hardware and server administration with service selection, identity,
networking, cost management, and operational design.

GitHub is more than a remote Git folder. In many teams it is the collaboration
surface for pull requests, code review, security scanning, issue tracking,
automation, and package publishing.

CI/CD replaces memory-based release discipline with executable release
discipline. If you previously relied on a build machine, deployment checklist,
and human care, CI/CD moves more of that process into source-controlled
automation.

AI services are external intelligence dependencies. From an architecture point
of view, they are closer to calling a payment processor, search service, or
document service than to adding an ordinary class library. They introduce
latency, cost, security, prompt design, evaluation, and correctness concerns.

## Layer 1 — Conceptual Model

The modern technology stack can be understood as five cooperating layers:

```text
Application layer
  .NET, ASP.NET Core, C#, application libraries

Data and dependency layer
  SQL Server, Redis, queues, files, APIs, AI services

Runtime and packaging layer
  Windows, Linux, Docker, container images

Platform and operations layer
  Cloud platforms, Kubernetes, identity, networking, observability

Delivery layer
  GitHub, pull requests, CI/CD, artifact registries, release automation
```

The application layer is where most business code lives. This is where you
write APIs, validation, business rules, background services, and integrations.

The data and dependency layer is where the application stores durable state,
reads fast temporary state, communicates with other systems, and calls external
capabilities.

The runtime and packaging layer answers the question, "What exactly runs, and
what does it require from the machine?" This includes the OS, installed runtime
or container image, process environment, ports, files, certificates, and
startup behavior.

The platform and operations layer answers the question, "Where does it run,
how is it secured, how does it scale, and how do we know it is healthy?"

The delivery layer answers the question, "How does a code change become a
validated production change?"

No single layer is the whole stack. A developer who only knows the application
layer may write good C# but struggle to diagnose production. A developer who
only knows platform tools may ship elaborate infrastructure for a simple
problem. Modern .NET fluency means understanding how the layers cooperate.

## Layer 2 — System Relationships

Each technology has inputs, outputs, dependencies, ownership boundaries, and
failure modes.

.NET takes source code, project files, NuGet packages, SDKs, and configuration
as inputs. It produces assemblies, applications, packages, and runtime
behavior. The development team usually owns the code and package choices; the
platform or operations team may own installed runtimes, base images, and
runtime policies.

ASP.NET Core takes HTTP requests, configuration, dependency registrations, and
middleware as inputs. It produces HTTP responses, logs, metrics, and calls to
dependencies. It fails when routing is wrong, configuration is missing,
dependencies are unavailable, startup fails, or runtime exceptions escape.

Linux takes processes, files, users, groups, sockets, services, and environment
variables as operating-system concepts. A .NET developer usually does not own
the whole Linux estate, but they may own enough of the application process to
read logs, understand paths, inspect environment variables, and troubleshoot
container behavior.

Docker takes a Dockerfile, application output, base images, and configuration
as inputs. It produces container images and containers. The development team
often owns the application image. A platform team may own the registry, base
image policy, runtime host, and security scanning.

Kubernetes takes declarative resource definitions that describe desired state.
It attempts to keep the actual cluster state aligned with those definitions.
The application team may own deployment definitions for its service; a platform
team often owns the cluster, networking, ingress, policies, secrets integration,
and shared observability.

SQL Server takes schema, queries, transactions, indexes, data files, memory,
storage, and connections. It produces durable state and query results. Its
failure boundaries include locking, blocking, disk, memory, schema migration,
backup, recovery, permissions, and network access.

Redis takes keys, values, data structures, expiration rules, memory, and client
connections. It produces fast reads, writes, and coordination behavior. Its
failure boundaries include memory pressure, eviction policy, persistence
configuration, clustering, and the risk of treating cached data as if it were
durable relational truth.

Cloud platforms take resource definitions, subscriptions or accounts,
permissions, regions, networks, and billing rules. They produce hosted
services. Their failure boundaries include identity, quota, cost, region
availability, misconfiguration, provider limits, and shared-responsibility
misunderstandings.

GitHub takes commits, branches, pull requests, issues, workflow files, and
repository permissions. It produces review history, source history, automation
events, and collaboration records. Its failure boundaries include branch-policy
gaps, secret leaks, broken workflows, weak review practices, and permissions
that are too broad.

CI/CD takes repository events, workflow definitions, build agents, secrets,
tests, package feeds, and deployment credentials. It produces build results,
test reports, packages, images, deployments, and audit trails. Its failure
boundaries include flaky tests, missing environment parity, credential
problems, incomplete rollback plans, and automation that hides rather than
reduces risk.

AI services take prompts, input data, context, model choices, safety settings,
tools, embeddings, and credentials. They produce generated text, structured
outputs, classifications, embeddings, or tool calls. Their failure boundaries
include latency, cost, hallucination, data leakage, model drift, evaluation
gaps, and ambiguous ownership of generated behavior.

The relationships matter because production failures rarely respect chapter
boundaries. A slow request might involve ASP.NET Core routing, Redis cache
misses, SQL Server query plans, cloud network latency, and missing telemetry.
The stack is a system.

## Layer 3 — Core Mechanics

The smallest useful example is a web API with a database, cache, and delivery
pipeline:

```text
GitHub repository
  |
  v
CI builds and tests the .NET solution
  |
  v
Docker image is produced
  |
  v
Cloud platform runs the ASP.NET Core container
  |
  +-- SQL Server stores orders
  |
  +-- Redis caches product lookups
  |
  +-- AI service summarizes support notes
  |
  v
Observability records logs, metrics, and traces
```

The core terminology starts here.

A runtime executes compiled application code. In modern .NET, the runtime is
not the same thing as the SDK. The SDK builds and publishes applications; the
runtime runs them.

A framework provides reusable application structure. ASP.NET Core is the web
framework used to build HTTP APIs, web applications, real-time apps, and
services.

An operating system hosts processes, files, networking, permissions, and
resource limits. Windows and Linux can both host modern .NET applications.

A container image is a packaged filesystem and metadata template used to create
containers. A container is a running instance of that image.

An orchestrator manages many containers across machines. Kubernetes is the
dominant open-source orchestrator and is widely used in cloud-native
environments, but it is not required for every application.

A relational database stores structured durable data using tables,
relationships, indexes, transactions, and queries. SQL Server remains a major
enterprise relational database and, according to DB-Engines in July 2026,
ranked third overall among database management systems.

An in-memory data store keeps data primarily in memory for speed. Redis is a
prominent example and ranked eighth overall in the July 2026 DB-Engines
ranking.

A cloud platform provides infrastructure and application capabilities as
services: compute, databases, storage, networking, identity, observability,
and AI.

A repository stores source history. Git is the version-control system; GitHub
is a collaboration platform built around Git repositories and automation.

Continuous integration means automatically building and testing code changes
after they are committed or proposed. Continuous delivery and deployment extend
that automation toward release artifacts and environments.

An AI service exposes model behavior through an API or SDK. In modern .NET,
Microsoft.Extensions.AI provides common abstractions for interacting with
models and related AI capabilities across providers.

## Layer 4 — Developer Workflow

Chapter 3 will teach the modern workflow in more detail. For this chapter, the
workflow is about recognizing which tool participates at each stage.

Early in development, you mostly touch .NET, ASP.NET Core, SQL Server or a
local database, maybe Redis, and GitHub. You run locally, test quickly, and
commit changes.

As the application grows, Docker often enters the workflow to make the local
environment more repeatable. Instead of every developer installing the same
database, cache, and supporting services by hand, a team can describe a local
multi-container environment.

When the team starts sharing changes, CI becomes important. A pull request
should not depend only on "it works on my machine." It should trigger a build
and tests in a clean environment.

When the team starts deploying repeatedly, CD becomes important. The question
shifts from "Can we build it?" to "Can we safely move this exact validated
artifact into an environment?"

As production needs grow, cloud services and observability become part of the
daily workflow. Developers need to know how configuration reaches the
application, where logs go, how database access is secured, how health is
reported, and how deployments can be rolled back.

Kubernetes usually appears after these basics. It is most useful when a team
needs a consistent platform for many containerized workloads, not when it is
trying to learn containers for the first time.

AI services may appear in two places. AI coding assistants may help during
development. AI application services may become runtime dependencies when the
product needs summarization, classification, chat, extraction, embeddings, or
agentic workflows.

Useful orientation commands:

```bash
dotnet --info
git --version
docker --version
kubectl version --client
```

On Windows PowerShell, the commands are the same:

```powershell
dotnet --info
git --version
docker --version
kubectl version --client
```

These commands are not a setup requirement for this chapter. They simply show
which parts of the stack are already present on your machine.

## Layer 5 — Production Usage

In production, the technology stack becomes a set of responsibility boundaries.

.NET and ASP.NET Core define the application runtime boundary. Production
questions include which .NET version is supported, whether the app is patched,
how configuration is loaded, how logs are emitted, how health is exposed, and
how dependency failures are handled.

Linux or Windows defines the host operating-system boundary. Production
questions include patching, file permissions, service identity, certificates,
network access, process limits, and diagnostic access.

Docker defines the packaging boundary. Production questions include base-image
trust, image size, vulnerability scanning, registry access, immutable tags,
startup behavior, and whether runtime configuration is separated from the
image.

Kubernetes defines the orchestration boundary. Production questions include
replicas, health probes, rolling updates, secrets integration, network policy,
resource limits, storage, cluster ownership, and operational complexity.

SQL Server defines the durable data boundary. Production questions include
backup and restore, high availability, transaction isolation, migration
strategy, index health, query performance, permissions, and cost.

Redis defines the fast state boundary. Production questions include whether the
data is disposable or durable, how memory is sized, how eviction works, whether
clustering is needed, and how cache misses affect the database.

Cloud platforms define the managed-service boundary. Production questions
include region choice, identity, networking, quotas, compliance, platform
service-level agreements, cost controls, and shared responsibility.

GitHub and CI/CD define the delivery boundary. Production questions include who
can approve changes, which checks are required, how secrets are protected, how
artifacts are versioned, and how deployments are audited.

AI services define the model boundary. Production questions include data
privacy, prompt injection, output validation, model selection, cost per call,
evaluation, latency, fallback behavior, and observability of AI decisions.

The state-of-the-art direction across these areas is not "use more tools." It
is platform engineering: make the correct path easy for teams. A mature
organization gives developers paved paths for common tasks such as creating an
API, adding a database, creating a pipeline, publishing a container, connecting
to secrets, emitting telemetry, and deploying safely.

That is the modern production goal: not heroic deployment knowledge, but
repeatable systems that make the safe thing normal.

## Layer 6 — Tradeoffs and Alternatives

The modern stack is full of good tools, and good tools can still be wrong for
the job.

.NET competes most often with ecosystems such as Java, Go, Node.js, Python,
Rust, and Kotlin. .NET is strong for enterprise applications, APIs, cloud
services, Windows integration, high-performance server workloads, and teams
that value C# and mature tooling. It may not be the natural first choice when a
team is already deeply invested in another ecosystem or when a specialized
runtime dominates a domain.

ASP.NET Core competes with frameworks such as Spring Boot, Express, FastAPI,
Django, Rails, Laravel, and Go HTTP frameworks. ASP.NET Core is strong for
typed, high-performance APIs and enterprise web systems. It can be excessive
for a tiny script-like endpoint, and it may be unfamiliar to teams centered on
JavaScript or Python.

Linux competes with Windows Server as a host for .NET workloads. Linux is
common for containers and cloud-native hosting. Windows remains appropriate
for applications with Windows-specific dependencies, legacy COM integration,
classic .NET Framework, or operational teams built around Windows tooling.

Docker competes with direct host installation, virtual machines, language-
specific packaging, and platform-native deployment packages. Docker is useful
when environment repeatability matters. It can be unnecessary for a simple
internal utility or a platform-as-a-service deployment that already abstracts
packaging well.

Kubernetes competes with simpler options: Azure App Service, Azure Container
Apps, AWS Elastic Beanstalk, AWS ECS, Google Cloud Run, ordinary VMs, and
managed platform services. Kubernetes is powerful when many services need a
shared orchestration model. It is often overengineering for one or two modest
applications.

SQL Server competes with PostgreSQL, MySQL, Oracle, SQLite, cloud-native
managed databases, document databases, and analytical stores. SQL Server is a
strong choice for enterprise relational workloads, T-SQL expertise, Microsoft
tooling, and existing estates. PostgreSQL is a major open-source alternative;
SQLite is excellent for embedded and local scenarios; document stores fit
different data shapes.

Redis competes with in-process memory caches, Memcached, database caching,
message brokers, and specialized streaming systems. Redis is useful when fast
shared state or data structures matter. It is not a substitute for relational
integrity, durable event logs, or careful database design.

Cloud platforms compete with on-premises hosting, colocation, private cloud,
and hybrid designs. Azure is often natural for Microsoft-centered enterprises,
AWS is broad and deeply established, and Google Cloud has strengths in data,
analytics, Kubernetes heritage, and AI. The right choice is usually shaped by
organizational skills, contracts, compliance, existing workloads, and service
fit.

GitHub competes with Azure DevOps, GitLab, Bitbucket, and self-hosted Git
systems. GitHub is widely used for open source and increasingly common in
enterprise collaboration. Azure DevOps remains common in Microsoft enterprise
shops with established Boards, Repos, and Pipelines usage.

CI/CD tools include GitHub Actions, Azure Pipelines, GitLab CI, Jenkins,
TeamCity, CircleCI, Buildkite, and others. The best tool is the one your team
can operate reliably with clear secrets management, repeatable builds, and
useful feedback.

AI services compete across providers and hosting models: OpenAI, Azure OpenAI,
Azure AI Foundry, GitHub Models, Amazon Bedrock, Google Gemini, local models
through tools such as Ollama, and traditional ML through ML.NET. Modern .NET's
direction is to provide abstractions that let applications use model services
without binding every part of the code to one provider.

The most common overengineering mistake is stacking all of these choices into
the first version of an application. A strong architecture grows the stack when
the system has earned the complexity.

## Layer 7 — Interview Perspective

Interviewers use stack questions to test whether you understand boundaries,
not whether you can recite logos.

Concepts commonly tested:

- the role of .NET versus ASP.NET Core;
- why Linux matters to modern .NET;
- the difference between containers and virtual machines;
- what Kubernetes adds on top of containers;
- why SQL Server and Redis are complementary rather than interchangeable;
- how GitHub, pull requests, and CI relate to team quality;
- what cloud platforms manage and what the team still owns;
- how AI services fit into an ordinary application architecture.

Representative questions:

- "Where does ASP.NET Core end and the hosting platform begin?"
- "Why would a .NET team use Docker?"
- "When would you avoid Kubernetes?"
- "What belongs in SQL Server versus Redis?"
- "How is GitHub Actions different from Git itself?"
- "What does a cloud provider manage for you, and what remains your
  responsibility?"
- "How would you add an AI feature without making the whole application depend
  on one model provider?"

A strong answer names the boundary and the tradeoff.

For example:

> "Redis can reduce load on SQL Server by caching frequently read data, but SQL
> Server remains the system of record. If Redis is unavailable, the application
> should either fall back to SQL Server or fail in a controlled way, depending
> on the feature."

Common misconceptions:

- ".NET is only a Windows platform."
- "ASP.NET Core requires IIS."
- "Docker is the same as Kubernetes."
- "Kubernetes makes applications cloud-native automatically."
- "Redis is just a faster database."
- "CI/CD is only a deployment script."
- "Cloud means no operations work."
- "AI services can be treated like deterministic libraries."

Small design scenario:

You are asked to design the first modern version of an internal order-tracking
API. The company knows C#, SQL Server, and Windows Server. It wants to become
more modern but does not yet have a large platform team.

A sensible stack might be:

- .NET and ASP.NET Core for the API;
- SQL Server for orders and durable business data;
- GitHub or Azure DevOps for source control and pull requests;
- CI to build and test every change;
- Docker for repeatable local dependencies and possibly packaging;
- a managed cloud app service or container app for hosting;
- basic logging, health checks, and metrics;
- Redis only if caching becomes necessary;
- Kubernetes only if the organization later needs orchestration at scale;
- AI services only when there is a concrete product feature, such as support
  note summarization or order-message classification.

The strong answer is not maximal. It is staged.

## Hands-On Lab

Objective:

Create a stack map for a modern .NET application and classify each technology
by responsibility.

Prerequisites:

- Chapter 1 completed.
- A text editor or notebook.
- Optional local installations of .NET, Git, Docker, and Kubernetes CLI tools.

Steps:

1. Draw five columns:

   ```text
   Application | Data | Packaging/Runtime | Platform/Ops | Delivery
   ```

2. Place each technology from this chapter into the most natural column:

   ```text
   .NET
   ASP.NET Core
   Linux
   Docker
   Kubernetes
   SQL Server
   Redis
   Cloud platform
   GitHub
   CI/CD
   AI services
   ```

3. For each technology, write one sentence explaining what problem it solves.
4. For each technology, write one sentence explaining what it does not solve.
5. Mark which technologies are essential for a first ASP.NET Core API.
6. Mark which technologies are optional until the system grows.
7. If you have the tools installed, run:

   ```bash
   dotnet --info
   git --version
   docker --version
   kubectl version --client
   ```

8. Rewrite the stack as a simple architecture diagram for an order-tracking
   API.

Expected results:

- You can describe the role of each major technology.
- You can separate application concerns from data, runtime, platform, and
  delivery concerns.
- You can identify which technologies are foundational and which are situational.

Validation commands:

```bash
dotnet --info
git --version
docker --version
kubectl version --client
```

Troubleshooting notes:

- If `docker` is not installed, complete the lab conceptually. Docker is taught
  later.
- If `kubectl` is not installed, that is fine. Kubernetes is intentionally not
  required yet.
- If you cannot decide where a technology belongs, ask what boundary it owns:
  code, data, runtime, platform, or delivery.

## Knowledge Check

1. Why is ASP.NET Core not the same layer as Docker or Kubernetes?
2. What problem does Linux solve for modern .NET teams if Windows Server still
   exists?
3. Why is Docker useful even before an application runs in Kubernetes?
4. What does Kubernetes add beyond running a single container?
5. Why should SQL Server usually remain the system of record when Redis is
   added?
6. What is the difference between Git and GitHub?
7. Why is CI/CD part of the technology stack rather than only a team process?
8. What does a cloud platform manage, and what does it not manage for your
   application team?
9. Why should AI services be treated as runtime dependencies rather than
   ordinary deterministic libraries?
10. Which technologies in this chapter would you choose for the first version
    of a small internal API, and which would you postpone?

## Summary

The modern .NET technology stack is a layered system.

.NET and ASP.NET Core provide the application foundation. SQL Server and Redis
serve different data needs: durable relational state and fast shared in-memory
state. Linux and Docker shape how applications run and how their environments
are packaged. Kubernetes manages containerized workloads when scale and
platform consistency justify its complexity. Cloud platforms provide managed
compute, data, identity, networking, and operations services. GitHub and CI/CD
turn source changes into validated, reviewable, repeatable delivery. AI
services add model-backed behavior when the product needs capabilities that
ordinary deterministic code does not provide.

The stack is not a checklist. It is a set of choices around boundaries. The
professional skill is knowing which boundary you are addressing and whether the
tool adds more clarity than complexity.

The next chapter moves from the technology map to the day-to-day workflow:
how modern teams create, review, test, and move .NET changes through the
software lifecycle.

## Sources

- Microsoft Learn, ".NET releases, patches, and support":
  https://learn.microsoft.com/en-us/dotnet/core/releases-and-support
- Microsoft Learn, "ASP.NET documentation":
  https://learn.microsoft.com/en-us/aspnet/core/
- Docker Docs, "What is Docker?":
  https://docs.docker.com/get-started/docker-overview/
- Kubernetes Documentation, "Concepts":
  https://kubernetes.io/docs/concepts/
- Microsoft Learn, "What is SQL Server?":
  https://learn.microsoft.com/en-us/sql/sql-server/what-is-sql-server
- Redis, "What is Redis?: An Overview":
  https://redis.io/tutorials/what-is-redis/
- GitHub Docs, "GitHub Actions documentation":
  https://docs.github.com/en/actions
- Microsoft Learn, "Use continuous integration":
  https://learn.microsoft.com/en-us/devops/develop/what-is-continuous-integration
- Microsoft Azure, "What is cloud computing?":
  https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-cloud-computing/
- Microsoft Learn, "Develop .NET apps with AI features":
  https://learn.microsoft.com/en-us/dotnet/ai/overview
- DB-Engines, "DB-Engines Ranking":
  https://db-engines.com/en/ranking/
- CNCF, "2025 Annual Cloud Native Survey" announcement:
  https://www.cncf.io/announcements/2026/01/20/kubernetes-established-as-the-de-facto-operating-system-for-ai-as-production-use-hits-82-in-2025-cncf-annual-cloud-native-survey/
- Stack Overflow, "2025 Developer Survey: Technology":
  https://survey.stackoverflow.co/2025/technology/

## Further Reading

- Microsoft Learn, ".NET + AI ecosystem tools and SDKs":
  https://learn.microsoft.com/en-us/dotnet/ai/dotnet-ai-ecosystem
- Google Cloud, "Google Cloud overview":
  https://docs.cloud.google.com/docs/overview
- AWS, "What is cloud computing?":
  https://docs.aws.amazon.com/whitepapers/latest/aws-overview/what-is-cloud-computing.html
- Docker Docs, "What is a container?":
  https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/
