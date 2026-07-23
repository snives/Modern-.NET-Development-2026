# Docker

## Chapter Purpose

Chapter 9 introduced Linux as an operating-system environment for modern .NET.
Docker builds directly on that foundation.

Docker exists because teams needed a repeatable way to package and run
applications across machines. Before containers became common, a deployment
often depended on a server's installed runtime, patch level, environment
variables, folders, certificates, native dependencies, and hand-maintained
configuration. "Works on my machine" was not a joke; it was a real boundary.

Docker changed that boundary by packaging an application and its runtime
environment into an image. A container is a running instance of that image.
The same image can run on a developer machine, CI runner, test host, cloud
container service, or Kubernetes cluster, assuming compatible CPU and OS
support.

Docker was not invented for .NET. It became popular first in the broader
Linux, cloud, and open-source world. Modern .NET adapted to that world by
becoming cross-platform, publishing official container images, supporting
container-friendly configuration and logging, and eventually adding SDK
support for publishing container images directly.

This chapter introduces why containers exist, images, containers, volumes,
networks, Dockerfiles, and container registries. Chapter 11 builds on this
with Docker Compose for multi-container development environments.

## Where This Fits

Docker sits between the application build and the runtime host.

```text
.NET source code
      |
      v
dotnet publish
      |
      v
Docker image
      |
      v
Container
      |
      +-- filesystem from image
      +-- environment variables
      +-- exposed port
      +-- mounted volumes when needed
      +-- network connections
      |
      v
Docker host, cloud container service, or Kubernetes
```

Docker does not replace ASP.NET Core, SQL Server, CI/CD, cloud platforms, or
Kubernetes. It provides a packaging and runtime boundary that those systems can
use.

For this book's progression, Docker is the bridge from "I can run the app" to
"I can run the same packaged app consistently in different places."

## Connection to the Reader's Existing Model

The closest Windows-era analogy is a disciplined deployment folder plus a
process boundary.

In an IIS deployment, you might publish an application to a folder, configure
an application pool, set environment-specific configuration, and point IIS at
the result. The server still supplied many assumptions: installed framework,
native dependencies, IIS configuration, machine-level certificates, directory
permissions, and OS patch level.

A Docker image moves more of that runtime assumption into a versioned package.
The image can include the application files, runtime base image, startup
command, working directory, exposed port metadata, and non-root user settings.

A container is not the same as a virtual machine. A VM includes a full guest
operating system. A Linux container is an isolated process using the host's
kernel with separate filesystem, process, network, and resource views. That is
why Chapter 9 matters: a containerized ASP.NET Core app is still a Linux
process.

An image is similar to an immutable deployment artifact. A container is
similar to running that artifact as a process. A registry is similar to a
package feed, but for container images.

Volumes are somewhat like mounted folders or attached disks. They let data
outlive a container or be shared into a container.

Docker networks are somewhat like private virtual networks for containers.
They let containers reach each other by name without exposing every internal
port to the host.

The analogy breaks down when you treat a container like a server you log into
and maintain. Containers are meant to be replaced, not lovingly patched in
place. If the app changes, rebuild the image and run a new container.

## Layer 1 — Conceptual Model

Docker is a platform for developing, shipping, and running applications using
containers.

It solves these problems:

- packaging application runtime dependencies consistently;
- reducing environment drift between developer machines and CI;
- giving applications a clear process and filesystem boundary;
- making local development dependencies easier to run;
- producing artifacts that cloud platforms and orchestrators can run;
- standardizing image distribution through registries.

It does not solve these problems by itself:

- it does not make the application scalable;
- it does not replace tests;
- it does not make secrets safe automatically;
- it does not make the database durable unless storage is designed correctly;
- it does not replace production monitoring;
- it does not remove the need to understand Linux, networking, or security.

The conceptual model is:

```text
Dockerfile describes how to build an image.
Image is the packaged template.
Container is a running instance of the image.
Registry stores and distributes images.
Volume stores data outside the container filesystem.
Network connects containers.
```

Images are immutable in spirit. Containers are disposable in spirit. Data that
must survive should live outside the container or in a real database.

## Layer 2 — System Relationships

The Docker client receives commands such as `docker build`, `docker run`,
`docker ps`, and `docker logs`.

The Docker engine builds images and runs containers. Docker Desktop provides a
developer-friendly environment on Windows and macOS, usually backed by a Linux
virtual machine for Linux containers.

The Dockerfile describes image construction. It identifies a base image,
copies files, runs build steps, sets the working directory, exposes ports, and
defines the startup command.

The base image provides the starting filesystem and runtime dependencies.
Microsoft publishes official .NET SDK, ASP.NET Core runtime, and .NET runtime
images. In .NET 10, Microsoft's default Linux container tags use Ubuntu-based
images instead of the older Debian default.

The application image layers your app on top of the base image. A typical
ASP.NET Core image uses a multi-stage build: one stage uses the SDK to build
and publish, and a smaller runtime stage runs the published app.

The container receives runtime inputs: environment variables, port mappings,
mounted volumes, network connections, CPU and memory limits, and secrets or
configuration supplied by the host.

The registry stores images. Docker Hub, GitHub Container Registry, Azure
Container Registry, Amazon Elastic Container Registry, and Google Artifact
Registry are common examples.

Failure boundaries include wrong base image, wrong CPU architecture, missing
files, bad working directory, incorrect port binding, case-sensitive path
errors, missing environment variables, container exits, permission problems,
unmounted volumes, network name resolution, large images, vulnerable base
images, and secrets baked into image layers.

## Layer 3 — Core Mechanics

A minimal ASP.NET Core Dockerfile often uses multiple stages:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

ENTRYPOINT ["dotnet", "Orders.Api.dll"]
```

The build stage uses the SDK image because it needs build tools. The runtime
stage uses the ASP.NET Core runtime image because it only needs to run the
published app.

Build an image:

```bash
docker build -t orders-api:dev .
```

Run a container:

```bash
docker run --rm -p 8080:8080 orders-api:dev
```

The `-p 8080:8080` option maps host port `8080` to container port `8080`.

Set an environment variable:

```bash
docker run --rm -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  orders-api:dev
```

List containers:

```bash
docker ps
docker ps -a
```

Inspect logs:

```bash
docker logs <container-name-or-id>
```

Stop a container:

```bash
docker stop <container-name-or-id>
```

Create a volume:

```bash
docker volume create orders-data
```

Run with a volume:

```bash
docker run --rm \
  -v orders-data:/data \
  orders-api:dev
```

Create a network:

```bash
docker network create orders-net
```

The modern .NET SDK can also publish container images without a Dockerfile in
some scenarios:

```bash
dotnet publish /t:PublishContainer
```

That is useful, but Dockerfiles remain important because many teams still use
them to express explicit build, runtime, and base-image choices.

## Layer 4 — Developer Workflow

The basic Docker workflow is:

```text
Create or update app
        |
        v
Write Dockerfile
        |
        v
Build image
        |
        v
Run container locally
        |
        v
Inspect logs and behavior
        |
        v
Tag image
        |
        v
Push image to registry
```

Create a sample API:

```bash
dotnet new webapi -n Chapter10.Api
cd Chapter10.Api
```

Add a `.dockerignore` file so build output and local files are not copied into
the image context:

```text
bin/
obj/
.git/
.vs/
.vscode/
```

Add a Dockerfile.

Build:

```bash
docker build -t chapter10-api:dev .
```

Run:

```bash
docker run --rm -p 8080:8080 chapter10-api:dev
```

Call the app:

```bash
curl http://localhost:8080/weatherforecast
```

If the app listens on a different port, align the container's ASP.NET Core URL
setting and the Docker port mapping:

```bash
docker run --rm -p 8080:8080 \
  -e ASPNETCORE_URLS=http://+:8080 \
  chapter10-api:dev
```

Tag for a registry:

```bash
docker tag chapter10-api:dev registry.example.com/chapter10-api:dev
```

Push:

```bash
docker push registry.example.com/chapter10-api:dev
```

You do not need to push images for every local experiment. The key development
habit is to make the runtime environment explicit and repeatable.

## Layer 5 — Production Usage

Production container usage starts with image discipline.

Choose supported base images. For .NET 10, default Microsoft Linux tags use
Ubuntu-based images. If your organization requires a specific distribution,
test it deliberately and maintain custom images when needed.

Configuration should be supplied at runtime, not baked into the image. The
same image should usually run in development, test, staging, and production
with different environment-specific settings.

Secrets should not be copied into images, written into Dockerfiles, or passed
casually on command lines that end up in shell history. Use platform secret
stores, secret mounts, managed identities, or CI/CD secret mechanisms.

Security includes base-image patching, vulnerability scanning, non-root
containers, minimal images, signed images where appropriate, restricted
capabilities, and least-privilege access to registries and runtime platforms.

Reliability depends on predictable startup, clear exit behavior, health
checks, resource limits, graceful shutdown, and logs written to standard
output. A container that silently fails or writes logs only to an internal file
is harder to operate.

Deployment should use immutable image tags or digests. Avoid deploying
whatever `latest` happens to mean at the moment. A production deployment
should identify the exact image it runs.

Observability should treat containers as replaceable. Logs should go to
standard output and standard error. Metrics and traces should flow to the
platform or observability system. Do not depend on logging into a container to
read local files.

Scaling requires stateless application containers. Durable state should live
in databases, managed storage, or carefully designed volumes. Scaling a
containerized API does not scale SQL Server automatically.

Persistence must be explicit. Container writable layers are temporary and tied
to the container. Use volumes for data that must survive container replacement,
but prefer managed databases for business data.

Cost comes from image size, registry storage, network transfer, build minutes,
runtime CPU and memory, vulnerability management, and operational complexity.
Small, well-built images are easier and cheaper to move.

Local development optimizes for repeatability and fast iteration. Production
optimizes for immutable artifacts, security, traceability, and recoverability.

## Layer 6 — Tradeoffs and Alternatives

Use Docker when you need repeatable runtime packaging, consistent local
dependencies, container-based deployment, CI parity, or preparation for cloud
container platforms.

Do not use Docker just because it is modern. A small internal console tool, a
desktop app, or an application deployed cleanly to a managed platform may not
need a custom container image.

Docker competes with direct host installation, virtual machines,
platform-native deployment packages, language-specific packaging, and
serverless deployment models. It is strongest when the runtime environment is
part of the problem.

Podman is an open-source daemonless container alternative and can run OCI
containers. Some organizations prefer it for security or Linux-native
workflows.

.NET SDK container publishing can reduce Dockerfile boilerplate. Dockerfiles
remain useful when the image requires custom OS packages, explicit build
steps, special users, or detailed control.

Kubernetes is not an alternative to Docker in the simple sense. Kubernetes is
an orchestrator for running containers across machines. Docker helps build and
run containers; Kubernetes manages containerized workloads at scale.

Common overengineering mistakes:

- containerizing before the app builds cleanly from the command line;
- baking secrets into images;
- using `latest` for production deployments;
- treating containers like long-lived servers;
- storing business data in the container writable layer;
- running as root because permissions are inconvenient;
- creating huge images by copying the whole repository;
- ignoring base-image updates and vulnerability scans.

The state-of-the-art direction is secure, minimal, traceable images; explicit
runtime configuration; non-root execution; SBOMs and vulnerability scanning;
and simple local workflows that match CI and production where it matters.

## Layer 7 — Interview Perspective

Interviewers use Docker questions to test whether you understand packaging,
runtime boundaries, and tradeoffs.

Concepts commonly tested:

- image versus container;
- Dockerfile;
- layers;
- base images;
- port mapping;
- environment variables;
- volumes;
- networks;
- registries;
- containers versus virtual machines;
- Docker versus Kubernetes.

Representative questions:

- "What problem does Docker solve?"
- "What is the difference between an image and a container?"
- "Why use a multi-stage Dockerfile for .NET?"
- "How does port mapping work?"
- "Where should secrets be provided to a container?"
- "What happens to data written inside a container?"
- "When would Docker be unnecessary?"
- "How is Docker different from Kubernetes?"

A strong answer connects repeatability and boundaries:

> "A Docker image packages the application and runtime environment. A
> container is a running instance of that image. The image helps reduce
> environment drift, but persistent data, secrets, networking, scaling, and
> monitoring still need explicit design."

Common misconceptions:

- "A container is a lightweight virtual machine."
- "Docker makes applications scalable."
- "Docker replaces CI/CD."
- "A container should be patched by logging into it."
- "Volumes are optional for durable data."
- "Kubernetes and Docker are the same layer."
- "If it runs in Docker locally, it is production-ready."

Small design scenario:

You have an ASP.NET Core API that runs locally but fails often on test servers
because the runtime version, environment variables, and installed dependencies
differ between machines.

A good Docker plan would define a Dockerfile, use official .NET base images,
set runtime configuration through environment variables, write logs to standard
output, run as a non-root user where possible, tag images with commit-based
versions, and push images to a registry for test deployment.

The strong answer uses Docker to reduce environment drift without pretending
it solves database, security, or deployment design by itself.

## Hands-On Lab

Objective:

Containerize a small ASP.NET Core API and run it locally.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- Docker Desktop or another OCI-compatible container runtime.
- A terminal.

Steps:

1. Create an API:

   ```bash
   dotnet new webapi -n Chapter10.Api
   cd Chapter10.Api
   ```

2. Add `.dockerignore`:

   ```text
   bin/
   obj/
   .git/
   .vs/
   .vscode/
   ```

3. Add a Dockerfile:

   ```dockerfile
   FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
   WORKDIR /src

   COPY *.csproj .
   RUN dotnet restore

   COPY . .
   RUN dotnet publish -c Release -o /app/publish

   FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
   WORKDIR /app

   COPY --from=build /app/publish .

   EXPOSE 8080

   ENTRYPOINT ["dotnet", "Chapter10.Api.dll"]
   ```

4. Build the image:

   ```bash
   docker build -t chapter10-api:dev .
   ```

5. Run the container:

   ```bash
   docker run --rm -p 8080:8080 \
     -e ASPNETCORE_URLS=http://+:8080 \
     chapter10-api:dev
   ```

6. In another terminal, call the API:

   ```bash
   curl http://localhost:8080/weatherforecast
   ```

7. List running containers:

   ```bash
   docker ps
   ```

8. Stop the container with `Ctrl+C` in the terminal where it is running.

Expected results:

- Docker builds an image.
- Docker runs a container from that image.
- The ASP.NET Core API responds through a mapped host port.
- Logs appear in the container's console output.

Validation commands:

```bash
docker build -t chapter10-api:dev .
docker run --rm -p 8080:8080 -e ASPNETCORE_URLS=http://+:8080 chapter10-api:dev
docker ps
curl http://localhost:8080/weatherforecast
```

Troubleshooting notes:

- If Docker cannot find the Dockerfile, run the command from the project
  directory.
- If the app does not respond, confirm the port mapping and
  `ASPNETCORE_URLS`.
- If the endpoint path differs, use the route created by the template.
- If restore fails during build, check network access and NuGet package
  sources.
- If the container exits immediately, inspect the console output or run
  `docker logs` with the container ID.

## Knowledge Check

1. Why did containers become important for modern application delivery?
2. What is the difference between a Docker image and a container?
3. Why is a container not the same as a full virtual machine?
4. What problem does a Dockerfile solve?
5. Why are multi-stage Dockerfiles useful for .NET applications?
6. What does port mapping do?
7. Why should secrets not be baked into images?
8. What happens to data written only to a container's writable layer?
9. What role does a registry play?
10. Why does Docker not automatically make an application production-ready?

## Summary

Docker gives modern .NET teams a repeatable packaging and runtime boundary.
An image is the packaged template. A container is a running instance. A
Dockerfile describes how the image is built. Volumes provide storage outside
the container filesystem. Networks connect containers. Registries store and
distribute images.

For a Windows developer, Docker is best understood as a disciplined deployment
artifact plus a Linux process boundary, not as a small VM. The app still needs
configuration, secrets, logging, health, persistence, and security decisions.

The next chapter adds Docker Compose, which lets a team run an ASP.NET Core
API, SQL Server, Redis, and other development dependencies together as a
multi-container environment.

## Sources

- [What is Docker?](https://docs.docker.com/get-started/docker-overview/)
- [Containerize a .NET application](https://docs.docker.com/guides/dotnet/containerize/)
- [.NET language-specific guide for Docker](https://docs.docker.com/guides/dotnet/)
- [Containerize an app with Docker tutorial](https://learn.microsoft.com/en-us/dotnet/core/docker/build-container)
- [Containerize an app with dotnet publish](https://learn.microsoft.com/en-us/dotnet/core/containers/sdk-publish)
- [Run an ASP.NET Core app in Docker containers](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/building-net-docker-images?view=aspnetcore-10.0)
- [Default .NET images use Ubuntu](https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/10.0/default-images-use-ubuntu)

## Further Reading

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker storage overview](https://docs.docker.com/engine/storage/)
- [Docker networking overview](https://docs.docker.com/engine/network/)
- [.NET container images](https://learn.microsoft.com/en-us/dotnet/core/docker/container-images)
