= Infrastructure as Code
<infrastructure-as-code>
== Chapter Purpose
<chapter-purpose>
Chapter 16 showed how deployment pipelines move application artifacts
through environments. Chapter 17 extends the same idea to the
environments themselves.

Infrastructure as code, usually shortened to IaC, exists because modern
applications depend on more than application files. An ASP.NET Core API
may need an app service, container environment, database, storage
account, virtual network, identity, secret store, monitoring workspace,
container registry, and deployment permissions. If those resources are
created by hand, the environment becomes a memory-based system.

That problem is familiar. In older Windows and IIS environments, a
production server might have had settings that only one administrator
understood: IIS bindings, application pool identities, Windows features,
firewall rules, scheduled tasks, registry settings, service accounts,
and SQL Server permissions. The server worked, but nobody wanted to
recreate it from scratch.

Infrastructure as code turns that implicit environment knowledge into
versioned, reviewable, repeatable files. Instead of saying, "Create the
database and storage account in the portal," the team describes the
desired resources in code and lets a tool provision or update them.

This chapter introduces why infrastructure became code, Terraform,
Bicep, configuration management, and environment provisioning. It does
not make you a cloud platform engineer in one chapter. It gives you the
mental model needed to understand how modern \.NET environments become
repeatable.

== Where This Fits
<where-this-fits>
Infrastructure as code sits beside application code and deployment
pipelines.

```text
Application source
        |
        v
CI/CD pipeline
        |
        +-- builds application artifact
        |
        +-- applies infrastructure code
        |
        v
Cloud environment
        |
        +-- compute
        +-- database
        +-- storage
        +-- networking
        +-- identity
        +-- secrets
        +-- monitoring
        |
        v
Deployed ASP.NET Core application
```

Chapter 17 follows cloud platforms and deployment pipelines because IaC
is most meaningful once you understand what resources exist and how
releases move through environments. Chapter 18 introduces Kubernetes,
where declarative infrastructure concepts appear again in manifests and
desired state.

The central idea is:

```text
Application code describes behavior.
Infrastructure code describes the environment where behavior runs.
Pipelines coordinate changes to both.
```

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
You already understand configuration drift.

One server has the right IIS module installed. Another has a different
TLS setting. A scheduled task exists in test but not production. A SQL
login has extra permissions because of a production incident three years
ago. A firewall rule was added manually and never documented. The system
works until it must be recreated, audited, scaled, or compared.

Infrastructure as code addresses that class of problem.

An IaC file is like a deployment runbook that a tool can execute
repeatedly. It is also like a source-controlled server build checklist,
but more precise.

Terraform configuration maps to cross-platform infrastructure
definitions. It can manage Azure, AWS, Google Cloud, on-premises
systems, SaaS products, and many other APIs through providers.

Bicep maps to Azure Resource Manager. It is Azure-specific and designed
as a cleaner declarative language for Azure resources than raw ARM
template JSON.

Configuration management maps to server configuration tools such as
Group Policy, Desired State Configuration, PowerShell scripts, Chef,
Puppet, or Ansible. The difference is that cloud IaC often provisions
managed services instead of configuring long-lived servers.

The analogy breaks down when infrastructure code is treated as a script.
Most IaC is declarative. You describe the desired end state. The tool
decides what actions are needed to reach it.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Infrastructure as code is the practice of defining infrastructure
resources in versioned files and applying those definitions with
automation.

It solves these problems:

- recreating environments reliably;
- reviewing infrastructure changes before they happen;
- reducing portal-only or click-only configuration;
- comparing environments;
- automating environment provisioning;
- tying infrastructure changes to application releases;
- improving auditability and rollback planning;
- reducing configuration drift.

It does not solve these problems automatically:

- it does not choose the right architecture;
- it does not make cloud resources secure by default;
- it does not remove the need to understand networking and identity;
- it does not eliminate state, drift, or migration risk;
- it does not make destructive changes safe;
- it does not replace production review.

The core model is:

```text
Desired state file
        |
        v
Plan or preview
        |
        v
Apply or deploy
        |
        v
Cloud resources
        |
        v
State, deployment record, or provider view
```

Terraform and Bicep both use declarative configuration, but they track
reality differently. Terraform stores state that maps configuration to
real resources. Bicep relies on Azure Resource Manager deployments and
Azure's resource model rather than a separate Terraform-style state
file.

That difference shapes how teams collaborate and recover from manual
changes.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The infrastructure code repository owns resource definitions. It may
live with the application code or in a separate platform repository,
depending on team ownership and release coupling.

The IaC tool reads configuration files. Terraform reads `.tf` files
written in HashiCorp Configuration Language. Bicep reads `.bicep` files
and compiles them to ARM templates for Azure Resource Manager.

The provider or cloud control plane owns resource creation. Terraform
uses providers to call APIs for Azure, AWS, Google Cloud, Kubernetes,
GitHub, and many other systems. Bicep submits deployments to Azure
Resource Manager.

The state or deployment record owns the mapping between desired
configuration and real resources. Terraform state is critical and must
be secured and backed up. Bicep does not use a separate state file;
Azure Resource Manager compares the deployment with existing Azure
resources.

The pipeline owns execution. It can run validation, plan, approval, and
apply steps. Production infrastructure changes should not depend on a
developer's laptop.

The environment owns the resources: app host, database, storage,
network, identity, role assignments, secret store, monitoring, and
policy assignments.

Failure boundaries include missing permissions, wrong subscription or
account, unsafe deletes, state file corruption, out-of-band portal
changes, naming collisions, quota limits, provider bugs, secret
exposure, policy violations, and infrastructure changes applied without
application compatibility.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
A simple Terraform configuration declares a provider and resources:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "rg-orders-dev"
  location = "eastus"
}
```

The basic Terraform workflow is:

```bash
terraform init
terraform plan
terraform apply
```

`init` installs providers and prepares the working directory. `plan`
previews changes. `apply` performs changes.

A simple Bicep file declares Azure resources:

```bicep
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: 'ordersstorage${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
```

Deploy with Azure CLI:

```bash
az deployment group create \
  --resource-group rg-orders-dev \
  --template-file main.bicep
```

Preview with what-if:

```bash
az deployment group what-if \
  --resource-group rg-orders-dev \
  --template-file main.bicep
```

Both tools support parameters, variables, modules, outputs, and reusable
patterns. The mechanics differ, but the discipline is the same: review
the planned change before applying it.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
A practical IaC workflow begins with one environment and a small
resource set.

```text
Choose target environment
        |
        v
Define resources in code
        |
        v
Format and validate
        |
        v
Preview changes
        |
        v
Review pull request
        |
        v
Apply through pipeline
        |
        v
Verify resources and application deployment
```

For Terraform:

```bash
terraform fmt
terraform validate
terraform plan
```

For Bicep:

```bash
az bicep build --file main.bicep
az deployment group what-if \
  --resource-group rg-orders-dev \
  --template-file main.bicep
```

Keep environment-specific values out of copied files when possible. Use
parameters:

```text
dev.tfvars
test.tfvars
prod.tfvars
```

or Bicep parameter files:

```text
main.dev.bicepparam
main.prod.bicepparam
```

The pull request should show:

```text
What resources change?
Which environment changes?
What is the preview or plan?
Is anything destroyed?
Are permissions changing?
Does the app deployment depend on this change?
How do we recover if it fails?
```

For learning, running IaC locally is fine. For teams, production applies
should move into CI/CD with approvals, secrets, and audit records.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production IaC begins with state and permissions.

Terraform state must be stored remotely, locked during changes, backed
up, and protected as sensitive data. State can contain resource
identifiers and secrets depending on providers and resources.

Bicep deployments rely on Azure Resource Manager, but production still
needs clear deployment scopes, permissions, template history, parameter
handling, and policy review.

Configuration should separate reusable modules from environment-specific
values. Repeating entire infrastructure definitions for every
environment invites drift.

Secrets should not be hard-coded in IaC files or parameter files. Prefer
secret references, managed identities, Key Vault, CI/CD secret stores,
or provider-supported secure inputs.

Security includes least-privilege deployment identities, protected
state, reviewed role assignments, network boundaries, policy
enforcement, and auditable change history.

Reliability depends on safe change ordering. Infrastructure changes can
break applications: removing a subnet, renaming a storage account,
rotating a key, or changing a database firewall can take production
down.

Deployment pipelines should preview infrastructure changes, require
approval for sensitive environments, and apply changes with identities
scoped to the target environment.

Observability applies to infrastructure changes too. Resource health,
deployment failures, policy violations, drift, quota usage, and cost
changes should be visible.

Scaling IaC requires modules, naming conventions, tagging, repository
structure, environment promotion, and ownership boundaries.

Persistence requires extra caution. Deleting a database, storage
account, key vault, or network can be far more damaging than redeploying
an app container. Production IaC should use deletion protection, locks,
backups, and review for stateful resources where appropriate.

Cost is part of the design. IaC can create expensive resources quickly.
Tags, budgets, policies, and cleanup automation should be part of the
environment model.

Local IaC experimentation optimizes for learning. Production IaC
optimizes for reviewability, least privilege, controlled change, and
recovery.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use Terraform when the organization needs multi-cloud, hybrid-cloud,
cross-provider automation, strong module ecosystems, or a consistent
workflow across many APIs.

Use Bicep when the target is Azure, the team wants deep Azure Resource
Manager integration, immediate Azure resource coverage, and a concise
Azure-native language.

Use ARM templates when required by legacy systems or generated tooling,
but prefer Bicep for hand-authored Azure templates in most new work.

Use Pulumi when the team wants to define infrastructure using
general-purpose languages such as C\#, TypeScript, Python, Go, or Java.
Use Ansible, Chef, or Puppet when configuration management of servers is
the central problem.

OpenTofu is an open-source Terraform fork created after Terraform
licensing changes. Some organizations consider it when they want a
Terraform-compatible open-source path.

Common overengineering mistakes:

- introducing IaC before naming and ownership conventions exist;
- putting secrets directly in code;
- applying production changes from a developer laptop;
- ignoring Terraform state security;
- treating plan output as unreadable noise;
- creating modules too early for one-off resources;
- letting portal changes drift away from code;
- using IaC to create resources no one understands.

The state-of-the-art direction is policy-aware, pipeline-driven IaC:
modules for common patterns, secure remote state, plan or what-if
review, environment approvals, drift detection, cost controls, and
integration with deployment pipelines.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use IaC questions to test whether you understand
repeatability and cloud responsibility.

Concepts commonly tested:

- why infrastructure became code;
- declarative versus imperative automation;
- Terraform providers;
- Terraform state;
- Bicep and ARM;
- plan versus apply;
- what-if previews;
- modules;
- environment parameterization;
- drift;
- secrets and state security.

Representative questions:

- "What problem does infrastructure as code solve?"
- "How is Terraform different from Bicep?"
- "Why is Terraform state important?"
- "What is a plan?"
- "What is Azure Bicep?"
- "How do you prevent dev and prod from drifting apart?"
- "Where should secrets live?"
- "Why should production infrastructure changes go through review?"

A strong answer names both benefits and risk:

#quote(block: true)[
"IaC makes environments repeatable and reviewable, but it can also
destroy resources repeatably if used carelessly. I would use plans or
what-if output, protect state, keep secrets out of code, apply through
pipelines, and require extra review for stateful resources and
permissions."
]

Common misconceptions:

- "IaC means no one needs to understand cloud resources."
- "Terraform state is just a cache."
- "Bicep works across all clouds."
- "If code review passed, applying infrastructure is always safe."
- "Portal changes are harmless."
- "Configuration management and provisioning are the same thing."
- "IaC rollback is always easy."

Small design scenario:

You need separate development, test, and production environments for an
ASP.NET Core order API. Each environment needs app hosting, SQL
database, storage, managed identity, Key Vault, and monitoring.

A good IaC design would create reusable modules, parameterize
environment names and sizes, use separate state or deployment scopes per
environment, store secrets in Key Vault, assign least-privilege
identities, preview changes in pull requests, and apply production
changes through an approved pipeline.

The strong answer makes environment creation boring and reviewable.

== Hands-On Lab
<hands-on-lab>
Objective:

Create a simple infrastructure-as-code preview for an Azure resource
using either Bicep or Terraform.

Prerequisites:

- Azure CLI installed if using Bicep.
- Terraform installed if using Terraform.
- A development Azure subscription or sandbox if you plan to apply
  changes.
- No production environment.

Steps:

+ Create a folder:

  ```bash
  mkdir chapter17-iac
  cd chapter17-iac
  ```

+ For Bicep, create `main.bicep` with a storage account resource.

+ Build the Bicep file:

  ```bash
  az bicep build --file main.bicep
  ```

+ Preview the deployment:

  ```bash
  az deployment group what-if \
    --resource-group rg-chapter17-dev \
    --template-file main.bicep
  ```

+ For Terraform, create `main.tf` with a resource group.

+ Initialize and validate:

  ```bash
  terraform init
  terraform fmt
  terraform validate
  ```

+ Create a plan:

  ```bash
  terraform plan
  ```

+ Do not apply to a shared or production environment.

Expected results:

- You can explain what resource the file describes.
- You can run a validation or preview command.
- You can describe what would change before applying it.
- You can explain where secrets and environment-specific values should
  not go.

Validation commands:

```bash
az bicep build --file main.bicep
az deployment group what-if --resource-group rg-chapter17-dev --template-file main.bicep
terraform init
terraform fmt
terraform validate
terraform plan
```

Troubleshooting notes:

- If Azure CLI is not logged in, run `az login`.
- If the resource group does not exist, create a sandbox group or keep
  the lab conceptual.
- If Terraform cannot authenticate, configure the provider for your
  cloud account.
- If a plan wants to destroy a resource you care about, stop.

== Knowledge Check
<knowledge-check>
+ Why did infrastructure become code?
+ What is the difference between declarative and imperative automation?
+ Why is Terraform state sensitive?
+ How does Bicep differ from Terraform?
+ What does a plan or what-if operation provide?
+ Why should production infrastructure changes go through a pipeline?
+ What causes drift?
+ Why should secrets not be stored in IaC files?
+ When is Terraform a better fit than Bicep?
+ When is Bicep a better fit than Terraform?

== Summary
<summary>
Infrastructure as code makes environments repeatable, reviewable, and
automatable. It turns cloud resources, networks, identities, databases,
storage, and monitoring into versioned definitions instead of portal
memory and handwritten setup notes.

Terraform is a general-purpose IaC tool that manages many providers and
tracks resources through state. Bicep is an Azure-native declarative
language that deploys through Azure Resource Manager without a
Terraform-style state file. Both support reusable modules, parameters,
previews, and pipeline-driven deployment.

The important habit is caution with power. IaC can reliably create
resources, but it can also reliably delete or misconfigure them. Plans,
what-if previews, protected state, least-privilege identities, secrets
management, approvals, and production review are part of responsible
IaC.

The next chapter introduces Kubernetes, another desired-state system
where declarative configuration describes how containerized workloads
should run.

== Sources
<sources>
- #link("https://developer.hashicorp.com/terraform/intro")[What is Terraform?]
- #link("https://developer.hashicorp.com/terraform/language")[Terraform language documentation]
- #link("https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/")[Bicep documentation]
- #link("https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview")[Azure Resource Manager templates overview]
- #link("https://learn.microsoft.com/en-us/azure/developer/iac/")[Get started with Infrastructure as Code on Azure]
- #link("https://learn.microsoft.com/en-us/azure/developer/terraform/get-started/comparing-terraform-and-bicep")[Comparing Terraform and Bicep]
- #link("https://learn.microsoft.com/en-us/azure/templates/")[Azure resource reference for Bicep, ARM templates, and Terraform AzAPI]

== Further Reading
<further-reading>
- #link("https://developer.hashicorp.com/terraform/tutorials")[Terraform tutorials]
- #link("https://registry.terraform.io/")[Terraform Registry]
- #link("https://learn.microsoft.com/en-us/training/paths/fundamentals-bicep/")[Deploy and manage resources in Azure by using Bicep]
- #link("https://azure.github.io/Azure-Verified-Modules/")[Azure Verified Modules]
- #link("https://opentofu.org/docs/")[OpenTofu documentation]
