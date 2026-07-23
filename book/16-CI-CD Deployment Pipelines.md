# CI/CD Deployment Pipelines

## Chapter Purpose

Chapter 8 introduced automated testing and CI basics: restore, build, test,
and report status before merge. Chapter 16 extends that idea from validation
to delivery.

Deployment pipelines exist because production releases are too important to
depend on memory, heroics, or one person's deployment script. A professional
team needs to know which commit was built, which tests passed, which artifact
was produced, which environment received it, who approved it, what changed,
and how to roll back if it fails.

If your earlier deployment model involved a build server, a release manager,
manual copy steps, scheduled outage windows, and a checklist, the goal will
feel familiar. The modern difference is that more of the release path is
versioned, automated, observable, and attached to the same source-control
workflow used by developers.

This chapter covers continuous deployment, release pipelines, Azure DevOps,
container publishing, environment promotion, deployment approvals, and rollback
strategies. It focuses on safely moving validated changes into production
environments. It does not replace Chapter 17's infrastructure as code or
Chapter 18's Kubernetes deployment model.

## Where This Fits

A deployment pipeline connects CI output to runtime environments.

```text
Pull request
    |
    v
CI: restore, build, test
    |
    v
Merge to main
    |
    v
Build deployable artifact
    |
    +-- publish folder
    +-- package
    +-- container image
    |
    v
Deploy to development or test
    |
    v
Promote to staging
    |
    v
Approval and release checks
    |
    v
Deploy to production
    |
    v
Monitor, verify, and roll back if needed
```

This chapter follows distributed applications because once a system includes
APIs, workers, caches, queues, databases, and cloud resources, release safety
becomes more important. A pipeline is not just a convenience. It is the system
that coordinates change.

The most important distinction is:

```text
CI proves the change can be built and tested.
CD moves a validated artifact through environments.
Release management controls when and how production changes happen.
```

## Connection to the Reader's Existing Model

Older enterprise release processes often had real discipline.

There might have been a build number, a release candidate, a QA signoff,
change advisory board approval, a deployment window, a rollback plan, and
post-release verification. Those controls existed because production mattered.

Modern pipelines do not remove that discipline. They try to make it
repeatable.

A release pipeline maps to a scripted version of the deployment checklist. It
defines steps such as downloading an artifact, applying configuration,
deploying to an environment, running smoke tests, and recording the result.

An environment maps to a named deployment target such as development, test,
staging, or production. GitHub Actions and Azure Pipelines both support
environment concepts with approvals, secrets, and deployment history.

A deployment approval maps to a human signoff or change-control step. The
difference is that the approval is attached to the pipeline run and can
control access to environment secrets.

A container registry maps to a package feed for runtime images. Instead of
publishing only DLLs or zip files, the pipeline can publish a tagged image.

A rollback maps to restoring the previous known-good release. The modern
expectation is that rollback should be practiced, documented, and tied to
identifiable artifacts.

The analogy breaks down when a pipeline is treated as a magic release machine.
If the pipeline deploys unreviewed schema changes, hides manual steps, lacks
health checks, or cannot roll back, it has automated risk rather than reduced
it.

## Layer 1 — Conceptual Model

A deployment pipeline is an automated path that moves a known software
artifact through one or more environments under controlled rules.

It solves these problems:

- making releases repeatable;
- tying deployments to commits and artifacts;
- reducing manual variation;
- controlling access to environment secrets;
- requiring approvals for sensitive environments;
- promoting the same artifact through stages;
- publishing container images;
- making rollback possible and traceable.

It does not solve these problems automatically:

- it does not make tests useful;
- it does not make database migrations safe;
- it does not choose the right deployment strategy;
- it does not replace production observability;
- it does not guarantee zero downtime;
- it does not fix bad architecture.

The conceptual model is:

```text
Source commit -> build -> artifact -> environment -> verification -> promotion
```

The strongest pipeline habit is build once, promote many times. Build the
artifact once from a known commit. Move that artifact through test, staging,
and production with environment-specific configuration supplied by the
environment, not by rebuilding different binaries.

## Layer 2 — System Relationships

The repository owns source code, workflow definitions, Dockerfiles, scripts,
and sometimes deployment manifests.

The CI system owns validation. It restores packages, builds, runs tests, and
publishes a build result.

The artifact store owns deployable output. This might be a pipeline artifact,
NuGet package feed, zip package, container registry, or cloud deployment
package.

The container registry owns container images. GitHub Container Registry,
Azure Container Registry, Docker Hub, Amazon ECR, and Google Artifact Registry
are common examples.

The environment owns deployment configuration: URLs, app settings, secret
references, deployment protections, approvals, and resource identity.

The deployment job owns change execution. It takes an artifact and applies it
to a target environment.

The approval system owns human or automated gates. GitHub environments can use
required reviewers, wait timers, branch restrictions, environment secrets, and
custom protection rules. Azure Pipelines environments can use approvals and
checks controlled by resource owners.

The monitoring system owns release verification. It tells the team whether
health, error rate, latency, and business indicators look acceptable after
deployment.

Failure boundaries include missing secrets, wrong environment, deploying the
wrong artifact, mutable tags, skipped approvals, pipeline credential leaks,
stuck deployments, failed database migrations, unavailable targets, partial
deployments, and rollback plans that were never tested.

## Layer 3 — Core Mechanics

A minimal deployment pipeline has stages.

```text
Build
  restore, build, test, publish artifact

Package
  create zip package or container image

Deploy test
  deploy artifact to a nonproduction environment

Approve production
  require human or automated checks

Deploy production
  deploy the same artifact

Verify
  run smoke checks and observe health
```

A simple GitHub Actions workflow can build and publish a container image:

```yaml
name: publish-container

on:
  push:
    branches: [ "main" ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v6

      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

The important detail is the tag. A commit SHA tag identifies the image better
than `latest`.

A deployment job can reference an environment:

```yaml
jobs:
  deploy-production:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Deploy the previously built artifact"
```

In GitHub Actions, environment protection rules can require approval before
the job proceeds. Environment secrets are not available to the job until
protection rules pass.

Azure Pipelines uses stages and environments:

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildAndTest
    steps:
    - script: dotnet build --configuration Release
    - script: dotnet test --configuration Release

- stage: DeployProduction
  dependsOn: Build
  jobs:
  - deployment: Deploy
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo Deploy artifact
```

In Azure DevOps, approvals and checks can be configured on environments and
other protected resources outside the YAML file. That separation matters:
someone who edits the pipeline YAML should not automatically be able to remove
production approval rules.

## Layer 4 — Developer Workflow

A developer-friendly deployment workflow begins before production.

Build locally:

```bash
dotnet restore
dotnet build -c Release
dotnet test -c Release
```

Build an image locally:

```bash
docker build -t orders-api:local .
```

Tag with a meaningful version for experiments:

```bash
docker tag orders-api:local orders-api:dev-$(git rev-parse --short HEAD)
```

In the pipeline, produce an artifact from the merge commit:

```text
main branch commit
    |
    v
Release artifact: orders-api:<commit-sha>
```

Promote through environments:

```text
development -> test -> staging -> production
```

At each environment, verify:

```text
Did deployment finish?
Is the app healthy?
Do smoke tests pass?
Are error rates normal?
Did database migration complete?
Is rollback still possible?
```

A pull request should not deploy to production. It may deploy a preview
environment or run integration tests. Production deployment should be tied to
merge, tag, release, or a deliberate manual workflow.

The developer's responsibility is not to memorize every CI/CD product. It is
to understand the release path well enough to diagnose when the pipeline fails
and to design changes that can move safely through it.

## Layer 5 — Production Usage

Production pipelines are security-sensitive systems.

Configuration should be environment-scoped. Development, test, staging, and
production should have separate settings. A pipeline should not copy local
configuration files into production.

Secrets should live in CI/CD secret stores, environment secrets, cloud secret
stores, or federated identity. Prefer short-lived credentials and managed
identity patterns when the platform supports them. Avoid long-lived
credentials stored in repository variables.

Security includes least-privilege pipeline identities, protected branches,
required reviews, environment approvals, audit trails, artifact integrity,
secret masking, dependency scanning, and careful use of third-party actions or
extensions.

Reliability depends on deterministic builds, reusable deployment scripts,
health checks, smoke tests, rollback, and protection against simultaneous
deployments. GitHub Actions concurrency groups and Azure environment locks can
help prevent overlapping deployments.

Deployment should use identifiable artifacts. For containers, prefer immutable
tags or digests. For zip or folder artifacts, keep build IDs, commit SHAs, and
checksums.

Observability should be wired into release verification. A pipeline can deploy
successfully while the application fails after startup. Health, logs, metrics,
and alerts complete the release signal.

Scaling affects deployment strategy. A single instance can be replaced
directly. Multiple instances may need rolling deployment, blue/green, canary,
or traffic-splitting strategies.

Persistence affects release safety. Database migrations are often the hardest
part of rollback. Use backward-compatible schema changes where possible and
avoid coupling rollback to destructive data changes.

Cost includes build minutes, hosted runners, self-hosted runner maintenance,
artifact storage, container registry storage, preview environments, and idle
deployment targets.

Local development optimizes for fast iteration. Production pipelines optimize
for traceability, controlled access, repeatability, verification, and recovery.

## Layer 6 — Tradeoffs and Alternatives

Use GitHub Actions when the repository and team collaboration already live in
GitHub, especially when pull requests, environment protection, packages, and
deployment history should stay close to the code.

Use Azure DevOps when the organization already uses Azure Boards, Azure Repos,
Azure Pipelines, release approvals, service connections, and enterprise
governance around Azure DevOps.

Use GitLab CI, Jenkins, TeamCity, CircleCI, Buildkite, Octopus Deploy, Argo CD,
Flux, or Spinnaker when the organization's platform, compliance, deployment
model, or existing skills fit those tools better.

Continuous deployment to production is appropriate when tests, observability,
rollback, and team maturity are strong. Continuous delivery with manual
production approval is often better for regulated systems, early teams, or
high-risk workloads.

Blue/green deployment reduces risk by running two environments and switching
traffic. Canary deployment reduces risk by sending a small percentage of
traffic to the new version first. Rolling deployment updates instances in
groups. Direct replacement is simpler but riskier.

Common overengineering mistakes:

- building an elaborate pipeline before the deployment steps are understood;
- approving deployments without looking at what changed;
- rebuilding separately for each environment;
- using mutable production tags such as `latest`;
- storing production credentials as broad repository secrets;
- automating database migrations with no review;
- having no rollback beyond "redeploy and hope";
- making pipelines so slow that developers bypass them.

The state-of-the-art direction is secure, traceable, artifact-based delivery:
short-lived credentials, protected environments, provenance and attestations,
container scanning, policy gates, deployment health verification, and rollback
paths that are tested before crisis.

## Layer 7 — Interview Perspective

Interviewers use CI/CD questions to test whether you understand release risk.

Concepts commonly tested:

- CI versus CD;
- build artifacts;
- environment promotion;
- deployment approvals;
- environment secrets;
- container image tags;
- branch protection;
- rollback;
- blue/green and canary deployment;
- database migration safety.

Representative questions:

- "What is the difference between continuous integration and continuous
  deployment?"
- "Why build once and promote the same artifact?"
- "How should production secrets be handled in a pipeline?"
- "What is an environment approval?"
- "Why avoid `latest` tags in production?"
- "How would you roll back a bad release?"
- "How do database changes affect deployment strategy?"
- "What should a deployment pipeline verify after release?"

A strong answer connects automation to control:

> "The pipeline should build and test once, produce a known artifact, deploy
> that artifact through environments, require approval for production, and
> verify health after deployment. Rollback should use a previous known-good
> artifact, but database migrations may require a separate compatibility plan."

Common misconceptions:

- "CI/CD means every commit must go straight to production."
- "A successful deployment job means the app is healthy."
- "Approvals are anti-DevOps."
- "Secrets are safe if they are hidden in YAML."
- "`latest` is fine if the build just completed."
- "Rollback is always simple."
- "Deployment pipelines replace observability."

Small design scenario:

You have an ASP.NET Core API, SQL Server database, Redis cache, and background
worker. The team currently deploys by copying files and restarting services.

A good pipeline plan would build and test the solution, publish the API and
worker artifacts or container images, tag them with the commit SHA, deploy to
test, run smoke checks, require approval for production, deploy API and worker
in a known order, run compatibility-safe database migrations, monitor health
and queue depth, and define rollback for both code and schema.

The strong answer treats deployment as a system change, not a file copy.

## Hands-On Lab

Objective:

Create a simple deployment-oriented workflow that builds, tests, publishes,
and records a container image tag.

Prerequisites:

- A GitHub repository.
- .NET 10 SDK or another supported SDK.
- Dockerfile from Chapter 10.
- Basic GitHub Actions knowledge from Chapter 8.

Steps:

1. Create `.github/workflows/release.yml`.

2. Add triggers:

   ```yaml
   on:
     push:
       branches: [ "main" ]
     workflow_dispatch:
   ```

3. Add a build job that restores, builds, and tests:

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v6
         - uses: actions/setup-dotnet@v4
           with:
             dotnet-version: "10.0.x"
         - run: dotnet restore
         - run: dotnet build --no-restore --configuration Release
         - run: dotnet test --no-build --configuration Release
   ```

4. Add a package job that builds a container image tagged with the commit SHA.

5. Configure a GitHub environment named `production`.

6. Add required reviewers to the `production` environment.

7. Add a placeholder deployment job that references the environment:

   ```yaml
   deploy-production:
     needs: build
     runs-on: ubuntu-latest
     environment: production
     steps:
       - run: echo "Deploy artifact for ${{ github.sha }}"
   ```

8. Trigger the workflow manually or by merging to `main`.

Expected results:

- The workflow validates the application.
- The workflow has a production deployment job gated by environment rules.
- The deployment step records the commit SHA it would deploy.
- You can explain what real deployment commands would replace the placeholder.

Validation commands:

```bash
dotnet restore
dotnet build -c Release
dotnet test -c Release
docker build -t app:${GITHUB_SHA:-local} .
```

Troubleshooting notes:

- If GitHub Actions cannot find the solution, check the repository root.
- If environment approval does not appear, confirm the job references the
  environment name exactly.
- If secrets are unavailable, remember that environment secrets are available
  only after environment protection rules pass.
- If Docker build fails, confirm the Dockerfile path and build context.

## Knowledge Check

1. How is CI different from CD?
2. Why should the same artifact move through multiple environments?
3. What is an environment in a deployment pipeline?
4. Why should production deployments often require approvals?
5. How do environment secrets reduce risk?
6. Why are immutable image tags or digests safer than `latest`?
7. What should a pipeline verify after deployment?
8. Why are database migrations a rollback risk?
9. When would blue/green or canary deployment be useful?
10. What makes a deployment pipeline auditable?

## Summary

Deployment pipelines turn release practice into a repeatable system. CI proves
that a change can be restored, built, and tested. CD moves a known artifact
through environments with controlled configuration, secrets, approvals,
verification, and rollback.

GitHub Actions and Azure DevOps both support modern deployment workflows.
GitHub uses environments, protection rules, environment secrets, and deployment
reviews. Azure Pipelines uses stages, environments, approvals, checks, service
connections, and protected resources. Other tools can implement the same core
ideas.

The strongest habit is to build once and promote deliberately. Production
deployment should use identifiable artifacts, protected secrets, clear
approval rules, health verification, and a rollback path that accounts for
data as well as code.

The next chapter moves one layer lower: infrastructure as code, where cloud
resources and environment provisioning become versioned artifacts too.

## Sources

- [Deploying with GitHub Actions](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments)
- [Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [Reviewing deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments)
- [Publishing Docker images with GitHub Actions](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images)
- [Define approvals and checks in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops)
- [Deployment control using approvals in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/approvals/approvals?view=azure-devops)

## Further Reading

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions security hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Azure Pipelines documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [Docker build-push-action](https://github.com/docker/build-push-action)
- [Azure Container Registry documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
