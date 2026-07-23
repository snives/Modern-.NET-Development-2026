# Common Architectural Patterns

## Chapter Purpose

Chapter 22 explained architecture styles: monoliths, modular monoliths,
microservices, distributed systems, scale, reliability, performance, and cost.
This chapter narrows the focus to patterns that commonly appear inside those
architectures.

Architectural patterns exist because the same design problems keep appearing:
how to isolate data access, how to separate writes from reads, how to react to
business events, how to move slow work out of request paths, and how to
represent meaningful changes inside the domain.

Patterns are useful because they give names to recurring solutions. They let a
team say "this should be a background job" or "this read model is CQRS" without
explaining the whole design from scratch.

Patterns are dangerous when they become ceremony. A repository that only wraps
Entity Framework Core without simplifying anything can make code worse. CQRS
can be a clean separation or a pile of duplicate models. Events can decouple
systems or hide control flow. Background jobs can improve responsiveness or
create invisible failure. Domain events can clarify business meaning or turn
every property change into noise.

This chapter teaches repository, CQRS, event-driven systems, background
processing, and domain events by asking the most important pattern question:
what problem is this pattern solving here?

## Where This Fits

Patterns sit inside an architecture style.

```text
Architecture style
        |
        +-- monolith
        +-- modular monolith
        +-- microservices
        |
        v
Application design patterns
        |
        +-- repository
        +-- CQRS
        +-- event-driven communication
        +-- background processing
        +-- domain events
        |
        v
Implementation
        |
        +-- ASP.NET Core endpoints
        +-- application services
        +-- EF Core
        +-- SQL Server
        +-- queues
        +-- workers
        +-- observability
```

A pattern does not decide the whole architecture. You can use background
processing inside a monolith. You can use domain events inside a modular
monolith. You can use CQRS without microservices. You can use repositories in
some places and direct EF Core queries in others.

Chapter 23 is the final technical architecture chapter before interview and
career preparation. It gives the reader vocabulary for architecture
discussions without pretending every vocabulary word belongs in every system.

## Connection to the Reader's Existing Model

The familiar model is an enterprise .NET application with layers.

You may have built applications with controllers, services, data access
classes, stored procedures, DTOs, SQL Server Agent jobs, Windows services,
message queues, and scheduled tasks. The names were different, but many of the
pressures were the same.

The repository pattern resembles a data access layer. It provides a collection-
like abstraction over persistence. The useful part is hiding persistence
details when the rest of the application should not know how data is stored or
queried.

CQRS resembles separating update procedures from reporting queries. A stored
procedure that enforces an order workflow is not the same as a reporting view
that joins orders, customers, and shipments for display. CQRS gives that
separation an architectural name.

Event-driven systems resemble using SQL triggers, Service Broker, MSMQ,
scheduled integration jobs, or publish-subscribe messaging to react after
something happens. The modern version usually uses explicit events, brokers,
queues, and handlers instead of hidden database behavior.

Background processing resembles Windows services, scheduled tasks, SQL Server
Agent jobs, or batch processors. The modern version might be an ASP.NET Core
hosted service, a worker service, a queue-triggered function, a containerized
worker, or a cloud job.

Domain events resemble writing down that a business fact occurred:
`OrderSubmitted`, `PaymentCaptured`, `ShipmentDelayed`, or
`CustomerRegistered`. They are not merely technical notifications. They
represent something the business cares about.

The analogy breaks down when old mechanisms hide too much. A SQL trigger may
run invisibly. A modern event handler should be observable, testable, and
owned. A scheduled task may retry by accident. A modern background worker
should be idempotent and instrumented.

## Layer 1 — Conceptual Model

An architectural pattern is a named solution to a recurring design problem.

Patterns solve these problems:

- giving teams shared vocabulary;
- separating responsibilities;
- making change safer;
- isolating persistence details;
- optimizing reads and writes differently;
- decoupling producers from consumers;
- moving slow work out of user requests;
- representing meaningful business events.

They do not solve these problems automatically:

- they do not replace understanding the domain;
- they do not make code clean by existing;
- they do not remove tradeoffs;
- they do not make distributed systems reliable by default;
- they do not guarantee performance;
- they do not excuse unclear ownership;
- they do not belong everywhere.

The conceptual model is:

```text
Pressure appears.
Pattern may fit.
Tradeoffs are evaluated.
Small implementation is tested.
Operational behavior is observed.
Pattern is kept only if it pays rent.
```

Patterns should reduce complexity where the system is under pressure. If a
pattern adds more concepts than it removes, it is probably too early.

## Layer 2 — System Relationships

The repository pattern sits between application logic and persistence. Inputs
are domain-oriented queries or operations. Outputs are domain objects,
aggregates, DTOs, or result sets. Its dependencies include EF Core, SQL Server,
or another store. Its failure boundary is persistence access.

CQRS splits command handling from query handling. Commands change state.
Queries read state. The write side owns validation, business rules, and
consistency. The read side owns efficient projection and presentation-friendly
data. The lifecycle boundary may be small, such as separate classes, or large,
such as separate databases.

Event-driven systems connect producers, event channels, and consumers. A
producer publishes that something happened. A channel stores or routes the
event. Consumers react independently. The ownership boundary is important:
the producer owns the meaning of the event, but consumers own their reactions.

Background processing moves work out of the interactive request path. A web
request may enqueue work and return quickly. A worker later processes the job,
updates state, sends notifications, or calls external systems. The lifecycle
boundary includes queueing, retries, dead-letter handling, and status tracking.

Domain events live inside the business model or application layer. They mark
important facts that occurred in the domain. They can trigger in-process
handlers, outbox messages, notifications, projections, or integration events.

Failure boundaries include repository abstractions that leak provider details,
CQRS models that drift, events that are published before database commits,
handlers that run twice, queues that grow without visibility, jobs that cannot
be retried safely, and domain events that become a dumping ground for every
side effect.

## Layer 3 — Core Mechanics

The repository pattern is most useful when it expresses domain intent:

```csharp
public interface IOrderRepository
{
    Task<Order?> GetForCheckoutAsync(
        int orderId,
        CancellationToken cancellationToken);

    Task SaveAsync(
        Order order,
        CancellationToken cancellationToken);
}
```

This is different from a generic wrapper that simply mirrors `DbSet<T>`.
Entity Framework Core already provides a unit-of-work-like `DbContext` and
set-like collections. A repository should add clarity, not hide useful EF Core
features behind weaker copies.

CQRS begins with separating command intent from query intent:

```csharp
public sealed record SubmitOrderCommand(int OrderId, int CustomerId);

public sealed class SubmitOrderHandler
{
    public Task HandleAsync(
        SubmitOrderCommand command,
        CancellationToken cancellationToken)
    {
        // Load order, validate business rules, change state, save.
        throw new NotImplementedException();
    }
}

public sealed record OrderSummaryDto(
    int OrderId,
    string CustomerName,
    string Status,
    DateTimeOffset SubmittedAt);
```

The command side protects business state. The query side can return exactly
what the screen or API needs without dragging the whole domain model into the
read path.

An event-driven flow has producers, channels, and consumers:

```text
Order API
  |
  | publishes OrderSubmitted
  v
Message broker or event channel
  |
  +--> Billing consumer
  +--> Shipment consumer
  +--> Notification consumer
```

Background processing often starts with a queue:

```text
POST /orders
  |
  v
Save order
  |
  v
Enqueue invoice job
  |
  v
Return response

Worker later:
  read job -> generate invoice -> save result -> publish completion event
```

A domain event names something meaningful:

```csharp
public sealed record OrderSubmitted(
    int OrderId,
    int CustomerId,
    DateTimeOffset OccurredAt);
```

The event should be past tense because it represents something that already
happened. A command asks the system to do something. An event says something
happened.

## Layer 4 — Developer Workflow

The developer workflow starts by identifying the pressure.

```text
Is data access too coupled?
Consider repository or query objects.

Are reads and writes pulling in opposite directions?
Consider CQRS.

Does another part of the system need to react?
Consider an event.

Is work slow or retry-prone?
Consider background processing.

Did something meaningful happen in the domain?
Consider a domain event.
```

For repository decisions:

1. Start with direct EF Core when it is clear and local.
2. Add repositories around aggregate persistence or complex persistence rules.
3. Avoid generic repositories that only copy EF Core.
4. Keep query-heavy reporting paths free to use optimized queries or read
   models.

For CQRS decisions:

1. Separate command classes from query classes first.
2. Keep one database until separate stores are justified.
3. Add projections when queries become expensive or awkward.
4. Add separate read stores only when scale, security, or performance requires
   it.

For event-driven decisions:

1. Name events in business language.
2. Publish after state changes are durable.
3. Make handlers idempotent.
4. Add correlation IDs and trace context.
5. Monitor queue depth, failures, retries, and dead-letter messages.

For background processing:

1. Decide whether the user needs the result immediately.
2. Store job state or publish progress when users need visibility.
3. Use queues for bursty work.
4. Make jobs safe to retry.
5. Add cancellation, timeout, and failure handling.

Useful .NET commands remain ordinary:

```bash
dotnet build
dotnet test
dotnet run
```

The more important workflow is review. Each pattern should be reviewed with
the question: what would be worse if we removed this pattern?

## Layer 5 — Production Usage

Production patterns must be observable and recoverable.

Configuration includes queue names, topic names, retry counts, dead-letter
settings, worker concurrency, cache duration, projection refresh intervals,
and feature flags.

Secrets include broker credentials, storage credentials, database credentials,
and service credentials used by workers. Workers should have the smallest
permissions needed for their jobs.

Security includes authorization before commands, authorization-aware queries,
tenant-safe read models, protected event payloads, safe handler permissions,
and audit trails for business operations.

Reliability depends on idempotency. Background jobs and event handlers may run
more than once. A handler should be able to detect that work is already done or
apply the same logical change safely.

Deployment must account for versioning. A new event field, command shape, or
read model can affect producers and consumers. In distributed systems, old and
new versions often run at the same time.

Observability should include command duration, query duration, event publish
counts, handler failures, queue depth, retry count, dead-letter messages,
projection lag, and correlation IDs across request, event, and worker spans.

Scaling differs by pattern. Queries can often scale with read replicas,
materialized views, or caches. Commands scale only as far as consistency rules
allow. Workers can scale horizontally when jobs are independent. Event
consumers can scale when partitions and ordering rules permit it.

Persistence is central. CQRS may use one database, two schemas, or separate
stores. Event-driven systems need to avoid losing events when a database
commit succeeds but publishing fails. The outbox pattern is a common answer:
store the outgoing event in the same transaction as the business change, then
publish it asynchronously.

Cost includes broker usage, extra storage, duplicate read models, worker
compute, retries, telemetry, and development time. Pattern cost is not only
cloud billing. It is also the mental load every developer carries.

Local development can use in-memory handlers, local containers, or development
queues. Production needs durable queues, retries, dead-letter handling,
monitoring, alerting, backup, access control, and runbooks.

## Layer 6 — Tradeoffs and Alternatives

Use repositories when persistence complexity deserves a domain-oriented
boundary, when tests benefit from substituting persistence behavior, or when a
module should not know how storage is implemented.

Do not use repositories when they only wrap EF Core with methods such as
`Add`, `Update`, `Delete`, and `GetById` without adding meaning.

Use CQRS when read and write needs differ significantly, when commands carry
business intent, when read models need different shapes, or when read and write
loads scale differently.

Do not use full CQRS with separate stores for simple CRUD screens.

Use event-driven architecture when producers and consumers should be
decoupled, when multiple reactions follow one business fact, when work can be
asynchronous, or when new consumers may be added without changing producers.

Do not use events when the workflow requires immediate consistency,
straight-line user feedback, or simple in-process method calls.

Use background processing when work is slow, bursty, retry-prone, scheduled,
CPU-intensive, I/O-intensive, or not required to finish before the user
receives a response.

Do not use background jobs when the user must know the result immediately and
the operation cannot be represented as pending.

Use domain events when the business cares that something happened and other
parts of the system may react.

Do not use domain events for every setter, save operation, or technical
notification.

Simpler alternatives include direct EF Core queries, application services,
transaction scripts, synchronous method calls, scheduled tasks, and ordinary
CRUD endpoints.

More advanced alternatives include event sourcing, sagas, workflow engines,
materialized views, separate read stores, streaming platforms, service buses,
and process managers.

Common overengineering mistakes:

- adding a generic repository to every entity;
- using CQRS before CRUD becomes painful;
- confusing commands and events;
- publishing events before the transaction commits;
- assuming queues guarantee exactly-once processing;
- building a service bus architecture for two method calls;
- hiding all control flow in handlers;
- adding background jobs without status, retries, or dead-letter handling;
- naming events after technical actions instead of business facts.

The best pattern is often the smallest version of the idea. Separate command
and query classes before separate databases. Use an in-process domain event
before a broker. Move one slow task to a worker before redesigning the whole
system.

## Layer 7 — Interview Perspective

Interviewers use pattern questions to test whether you understand tradeoffs.

Concepts commonly tested:

- repository pattern;
- EF Core and repositories;
- CQRS;
- commands versus queries;
- events versus commands;
- event-driven architecture;
- background jobs;
- queues;
- idempotency;
- outbox pattern;
- domain events;
- eventual consistency.

Representative questions:

- "Should every EF Core application use repositories?"
- "What is CQRS?"
- "When would you split read and write models?"
- "How is an event different from a command?"
- "Why do background jobs need idempotency?"
- "What happens if publishing an event fails after the database commit?"
- "When would you use a queue?"
- "What is a domain event?"
- "How do you monitor event-driven systems?"

A strong answer is conditional:

> "I would use a repository only when it adds a useful domain boundary over
> persistence. EF Core already abstracts many data-access details. For CQRS, I
> would start by separating command and query handlers, then consider separate
> read models or stores only when performance, scale, or security requires it.
> For events and background jobs, I would design for retries, idempotency,
> correlation, and dead-letter handling."

Common misconceptions:

- "Repository is mandatory with EF Core."
- "CQRS means separate databases."
- "Events are just async method calls."
- "Queues guarantee exactly-once processing."
- "Background jobs are simpler because users do not see them."
- "Domain events should be raised for every property change."
- "Event-driven architecture removes coupling entirely."

Small design scenario:

An order system accepts orders, charges payments, generates invoices, sends
emails, updates a reporting dashboard, and notifies the warehouse. Users need a
fast response after submitting an order, but the invoice can be generated
later.

A good design might handle `SubmitOrderCommand` synchronously enough to
validate and save the order, raise an `OrderSubmitted` domain event, store an
outbox message, publish an integration event after commit, process invoice and
email work in background workers, and update a read model for reporting. The
design should also include idempotency, retries, dead-letter monitoring, and
correlation IDs.

The strong answer does not apply every pattern everywhere. It applies each
pattern where the pressure exists.

## Hands-On Lab

Objective:

Choose appropriate patterns for an order submission workflow.

Prerequisites:

- Familiarity with ASP.NET Core, EF Core, SQL Server, queues, and observability.
- The architecture decision habits from Chapter 22.

Steps:

1. Start with this workflow:

   ```text
   User submits order.
   System validates order.
   System saves order.
   System charges payment.
   System generates invoice.
   System sends confirmation email.
   System updates reporting dashboard.
   ```

2. Mark which steps must happen before the user gets a response.

3. Mark which steps can happen later.

4. Define one command:

   ```text
   SubmitOrderCommand
   ```

5. Define one domain event:

   ```text
   OrderSubmitted
   ```

6. Decide whether the first version needs CQRS with separate stores or only
   separate command and query handlers.

7. Decide whether a repository adds value over direct EF Core usage.

8. Choose background jobs for slow or retry-prone work.

9. Define what must be idempotent.

10. Define observability:

    ```text
    command duration
    event publish count
    queue depth
    handler failures
    retry count
    dead-letter count
    invoice generation duration
    email send result
    ```

Expected results:

- A command definition.
- A domain event definition.
- A decision on repository usage.
- A decision on CQRS scope.
- A background processing plan.
- An idempotency plan.
- An observability checklist.

Validation commands:

If you implement a small prototype:

```bash
dotnet build
dotnet test
dotnet run
```

If you only design the workflow, validate it by explaining:

- what happens synchronously;
- what happens asynchronously;
- what is retried;
- what happens if a handler fails;
- how duplicate messages are handled;
- how a responder can diagnose a stuck order.

Troubleshooting notes:

- If the user must wait for every step, the workflow may need fewer background
  jobs or better status messaging.
- If a duplicate message would charge the customer twice, idempotency is
  missing.
- If an event can be lost after saving the order, consider an outbox.
- If reporting queries are slow, consider a read model before separating the
  whole service.
- If the pattern explanation is longer than the business workflow, simplify.

## Knowledge Check

1. What problem should a repository solve in an EF Core application?
2. Why can a generic repository be harmful?
3. How are commands different from queries in CQRS?
4. Why does CQRS not always require separate databases?
5. How is a domain event different from an integration event?
6. Why should events usually be named in the past tense?
7. What kinds of work belong in background processing?
8. Why must event handlers and background jobs often be idempotent?
9. What does the outbox pattern protect against?
10. How can architectural patterns add unnecessary complexity?

## Summary

Architectural patterns are named tools for recurring design pressure. They are
not maturity badges. A pattern earns its place when it makes the system easier
to change, understand, scale, test, or operate.

Repositories can provide a useful persistence boundary, but EF Core already
solves many data-access problems. CQRS separates commands from queries and can
grow from separate classes to separate stores when the pressure justifies it.
Event-driven systems decouple producers and consumers, but require
idempotency, observability, and eventual-consistency thinking. Background
processing keeps slow or retry-prone work out of user requests. Domain events
capture meaningful business facts.

The practical architecture habit is to begin with the smallest useful version
of a pattern. Add complexity only when it removes a more painful complexity
from the system.

The next chapter shifts from technical patterns to professional readiness:
interviews, system design discussions, coding exercises, portfolio building,
certifications, open-source contributions, and staying current in the .NET
ecosystem.

## Sources

- [Azure Architecture Center: CQRS pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs)
- [Azure Architecture Center: Event-driven architecture style](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)
- [Azure Architecture Center: Best practices for background jobs](https://learn.microsoft.com/en-us/azure/architecture/best-practices/background-jobs)
- [Azure Architecture Center: Cloud design patterns](https://learn.microsoft.com/en-us/azure/architecture/patterns/)
- [Martin Fowler: Domain Event](https://martinfowler.com/eaaDev/DomainEvent.html)

## Further Reading

- [Azure Architecture Center: Design patterns for microservices](https://learn.microsoft.com/en-us/azure/architecture/microservices/design/patterns)
- [Azure Architecture Center: Queue-Based Load Leveling pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/queue-based-load-leveling)
- [Azure Architecture Center: Competing Consumers pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/competing-consumers)
- [Azure Architecture Center: Scheduler Agent Supervisor pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/scheduler-agent-supervisor)
- [Martin Fowler: Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
