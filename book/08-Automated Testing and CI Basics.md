# Automated Testing and CI Basics

## Chapter Purpose

The previous chapters built the first usable application shape: modern .NET,
ASP.NET Core, data access, and security. That is enough to write meaningful
software. It is also enough to break meaningful software.

Automated testing and continuous integration exist because professional teams
need confidence before change reaches production. Manual testing, careful code
review, and developer judgment still matter, but they are not enough by
themselves. People forget steps. Local machines drift. Integration problems
hide until code meets other code. Security-sensitive behavior can regress
quietly. A database change can compile but fail when the application starts.

If your earlier model involved a local Visual Studio build, a QA phase, and a
build server that produced occasional releases, the modern model pulls
validation earlier. Every proposed change should be able to prove basic health:
the solution restores, builds, and passes the relevant test suite in a clean
environment.

This chapter introduces automated validation, unit tests, integration tests,
test projects, GitHub Actions, pull request checks, and build pipelines. It
focuses on validating application changes before deployment. Production release
automation comes later in Chapter 16.

## Where This Fits

Automated testing and CI sit between developer workflow and deployment.

```text
Developer branch
        |
        v
Local build and tests
        |
        v
Pull request
        |
        v
CI workflow
        |
        +-- restore packages
        +-- build solution
        +-- run unit tests
        +-- run selected integration tests
        +-- report status
        |
        v
Merge decision
```

This chapter builds directly on Chapter 3's workflow loop. It uses the
application structure from Chapters 4-7 but does not require Linux, Docker,
cloud hosting, or production pipeline knowledge yet.

That ordering matters. Before learning deployment automation, the reader
should know what a pipeline is supposed to validate. A fast, repeatable build
and test process is the foundation. Without it, continuous deployment simply
makes broken releases move faster.

## Connection to the Reader's Existing Model

You probably already know several older validation patterns:

- compile the solution in Visual Studio;
- run the application locally;
- execute a few manual smoke tests;
- rely on QA test plans;
- use a build server to produce artifacts;
- deploy to a test server;
- fix bugs found after integration.

Modern testing and CI keep the same goal but move feedback closer to the code
change.

A unit test is like a small repeatable check around one piece of logic. Instead
of opening the application and manually exercising a case, the test runner does
it every time.

An integration test is closer to exercising a slice of the application the way
the runtime uses it. In ASP.NET Core, integration tests can start a test host
and send HTTP requests through the request pipeline.

A CI build is like a clean build machine with discipline. It does not care
that the code worked in your Visual Studio session. It restores dependencies,
builds, and tests from source in a separate environment.

A pull request check is like an automated reviewer that handles mechanical
questions: does it compile, do tests pass, did formatting drift, did a basic
security scan fail? It cannot judge whether the design is good, but it can
protect the team from many repeatable mistakes.

The analogy breaks down when CI is treated as a final QA department. CI is a
feedback system, not a substitute for thoughtful design, exploratory testing,
threat modeling, performance testing, or production monitoring.

## Layer 1 — Conceptual Model

Automated testing is executable evidence that the software behaves as expected
in specific scenarios.

Continuous integration is the practice of automatically validating changes
when they are committed or proposed for merge.

Together, they solve these problems:

- catching regressions early;
- proving that the project builds outside one developer's machine;
- reducing integration surprises;
- documenting expected behavior in executable form;
- giving reviewers confidence;
- protecting the main branch;
- making later deployment automation safer.

They do not solve these problems automatically:

- they do not prove the absence of bugs;
- they do not replace human review;
- they do not guarantee useful coverage;
- they do not validate production performance by default;
- they do not make flaky tests trustworthy;
- they do not remove the need for observability after deployment.

The conceptual model is:

```text
Unit tests answer: does this small behavior work?
Integration tests answer: do these components work together?
CI answers: does this change work from a clean shared process?
Pull request checks answer: is this change ready for human merge judgment?
```

The goal is not to maximize test count. The goal is to create a fast,
trustworthy signal about the risks that matter.

## Layer 2 — System Relationships

The production project contains application code. It might be an ASP.NET Core
API, class library, worker service, or console application.

The test project contains test code. It references the production project and
uses a test framework such as MSTest, xUnit, or NUnit.

The test framework provides attributes, assertions, fixtures, and conventions.
MSTest, xUnit, and NUnit are common choices in .NET. The best choice is often
the one your team already understands.

The test runner discovers and executes tests. `dotnet test` builds the project
and runs tests using the configured runner. In .NET 10, test runner selection
can be configured, with VSTest as the traditional default and Microsoft
Testing Platform available for newer scenarios.

The system under test, often shortened to SUT, is the application or component
being tested. In an ASP.NET Core integration test, the SUT is usually the web
application started by the test host.

Test doubles replace dependencies when isolation is useful. Fakes, stubs,
mocks, and in-memory implementations can make unit tests fast and focused.
They can also hide integration problems when overused.

The CI system runs validation away from the developer's workstation. GitHub
Actions, Azure Pipelines, GitLab CI, Jenkins, TeamCity, CircleCI, and others
can all perform this role.

The pull request receives CI status. Branch protection can require selected
checks to pass before merge.

Failure boundaries include missing SDKs, package restore failures, flaky
tests, tests that depend on local machine state, slow integration tests,
secrets missing in CI, inconsistent databases, incorrect test data, weak
assertions, and test suites that are ignored because they are noisy.

## Layer 3 — Core Mechanics

A unit test starts with a small behavior.

```csharp
public sealed class OrderTotalCalculator
{
    public decimal Calculate(decimal subtotal, decimal tax)
    {
        if (subtotal < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(subtotal));
        }

        return subtotal + tax;
    }
}
```

An MSTest unit test might look like this:

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public sealed class OrderTotalCalculatorTests
{
    [TestMethod]
    public void Calculate_WithSubtotalAndTax_ReturnsTotal()
    {
        var calculator = new OrderTotalCalculator();

        var result = calculator.Calculate(100m, 8.25m);

        Assert.AreEqual(108.25m, result);
    }
}
```

The familiar pattern is Arrange, Act, Assert:

```text
Arrange: create the situation
Act: run the behavior
Assert: verify the result
```

An ASP.NET Core integration test checks a broader slice. It can start the app
in a test host and make HTTP requests through the pipeline:

```csharp
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public sealed class HealthEndpointTests
{
    [TestMethod]
    public async Task HealthEndpoint_ReturnsOk()
    {
        await using var factory =
            new WebApplicationFactory<Program>();

        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health/basic");

        response.EnsureSuccessStatusCode();
    }
}
```

This type of test can catch routing, middleware, dependency injection, and
configuration problems that a small unit test would miss.

A basic GitHub Actions workflow for .NET validation has the same shape as the
local commands:

```yaml
name: dotnet-ci

on:
  pull_request:
  push:
    branches: [ "main" ]

jobs:
  build-test:
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

The YAML is not magic. It checks out code, installs or selects .NET, restores
packages, builds, and runs tests.

## Layer 4 — Developer Workflow

Start by creating a solution with production and test projects:

```bash
dotnet new sln -n Chapter08
dotnet new classlib -n Chapter08.Domain
dotnet new mstest -n Chapter08.Domain.Tests
dotnet sln add Chapter08.Domain/Chapter08.Domain.csproj
dotnet sln add Chapter08.Domain.Tests/Chapter08.Domain.Tests.csproj
dotnet add Chapter08.Domain.Tests/Chapter08.Domain.Tests.csproj reference Chapter08.Domain/Chapter08.Domain.csproj
```

Run tests locally:

```bash
dotnet test
```

Run with Release configuration:

```bash
dotnet test --configuration Release
```

Filter tests when diagnosing:

```bash
dotnet test --filter "FullyQualifiedName~Order"
```

Create an ASP.NET Core integration test project when testing the request
pipeline:

```bash
dotnet new mstest -n Chapter08.Api.Tests
dotnet add Chapter08.Api.Tests package Microsoft.AspNetCore.Mvc.Testing
dotnet add Chapter08.Api.Tests reference Chapter08.Api/Chapter08.Api.csproj
dotnet sln add Chapter08.Api.Tests/Chapter08.Api.Tests.csproj
```

Keep unit and integration tests separated when practical. This makes it easier
to run fast tests frequently and broader tests intentionally.

Create a workflow file:

```text
.github/workflows/dotnet-ci.yml
```

Use it to run restore, build, and test on pull requests and pushes to `main`.

The daily workflow becomes:

```text
Change code
  |
  v
Run focused tests locally
  |
  v
Run full local validation before opening PR
  |
  v
Open PR
  |
  v
CI validates in clean environment
  |
  v
Reviewer evaluates behavior and design
```

When CI fails, assume the signal matters until you prove otherwise. A flaky
test is not harmless. It teaches the team to distrust the pipeline.

## Layer 5 — Production Usage

This chapter is not about production deployment, but test and CI choices shape
production risk.

Configuration should distinguish local test settings from production settings.
Tests should not accidentally connect to production databases, production
queues, production identity providers, or paid AI services.

Secrets should be avoided in tests when possible. When CI needs secrets, use
the CI platform's secure secret store and restrict access. Never commit secrets
to test configuration.

Security-sensitive behavior deserves tests. Authorization policies, ownership
checks, input validation, and secret-loading behavior should not rely only on
manual testing. Chapter 7's security boundaries are good candidates for
focused integration tests.

Reliability improves when CI protects the main branch. A main branch that
regularly fails builds becomes background noise. A healthy main branch gives
the team a trustworthy integration point.

Deployment depends on validated artifacts. Later CD pipelines should consume
artifacts produced after restore, build, and test. If the validation path is
unclear, deployment automation inherits that uncertainty.

Observability starts in CI too. Failed tests, test duration, flaky test
patterns, code coverage trends, and build times are signals about the health
of the engineering system.

Scaling the test suite requires layers. Thousands of slow integration tests on
every pull request may block development. A better shape is many fast unit
tests, focused integration tests for important boundaries, and heavier tests
scheduled or gated where appropriate.

Persistence in tests requires caution. Tests that write to a real database
need clean setup and teardown, isolated data, or disposable databases. Shared
test databases often create order-dependent failures.

Cost appears through CI minutes, hosted runners, cloud test environments,
database instances, browser tests, and AI-assisted test generation. Fast
feedback is valuable; wasteful feedback is still waste.

Local development optimizes for speed. CI optimizes for clean reproducibility.
Production optimizes for safety. The three should align, but they are not the
same environment.

## Layer 6 — Tradeoffs and Alternatives

Use unit tests for deterministic business rules, validation logic, mapping
logic, calculations, authorization decisions, and small service behavior.

Use integration tests for ASP.NET Core routing, middleware, dependency
injection, database access, configuration, authentication behavior, and
important cross-component flows.

Use end-to-end tests sparingly for complete user or system flows. They are
valuable, but slower and more fragile. Browser automation tools such as
Playwright are useful when the UI matters.

MSTest, xUnit, and NUnit are all credible .NET test frameworks. MSTest has
first-party Microsoft positioning and integrates naturally with Visual Studio.
xUnit is common in open-source and ASP.NET Core samples. NUnit is mature and
widely used. Pick one deliberately and avoid mixing frameworks casually.

GitHub Actions is a natural CI choice for repositories hosted on GitHub.
Azure Pipelines fits many Azure DevOps organizations. GitLab CI, Jenkins,
TeamCity, CircleCI, and Buildkite are valid alternatives depending on existing
platform, compliance, hosting, and team skill.

Common overengineering mistakes:

- testing trivial property getters while missing business rules;
- mocking every dependency until the test no longer represents reality;
- writing only integration tests and accepting slow feedback;
- depending on test execution order;
- allowing flaky tests to remain unresolved;
- treating code coverage percentage as proof of quality;
- running production-like tests against production resources;
- adding CI gates no one understands.

The state-of-the-art direction is faster, more reliable feedback: clear test
layers, parallel execution where safe, disposable infrastructure for
integration tests, test impact analysis in large systems, and CI workflows that
produce useful diagnostics instead of only red or green lights.

## Layer 7 — Interview Perspective

Interviewers use testing and CI questions to learn whether you can work safely
on a team.

Concepts commonly tested:

- unit tests versus integration tests;
- Arrange, Act, Assert;
- test project structure;
- `dotnet test`;
- test doubles;
- CI workflow basics;
- pull request checks;
- branch protection;
- flaky tests;
- testing security and data-access behavior.

Representative questions:

- "What is the difference between a unit test and an integration test?"
- "What should run in CI for a .NET API?"
- "How would you structure test projects in a solution?"
- "What do you do when a test passes locally but fails in CI?"
- "Why are flaky tests dangerous?"
- "How would you test an authorization policy?"
- "What belongs in a pull request check versus a deployment pipeline?"

A strong answer connects tests to risk:

> "I use unit tests for fast feedback on isolated business behavior and focused
> integration tests for boundaries such as HTTP routing, dependency injection,
> database access, and authorization. CI should restore, build, and run the
> relevant tests in a clean environment before merge."

Common misconceptions:

- "Unit tests prove the whole application works."
- "Integration tests are always better because they test more."
- "CI is only useful after deployment automation exists."
- "Flaky tests are acceptable if they usually pass."
- "Code coverage means the behavior is correct."
- "Tests should connect to whatever database is easiest."
- "A pull request check replaces code review."

Small design scenario:

You inherit an ASP.NET Core order API with EF Core and JWT authorization. The
team manually tests endpoints before release and often finds broken
authorization or migration problems late.

A good first validation plan would add unit tests for order business rules,
integration tests for protected endpoints, a migration check for pending model
changes, and a GitHub Actions workflow that restores, builds, and runs tests
on pull requests. It would not begin by building a complex production release
pipeline.

## Hands-On Lab

Objective:

Create a test project, write a unit test, and add a basic GitHub Actions CI
workflow for a .NET solution.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- Git installed.
- A GitHub repository if you want to run the workflow remotely.

Steps:

1. Create a solution and projects:

   ```bash
   dotnet new sln -n Chapter08
   dotnet new classlib -n Chapter08.Domain
   dotnet new mstest -n Chapter08.Domain.Tests
   dotnet sln add Chapter08.Domain/Chapter08.Domain.csproj
   dotnet sln add Chapter08.Domain.Tests/Chapter08.Domain.Tests.csproj
   dotnet add Chapter08.Domain.Tests/Chapter08.Domain.Tests.csproj reference Chapter08.Domain/Chapter08.Domain.csproj
   ```

2. Add a small class to the domain project:

   ```csharp
   public sealed class OrderTotalCalculator
   {
       public decimal Calculate(decimal subtotal, decimal tax)
       {
           if (subtotal < 0)
           {
               throw new ArgumentOutOfRangeException(nameof(subtotal));
           }

           return subtotal + tax;
       }
   }
   ```

3. Add a test for the calculator.

4. Run tests:

   ```bash
   dotnet test
   ```

5. Create `.github/workflows/dotnet-ci.yml`.

6. Add this workflow:

   ```yaml
   name: dotnet-ci

   on:
     pull_request:
     push:
       branches: [ "main" ]

   jobs:
     build-test:
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

7. Commit the workflow and open a pull request if using GitHub.

Expected results:

- The solution builds.
- The test project references the production project.
- `dotnet test` runs the test locally.
- GitHub Actions can restore, build, and test the solution on pull requests.

Validation commands:

```bash
dotnet restore
dotnet build
dotnet test
git status
```

Troubleshooting notes:

- If the test project cannot see the production type, check the project
  reference.
- If CI fails but local tests pass, compare SDK versions and operating systems.
- If the workflow cannot find a solution, confirm it runs from the repository
  root.
- If `actions/setup-dotnet` cannot find the version, check the supported SDK
  version syntax.

## Knowledge Check

1. Why does automated validation belong before deployment automation?
2. What is the difference between a unit test and an integration test?
3. Why should unit tests usually avoid real databases and network calls?
4. When is an integration test worth its extra cost?
5. What does `dotnet test` do?
6. Why is a clean CI environment more trustworthy than one developer's machine?
7. What should a basic .NET pull request workflow validate?
8. Why are flaky tests harmful to team behavior?
9. What security-sensitive behavior should be tested in an API?
10. Why is code coverage useful but insufficient?

## Summary

Automated testing turns expected behavior into executable evidence.
Continuous integration runs that evidence in a clean shared process before
changes are merged.

Unit tests are fast checks around small behavior. Integration tests verify that
important components work together, such as ASP.NET Core routing, middleware,
dependency injection, configuration, data access, and authorization. CI ties
those checks to pull requests and the main branch.

The goal is not a giant test suite for its own sake. The goal is trustworthy
feedback. A healthy validation system is fast enough to use, broad enough to
catch meaningful regressions, and reliable enough that the team believes it.

The next chapter shifts operating systems. With a validated .NET application
workflow in place, you can now learn the Linux concepts modern .NET developers
need before containers and cloud hosting.

## Sources

- [dotnet test command](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test)
- [Write tests with MSTest](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-mstest-writing-tests)
- [Integration tests in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-10.0)
- [Building and testing .NET with GitHub Actions](https://docs.github.com/en/actions/tutorials/build-and-test-code/net)
- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Order unit tests](https://learn.microsoft.com/en-us/dotnet/core/testing/order-unit-tests)

## Further Reading

- [Testing in .NET](https://learn.microsoft.com/en-us/dotnet/core/testing/)
- [Unit testing C# with MSTest and .NET](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-mstest)
- [ASP.NET Core testing documentation](https://learn.microsoft.com/en-us/aspnet/core/test/?view=aspnetcore-10.0)
- [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions)
