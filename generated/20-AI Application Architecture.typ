= AI Application Architecture
<ai-application-architecture>
== Chapter Purpose
<chapter-purpose>
AI application architecture is the design discipline for adding language
models, retrieval, tools, and human workflows to ordinary business
software.

The technology exists because large language models changed what
applications can do with unstructured input. A traditional application
usually expects users to click a button, fill a form, call an API, or
upload data in a known format. A model can accept natural language,
summarize documents, draft text, classify messages, extract structure,
answer questions, and decide when a business system should be queried.

That power creates a new architectural problem. A model is not a
database, not a rules engine, not an API, and not a trusted employee. It
is a probabilistic component that needs context, constraints, tools,
evaluation, security, observability, and fallback behavior.

Modern AI application architecture grew quickly after the public release
of chat-oriented large language models. Early applications often sent a
prompt to a model and displayed the answer. Production systems moved
beyond that pattern into retrieval-augmented generation, embeddings,
vector databases, function calling, agent workflows, structured outputs,
safety controls, and model-selection strategies.

The state of the art is changing rapidly, but the durable architecture
is clear: keep business authority in your application and systems of
record, use models for language and reasoning tasks, retrieve trusted
context when needed, call tools through explicit contracts, observe
behavior, evaluate quality, and control cost.

== Where This Fits
<where-this-fits>
AI architecture sits beside the application layer, not above the whole
system as magic.

```text
User or business process
        |
        v
ASP.NET Core application
        |
        +-- authorization and business rules
        |
        +-- AI orchestration layer
        |       |
        |       +-- prompt and instructions
        |       +-- model selection
        |       +-- retrieved context
        |       +-- tool/function contracts
        |       +-- response validation
        |
        +-- systems of record
        |       |
        |       +-- SQL Server
        |       +-- document storage
        |       +-- queues
        |       +-- internal APIs
        |
        +-- vector index
        |
        v
Observability, evaluation, security, and cost controls
```

This chapter begins Part VI. The earlier chapters gave you the
production platform: APIs, data access, security, testing, containers,
cloud hosting, distributed systems, CI/CD, Kubernetes, and
observability. AI applications use all of those foundations.

Chapter 21 will show \.NET implementation options such as
`Microsoft.Extensions.AI`, Semantic Kernel, and AI-powered APIs. This
chapter answers the design questions that should come first: what should
the model do, what context does it need, what tools may it call, how is
the answer checked, and when should the system avoid AI entirely?

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
The closest familiar analogy is a business application that calls a
specialized external service.

You may have integrated payment gateways, address validation APIs,
credit checks, document-generation services, search indexes, reporting
databases, or rules engines. Those systems extend the application, but
they do not own the business. Your application still controls
authorization, validation, transactions, audit, and persistence.

An AI model should be treated the same way.

An LLM is like a language-capable service. It can transform, summarize,
classify, draft, compare, and reason over text, images, or other
supported inputs depending on the model. It should not become the system
of record.

Embeddings are like search keys created from meaning rather than exact
words. Traditional SQL indexes help find rows by values. Full-text
indexes help find documents by words. Vector indexes help find content
that is semantically similar.

Retrieval-augmented generation is like giving an employee the right
folder before asking a question. The model is not expected to remember
your company policy. The application retrieves relevant policy sections
and asks the model to answer using that material.

Function calling is like letting a workflow engine call approved
services through known interfaces. The model can request a tool call,
but the application decides whether to execute it, with what identity,
and how to validate the result.

Agents are like automated assistants that can take multiple steps toward
a goal. The useful analogy is a supervised workflow, not an autonomous
employee with unlimited access.

The analogy breaks down if you expect deterministic behavior. A stored
procedure returns the same result for the same committed data. A
language model may produce different wording, may misunderstand
ambiguous instructions, and may generate confident but incorrect text.
The architecture must expect that.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
An AI application uses a model as one component inside a larger software
system.

It solves these problems:

- understanding natural-language user input;
- summarizing long or messy content;
- drafting human-readable text;
- extracting structured data from unstructured content;
- classifying messages, documents, or records;
- answering questions from trusted sources;
- helping users navigate complex workflows;
- calling approved tools based on user intent.

It does not solve these problems automatically:

- it does not make unreliable data reliable;
- it does not replace authorization;
- it does not replace deterministic business rules;
- it does not remove the need for tests and evaluations;
- it does not guarantee truth;
- it does not protect secrets by default;
- it does not make every workflow cheaper or faster.

The conceptual model is:

```text
User intent
    |
    v
Application policy and security
    |
    v
Context selection
    |
    v
Model request
    |
    v
Validation and tool execution
    |
    v
Business response, persistence, or human review
```

The model is powerful, but the application remains responsible for what
is allowed, what is trusted, what is stored, and what happens next.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
AI architecture has several major parts.

The user or calling process provides intent. That intent may be a chat
message, support ticket, document, email, uploaded file, voice
transcript, or internal workflow event.

The application layer authenticates the caller, authorizes the
operation, loads tenant and user context, applies business rules, and
decides whether AI is appropriate.

The prompt contains instructions and input for the model. A prompt is
not just the user's text. It may include system instructions, developer
instructions, conversation history, retrieved context, output format
requirements, and tool definitions.

The model performs language, reasoning, generation, extraction, or
tool-choice work. Different models have different strengths, costs,
latencies, context limits, modalities, and operational characteristics.

The retrieval pipeline finds relevant external information. It may query
SQL Server, a search engine, document storage, a vector database, or
internal APIs.

The embedding model converts text or other supported content into
vectors that can be compared by semantic similarity.

The vector database or vector index stores embeddings with document
chunks, metadata, source identifiers, permissions, and freshness
information.

Function calling gives the model a set of structured tool contracts. The
model can request a function with arguments. The application validates
the request, executes approved code or APIs, and returns results to the
model or the user.

An agent workflow coordinates multiple model calls, retrieval steps,
tool calls, validations, and decisions. Agents can be useful, but they
expand the failure surface because the system may take several actions
before returning.

Observability and evaluation measure behavior. Production AI systems
should track latency, cost, token usage, tool calls, retrieval quality,
failures, safety blocks, user feedback, and outcome quality.

Failure boundaries include prompt injection, stale retrieved context,
incorrect model output, missing citations, tool misuse, permission
leakage, model outages, rate limits, high latency, runaway cost, weak
evaluation data, and user overtrust.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
An LLM is a model trained to predict and generate language-like output
from input context. In application architecture, the important point is
not the training math. The important point is that the model produces
likely text or structured output based on its training, instructions,
and supplied context.

A token is a unit of text used by the model. Cost, latency, and context
limits are usually measured in tokens. Long documents, long chat
histories, and large retrieved context increase token usage.

An embedding is a numeric representation of meaning. Similar pieces of
content produce vectors that are near each other in vector space. That
enables semantic search.

Retrieval-augmented generation, usually called RAG, uses retrieval to
ground a model response in external content:

```text
User asks question
      |
      v
Application rewrites or analyzes query
      |
      v
Search retrieves relevant chunks
      |
      v
Application builds prompt with sources
      |
      v
Model answers using retrieved context
      |
      v
Application validates, cites, logs, and returns
```

A document chunk is a smaller section of a larger source. Chunking
exists because models and search systems work better when they receive
focused context instead of entire documents.

Metadata describes the chunk: source, title, version, tenant, security
label, date, author, product, or business category. Metadata lets the
application filter before search and explain where an answer came from.

Function calling uses structured contracts. A model might be given a
tool such as:

```json
{
  "name": "get_order_status",
  "description": "Get the current status of an order by order ID.",
  "parameters": {
    "type": "object",
    "properties": {
      "orderId": {
        "type": "integer",
        "description": "The internal order identifier."
      }
    },
    "required": ["orderId"]
  }
}
```

The model does not directly query the database. It requests
`get_order_status` with arguments. The application validates the
arguments, checks authorization, calls the real service, and decides
what result may be returned.

Structured outputs constrain model responses to a schema. They are
useful when the application needs JSON that can be validated and
processed.

Model selection is the practice of choosing a model based on task. A
good architecture may use one model for complex reasoning, another for
fast classification, another for embeddings, and another for multimodal
input.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
The developer workflow should begin with a use case, not a model.

```text
Define user problem
      |
      v
Decide whether AI is appropriate
      |
      v
Identify trusted data and allowed actions
      |
      v
Design prompt, retrieval, and tool boundaries
      |
      v
Build smallest evaluation set
      |
      v
Prototype
      |
      v
Measure quality, latency, cost, and safety
      |
      v
Harden for production
```

Start with narrow tasks:

- summarize a support ticket;
- classify an incoming email;
- draft a customer-safe response;
- answer questions from a known policy repository;
- extract fields from a contract;
- choose from a small set of approved workflow actions.

For RAG, the workflow is:

+ Identify trusted source documents.
+ Split documents into chunks.
+ Generate embeddings for chunks.
+ Store vectors, text, source identifiers, and metadata.
+ At query time, retrieve relevant chunks.
+ Build a prompt that includes the user question and retrieved context.
+ Ask the model for an answer with citations or source references.
+ Validate the answer and log enough telemetry to improve the system.

For function calling, the workflow is:

+ Define the business operation as a narrow tool.
+ Describe the tool clearly.
+ Validate model-proposed arguments.
+ Apply authorization using the user's identity.
+ Execute the real API or service.
+ Return a limited result to the model.
+ Audit the operation.

For agents, the workflow adds planning and limits:

+ Define the goal.
+ Define allowed tools.
+ Set step limits, timeouts, and budgets.
+ Require confirmation for important actions.
+ Store intermediate state.
+ Observe every step.
+ Provide human review where consequences are significant.

Do not wait until production to evaluate. Create a small test set of
realistic inputs, expected outcomes, unacceptable outputs, and edge
cases. AI tests are often less like exact unit tests and more like
regression checks for behavior.

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production AI systems need the same engineering discipline as any other
distributed system, plus a few AI-specific controls.

Configuration includes model names, deployment names, API endpoints,
token budgets, timeouts, retry policies, sampling settings, retrieval
settings, chunk sizes, similarity thresholds, and feature flags.

Secrets include API keys, managed identity configuration, search
credentials, storage credentials, and tool access credentials. Do not
place secrets in prompts, logs, retrieved context, or evaluation
datasets.

Security includes authentication, authorization, data minimization,
prompt injection defense, output validation, tool allowlists, tenant
isolation, content filtering, audit logging, and human approval for
consequential actions.

Reliability includes retries with backoff, circuit breakers, fallback
responses, cached non-sensitive results, graceful degradation,
model-provider failover where appropriate, queue-based background
processing, and clear user messages when AI is unavailable.

Deployment should separate prompt changes, retrieval changes, model
changes, and application code changes. A prompt is production behavior.
Treat important prompt and tool-contract changes with review,
versioning, testing, and rollback.

Observability should include latency, token usage, cost, model name,
prompt version, retrieved document IDs, tool calls, validation failures,
content filter results, user feedback, and downstream business outcome.
Avoid logging full sensitive prompts and responses unless there is a
controlled retention and privacy policy.

Scaling depends on rate limits, token volume, model latency,
vector-search capacity, document-ingestion throughput, and tool-call
throughput. More app instances do not automatically create more model
capacity.

Persistence includes conversation history, retrieved source references,
document indexes, embeddings, evaluation results, and audit records.
Store the minimum needed for the business purpose, and apply retention
rules.

Cost includes model input tokens, output tokens, embeddings, vector
storage, search operations, tool calls, document ingestion,
observability, human review, and engineering time. Cost should be
visible before a feature is broadly enabled.

Local development can use small examples, local test documents, mocked
tool calls, and development model deployments. Production needs real
permissions, rate limits, redaction, monitoring, evaluations, fallback
behavior, and audit.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use AI when the problem involves language, ambiguity, summarization,
classification, extraction, semantic search, reasoning over documents,
or a natural-language interface over existing systems.

Do not use AI when deterministic code, SQL, full-text search, a rules
engine, a form, a report, or a simple workflow would be cheaper,
clearer, faster, and more reliable.

RAG is useful when answers should come from private, current, or
domain-specific documents. It is not necessary when the task is
transformation, classification, or extraction from the user's provided
input.

Fine-tuning may be useful for specialized style, classification, or
repeated patterns, but it is not the first answer for adding private
facts. Private facts usually belong in retrieval or tools, not in model
weights.

Agents are useful when a task requires multiple steps and tool use. They
are not appropriate when the workflow must be deterministic, fully
auditable, or high consequence without approval gates.

Function calling is useful when the model needs to interact with real
systems. It should be narrow, validated, authorized, and observable.

Open-source models can provide more deployment control, data locality,
and cost predictability at scale. They also require model hosting, GPU
capacity, serving infrastructure, evaluation, upgrades, and security
patching.

Managed model APIs reduce hosting burden and provide fast access to
advanced capabilities. They create dependency on provider availability,
pricing, regions, rate limits, data handling terms, and model lifecycle
changes.

Common overengineering mistakes:

- adding chat when a button would be better;
- using AI as the source of truth;
- skipping authorization on retrieved documents;
- giving an agent broad tool access;
- relying on prompt wording instead of validation;
- storing sensitive prompts without a policy;
- ignoring token cost and latency;
- changing models without evaluation;
- treating a demo-quality RAG pipeline as production-ready.

The state-of-the-art direction is task-specific model selection,
grounded RAG, structured outputs, explicit tool contracts, agent
workflows with guardrails, automated evaluation, privacy-aware
telemetry, and human review for actions that affect money, legal status,
safety, security, or customer trust.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use AI architecture questions to test whether you can
integrate models responsibly into real applications.

Concepts commonly tested:

- LLMs;
- tokens and context windows;
- embeddings;
- vector databases;
- RAG;
- chunking;
- metadata filtering;
- prompt injection;
- function calling;
- structured outputs;
- agents;
- model selection;
- evaluation;
- latency, cost, and safety tradeoffs.

Representative questions:

- "When would you use RAG instead of fine-tuning?"
- "What is an embedding?"
- "What does a vector database store?"
- "How would you let an AI assistant check order status?"
- "How do you prevent a model from exposing documents a user cannot
  access?"
- "What is prompt injection?"
- "When should an agent ask for human confirmation?"
- "How would you choose between a fast model and a more capable model?"
- "What would you monitor in production?"

A strong answer keeps authority in the application:

#quote(block: true)[
"I would use the model for language understanding and generation, but
keep authorization, business rules, tool execution, and persistence in
the application. For company knowledge I would use RAG with
permission-filtered retrieval. For actions I would expose narrow
function calls, validate arguments, audit execution, and require
approval for consequential changes."
]

Common misconceptions:

- "The model remembers our documents after we send them once."
- "RAG guarantees correct answers."
- "A vector database replaces SQL Server."
- "Prompt instructions are enough security."
- "An agent should have access to every internal API."
- "The most capable model is always the best model."
- "If the model returns JSON, the application can trust it."

Small design scenario:

You need to add an assistant to an internal order-management
application. It should answer questions about order policies, summarize
order history, and let authorized support staff check shipment status.

A good design would use RAG for policy documents, SQL Server or internal
APIs for order history, function calling for shipment status,
authorization filters before retrieval and tool execution, structured
outputs for machine-readable results, audit logs for tool calls, prompt
and model versioning, user feedback, and dashboards for latency, cost,
errors, and answer quality.

The strong answer avoids making the model the database, the security
boundary, or the final authority for consequential actions.

== Hands-On Lab
<hands-on-lab>
Objective:

Design an AI architecture for a support assistant before writing
implementation code.

Prerequisites:

- A basic understanding of ASP.NET Core APIs.
- Familiarity with SQL Server-backed business applications.
- Familiarity with observability concepts from Chapter 19.

Steps:

+ Choose a narrow support scenario, such as answering return-policy
  questions and checking order status.

+ Identify the trusted sources:

  ```text
  return policy documents
  order database
  shipment API
  support knowledge base
  ```

+ Classify each source:

  ```text
  retrieved context
  system of record
  tool/function
  human-only reference
  ```

+ Draw the request flow from user message to final answer.

+ Decide which parts use RAG and which parts use function calling.

+ Define at least three tool boundaries, such as:

  ```text
  get_order_summary(orderId)
  get_shipment_status(orderId)
  create_support_note(orderId, note)
  ```

+ Mark which tools require human confirmation.

+ Define what telemetry must be captured:

  ```text
  model name
  prompt version
  retrieved document IDs
  tool calls
  latency
  token usage
  validation failures
  user feedback
  ```

+ Define five evaluation cases, including one prompt-injection attempt
  and one unauthorized-document attempt.

+ Decide when the assistant should refuse, ask for clarification, or
  hand off to a human.

Expected results:

- A clear architecture diagram.
- A list of trusted sources.
- A separation between retrieval, tools, and systems of record.
- Tool contracts with authorization and confirmation rules.
- An evaluation checklist.
- A telemetry plan.

Validation commands:

No command is required for this architecture lab. If you want to capture
the design in the repository, create a Markdown design note in a scratch
location or future sample folder after the chapter exercise is complete.

Troubleshooting notes:

- If the assistant needs private facts, use retrieval or tools.
- If the assistant needs to change business data, require explicit tool
  contracts and authorization.
- If users could be harmed by a wrong answer, add human review or
  refusal behavior.
- If cost is unclear, estimate token volume before implementation.
- If quality is subjective, create evaluation examples before choosing a
  model.

== Knowledge Check
<knowledge-check>
+ Why should an AI model not be treated as the system of record?
+ How are embeddings different from SQL indexes and full-text indexes?
+ What problem does RAG solve?
+ Why is metadata important in a vector index?
+ How does function calling differ from letting a model directly access
  a database?
+ When is an agent useful, and when is it risky?
+ Why is model selection an architectural decision rather than only a
  coding detail?
+ What should be evaluated before changing a prompt or model?
+ How can prompt injection affect a RAG application?
+ What production telemetry would you collect for an AI assistant?

== Summary
<summary>
AI application architecture is the careful integration of language
models into ordinary business systems. The application still owns
identity, authorization, business rules, persistence, transactions,
audit, and user experience. The model contributes language
understanding, generation, summarization, classification, extraction,
and tool-choice capability.

The main architectural building blocks are LLMs, prompts, embeddings,
vector indexes, RAG pipelines, function calls, structured outputs,
agents, evaluations, and observability. Each has a specific job. RAG
supplies trusted context. Function calling gives the model controlled
access to actions. Agents coordinate multiple steps. Evaluation and
telemetry keep the system honest after the demo.

The most important design habit is boundary keeping. Do not let the
model become the database, the security layer, the workflow engine, or
the final authority for consequential actions. Use it where language and
reasoning help, then surround it with the same engineering discipline
used for the rest of the modern \.NET system.

Chapter 21 turns this architecture into \.NET implementation patterns
using `Microsoft.Extensions.AI`, Semantic Kernel, ASP.NET Core APIs, and
integration with existing business applications.

== Sources
<sources>
- #link("https://platform.openai.com/docs/quickstart/make-your-first-api-request")[OpenAI API developer quickstart]
- #link("https://help.openai.com/en/articles/8555517-function-calling-in-the-openai-api")[OpenAI function calling guide]
- #link("https://platform.openai.com/docs/models/default-usage-policies-by-endpoint")[OpenAI API data controls]
- #link("https://platform.openai.com/docs/models")[OpenAI model documentation]
- #link("https://learn.microsoft.com/en-us/azure/developer/ai/augment-llm-rag-fine-tuning")[Microsoft guidance on augmenting LLMs with RAG or fine-tuning]
- #link("https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-generate-embeddings")[Azure Architecture Center: RAG generate embeddings phase]
- #link("https://learn.microsoft.com/en-us/semantic-kernel/")[Semantic Kernel documentation]

== Further Reading
<further-reading>
- #link("https://platform.openai.com/docs/guides/text")[OpenAI text generation documentation]
- #link("https://platform.openai.com/docs/guides/embeddings")[OpenAI embeddings documentation]
- #link("https://platform.openai.com/docs/guides/structured-outputs")[OpenAI structured outputs documentation]
- #link("https://platform.openai.com/docs/guides/agents")[OpenAI agents documentation]
- #link("https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-solution-design-and-evaluation-guide")[Azure Architecture Center RAG guidance]
- #link("https://learn.microsoft.com/en-us/semantic-kernel/concepts/")[Microsoft Semantic Kernel concepts]
