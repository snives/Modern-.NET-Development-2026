= Cloud Platforms
<cloud-platforms>
== Chapter Purpose
<chapter-purpose>
Chapter 12 explained how an ASP.NET Core application becomes a
deployable artifact and runs under a host. Chapter 13 expands the
hosting question into the cloud.

Cloud platforms exist because organizations wanted infrastructure and
application capabilities without buying, installing, and operating every
piece of hardware and platform software themselves. Instead of procuring
servers, storage arrays, load balancers, firewall appliances, backup
systems, and data center space months in advance, teams can provision
compute, databases, storage, networking, identity, observability, and AI
services on demand.

For a Windows, IIS, and SQL Server developer, the cloud can feel like a
data center with an API. That analogy is useful. Azure, AWS, and Google
Cloud all provide virtual machines, networks, disks, databases,
firewalls, identity systems, logs, and management consoles. But the
analogy breaks down because the cloud is not just rented servers. It is
a catalog of managed services with different responsibility boundaries,
pricing models, regional behavior, identity systems, and operational
tradeoffs.

This chapter introduces Azure, AWS, Google Cloud, managed databases,
storage, networking, and identity. It explains how the major cloud
providers compare without pretending that a single chapter can make you
a cloud architect.

== Where This Fits
<where-this-fits>
Cloud platforms sit underneath and around deployed applications.

```text
ASP.NET Core artifact or container image
        |
        v
Cloud compute service
        |
        +-- managed database
        +-- object storage
        +-- virtual network
        +-- identity and secrets
        +-- load balancing
        +-- logs and metrics
        +-- deployment integration
        |
        v
Users, partners, internal systems, and operations teams
```

Chapter 13 follows deployment because cloud services are easier to
understand once publishing, hosting, reverse proxies, configuration, and
production deployment are clear. It prepares for Chapter 14 on
observability, Chapter 16 on deployment pipelines, Chapter 17 on
infrastructure as code, and Chapter 18 on Kubernetes.

The purpose here is not to memorize product names. Product names change,
services evolve, and teams standardize differently. The purpose is to
understand the major cloud categories and the responsibility tradeoffs.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
A traditional enterprise environment might have had:

- Windows Server VMs;
- IIS;
- SQL Server;
- file shares;
- Active Directory;
- load balancers;
- firewall rules;
- backup jobs;
- monitoring tools;
- deployment scripts;
- server administrators and DBAs.

Cloud platforms provide equivalents, but they are exposed as services.

A virtual machine maps directly to a server VM. You still patch,
configure, secure, monitor, and deploy to it. It is the most familiar
cloud starting point, but also the least transformative.

A managed app platform maps roughly to "I want to run my application
without owning the server." Azure App Service, Azure Container Apps, AWS
App Runner, AWS Elastic Beanstalk, Google App Engine, and Google Cloud
Run are examples in this family.

A managed database maps to SQL Server operated as a service. Azure SQL
Database, Amazon RDS for SQL Server, and Google Cloud SQL for SQL Server
all reduce some database server administration, though schema design,
indexing, query performance, security, and cost remain application
responsibilities.

Object storage maps loosely to file shares, but it is not a normal
filesystem. Azure Blob Storage, Amazon S3, and Google Cloud Storage
store objects in buckets or containers and expose APIs for durable
storage.

Cloud identity maps partly to Active Directory and service accounts.
Microsoft Entra ID, AWS IAM, and Google Cloud IAM all answer questions
about who or what can access a resource.

Cloud networking maps to VLANs, subnets, firewalls, DNS, public IPs, and
load balancers, but the implementation is virtual and API-driven.

The old model asked, "Which server owns this?" The cloud model asks,
"Which service owns this responsibility, in which region, under which
identity, with which cost and failure boundary?"

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
A cloud platform is a provider-operated set of infrastructure and
application services that customers provision and configure on demand.

It solves these problems:

- provisioning compute without buying hardware;
- using managed databases and storage;
- scaling resources up and down;
- deploying across regions and zones;
- integrating identity and access control;
- automating infrastructure through APIs;
- paying for measured usage instead of only fixed capital expense;
- accessing specialized services such as messaging, analytics, and AI.

It does not solve these problems automatically:

- it does not choose the right architecture;
- it does not make applications secure by default;
- it does not eliminate operations work;
- it does not make databases cheap or fast automatically;
- it does not prevent outages;
- it does not remove the need to understand networking, identity, and
  cost.

The basic cloud model is:

```text
Compute runs code.
Databases store structured durable data.
Object storage stores files and blobs.
Networking connects and isolates resources.
Identity controls access.
Observability reports behavior.
Billing measures usage.
```

The state-of-the-art direction in 2026 is managed platforms, container
services, serverless functions, managed databases, integrated identity,
platform engineering, AI services, and infrastructure as code. The trend
is not "never use VMs." The trend is to choose the highest useful level
of management without losing required control.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The cloud account or tenant is the top-level administrative boundary.
Azure uses tenants, subscriptions, management groups, and resource
groups. AWS uses accounts, organizations, regions, and resources. Google
Cloud uses organizations, folders, projects, regions, zones, and
resources.

The region is the geographic placement boundary. It affects latency,
data residency, service availability, disaster recovery, and cost.

The availability zone is a failure-isolation boundary inside many
regions. Not every service uses zones the same way. Some resources are
global, some are regional, and some are zonal.

The compute service runs application code. Options include VMs, app
platforms, container services, serverless functions, and Kubernetes.

The database service stores durable structured data. Managed relational
databases reduce server management, but the team still owns schema,
query behavior, access patterns, and migration safety.

The storage service stores objects, files, disks, backups, and
artifacts. Object storage is commonly used for uploads, exports, static
files, logs, backups, and data exchange.

The virtual network controls private communication, public exposure,
subnets, routes, firewall rules, DNS, load balancers, private endpoints,
and service connectivity.

The identity system controls access for users, applications, services,
build pipelines, and administrators. Strong cloud design relies on least
privilege and short-lived or managed credentials where possible.

Failure boundaries include region outages, identity misconfiguration,
public network exposure, quota limits, wrong service tier, missing
backups, overly broad permissions, secret leakage, service limits,
unexpected cost, and provider-specific behavior hidden behind familiar
names.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
The smallest useful cloud design for an ASP.NET Core API looks like
this:

```text
Public HTTPS endpoint
        |
        v
Managed app or container service
        |
        +-- managed SQL database
        +-- object storage for uploaded files
        +-- secret store for connection strings and keys
        +-- identity for service-to-service access
        +-- logs and metrics
```

The three major providers offer similar categories with different names
and different strengths.

For compute:

```text
Azure: Azure App Service, Azure Container Apps, Azure Functions, Azure VMs,
       Azure Kubernetes Service

AWS: Elastic Beanstalk, App Runner, Lambda, EC2, ECS, EKS

Google Cloud: App Engine, Cloud Run, Cloud Functions, Compute Engine,
              Google Kubernetes Engine
```

For relational databases:

```text
Azure: Azure SQL Database, Azure SQL Managed Instance,
       Azure Database for PostgreSQL

AWS: Amazon RDS, Amazon Aurora

Google Cloud: Cloud SQL, AlloyDB for PostgreSQL
```

For object storage:

```text
Azure: Azure Blob Storage
AWS: Amazon S3
Google Cloud: Cloud Storage
```

For identity and secrets:

```text
Azure: Microsoft Entra ID, managed identities, Azure Key Vault
AWS: IAM, IAM roles, AWS Secrets Manager, AWS Systems Manager Parameter Store
Google Cloud: Cloud IAM, service accounts, Secret Manager
```

For a \.NET team, the most important mechanics are not the names but the
questions:

```text
Where does the app run?
Where is data stored?
How does the app authenticate to dependencies?
Which network paths are public and private?
How is configuration supplied?
How are logs and metrics collected?
How is cost measured?
```

Cloud development uses provider CLIs as well as portals:

```bash
az version
aws --version
gcloud version
```

Those commands are not required for every developer, but teams that
deploy to cloud platforms should understand that cloud resources are
scriptable and eventually should be defined with repeatable automation.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
At the developer level, the cloud workflow should begin with a target
environment and a responsibility map.

For an ASP.NET Core API:

```text
Application artifact: publish folder or container image
Compute target: managed app service or container service
Database: managed SQL database
Secrets: provider secret store
Identity: app-managed identity or service role
Networking: HTTPS public endpoint, private database path if possible
Observability: provider logs and metrics
```

A simple early workflow:

```text
Build and test locally
        |
        v
Publish or build container image
        |
        v
Provision cloud resources
        |
        v
Configure app settings and secrets
        |
        v
Deploy artifact
        |
        v
Verify health and logs
        |
        v
Record cost and cleanup plan
```

Do not start by clicking every interesting cloud service. Start with the
minimum runtime path: app, database, configuration, identity, logs, and
network exposure.

Provider-specific tools are useful:

```bash
az login
az group list
```

```bash
aws configure sso
aws sts get-caller-identity
```

```bash
gcloud auth login
gcloud config list
```

These commands answer the same question in different ecosystems: which
cloud identity and context am I using?

For team work, avoid unmanaged portal-only resources. Manual exploration
is fine for learning, but production resources should move toward
infrastructure as code in Chapter 17.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production cloud usage starts with the shared responsibility model. The
cloud provider owns the physical data centers and managed service
internals. The customer still owns application code, configuration,
identity assignments, data classification, access policy, network
exposure, cost management, and many security decisions.

Configuration should be environment-specific and centrally controlled.
Do not use the same database, storage account, secret, or identity
across development, test, and production unless there is a deliberate
and reviewed reason.

Secrets should live in managed secret stores or be replaced by managed
identity patterns when possible. A cloud platform makes secret storage
easier; it does not make hard-coded secrets safe.

Security includes IAM, network isolation, private endpoints, TLS,
managed identity, key rotation, audit logs, policy enforcement, patching
choices, and secure deployment credentials.

Reliability depends on regions, zones, backups, replication, health
checks, autoscaling, service quotas, retry behavior, and disaster
recovery plans. Managed services reduce some work but introduce
provider-specific limits and failure modes.

Deployment should use traceable artifacts and controlled promotion. A
cloud portal deployment can teach the platform, but production should
eventually be automated and repeatable.

Observability is a first-class cloud concern. Each provider offers
logging, metrics, tracing, alerting, and dashboards. Chapter 14
introduces the basic diagnostics needed for deployed applications.

Scaling should follow bottlenecks. Scaling app instances is easy on many
cloud platforms. Scaling a database, cache, or downstream API may be
harder and more expensive.

Persistence requires backup and retention decisions. Managed databases
and object storage are durable services, but accidental deletion, bad
migrations, and corrupt writes remain application and operations risks.

Cost must be designed, not discovered by surprise. Use budgets, tags or
labels, alerts, right-sized service tiers, cleanup automation, and
review of logs, storage, network transfer, and idle resources.

Local development optimizes for quick feedback. Cloud production
optimizes for secure identity, durable services, controlled network
exposure, observable operation, and accountable cost.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Azure is often the most natural cloud for Microsoft-centered
enterprises. It integrates deeply with \.NET, Visual Studio, GitHub,
Microsoft Entra ID, Windows Server, SQL Server, Azure SQL, and Microsoft
security and governance tools. It is not limited to Microsoft
technologies; Azure also supports Linux, containers, Kubernetes,
Terraform, PostgreSQL, MySQL, Java, Python, JavaScript, Go, and more.

AWS has the longest history as a broad public cloud platform and a very
large service catalog and community. It is a common choice for
organizations with existing AWS investment, broad cloud skills, mature
platform teams, or service needs that align with AWS strengths.

Google Cloud is strong in data, analytics, Kubernetes heritage, global
networking, and AI-related services. It can be attractive when those
strengths fit the organization or when teams already use Google Cloud
foundations.

Gartner's 2025 Magic Quadrant for Strategic Cloud Platform Services
named AWS, Microsoft, and Google as Leaders according to provider
announcements and the published Gartner abstract. That does not make the
choice automatic. It means all three are credible strategic providers.

Alternatives include on-premises infrastructure, private cloud, hybrid
cloud, Oracle Cloud, IBM Cloud, sovereign clouds, managed hosting
providers, and platform-as-a-service products outside the hyperscalers.

Common overengineering mistakes:

- choosing Kubernetes before a managed app service has been considered;
- exposing databases publicly for convenience;
- using one cloud account or subscription for every environment;
- granting administrator permissions to application identities;
- ignoring egress and logging costs;
- assuming managed means maintenance-free;
- using portal clicks as the only production documentation;
- copying provider reference architectures without understanding the
  workload.

The best provider is not always the provider with the most services. It
is the provider your organization can operate securely, reliably, and
economically for the system you are building.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use cloud questions to test whether you understand
tradeoffs and responsibility boundaries.

Concepts commonly tested:

- cloud versus traditional hosting;
- IaaS, PaaS, containers, and serverless;
- regions and availability zones;
- managed databases;
- object storage;
- virtual networking;
- IAM and managed identity;
- secrets management;
- cost awareness;
- provider comparison.

Representative questions:

- "Why use a managed app platform instead of a VM?"
- "What is the difference between object storage and a file share?"
- "What does a managed database manage, and what does the team still
  own?"
- "Why do regions and zones matter?"
- "How should an app authenticate to cloud resources?"
- "When would Azure be a natural fit for a \.NET team?"
- "Why might a team choose AWS or Google Cloud instead?"
- "What cloud costs surprise teams?"

A strong answer names ownership:

#quote(block: true)[
"A managed database removes much of the server administration, but the
team still owns schema design, indexes, queries, migrations,
permissions, backup retention choices, and cost. Managed means the
boundary moved, not that the responsibility disappeared."
]

Common misconceptions:

- "Cloud means no operations."
- "Managed services are always cheaper."
- "A VM in the cloud is automatically cloud-native."
- "Object storage is just a normal disk."
- "The provider secures everything."
- "Any cloud provider choice is only a technical decision."
- "The best cloud is the one with the longest feature list."

Small design scenario:

You need to host an ASP.NET Core order API with SQL Server, file
uploads, authentication, and basic monitoring. The company already uses
Microsoft Entra ID and SQL Server.

A strong first design might use Azure App Service or Azure Container
Apps, Azure SQL Database, Azure Blob Storage, managed identity, Azure
Key Vault, and Azure Monitor. It would keep the design simple, use
private connectivity where appropriate, avoid public database exposure,
and introduce infrastructure as code once the resource model is
understood.

If the company already had mature AWS or Google Cloud operations, the
same architecture categories would map to that provider's services
instead.

== Hands-On Lab
<hands-on-lab>
Objective:

Create a provider-neutral cloud architecture map for an ASP.NET Core
API.

Prerequisites:

- Chapters 1-12 completed.
- No cloud account is required.

Steps:

+ Draw these boxes:

  ```text
  ASP.NET Core API
  Managed compute
  Managed SQL database
  Object storage
  Secret store
  Identity system
  Virtual network
  Logs and metrics
  ```

+ For Azure, map each box to a likely service.

+ For AWS, map each box to a likely service.

+ For Google Cloud, map each box to a likely service.

+ For each provider, answer:

  ```text
  Which service runs the API?
  Which service stores relational data?
  Which service stores uploaded files?
  How does the app get secrets?
  How does the app authenticate to dependencies?
  What is public?
  What should be private?
  Where do logs and metrics go?
  ```

+ Choose one provider and write a one-paragraph justification based on
  team skills, existing systems, security, operations, and cost.

Expected results:

- You can map the same application architecture to Azure, AWS, and
  Google Cloud.
- You can explain why managed services change responsibility boundaries.
- You can identify provider-specific names without confusing them with
  the underlying concepts.

Validation commands:

```bash
az version
aws --version
gcloud version
```

These commands are optional and only validate whether provider CLIs are
installed.

Troubleshooting notes:

- If a CLI is not installed, complete the lab conceptually.
- If service names differ by region or release, use current provider
  documentation.
- If two services seem to fit, compare operational responsibility,
  networking, scaling, and cost rather than choosing by name.

== Knowledge Check
<knowledge-check>
+ Why is the cloud more than rented virtual machines?
+ What does a managed app platform manage for an ASP.NET Core
  application?
+ What does a managed database not manage for the application team?
+ Why do regions and zones matter?
+ How is object storage different from a normal application folder?
+ Why is identity central to cloud architecture?
+ What should usually be private in a database-backed API architecture?
+ Why is cost a design concern in cloud systems?
+ When is Azure a natural fit for a \.NET organization?
+ Why might AWS or Google Cloud still be the right choice for a \.NET
  system?

== Summary
<summary>
Cloud platforms provide compute, databases, storage, networking,
identity, observability, AI, and operations capabilities as services.
They reduce the need to own physical infrastructure and some platform
operations, but they do not remove engineering responsibility.

For modern \.NET developers, Azure, AWS, and Google Cloud are best
understood through categories first and product names second. An ASP.NET
Core API needs a place to run, a database, storage, configuration,
secrets, identity, network boundaries, logs, metrics, and cost controls.
Each provider supplies those capabilities differently.

Azure is often natural for Microsoft-centered enterprises. AWS is broad,
mature, and deeply established. Google Cloud is strong in data,
Kubernetes, networking, and AI-oriented platform capabilities. The right
choice depends on the organization's existing skills, contracts,
compliance, architecture, and operational maturity.

The next chapter introduces observability basics so deployed
applications can be understood after they leave the developer machine.

== Sources
<sources>
- #link("https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/why-azure")[Why Azure?]
- #link("https://docs.aws.amazon.com/whitepapers/latest/aws-overview/what-is-cloud-computing.html")[What is cloud computing? - AWS]
- #link("https://docs.aws.amazon.com/whitepapers/latest/aws-overview/introduction.html")[Overview of Amazon Web Services]
- #link("https://docs.cloud.google.com/docs/overview")[Google Cloud overview]
- #link("https://www.gartner.com/en/documents/6808434")[Gartner Magic Quadrant for Strategic Cloud Platform Services]
- #link("https://aws.amazon.com/blogs/aws/aws-named-as-a-leader-in-2025-gartner-magic-quadrant-for-strategic-cloud-platform-services-for-15-years-in-a-row/")[AWS named as a Leader in 2025 Gartner Magic Quadrant for Strategic Cloud Platform Services]
- #link("https://cloud.google.com/blog/products/compute/google-is-a-leader-in-gartner-magic-quadrant-for-scps/")[Google is a Leader in the Gartner Magic Quadrant for Strategic Cloud Platform Services]

== Further Reading
<further-reading>
- #link("https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/")[Microsoft Cloud Adoption Framework for Azure]
- #link("https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html")[AWS Well-Architected Framework]
- #link("https://docs.cloud.google.com/architecture/framework")[Google Cloud Architecture Framework]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/")[Azure Well-Architected Framework]
- #link("https://cloud.google.com/products")[Google Cloud products]
- #link("https://aws.amazon.com/products/")[AWS products]
