# Modern Development Workflow

## Chapter Purpose

The previous chapter named the major technologies in the modern .NET stack.
This chapter shows how work moves through that stack during an ordinary
professional development cycle.

If your baseline is Visual Studio 2019, Team Foundation Server or an older Git
setup, manual QA handoffs, and deployments coordinated through people and
servers, the modern workflow can look busier than the old one. There are pull
requests, automated checks, cloud development environments, code review tools,
pipeline statuses, package feeds, container images, security scans, and AI
coding assistants.

The purpose of all that machinery is not ceremony. It is controlled feedback.

Modern development workflow exists because professional software teams learned
the cost of late integration, unclear review, environment drift, manual
deployment, and production surprises. The newer workflow tries to make each
change small enough to understand, visible enough to review, automated enough
to validate, and traceable enough to operate.

This chapter does not teach full CI/CD implementation. Chapter 8 covers
automated testing and CI basics, and Chapter 16 covers deployment pipelines.
Here, the goal is to understand the complete lifecycle at a high level: local
development, source control, pull requests, testing, code reviews, AI coding
assistants, development environments, and how code moves toward production.

## Where This Fits

Chapter 1 shifted the mental model from server-centered development to
platform-centered development. Chapter 2 identified the technologies in that
platform. Chapter 3 connects them through time.

A modern workflow is a loop:

```text
Plan a small change
        |
        v
Create or update code locally
        |
        v
Run local build and tests
        |
        v
Commit to a short-lived branch
        |
        v
Open a pull request
        |
        v
Review, discuss, and revise
        |
        v
Automated checks validate the change
        |
        v
Merge to the main branch
        |
        v
Build artifact or package
        |
        v
Deploy through a controlled process
        |
        v
Observe production behavior
        |
        v
Feed learning back into the next change
```

The key idea is that development does not end when code compiles. In a modern
team, the workflow connects development, delivery, and operations. Microsoft
describes DevOps as uniting people, process, and technology across planning,
development, delivery, and operations. That is the lifecycle this chapter is
mapping.

This workflow is now common across ecosystems, not only .NET. Java, Node.js,
Python, Go, and .NET teams all use variants of this pattern because it solves a
team coordination problem, not a language-specific problem.

## Connection to the Reader's Existing Model

The familiar workflow probably had these landmarks:

- open the solution in Visual Studio;
- make a change;
- run locally with IIS Express or a local IIS site;
- maybe run unit tests;
- check in code;
- wait for a build or manually produce one;
- hand off to QA or operations;
- deploy by copying files, running a script, or using a release tool;
- troubleshoot on the server if something failed.

Modern development keeps the same broad intent but makes more of the workflow
explicit and repeatable.

Visual Studio is still a powerful local environment, but it is no longer the
only place where the project must build. A build should work from the command
line, on another developer's machine, and on a clean build agent.

Source control is no longer just a backup and history mechanism. It is the
coordination point for branches, pull requests, review, automated checks,
security scanning, release notes, and sometimes infrastructure definitions.

A pull request is similar to a formal code review or change request, but it is
attached directly to the code diff, tests, comments, approvals, and automation
results.

Automated tests are similar to regression test scripts, but they execute as
part of the normal change process instead of waiting for a separate late-stage
test phase.

A CI check is similar to a build-server validation, but modern teams expect it
to run frequently, consistently, and close to the code review.

A development environment is still a workstation-like place where you write
and run code. The difference is that the environment may be local, container
based, cloud hosted, or standardized through repository configuration.

An AI coding assistant is not a replacement for the developer. It is closer to
an always-available pair programmer that can suggest code, explain APIs, draft
tests, summarize changes, and help navigate unfamiliar areas. The analogy is
useful as long as you remember that the assistant does not own correctness,
security, or design judgment.

The old model often relied on expert memory: the senior developer knew how to
build it, the release engineer knew how to deploy it, and the production admin
knew which server setting mattered. The modern model tries to turn that memory
into visible workflow.

## Layer 1 — Conceptual Model

Modern development workflow is the repeatable path by which a team turns an
idea into a safe, reviewed, validated, deployable software change.

It exists to solve five recurring problems.

First, integration delay. When developers work separately for too long, changes
conflict, assumptions diverge, and bugs are discovered late. Short-lived
branches, frequent commits, pull requests, and CI reduce the cost of bringing
work together.

Second, environment drift. If every developer's machine, test server, and
production server is slightly different, success in one place does not predict
success in another. SDK-based builds, containerized dependencies, documented
setup, and cloud development environments reduce drift.

Third, review ambiguity. A hallway conversation or email thread is easy to
lose. Pull requests connect the code, conversation, tests, and approval record.

Fourth, manual validation. Humans are good at judgment and design review.
Humans are poor at repeatedly remembering every mechanical check. Automated
builds, tests, linters, formatters, and scans handle repeatable validation so
people can focus on meaning.

Fifth, production disconnect. In older workflows, developers could finish a
change and lose sight of it once it crossed into QA or operations. Modern
workflow keeps feedback connected through deployment status, telemetry,
incidents, and post-release learning.

What the workflow does not solve by itself:

- It does not guarantee good architecture.
- It does not make tests valuable just because they are automated.
- It does not replace code review judgment.
- It does not remove the need for production ownership.
- It does not make AI-generated code correct.
- It does not make a broken team healthy through tools alone.

The workflow is a support system for disciplined engineering. It makes good
habits easier to repeat.

## Layer 2 — System Relationships

The modern workflow has several connected actors and boundaries.

The developer owns the local change. Inputs include a work item, branch,
existing code, local environment, tests, and context from previous chapters or
documentation. Outputs include commits, tests, documentation updates, and a
pull request.

The repository owns shared history. It receives commits and branches. It
outputs version history, diffs, merge records, tags, and sometimes release
artifacts. Its failure boundaries include bad branching practices, weak
permissions, missing history, and unclear ownership.

The pull request owns review coordination. It receives a proposed diff,
description, linked work item, review comments, automated check results, and
updates from the author. It outputs an approved, rejected, or revised change.
Its failure boundaries include oversized changes, vague descriptions,
rubber-stamp review, stale branches, and unresolved discussion.

The test suite owns repeatable validation. It receives compiled code, test
data, dependencies, and environment configuration. It outputs pass/fail
signals and diagnostics. Its failure boundaries include flaky tests, missing
coverage for important behavior, over-mocked tests, slow feedback, and tests
that assert implementation details instead of behavior.

The CI system owns clean validation. It receives repository events such as
commits or pull requests. It checks out the code, restores dependencies, builds
the solution, runs tests, and reports status. Its failure boundaries include
broken agents, missing secrets, unavailable package feeds, nondeterministic
tests, and mismatched SDK versions.

The code review process owns human judgment. It receives the author's intent,
the diff, test evidence, design context, and automated results. It outputs
feedback, suggestions, approval, or a request for changes. Its failure
boundaries include reviewing style while missing behavior, deferring too much
to automation, or treating review as personal criticism instead of shared
ownership.

The development environment owns local productivity. It receives repository
configuration, SDKs, tools, containers, secrets for local development, and IDE
settings. It outputs fast feedback. Its failure boundaries include slow setup,
hidden machine-specific assumptions, missing dependencies, and local-only
success.

The AI coding assistant owns suggestion and acceleration, not authority. It
receives prompts, visible code context, chat history, repository files, and
possibly tool access depending on the environment. It outputs suggestions,
explanations, edits, tests, or summaries. Its failure boundaries include
plausible but wrong code, outdated assumptions, insecure suggestions, data
exposure, and over-trust.

The deployment process owns movement toward runtime environments. In this
chapter, deployment remains a high-level concept. Later chapters teach the
mechanics. For now, understand that the output of development should be a
validated change that can become a deployable artifact through a controlled
path.

## Layer 3 — Core Mechanics

The smallest useful workflow is a branch and pull request with automated
validation.

```text
main branch
  |
  +-- feature branch
        |
        v
      commits
        |
        v
      pull request
        |
        +-- human review
        |
        +-- automated build and tests
        |
        v
      merge
        |
        v
main branch with validated change
```

The main branch represents the shared integration line. Some teams call it
`main`, some use `master`, and some use trunk-based development language. The
name matters less than the rule: the shared line should be kept healthy.

A branch is an isolated line of work. Modern teams generally prefer
short-lived branches because they reduce integration delay.

A commit is a recorded change. Good commits make the history understandable.
They are not just save points; they are communication.

A pull request proposes that branch changes be merged into another branch. It
contains the diff, discussion, review state, and automated checks.

A code review is a human evaluation of the proposed change. GitHub pull request
reviews support comments, suggestions, approval, and requests for changes.

A check is an automated result attached to the proposed change. Checks might
build the solution, run tests, enforce formatting, scan dependencies, or
produce preview artifacts.

Continuous integration is the practice of automatically building and testing
code when changes are committed to version control. It exists to catch
integration problems early.

Continuous delivery is the broader practice of automating build, test,
configuration, and deployment movement toward environments. This chapter
mentions it only as part of the lifecycle. The detailed release pipeline comes
later.

A development environment is the place where the developer writes and runs the
application. It can be a local machine, a local container setup, a cloud
environment such as GitHub Codespaces, or a managed developer workstation such
as Microsoft Dev Box.

An AI coding assistant is a tool that uses large language models to assist
with coding tasks. Examples include inline suggestions, chat-based code
explanation, refactoring help, test generation, and debugging support. The
state-of-the-art direction in 2026 is broader than autocomplete: assistants
are increasingly integrated into IDEs, repositories, pull requests, terminals,
cloud consoles, and agent-like workflows. That power makes review and judgment
more important, not less.

## Layer 4 — Developer Workflow

Here is the modern workflow in practical terms.

Start with a small piece of work. It might come from a backlog item, bug
report, incident follow-up, architecture decision, or direct user need. The
unit of work should be small enough that someone else can review it without
reconstructing the entire system.

Update your local repository:

```bash
git status
git pull
```

Create a branch:

```bash
git switch -c feature/add-order-status
```

Run the application or tests before changing code when practical. This gives
you a baseline:

```bash
dotnet build
dotnet test
```

Make the change in your editor or IDE. Visual Studio, Visual Studio Code,
JetBrains Rider, Codespaces, and Dev Box can all participate in modern .NET
workflows. The specific tool matters less than whether the workflow is
repeatable outside one tool.

Use an AI coding assistant carefully if available. Good uses include asking it
to explain unfamiliar code, draft a test shape, identify edge cases, summarize
a diff, or suggest a refactoring. Risky uses include accepting large generated
changes without understanding them, pasting secrets into prompts, or treating
generated code as reviewed code.

Run local validation:

```bash
dotnet format --verify-no-changes
dotnet build
dotnet test
```

The exact commands vary by repository. Some teams use scripts, `make`, `just`,
PowerShell, npm, Docker Compose, or custom build tools. The principle is that
the repository should expose a known way to validate the change.

Commit the change:

```bash
git status
git add .
git commit -m "Add order status validation"
```

Push the branch:

```bash
git push -u origin feature/add-order-status
```

Open a pull request. The pull request description should explain what changed,
why it changed, how it was tested, and any risk or follow-up work. If the
change has screenshots, logs, migration notes, or API examples, include them.

Respond to review. Review is not a ceremony after the real work; it is part of
the work. A reviewer may find a missed case, unclear name, fragile test, hidden
security issue, or simpler design.

Wait for automated checks. If checks fail, fix the branch rather than hoping
the failure is unrelated. If the failure is flaky, treat that as a workflow
problem worth improving.

Merge after review and checks pass. Depending on team policy, the merge may
create a merge commit, squash commits, or rebase. That policy is less important
than keeping shared history understandable and the main branch healthy.

After merge, the change moves toward deployment. In a mature environment, the
same change can be traced from work item to pull request, commit, build
artifact, deployment, and production telemetry.

## Layer 5 — Production Usage

Workflow choices affect production quality.

Configuration should be separated from code. Local development may use local
settings or user secrets. CI may use test configuration. Production may use
environment variables, managed secret stores, or platform configuration.
Workflow should make it hard to accidentally commit secrets.

Security should shift earlier without pretending development can catch
everything. Modern workflows often include dependency scanning, secret
scanning, branch protection, least-privilege repository access, required
reviews, and controlled deployment credentials. These practices reduce risk
before the application reaches production.

Reliability starts before deployment. Small changes are easier to review,
test, deploy, and roll back. Automated tests reduce regression risk. Pull
requests capture design judgment. CI confirms that the change works outside the
author's machine.

Deployment should consume validated artifacts. A common failure in older
systems was rebuilding or modifying files during release in ways that made it
unclear what actually reached production. Modern workflows try to build once,
identify the artifact, and move that artifact through environments.

Observability closes the loop. Production logs, metrics, traces, errors, and
alerts tell the team whether the change behaved as expected. Without feedback,
deployment is a cliff.

Scaling affects workflow because larger teams need clearer boundaries. A
three-person team can coordinate with conversation. A thirty-person team needs
branch policies, ownership rules, review expectations, consistent local setup,
and automation that prevents accidental damage.

Persistence affects workflow because database changes must be coordinated with
application changes. A schema migration, data correction, or index change is
not just "code." It has deployment ordering, rollback, locking, backup, and
performance implications.

Cost affects workflow when builds, cloud development environments, preview
environments, AI tools, and test infrastructure are metered. A modern workflow
should give fast feedback without silently creating waste.

Local-development arrangements optimize for fast feedback. Production designs
optimize for reliability, security, auditability, and recoverability. A good
workflow keeps those goals connected without pretending they are identical.

## Layer 6 — Tradeoffs and Alternatives

There is no single correct workflow for every team.

Small teams may use lightweight GitHub repositories, short branches, pull
requests, and a few required checks. Larger enterprises may add issue
tracking, change approval, security gates, compliance evidence, release trains,
and environment promotion.

GitHub is widely used, especially for open source and many modern product
teams. Azure DevOps remains common in Microsoft-oriented enterprises. GitLab,
Bitbucket, Jenkins, TeamCity, CircleCI, and Buildkite are also valid choices.
The workflow principles matter more than the brand: versioned code, review,
automated validation, traceable delivery, and feedback from production.

Pull requests are not the only collaboration model. Some high-performing teams
use trunk-based development with very short-lived branches and strong
automation. Some regulated environments require heavier approval processes.
Some open-source projects rely on maintainer review across forks. The best
choice depends on team size, risk, deployment frequency, and compliance needs.

Local development is not always enough. A standard workstation may be fastest
for many developers. A containerized setup may reduce dependency drift.
GitHub Codespaces can provide cloud-hosted, repository-configured development
environments. Microsoft Dev Box can provide secure, managed cloud development
workstations. These options solve setup and consistency problems, but they add
cost and administrative decisions.

AI coding assistants can accelerate exploration, routine code, test drafts,
documentation, and unfamiliar API usage. They can also produce confident
mistakes. Use them as collaborators under review, not as authorities.

Common overengineering mistakes:

- requiring a pull request for every tiny experimental spike;
- creating so many pipeline gates that developers stop trusting the system;
- running slow checks on every keystroke-level change;
- adding cloud development environments before local setup is understood;
- treating code review as permission bureaucracy instead of design feedback;
- accepting AI-generated code because it looks polished;
- confusing a sophisticated workflow with a healthy engineering culture.

Simpler alternatives are sometimes better. A small internal tool may need Git,
a README, a build command, and a modest test suite before it needs preview
environments and advanced deployment rings. More advanced alternatives are
worthwhile when the risk and scale justify them: trunk-based development,
ephemeral environments, progressive delivery, feature flags, policy-as-code,
supply-chain signing, and platform-engineered paved paths.

The state-of-the-art direction is not heavier process. It is shorter feedback
loops with stronger guardrails.

## Layer 7 — Interview Perspective

Interviewers use workflow questions to learn how you work with a team.

Concepts commonly tested:

- the purpose of source control beyond backup;
- branch and pull request workflow;
- what belongs in a pull request description;
- the difference between local tests and CI checks;
- the purpose of code review;
- how to handle failed builds;
- how AI coding assistants should and should not be used;
- how a code change moves toward production.

Representative questions:

- "Walk me through your development workflow from task to merge."
- "What makes a pull request easy to review?"
- "What should happen before code is merged to the main branch?"
- "How do you respond when CI fails but the code works locally?"
- "What is the difference between continuous integration and continuous
  delivery?"
- "How do you use AI coding tools responsibly?"
- "How would you improve a team that deploys manually and often has release
  surprises?"

A strong answer describes feedback loops. For example:

> "I try to keep changes small, run local validation before opening the pull
> request, explain the intent and test evidence, respond to review, and treat
> CI failures as real until understood. After merge, the change should be
> traceable through build and deployment so production feedback can be tied
> back to the code."

Common misconceptions:

- "Source control is mainly a backup."
- "A pull request is only for catching syntax mistakes."
- "If it works locally, CI is optional."
- "Code review is less important when tests pass."
- "AI-generated code does not need the same review as human-written code."
- "DevOps means developers do all operations work."
- "Continuous delivery means every commit must go directly to production."

Small design scenario:

You join a team maintaining a .NET line-of-business application. Developers
work directly on a shared branch, releases are manual, tests are mostly run by
QA near the end, and production fixes often happen under pressure.

A good modernization plan would be incremental:

- move to short-lived branches and pull requests;
- require a clear description and reviewer before merge;
- add a clean build check;
- add a small but meaningful automated test set;
- document local setup;
- protect the main branch;
- make release artifacts identifiable;
- improve production logging before attempting aggressive deployment
  automation;
- introduce AI coding tools with review and security expectations.

The answer should improve feedback before adding ceremony.

## Hands-On Lab

Objective:

Practice the shape of a modern workflow using a small repository-level change.

Prerequisites:

- Git installed.
- .NET SDK installed.
- A local repository.
- No remote repository is required for the local parts of this lab.

Steps:

1. Inspect the repository state:

   ```bash
   git status
   ```

2. Create a branch:

   ```bash
   git switch -c workflow-practice
   ```

3. Inspect the installed .NET SDK:

   ```bash
   dotnet --info
   ```

4. If the repository has a solution or project, run:

   ```bash
   dotnet build
   dotnet test
   ```

   If the repository does not yet contain buildable code, write down the
   commands you expect the repository to support once code exists.

5. Create a short pull request draft in a text file or notebook with these
   headings:

   ```text
   Summary
   Why
   Testing
   Risks
   Follow-up
   ```

6. Write a sample review comment against your own hypothetical change. Make it
   specific, respectful, and actionable.

7. Write one AI-assistant prompt that would be useful and safe for this work.
   For example:

   ```text
   Review this small diff for edge cases and missing tests. Do not rewrite the
   implementation unless you find a specific issue.
   ```

8. Return to your original branch when finished:

   ```bash
   git switch -
   ```

Expected results:

- You can describe the workflow from branch to pull request to validation.
- You can distinguish local validation from CI validation.
- You can write a useful pull request description.
- You can state how AI assistance fits into review rather than replacing it.

Validation commands:

```bash
git status
git branch --show-current
dotnet --info
dotnet build
dotnet test
```

Troubleshooting notes:

- If `git switch -c` fails because the branch already exists, choose another
  branch name.
- If `dotnet build` fails because there is no project file, that is acceptable
  for this chapter. The next chapters begin building code.
- If `dotnet test` reports no test projects, note that as a future workflow
  gap rather than an error.
- If you use an AI assistant, do not paste secrets, private credentials, or
  confidential production data into the prompt.

## Knowledge Check

1. Why is modern development workflow best understood as a feedback loop?
2. What problems do short-lived branches reduce?
3. What information should a pull request description provide to reviewers?
4. Why are automated checks useful even when reviewers are experienced?
5. How is continuous integration different from continuous delivery?
6. Why is "works on my machine" weaker evidence than a passing CI build?
7. What kinds of comments make code review more useful?
8. How can cloud development environments reduce onboarding friction?
9. What risks do AI coding assistants introduce into the workflow?
10. Why should production telemetry feed back into development planning?

## Summary

Modern .NET development workflow is the path from idea to validated change to
production feedback.

The core practices are not mysterious: work in small increments, keep source
history clear, review proposed changes, automate repeatable validation, protect
the shared branch, package changes consistently, and learn from production
behavior. The tools have changed, but the goal is familiar: make software
change safer.

Compared with older workstation-and-server workflows, the modern workflow
places more responsibility in shared systems: Git repositories, pull requests,
CI checks, documented development environments, controlled delivery, and
observability. AI coding assistants now participate in that workflow, but they
do not replace the developer's responsibility for correctness, security, and
design.

The next chapter begins the practical .NET layer. With the workflow map in
place, you can now look at modern .NET versions, SDKs, project structure,
cross-platform development, and language improvements as parts of a larger
professional system.

## Sources

- Microsoft Learn, "What is DevOps?":
  https://learn.microsoft.com/en-us/devops/what-is-devops
- Microsoft Learn, "Use continuous integration":
  https://learn.microsoft.com/en-us/devops/develop/what-is-continuous-integration
- Microsoft Learn, "What is continuous delivery?":
  https://learn.microsoft.com/en-us/devops/deliver/what-is-continuous-delivery
- GitHub Docs, "Quickstart for reviewing pull requests":
  https://docs.github.com/en/pull-requests/get-started/reviewing-pull-requests-quickstart
- GitHub Docs, "Requesting a pull request review":
  https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/requesting-a-pull-request-review
- GitHub Docs, "What are GitHub Codespaces?":
  https://docs.github.com/en/codespaces/about-codespaces/what-are-codespaces
- Microsoft Learn, "Open a dev box in VS Code":
  https://learn.microsoft.com/en-us/azure/dev-box/how-to-set-up-dev-tunnels
- Microsoft Learn, "GitHub Copilot Fundamentals":
  https://learn.microsoft.com/en-us/training/paths/copilot/

## Further Reading

- Microsoft Learn, "Deliver with DevOps":
  https://learn.microsoft.com/en-us/training/modules/deliver-with-devops/
- GitHub Docs, "About pull requests":
  https://docs.github.com/en/pull-requests/collaborating-with-pull-requests
- GitHub Docs, "GitHub Actions documentation":
  https://docs.github.com/en/actions
- Microsoft Learn, "Adopt, extend and build Copilot experiences across the
  Microsoft Cloud":
  https://learn.microsoft.com/en-us/microsoft-cloud/dev/copilot/overview
