= Modern \.NET
<modern-.net>
== Chapter Purpose
<chapter-purpose>
The first three chapters established the modern \.NET landscape, the
technology stack, and the development workflow. This chapter moves into
the platform at the center of that system: modern \.NET itself.

For an experienced developer returning from the \.NET 5 era, the
important shift is not that C\# suddenly became unfamiliar. The shift is
that \.NET is now a fast-moving, cross-platform, SDK-driven platform
with a regular support cadence, simpler project files, stronger
command-line workflows, first-class container and cloud integration, and
ongoing language evolution.

Modern \.NET exists because the old \.NET world had reached a boundary.
\.NET Framework was powerful and deeply integrated with Windows, IIS,
Visual Studio, and enterprise infrastructure, but that same integration
made it hard to move at cloud speed. The industry was moving toward open
source, Linux servers, containers, command-line automation,
microservice-friendly runtimes, and frequent platform updates. Java,
Node.js, Go, Python, and other ecosystems had already made
cross-platform server development feel ordinary.

\.NET Core began as Microsoft's answer to that reality: a modular,
cross-platform, open-source version of \.NET. \.NET 5 unified the
branding around "one \.NET" for modern workloads. By 2026, modern \.NET
is no longer a side path. It is the main \.NET line.

This chapter explains modern \.NET versions, SDKs, project structure,
cross-platform development, and language improvements. It gives enough
practical mechanics to orient you without turning into a full API
reference.

== Where This Fits
<where-this-fits>
Modern \.NET is the application platform layer underneath the rest of
the book.

```text
Developer workflow
  |
  v
.NET SDK and project system
  |
  v
C# source code, project files, NuGet packages
  |
  v
Build, test, publish
  |
  v
Runtime process
  |
  +-- ASP.NET Core
  +-- worker services
  +-- console tools
  +-- libraries
  |
  v
Windows, Linux, containers, cloud platforms
```

Chapter 5 builds on this foundation with ASP.NET Core. Chapter 6 applies
it to data access. Chapter 8 uses it for automated testing and CI.
Chapters 9-13 use it across Linux, Docker, deployment, and cloud
hosting.

The key point: modern \.NET is both a runtime and a development
platform. The runtime runs applications. The SDK builds, tests,
publishes, packages, and tools them. The project system describes how
source code becomes output.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
You already understand \.NET as a managed platform: C\# compiles to
assemblies, the runtime executes managed code, libraries provide
reusable APIs, and project files describe how the application is built.

That model still works, but several boundaries have moved.

In \.NET Framework, the installed framework felt like part of the
Windows machine. Applications targeted a framework version that was
installed on the server. Visual Studio was often the center of build and
publish behavior. Project files were verbose. IIS was the natural web
host. Windows was assumed.

In modern \.NET, the SDK is the center of development. The command line
can create, build, test, run, publish, and package applications. Visual
Studio, Visual Studio Code, Rider, GitHub Actions, Azure Pipelines,
Docker builds, and cloud development environments all use the same
underlying project and SDK model.

The modern project file is much smaller because SDK-style projects infer
many defaults. A project file no longer needs to list every source file
by default. NuGet package references are first-class. Target frameworks
are explicit.

Side-by-side installation is normal. A machine can have several SDKs and
runtimes installed. A repository can use `global.json` to select the SDK
range used by command-line builds. This is very different from thinking
of the server as having one blessed framework personality.

Cross-platform hosting is normal. A \.NET application may be developed
on Windows, built on Linux, tested in CI, packaged into a container, and
deployed to a managed cloud environment. That does not mean Windows is
obsolete. It means Windows is one supported environment rather than the
assumption under every layer.

The IIS analogy remains useful for understanding process hosting, ports,
configuration, and deployment. It breaks down when you assume IIS owns
the application lifecycle. In modern \.NET, an ASP.NET Core application
is itself a process. IIS may reverse proxy to it, but so may Nginx, a
cloud load balancer, a container platform, or a local development
server.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Modern \.NET is the current, cross-platform \.NET implementation for
building applications, services, libraries, tools, cloud workloads,
desktop apps, mobile apps, games, and AI-enabled systems.

It solves several problems:

- it provides a common managed runtime for C\# and other \.NET
  languages;
- it supports cross-platform development and hosting;
- it supplies a consistent SDK and command-line workflow;
- it uses a simpler project format;
- it supports side-by-side versions and regular releases;
- it integrates naturally with packages, tests, containers, cloud
  platforms, telemetry, and modern tooling.

It does not solve every application concern:

- it does not choose your architecture;
- it does not make your code maintainable automatically;
- it does not remove the need to understand deployment;
- it does not replace SQL Server, Redis, or cloud platforms;
- it does not guarantee cross-platform behavior if your code uses
  platform-specific APIs;
- it does not make every old \.NET Framework application portable
  without work.

The conceptual center is this:

```text
SDK describes how to build.
Project file describes what to build.
Target framework describes which APIs are available.
Runtime executes the built application.
```

Once that model is clear, most modern \.NET mechanics become easier to
place.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
Modern \.NET interacts with the rest of the system through a few
important relationships.

The SDK receives project files, source files, package references, target
frameworks, analyzers, tool manifests, and build properties. It outputs
compiled assemblies, test results, NuGet packages, publish folders,
container images in some scenarios, and diagnostic information.

The runtime receives compiled assemblies, dependencies, configuration,
command line arguments, environment variables, and operating-system
services. It outputs process behavior: HTTP responses, console output,
logs, files, network calls, database calls, and exit codes.

The project file owns build intent. It tells the SDK which project SDK
to use, which target framework to compile against, which packages to
reference, and which build options matter. In SDK-style projects, many
conventions are implicit, which keeps the file small but makes it
important to understand the defaults.

NuGet owns package distribution. A modern \.NET project usually depends
on NuGet packages from nuget.org, private feeds, or local package
sources. Package restore is therefore part of build reliability and
supply-chain security.

The operating system owns process execution, files, environment
variables, networking, certificates, native dependencies, and
permissions. If an application uses only cross-platform \.NET APIs, it
can often run on Windows, Linux, and macOS. If it depends on
Windows-specific APIs, COM components, registry behavior, GDI, or old
framework libraries, portability becomes a design constraint.

The CI system owns clean reproducibility. It uses the SDK to restore,
build, test, and publish without relying on a developer's machine. If
the build works only inside one person's IDE, the project is not yet
modern in workflow terms.

The deployment platform owns runtime placement. It may run the app as a
Windows service, IIS-hosted process, Linux systemd service, container,
managed app service, serverless function, or orchestrated workload.
\.NET supports many of these targets, but each target changes
configuration and operations.

Failure boundaries include mismatched SDK versions, unsupported target
frameworks, missing runtimes, package restore failures,
platform-specific code, native dependency issues, incorrect runtime
identifiers, broken publish settings, and assuming local development
behavior will match production.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
The modern \.NET mechanics begin with versions.

Microsoft ships major \.NET releases annually. Releases alternate
between Long Term Support (LTS) and Standard Term Support (STS). As of
July 22, 2026, Microsoft lists \.NET 10 as an LTS release supported
until November 2028, \.NET 9 as an STS release supported until November
2026, and \.NET 8 as an LTS release supported until November 2026.

That version choice matters. For production enterprise applications, an
LTS release is often the conservative default. An STS release may be
useful when a team wants newer platform capabilities and accepts a
faster upgrade rhythm.

The next mechanic is the distinction between SDK and runtime.

The runtime runs \.NET applications. The SDK creates and builds them. A
server may need only the runtime if it runs framework-dependent
applications. A developer machine and CI agent need the SDK.

The target framework tells the compiler which API surface the project
uses. For modern \.NET, this appears as a target framework moniker:

```xml
<TargetFramework>net10.0</TargetFramework>
```

A library can target multiple frameworks when it needs to support more
than one consumer:

```xml
<TargetFrameworks>net8.0;net10.0</TargetFrameworks>
```

Multi-targeting is useful for libraries. It is usually unnecessary for a
simple application where the team controls the runtime environment.

The project SDK appears at the top of an SDK-style project file:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
```

For a web application, the project uses the web SDK:

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

`ImplicitUsings` reduces repetitive `using` directives for common
namespaces. `Nullable` enables nullable reference type analysis, which
helps identify possible null-related bugs at compile time. If you are
returning from older C\# habits, nullable reference types are one of the
most important language-era changes to take seriously.

Runtime identifiers, or RIDs, identify target platforms such as
`win-x64`, `linux-x64`, and `osx-arm64`. They matter when publishing for
a specific platform or using packages with native assets.

`global.json` can select the SDK version used by CLI commands in a
repository:

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestFeature"
  }
}
```

This does not choose the runtime your project targets. The target
framework does that. `global.json` chooses the SDK used to build.

C\# evolves with \.NET. As of \.NET 10, C\# 14 is the latest C\#
release. It includes features such as extension members,
null-conditional assignment, `field` backed properties, improved
`Span<T>` conversions, and file-based app support. You do not need to
memorize every new feature immediately. The important production habit
is to distinguish language convenience from design clarity.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
The modern \.NET workflow is SDK-first. You can still use Visual Studio,
and many enterprise developers should, but the project should also
behave predictably from the command line.

Check your environment:

```bash
dotnet --info
dotnet --list-sdks
dotnet --list-runtimes
```

Create a console application:

```bash
dotnet new console -n ModernDotnetDemo
cd ModernDotnetDemo
dotnet run
```

Inspect the project file:

```bash
cat ModernDotnetDemo.csproj
```

On Windows PowerShell:

```powershell
Get-Content .\ModernDotnetDemo.csproj
```

Build and run:

```bash
dotnet build
dotnet run
```

Create a solution and add the project:

```bash
cd ..
dotnet new sln -n ModernDotnetDemo
dotnet sln ModernDotnetDemo.sln add ModernDotnetDemo/ModernDotnetDemo.csproj
```

Create a local tool manifest when a repository needs repeatable local
tools:

```bash
dotnet new tool-manifest
dotnet tool restore
```

Local tools matter because they let a repository define tool
dependencies without requiring every developer to install the same
global tool manually. Examples later in the book may include formatters,
EF Core tools, or other project-specific commands.

Create a `global.json` when a repository needs predictable SDK
selection:

```bash
dotnet new globaljson --sdk-version 10.0.100 --roll-forward latestFeature
```

The exact SDK version should match the version your team supports. In
CI, being explicit avoids surprising builds when an agent image updates.

Publish the application:

```bash
dotnet publish -c Release
```

This produces output that can be run on a machine with an appropriate
runtime or packaged into a deployment artifact. Later chapters cover
ASP.NET Core, containers, and deployment in detail.

The workflow principle is simple: the same basic commands should work
locally, in CI, and in deployment automation.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production \.NET usage starts with support.

Choose a supported \.NET version. For most enterprise production
applications, that usually means choosing an LTS version unless a
specific STS feature justifies the shorter support window. Keep
applications patched with servicing updates because Microsoft support
expects supported releases to be on supported servicing levels.

Separate SDK concerns from runtime concerns. Build agents need SDKs.
Runtime hosts may need only runtimes, or no preinstalled runtime if you
publish self-contained or run in a container image that includes the
runtime. Do not assume the production machine has the same SDKs as a
developer workstation.

Configuration belongs outside the compiled application. Modern \.NET
supports configuration from JSON files, environment variables,
command-line arguments, secret stores, and platform providers. Local
development can use local settings. Production should use mechanisms
appropriate to the host platform.

Secrets should not be committed to source control. User secrets can be
useful for local development. Production secrets should come from
managed secret stores, environment injection, platform identity, or
deployment systems.

Reliability depends on predictable builds and repeatable publishes. A
production artifact should be identifiable. You should know which
commit, target framework, SDK, package versions, and deployment settings
produced it.

Observability starts in the application. Even before advanced telemetry,
modern \.NET applications should emit meaningful logs and expose health
where appropriate. ASP.NET Core expands on this in the next chapter.

Cross-platform production requires discipline. File paths, case
sensitivity, line endings, certificates, native libraries, time zones,
globalization, process signals, and filesystem permissions can differ
between Windows and Linux. Code that assumes Windows behavior may
compile but still fail when hosted elsewhere.

Cost enters through runtime choices. Self-contained deployments can be
larger. Containers introduce base-image and registry management. Cloud
hosts charge for compute, memory, storage, networking, and sometimes
build minutes. Newer features such as Native AOT can reduce startup time
and footprint in some workloads, but they also introduce compatibility
and diagnostic tradeoffs.

Local development optimizes for speed and convenience. Production
optimizes for supportability, security, repeatability, and clear
ownership.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Modern \.NET is a strong choice when a team values C\#, mature tooling,
enterprise libraries, high-performance server workloads, Microsoft
ecosystem integration, and cross-platform deployment.

It competes with Java, Go, Node.js, Python, Rust, Kotlin, Ruby, PHP, and
other ecosystems. Java remains a major enterprise platform with Spring.
Go is common for small, fast cloud-native services and infrastructure
tooling. Node.js is natural for JavaScript-centered teams. Python
dominates many data and automation workflows. Rust is compelling when
memory safety and systems-level control matter. Modern \.NET's advantage
is the combination of C\#, runtime performance, enterprise fit, tooling,
and platform breadth.

Use modern \.NET for new \.NET applications unless you have a specific
reason not to. Use \.NET Framework only when the application depends on
technologies that require it, such as some legacy ASP.NET, WCF server
scenarios, Windows-specific desktop dependencies, or older third-party
libraries that cannot move.

Choose LTS for conservative production systems. Choose STS only when the
team has an explicit upgrade plan and wants newer features sooner.

Use SDK-style projects for modern projects. Avoid manually expanding
project files into old-style file lists unless a special build
requirement demands it.

Use multi-targeting for reusable libraries that must support multiple
consumers. Avoid multi-targeting applications without a clear reason; it
increases testing and support work.

Use self-contained deployment when you need to carry the runtime with
the app. Use framework-dependent deployment when the host environment
manages the runtime. Use containers when repeatable packaging and
runtime environment consistency matter.

Use Native AOT selectively. It can improve startup time and deployment
size for some workloads, especially small services and command-line
tools, but it can limit reflection-heavy libraries and change
diagnostics.

Common overengineering mistakes:

- upgrading target frameworks without checking package and hosting
  support;
- treating every new C\# feature as a reason to rewrite old code;
- multi-targeting applications unnecessarily;
- pinning SDK versions so tightly that servicing becomes painful;
- ignoring nullable warnings because the project still compiles;
- assuming cross-platform means every API behaves identically
  everywhere;
- choosing self-contained, containerized, trimmed, and AOT deployment
  all at once before understanding the tradeoffs.

The state-of-the-art direction in modern \.NET is pragmatic platform
breadth: fast runtime, minimal hosting, container support, cloud
integration, better diagnostics, optional Native AOT, strong language
evolution, and AI-friendly libraries. The skill is knowing which
capabilities the application actually needs.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use modern \.NET questions to test whether you understand
the platform model, not just C\# syntax.

Concepts commonly tested:

- \.NET Framework versus \.NET Core versus modern \.NET;
- LTS versus STS releases;
- SDK versus runtime;
- target frameworks and target framework monikers;
- SDK-style project files;
- NuGet package references;
- `global.json`\;
- framework-dependent versus self-contained deployment;
- cross-platform hosting;
- nullable reference types;
- when to use newer language features.

Representative questions:

- "What changed between \.NET Framework and modern \.NET?"
- "What is the difference between the \.NET SDK and the runtime?"
- "Why would a project use `global.json`?"
- "What does `net10.0` mean?"
- "When would you choose an LTS release?"
- "What makes SDK-style project files different from older project
  files?"
- "What should you check before running a \.NET application on Linux?"
- "When would self-contained deployment be useful?"

A strong answer connects versioning, build, and runtime:

#quote(block: true)[
"The target framework controls which APIs the project compiles against.
The SDK builds the project, and `global.json` can influence which SDK is
selected for CLI commands. The runtime is what actually executes the
application. In production, those choices affect support, deployment
size, patching, and compatibility."
]

Common misconceptions:

- "\.NET is just a renamed \.NET Framework."
- "The SDK and runtime are the same thing."
- "`global.json` chooses the target framework."
- "If it compiles on Windows, it is automatically Linux-ready."
- "LTS means the application never needs patching."
- "New C\# syntax is always a net improvement."
- "Self-contained deployment is always better."

Small design scenario:

You inherit a \.NET 5 internal API. It builds only in Visual Studio, has
no `global.json`, targets an out-of-support framework, and is deployed
manually to a Windows server.

A good modernization plan would:

- move to a supported LTS target framework;
- verify package compatibility;
- make the build work through `dotnet build`\;
- add or update `global.json` if the team needs SDK predictability;
- enable nullable analysis thoughtfully if it is not already enabled;
- define a repeatable publish command;
- confirm whether the app has Windows-specific assumptions;
- defer containers, cloud migration, and advanced deployment until the
  platform baseline is healthy.

The strong answer upgrades the foundation before changing the hosting
model.

== Hands-On Lab
<hands-on-lab>
Objective:

Create a small modern \.NET console application and inspect the
SDK-style project model.

Prerequisites:

- \.NET 10 SDK installed, or another currently supported \.NET SDK.
- A terminal.
- A text editor or IDE.

Steps:

+ Create a working folder:

  ```bash
  mkdir ModernDotnetLab
  cd ModernDotnetLab
  ```

+ Check installed SDKs and runtimes:

  ```bash
  dotnet --info
  dotnet --list-sdks
  dotnet --list-runtimes
  ```

+ Create a console app:

  ```bash
  dotnet new console -n HelloModernDotnet
  cd HelloModernDotnet
  ```

+ Open `HelloModernDotnet.csproj` and identify:

  - the project SDK;
  - the target framework;
  - whether nullable reference types are enabled;
  - whether implicit usings are enabled.

+ Run the app:

  ```bash
  dotnet run
  ```

+ Build in Release configuration:

  ```bash
  dotnet build -c Release
  ```

+ Publish the app:

  ```bash
  dotnet publish -c Release
  ```

+ Create a solution one directory above the project:

  ```bash
  cd ..
  dotnet new sln -n ModernDotnetLab
  dotnet sln ModernDotnetLab.sln add HelloModernDotnet/HelloModernDotnet.csproj
  ```

+ Create a `global.json`:

  ```bash
  dotnet new globaljson --roll-forward latestFeature
  ```

+ Re-run:

  ```bash
  dotnet --info
  ```

Expected results:

- You can identify the SDK and runtime versions installed.
- You can explain the project SDK and target framework in the project
  file.
- You can build, run, and publish from the command line.
- You can explain what `global.json` does and does not control.

Validation commands:

```bash
dotnet --info
dotnet build
dotnet run
dotnet publish -c Release
```

Troubleshooting notes:

- If `dotnet` is not recognized, install the \.NET SDK and reopen the
  terminal.
- If `dotnet new console` targets a different framework than expected,
  inspect which SDK is installed and selected.
- If `global.json` causes an SDK error, the requested SDK may not be
  installed or the roll-forward setting may be too restrictive.
- If publish output is hard to find, inspect the `bin/Release` folder
  under the project.

== Knowledge Check
<knowledge-check>
+ Why did modern \.NET move away from the Windows-centered assumptions
  of \.NET Framework?
+ What is the difference between the \.NET SDK and the \.NET runtime?
+ Why does the target framework matter to both compilation and
  production support?
+ When is an LTS release usually preferable to an STS release?
+ What does an SDK-style project file hide through convention?
+ What does `global.json` control, and what does it not control?
+ Why can cross-platform development still fail when the code compiles?
+ When would multi-targeting be useful?
+ What production tradeoff does self-contained deployment make?
+ Why should nullable reference type warnings be treated as design
  feedback instead of noise?

== Summary
<summary>
Modern \.NET is the main \.NET platform for current professional
development. It grew out of the need for a cross-platform, open-source,
cloud-ready, SDK-driven successor to the Windows-centered \.NET
Framework world.

The central mechanics are straightforward once the layers are separated.
The SDK builds and tools applications. The runtime executes them. The
project file describes build intent. The target framework describes the
API surface. NuGet packages provide dependencies. `global.json` can
select the SDK used by command line builds. Runtime identifiers describe
target platforms when platform- specific publishing or native assets
matter.

Modern \.NET's power is not only newer APIs. It is that the same project
model can participate in local development, command-line builds, CI,
containers, Linux hosting, cloud platforms, and production deployment.

The next chapter builds on this foundation with ASP.NET Core, where
modern \.NET becomes a web and API application platform.

== Sources
<sources>
- Microsoft Learn, "\.NET releases, patches, and support":
  https:/\/learn.microsoft.com/en-us/dotnet/core/releases-and-support
- Microsoft Learn, "What's new in \.NET 10":
  https:/\/learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/overview
- Microsoft Learn, "\.NET project SDKs":
  https:/\/learn.microsoft.com/en-us/dotnet/core/project-sdk/overview
- Microsoft Learn, "Target frameworks in SDK-style projects":
  https:/\/learn.microsoft.com/en-us/dotnet/standard/frameworks
- Microsoft Learn, "\.NET Runtime Identifier catalog":
  https:/\/learn.microsoft.com/en-us/dotnet/core/rid-catalog
- Microsoft Learn, "global.json overview":
  https:/\/learn.microsoft.com/en-us/dotnet/core/tools/global-json
- Microsoft Learn, "Install \.NET on Windows":
  https:/\/learn.microsoft.com/en-us/dotnet/core/install/windows
- Microsoft Learn, "What's new in C\# 14":
  https:/\/learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14

== Further Reading
<further-reading>
- Microsoft Learn, "\.NET CLI overview":
  https:/\/learn.microsoft.com/en-us/dotnet/core/tools/
- Microsoft Learn, "\.NET tools":
  https:/\/learn.microsoft.com/en-us/dotnet/core/tools/global-tools
- Microsoft Learn, "C\# language reference":
  https:/\/learn.microsoft.com/en-us/dotnet/csharp/language-reference/
- Microsoft Learn, "\.NET application publishing overview":
  https:/\/learn.microsoft.com/en-us/dotnet/core/deploying/
