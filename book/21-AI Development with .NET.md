# AI Development with .NET

## Chapter Purpose

Chapter 20 explained the architecture of AI applications: keep business
authority in the application, use models for language work, retrieve trusted
context, expose approved tools, validate outputs, observe behavior, and control
cost.

This chapter turns that architecture into .NET development practice.

.NET did not become an AI platform by replacing ASP.NET Core, dependency
injection, logging, configuration, background services, or testing. It became a
practical AI application platform by adding AI abstractions and orchestration
libraries that fit into those existing patterns.

The problem this chapter resolves is tool choice. A modern .NET developer can
call a model API directly, use `Microsoft.Extensions.AI` abstractions, use
Semantic Kernel, use an agent framework, or call cloud-specific SDKs. Those
choices are not interchangeable. They sit at different levels.

`Microsoft.Extensions.AI` exists to give .NET applications common abstractions
for generative AI components such as chat clients and embedding generators. It
follows familiar .NET patterns: dependency injection, middleware, telemetry,
caching, and testable interfaces.

Semantic Kernel exists at a higher orchestration level. It helps organize
prompts, plugins, services, memory, filters, and agent-style workflows. It is
useful when an application needs more than one model call and a few lines of
provider code.

The state-of-the-art direction in .NET AI development is provider-neutral
abstractions for basic integration, orchestration frameworks for multi-step
workflows, explicit tool contracts, RAG pipelines, OpenTelemetry, evaluation,
and production security controls.

## Where This Fits

AI development with .NET sits inside the application layer.

```text
ASP.NET Core API or worker
        |
        +-- Controllers, endpoints, or jobs
        |
        +-- Application services
        |       |
        |       +-- IChatClient
        |       +-- IEmbeddingGenerator
        |       +-- prompt templates
        |       +-- tool/function services
        |
        +-- Semantic Kernel or agent workflow
        |
        +-- SQL Server, search, storage, queues, APIs
        |
        v
Model provider, Azure OpenAI, OpenAI, local model, or other AI service
```

The model provider remains outside the application. Your .NET code owns
identity, authorization, validation, tool execution, persistence, telemetry,
and user experience.

This chapter follows AI architecture because implementation choices should be
driven by architecture. It prepares for the architecture chapters that follow
because AI features still live inside monoliths, modular monoliths,
microservices, background workers, and distributed systems.

## Connection to the Reader's Existing Model

The familiar model is dependency injection around an external service.

In a traditional .NET application, you might define an interface for payment
processing, inject an implementation, configure credentials, log calls, retry
transient failures, mock the interface in tests, and keep business rules in
application services.

`Microsoft.Extensions.AI` brings that same habit to AI. Instead of scattering
provider-specific model calls throughout controllers, code can depend on an
abstraction such as `IChatClient`.

Semantic Kernel is closer to a workflow and integration layer. If
`IChatClient` is like an HTTP client abstraction for model calls, Semantic
Kernel is closer to a small orchestration runtime that knows about prompts,
plugins, tool calls, model services, and conversations.

Native plugins in Semantic Kernel feel familiar if you have exposed C# methods
through Web API controllers, background jobs, or service classes. You write
ordinary C# methods, describe them clearly, and let the AI orchestration layer
make them available as callable capabilities.

The analogy breaks down if you treat the model like a deterministic service.
An address validation API either returns a valid result or an error. A model
may return plausible but wrong output, ask to call the wrong tool, or require a
clarifying question. The .NET code around the model must handle uncertainty.

## Layer 1 — Conceptual Model

AI development with .NET is the practice of adding model-backed capabilities
to .NET applications using familiar application patterns.

It solves these problems:

- calling AI providers from ASP.NET Core and worker services;
- isolating provider-specific SDK code;
- testing AI-facing application logic;
- generating embeddings for retrieval;
- adding prompts and structured outputs;
- exposing C# functions as model-callable tools;
- building RAG workflows;
- integrating AI into existing business applications.

It does not solve these problems automatically:

- it does not make model output correct;
- it does not remove the need for authorization;
- it does not choose the right architecture;
- it does not guarantee low cost or low latency;
- it does not make private data safe by default;
- it does not replace evaluations;
- it does not make every agent workflow production-ready.

The conceptual model is:

```text
.NET application code
      |
      v
AI abstraction or orchestration library
      |
      v
Provider SDK or service endpoint
      |
      v
Model, embedding model, or agent runtime
```

Use the lowest layer that solves the problem. A simple classification endpoint
may only need `IChatClient`. A multi-step support assistant with tools,
retrieval, and conversation state may benefit from Semantic Kernel or an agent
framework.

## Layer 2 — System Relationships

The ASP.NET Core endpoint or background service receives the request. It
authenticates the caller, authorizes the operation, loads application data, and
calls an application service.

The application service owns the use case. It decides which prompt to use,
which context to retrieve, which model capability is needed, what tools are
allowed, and how to validate the result.

`IChatClient` represents a chat-capable model interaction. Application code can
depend on this interface instead of a concrete provider client.

`IEmbeddingGenerator` represents embedding generation. It lets application
code create vectors for text or other supported input and store them in a
search or vector system.

Middleware in the AI client pipeline can add cross-cutting concerns such as
logging, telemetry, caching, function invocation, rate limiting, or custom
policy.

Semantic Kernel organizes services and plugins. A kernel can hold AI service
configuration, prompt execution, plugin functions, filters, and workflow
behavior.

A plugin exposes capabilities to the model. A plugin might wrap an order
service, shipment API, policy lookup, calendar operation, or document tool.

The model provider executes the model request. It may be OpenAI, Azure OpenAI,
Azure AI Foundry, a local model through Ollama, GitHub Models, Amazon Bedrock,
Google Gemini, or another provider supported by the application's libraries.

Failure boundaries include provider outages, rate limits, invalid credentials,
model changes, prompt regressions, malformed structured output, unsafe tool
arguments, unauthorized context retrieval, missing embeddings, and telemetry
blind spots.

## Layer 3 — Core Mechanics

At the lowest useful level, application code asks a chat client for a response.

```csharp
public sealed class SupportDraftService
{
    private readonly IChatClient _chatClient;

    public SupportDraftService(IChatClient chatClient)
    {
        _chatClient = chatClient;
    }

    public async Task<string> DraftReplyAsync(
        string customerMessage,
        CancellationToken cancellationToken)
    {
        var response = await _chatClient.GetResponseAsync(
            $"""
            Draft a concise support reply.

            Customer message:
            {customerMessage}
            """,
            cancellationToken: cancellationToken);

        return response.Text;
    }
}
```

The example is intentionally small. In production, the prompt would usually be
versioned, the input would be validated, sensitive data would be minimized, and
the output would be checked before returning it to a user.

For embeddings, application code sends text to an embedding generator and
stores the resulting vector with source metadata:

```csharp
public sealed class PolicyIndexingService
{
    private readonly IEmbeddingGenerator<string, Embedding<float>> _embeddings;
    private readonly IPolicyVectorStore _store;

    public PolicyIndexingService(
        IEmbeddingGenerator<string, Embedding<float>> embeddings,
        IPolicyVectorStore store)
    {
        _embeddings = embeddings;
        _store = store;
    }

    public async Task IndexChunkAsync(
        PolicyChunk chunk,
        CancellationToken cancellationToken)
    {
        var vector = await _embeddings.GenerateAsync(
            chunk.Text,
            cancellationToken: cancellationToken);

        await _store.UpsertAsync(
            chunk.Id,
            chunk.Text,
            vector.Vector,
            chunk.Metadata,
            cancellationToken);
    }
}
```

A RAG endpoint combines retrieval and chat:

```text
API receives question
  |
  v
Authorize user
  |
  v
Retrieve allowed policy chunks
  |
  v
Build prompt with retrieved context
  |
  v
Ask model for answer
  |
  v
Return answer with source references
```

Semantic Kernel adds an orchestration layer. A simplified native plugin might
look like this:

```csharp
public sealed class OrderPlugin
{
    private readonly IOrderService _orders;

    public OrderPlugin(IOrderService orders)
    {
        _orders = orders;
    }

    [KernelFunction]
    [Description("Gets the shipment status for an order the user is allowed to view.")]
    public Task<string> GetShipmentStatusAsync(
        [Description("The internal order ID.")] int orderId,
        CancellationToken cancellationToken)
    {
        return _orders.GetShipmentStatusAsync(orderId, cancellationToken);
    }
}
```

The method is still ordinary C#. The important production question is whether
the underlying service checks authorization, validates the order ID, audits
access, and returns only data the model should see.

## Layer 4 — Developer Workflow

The .NET AI workflow begins with the smallest useful slice.

```text
Choose one use case
      |
      v
Create an application service
      |
      v
Inject IChatClient or IEmbeddingGenerator
      |
      v
Add prompt and validation
      |
      v
Add retrieval or tools only when needed
      |
      v
Write tests and evaluation cases
      |
      v
Add telemetry and production controls
```

For a simple AI-powered API:

1. Create an ASP.NET Core project.
2. Add the AI client packages required by the selected provider.
3. Register the chat client in dependency injection.
4. Create an application service that depends on `IChatClient`.
5. Add an endpoint that calls the service.
6. Validate input length and content.
7. Add logging and telemetry.
8. Test normal, edge, and unsafe inputs.

For a RAG feature:

1. Build an ingestion path for trusted documents.
2. Chunk the documents.
3. Generate embeddings.
4. Store text, vectors, source IDs, and metadata.
5. Query the vector store at request time.
6. Filter results by tenant and authorization.
7. Build a prompt using retrieved context.
8. Return source references with the answer.

For a Semantic Kernel workflow:

1. Register model services.
2. Create or load prompt templates.
3. Add native plugins for approved business actions.
4. Add filters or middleware for logging, authorization, and validation.
5. Invoke the workflow from an application service.
6. Record tool calls, prompt version, model name, and outcome.

Useful commands depend on the chosen packages, but the development rhythm is
ordinary .NET:

```bash
dotnet new webapi -n SupportAssistant
dotnet add package Microsoft.Extensions.AI
dotnet build
dotnet test
dotnet run
```

When using templates or samples, treat them as starting points. Before using
them in production, review identity, authorization, data retention, model
configuration, logging, cost, and deployment settings.

## Layer 5 — Production Usage

Production .NET AI development should feel like production .NET development:
configuration, security, reliability, observability, testing, deployment, and
cost all matter.

Configuration includes provider endpoints, deployment names, model names,
temperature or reasoning settings, token limits, timeouts, retry policy,
prompt versions, retrieval settings, embedding model choices, and feature
flags.

Secrets include API keys, managed identity settings, search credentials,
storage connection strings, and tool credentials. Prefer managed identity or
secure secret stores when available. Never put secrets in prompts.

Security includes normal ASP.NET Core authentication and authorization, plus
AI-specific controls: prompt-injection defenses, tool allowlists, output
validation, tenant-filtered retrieval, redaction, content filtering, and audit
logging.

Reliability includes cancellation tokens, timeouts, retries with backoff,
circuit breakers, graceful fallback responses, queue-based background work,
provider health checks, and safe behavior when a model or vector store is
unavailable.

Deployment should version prompts, tool contracts, retrieval pipelines, and
model choices. A model change can alter behavior even when application code is
unchanged.

Observability should use the Chapter 19 habits. Track request latency, model
latency, token usage, cost, model name, prompt version, retrieved document IDs,
tool calls, validation failures, safety decisions, and user feedback.

Scaling depends on both .NET application capacity and AI-provider capacity.
Increasing pods or app instances does not remove model rate limits. Use
queues, caching, throttling, and backpressure for expensive or bursty
workloads.

Persistence includes conversation history, embeddings, source documents,
evaluation cases, audit records, prompt versions, and user feedback. Store only
what the business needs and apply retention rules.

Cost management includes token budgets, embedding costs, vector storage,
search operations, tool-call costs, observability storage, and human review.
Expose cost signals before the feature becomes widely used.

Local development may use test providers, small document sets, console
exporters, fake tool implementations, and narrow evaluation cases. Production
requires real identity, private networking where appropriate, secret
management, monitoring, evaluation, rollout controls, and incident response.

## Layer 6 — Tradeoffs and Alternatives

Use `Microsoft.Extensions.AI` when you want provider-neutral abstractions,
dependency injection, testability, middleware, telemetry, caching, or the
ability to swap concrete model providers without rewriting application
services.

Use a provider SDK directly when the feature depends heavily on provider-specific
capabilities and the portability layer would hide important behavior.

Use Semantic Kernel when the application needs prompt orchestration, plugins,
function calling, multi-step workflows, memory concepts, filters, or agent-like
composition.

Use a simpler direct call when the feature is a narrow one-step task and the
extra orchestration layer would add complexity without value.

Use an agent framework when the workflow requires multi-step planning, tool
use, conversation state, collaboration between agents, or reusable agent
definitions. Avoid agents for deterministic workflows that should be ordinary
C# code.

Use RAG when answers need private or current business context. Do not use RAG
for every AI feature; classification, extraction, drafting, and summarization
may only need the user's input.

Open-source or local model options can reduce data-sharing concerns and offer
deployment control. They also require hosting, GPU capacity, model management,
serving infrastructure, and evaluation.

Managed providers offer fast access to capable models and operational support.
They introduce dependency on provider availability, pricing, rate limits,
regions, data-handling terms, and model lifecycle.

Common overengineering mistakes:

- wrapping every model call in a custom framework before one feature exists;
- choosing an agent for a one-step task;
- exposing broad plugins without authorization checks;
- putting business rules in prompts instead of C#;
- skipping evaluation because the demo looked good;
- logging sensitive prompts and responses;
- assuming provider-neutral abstractions remove all provider differences;
- using production documents in local experiments without a data policy.

The state-of-the-art direction is layered development: provider-neutral
interfaces for common calls, orchestration frameworks for workflows, explicit
tools, RAG with permission-aware retrieval, OpenTelemetry, automated
evaluations, secure deployment, and human approval for consequential actions.

## Layer 7 — Interview Perspective

Interviewers use .NET AI questions to test whether you can build model-backed
features without abandoning normal engineering discipline.

Concepts commonly tested:

- `IChatClient`;
- `IEmbeddingGenerator`;
- dependency injection;
- provider SDKs;
- Semantic Kernel;
- plugins;
- function calling;
- RAG implementation;
- prompt versioning;
- evaluation;
- telemetry;
- authorization around tools and retrieval;
- cost and latency controls.

Representative questions:

- "Why would you use `Microsoft.Extensions.AI`?"
- "When would you call the provider SDK directly?"
- "What problem does Semantic Kernel solve?"
- "How do you expose C# code as a tool safely?"
- "How would you build a RAG endpoint in ASP.NET Core?"
- "How do you test AI behavior?"
- "What should be logged or measured for an AI feature?"
- "How do you keep a model from seeing documents the user cannot access?"

A strong answer separates layers:

> "I would keep the ASP.NET Core application responsible for authentication,
> authorization, validation, and persistence. For simple model calls I would
> depend on `IChatClient` so the application service is testable and less tied
> to one provider. For multi-step workflows I might use Semantic Kernel with
> narrow plugins, but every tool would still enforce authorization and audit
> access."

Common misconceptions:

- "`Microsoft.Extensions.AI` is a model provider."
- "Semantic Kernel replaces ASP.NET Core services."
- "A plugin method is safe because it is only called by the model."
- "RAG means the model has learned our documents."
- "A prompt change is not a production change."
- "Mocks are enough to prove answer quality."
- "Provider-neutral code means all models behave the same."

Small design scenario:

You need to add an AI feature to an existing ASP.NET Core order-management
application. The assistant should summarize a customer conversation, answer
questions from support policy documents, and let authorized users check
shipment status.

A good design would use `IChatClient` for model calls, an embedding generator
and vector store for policy retrieval, normal SQL Server or internal APIs for
order data, a narrow shipment-status plugin or function, authorization checks
before retrieval and tool execution, prompt versioning, evaluation cases,
OpenTelemetry, and cost tracking.

The strong answer keeps the model behind application services instead of
letting controllers or prompts own business behavior.

## Hands-On Lab

Objective:

Design and scaffold a small ASP.NET Core AI endpoint that can be implemented
with `Microsoft.Extensions.AI` and later expanded with Semantic Kernel.

Prerequisites:

- .NET SDK installed.
- Basic ASP.NET Core knowledge.
- Access to a development AI provider or a test double.
- The architecture design from Chapter 20.

Steps:

1. Create a new web API project:

   ```bash
   dotnet new webapi -n SupportAssistant
   cd SupportAssistant
   ```

2. Add the common AI abstractions package:

   ```bash
   dotnet add package Microsoft.Extensions.AI
   ```

3. Add the provider-specific package required by your chosen model provider.

4. Register an `IChatClient` in dependency injection.

5. Create a `SupportDraftService` that depends on `IChatClient`.

6. Add an endpoint such as:

   ```text
   POST /support/draft-reply
   ```

7. Validate input length and reject empty requests.

8. Add structured logging for request ID, prompt version, model name, latency,
   and validation result.

9. Write tests for:

   ```text
   empty input
   long input
   normal support request
   unsafe or policy-breaking request
   provider failure
   ```

10. Sketch the next step: either add RAG for policy documents or add a narrow
    Semantic Kernel plugin for shipment status.

Expected results:

- The endpoint calls an application service, not the provider directly.
- The service depends on an AI abstraction.
- Inputs are validated.
- AI-provider configuration is outside source code.
- Logs include operational context without sensitive prompt content.
- Tests cover behavior around the AI boundary.

Validation commands:

```bash
dotnet build
dotnet test
dotnet run
curl -X POST http://localhost:5000/support/draft-reply \
  -H "Content-Type: application/json" \
  -d '{"message":"My order is late. Can someone help?"}'
```

Troubleshooting notes:

- If package APIs differ, check the current provider documentation and keep
  the application service boundary the same.
- If authentication fails, verify secrets or managed identity configuration.
- If responses are slow, measure model latency separately from application
  latency.
- If tests are brittle, mock the AI abstraction and evaluate model behavior
  separately with sample cases.
- If the endpoint leaks sensitive data, fix logging and prompt construction
  before adding more features.

## Knowledge Check

1. Why is `IChatClient` useful in an ASP.NET Core application?
2. When is a direct provider SDK call better than a provider-neutral
   abstraction?
3. What problem does `IEmbeddingGenerator` solve?
4. How is Semantic Kernel different from `Microsoft.Extensions.AI`?
5. Why should C# plugin methods still enforce authorization?
6. What belongs in application code instead of a prompt?
7. How would you test an application service that depends on an AI model?
8. Why should prompt versions be observable in production?
9. What telemetry would you capture for a RAG endpoint?
10. When should an AI workflow use a background queue instead of a direct HTTP
    request?

## Summary

AI development with .NET is not a separate universe from the rest of modern
.NET. It uses the same foundation: ASP.NET Core, dependency injection,
configuration, logging, testing, background services, security, deployment,
and observability.

`Microsoft.Extensions.AI` provides common abstractions such as chat clients and
embedding generators so application code can stay testable and less tightly
coupled to one provider. Semantic Kernel sits above that layer when prompts,
plugins, tool calls, memory, filters, and agent-style workflows need
orchestration.

The implementation habit is to keep AI behind application services. Controllers
and endpoints should not become prompt assembly scripts, and prompts should not
become business-rule engines. Use models for language work, use C# for
authority and validation, use retrieval for trusted context, use tools for
approved actions, and use telemetry and evaluations to understand behavior.

The next chapter moves from AI-specific implementation back to broad
architecture: monoliths, modular monoliths, microservices, scale, reliability,
performance, and cost.

## Sources

- [Develop .NET apps with AI features](https://learn.microsoft.com/en-us/dotnet/ai/overview)
- [Microsoft.Extensions.AI libraries](https://learn.microsoft.com/en-us/dotnet/ai/microsoft-extensions-ai)
- [AI apps for .NET developers](https://learn.microsoft.com/en-us/dotnet/ai/)
- [Quickstart: Create a .NET AI app using the AI app template](https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/ai-templates)
- [Semantic Kernel documentation](https://learn.microsoft.com/en-us/semantic-kernel/)
- [Add native code as a Semantic Kernel plugin](https://learn.microsoft.com/en-us/semantic-kernel/concepts/plugins/adding-native-plugins)
- [Semantic Kernel Agent Framework](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/)
- [OpenAI API developer quickstart](https://platform.openai.com/docs/quickstart/make-your-first-api-request)

## Further Reading

- [Get started with .NET AI and the Model Context Protocol](https://learn.microsoft.com/en-us/dotnet/ai/get-started-mcp)
- [Microsoft.Extensions.AI API reference](https://learn.microsoft.com/en-us/dotnet/api/microsoft.extensions.ai)
- [Semantic Kernel concepts](https://learn.microsoft.com/en-us/semantic-kernel/concepts/)
- [OpenAI function calling guide](https://help.openai.com/en/articles/8555517-function-calling-in-the-openai-api)
- [OpenAI structured outputs documentation](https://platform.openai.com/docs/guides/structured-outputs)
