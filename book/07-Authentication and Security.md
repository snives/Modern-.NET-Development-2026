# Authentication and Security

## Chapter Purpose

Chapter 6 gave the application durable state. Once an API can read and change
business data, the next question is unavoidable: who is allowed to do it?

Authentication and security exist because useful systems have boundaries.
Some callers are anonymous. Some are employees. Some are customers. Some are
services. Some can read. Some can write. Some can approve payments, reset
passwords, view audit records, or administer tenants. The application must
know the difference.

For a developer coming from Windows, IIS, SQL Server, and enterprise
application development, the familiar model may involve Windows Authentication,
Active Directory groups, IIS settings, SQL logins, service accounts, and
connection strings protected on a server. Those ideas still matter, but modern
.NET applications commonly run behind reverse proxies, in containers, on cloud
platforms, and across identity providers. Security is no longer only a server
setting. It is an application, platform, identity, deployment, and operations
concern.

ASP.NET Core provides authentication and authorization building blocks. OAuth
2.0 and OpenID Connect provide common protocol patterns. JSON Web Tokens, or
JWTs, are commonly used to carry identity and authorization claims to APIs.
Secrets management keeps credentials and sensitive configuration out of source
control and ordinary application files.

This chapter introduces authentication, authorization, JWT, OAuth, OpenID
Connect, and secrets management at the level needed for modern .NET API
development. It does not make you an identity specialist. It gives you the
map, terminology, and basic mechanics so later chapters can build securely.

## Where This Fits

Security surrounds the HTTP and data boundaries introduced in Chapters 5 and
6.

```text
Client
  |
  | obtains token or session through identity system
  v
ASP.NET Core API
  |
  +-- Authentication: who is the caller?
  |
  +-- Authorization: what may this caller do?
  |
  +-- Application service
  |
  +-- Data access
  |
  v
SQL Server, cache, queue, external API, or AI service
```

Security also touches deployment:

```text
Source control -> CI/CD -> runtime platform
      |              |             |
      v              v             v
  no secrets     protected     managed identity,
  in code        variables     secret store,
                                TLS, audit
```

The application cannot treat authentication as a decorative endpoint attribute
added at the end. Authentication affects request handling. Authorization
affects business rules. Secrets affect configuration. Identity affects
database, cloud, queue, and external API access.

## Connection to the Reader's Existing Model

Windows enterprise systems often used a perimeter-oriented security model.

The application ran on a known Windows server. IIS might require Windows
Authentication. Users belonged to Active Directory groups. The application pool
identity accessed files or SQL Server. Connection strings lived in
configuration files protected by server permissions. The network boundary did
some of the work.

Modern systems use many of the same ideas with different shapes.

An application pool identity maps conceptually to a service identity or
managed identity. It answers, "What is this running application allowed to
access?"

An Active Directory group maps conceptually to claims, roles, and policies. It
answers, "What does this authenticated user or service represent?"

IIS authentication settings map conceptually to ASP.NET Core authentication
schemes and middleware. The request still needs an identity before protected
resources can be accessed, but the mechanism may be cookies, JWT bearer tokens,
OpenID Connect, certificates, API keys, or platform-provided identity.

SQL Server permissions still matter. Application authorization should not be
the only protection around data. The database account or managed identity
should have only the access the application needs.

The analogy breaks down when the application is no longer protected mainly by
a corporate network or one IIS server. Public APIs, mobile clients, cloud
services, service-to-service calls, and external identity providers require
explicit trust decisions. "It is inside the network" is not a complete security
model.

## Layer 1 — Conceptual Model

Authentication determines identity.

Authorization determines access.

Secrets management protects sensitive values the application needs to operate.

Those three concepts are related, but they are not interchangeable.

Authentication answers:

```text
Who is calling?
```

Authorization answers:

```text
What is this caller allowed to do?
```

Secrets management answers:

```text
How does the application safely obtain credentials and sensitive settings?
```

Authentication solves the problem of establishing a caller's identity. In an
ASP.NET Core API, the result is usually a `ClaimsPrincipal`: an identity plus
claims about that identity.

Authorization solves the problem of making access decisions. It can use roles,
claims, policies, resource ownership, tenant boundaries, business state, or a
combination of those.

JWT bearer authentication solves a common API problem: a client can send a
token in the `Authorization` header, and the API can validate that token
without storing server-side session state for every request.

OAuth 2.0 solves delegated authorization. It lets a client obtain access to a
resource with scoped permission, often without giving the client the user's
password.

OpenID Connect builds on OAuth 2.0 to provide authentication and sign-in. It
adds ID tokens and standardized identity information.

Secrets management solves the problem of keeping passwords, connection
strings, API keys, certificates, signing keys, and client secrets out of code,
logs, and casual configuration files.

Security does not solve these problems automatically:

- it does not make poor authorization rules correct;
- it does not protect secrets that are logged or committed;
- it does not make JWT contents trustworthy unless the token is validated;
- it does not replace input validation;
- it does not make production safe without patching and monitoring;
- it does not remove the need for least privilege.

## Layer 2 — System Relationships

The client initiates a request. It may be a browser, mobile app, JavaScript
frontend, server-side app, scheduled job, webhook sender, or another API.

The identity provider authenticates users or services and issues tokens or
session information. Examples include Microsoft Entra ID, Auth0, Okta,
Duende IdentityServer, Keycloak, cloud identity services, and custom identity
systems. The identity provider owns sign-in policy, token issuance, keys,
claims, and often multi-factor authentication.

The ASP.NET Core authentication middleware examines the incoming request. It
uses configured authentication handlers, called schemes, to validate cookies,
bearer tokens, certificates, or other credentials. If successful, it creates
the user identity for the request.

The authorization system evaluates whether that identity can access the
resource. ASP.NET Core supports role-based and policy-based authorization.
Policies can evaluate claims and custom requirements.

The endpoint or controller performs application behavior only after the
security boundary allows it. Some endpoints may allow anonymous access, such
as health checks or public metadata. Others require an authenticated user or a
specific policy.

The data layer receives the result of these decisions indirectly. It should
not assume the endpoint already made every correct access decision. Important
business rules, such as tenant ownership or row-level access, should be
enforced near the application service or data boundary as well.

The configuration system provides non-secret and secret settings. In
development, user secrets can hold local values. In production, a managed
secret store or platform configuration should provide sensitive values.

Failure boundaries include expired tokens, wrong issuer, wrong audience,
missing signing keys, clock skew, missing claims, incorrect policies, confused
roles, overbroad permissions, leaked secrets, broken redirect URIs, CORS
misconfiguration, and authorization checks that protect the endpoint but not
the underlying business operation.

## Layer 3 — Core Mechanics

In ASP.NET Core, authentication and authorization are configured in
`Program.cs`.

A JWT bearer API has this broad shape:

```csharp
builder.Services
    .AddAuthentication()
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"];
        options.Audience = builder.Configuration["Auth:Audience"];
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/orders", () => Results.Ok())
   .RequireAuthorization();

app.Run();
```

`AddAuthentication` registers authentication services. `AddJwtBearer`
registers a bearer-token authentication scheme. The authority identifies the
issuer trusted by the API. The audience identifies the API the token is meant
for.

`AddAuthorization` registers authorization services.

`UseAuthentication` runs authentication middleware. `UseAuthorization` runs
authorization middleware. The order matters: authorization depends on the
identity created by authentication.

`RequireAuthorization` marks the endpoint as protected.

A policy expresses a named access rule:

```csharp
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanReadOrders", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("scope", "orders.read");
    });
});
```

The endpoint can require that policy:

```csharp
app.MapGet("/orders/{id:int}", (int id) =>
{
    return Results.Ok(new { id });
})
.RequireAuthorization("CanReadOrders");
```

For controllers, the same idea appears with attributes:

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CanReadOrders")]
public sealed class OrdersController : ControllerBase
{
    [HttpGet("{id:int}")]
    public IActionResult Get(int id)
    {
        return Ok(new { id });
    }
}
```

JWT stands for JSON Web Token. In an API scenario, a bearer token is commonly
sent like this:

```http
Authorization: Bearer eyJhbGciOi...
```

The API should validate the token's signature, issuer, audience, expiration,
and relevant claims. It should not merely decode the token and trust the
contents.

Secrets should come from configuration, not constants:

```csharp
var connectionString =
    builder.Configuration.GetConnectionString("Orders");
```

For local development, user secrets can keep values out of the repository:

```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Orders" "Server=..."
```

User secrets are for development convenience. They are not a production secret
store.

## Layer 4 — Developer Workflow

A safe development workflow begins before code is written.

Identify the protected resources:

```text
Orders
Invoices
User profile
Administration
Reports
Health checks
```

Identify the callers:

```text
Anonymous user
Authenticated customer
Employee
Administrator
Background service
Partner API
```

Define access rules in ordinary language:

```text
Customers can read their own orders.
Employees can read orders for assigned regions.
Administrators can change order status.
Background services can write fulfillment events.
Anonymous users can read public health metadata only.
```

Then translate those rules into authentication schemes, policies, claims,
roles, and application checks.

Create an API:

```bash
dotnet new webapi -n Chapter07.Api
cd Chapter07.Api
```

Add JWT bearer support:

```bash
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

Initialize user secrets for local values:

```bash
dotnet user-secrets init
dotnet user-secrets set "Auth:Authority" "https://login.example.com/"
dotnet user-secrets set "Auth:Audience" "chapter07-api"
```

Build and run:

```bash
dotnet build
dotnet run
```

The exact identity-provider configuration depends on the provider. Microsoft
Entra ID, Auth0, Okta, Keycloak, and other providers all require application
registration, redirect URI or API audience settings, and token configuration.
Those details belong to the provider setup. The ASP.NET Core application
should treat the provider as the trusted authority and validate tokens
accordingly.

During development, avoid these habits:

- do not commit tokens;
- do not paste production client secrets into local files;
- do not log authorization headers;
- do not turn off token validation to "get unstuck";
- do not rely on frontend checks as the only authorization enforcement.

Use local test tokens, development identity providers, or integration-test
helpers when available. Chapter 8 returns to testing; this chapter's goal is
to establish the secure workflow mindset.

## Layer 5 — Production Usage

Production security starts with trust boundaries.

Configuration should separate local, test, staging, and production identity
settings. A token issued for a development audience should not work against
production. A production API should validate issuer, audience, lifetime, and
signature.

Secrets should be stored in a managed secret store or platform secret system.
Examples include Azure Key Vault, AWS Secrets Manager, Google Secret Manager,
Kubernetes secrets with appropriate encryption and access controls, or a
dedicated enterprise vault. Environment variables can be a delivery mechanism,
but they are not a complete secret-management strategy by themselves.

Security requires least privilege. The application identity should have only
the database, storage, queue, and cloud permissions it needs. Users and service
clients should receive only the scopes, roles, or claims required for their
work.

Reliability includes key rollover, token expiration, identity-provider
availability, clock synchronization, and fallback behavior. If the identity
provider has an outage, existing token validation may continue for a period
depending on cached metadata and keys, but new sign-ins may fail.

Deployment must protect credentials. CI/CD systems should use secure variable
stores, federated identity, managed identity, or short-lived credentials when
possible. Long-lived client secrets copied between systems are operational
debt.

Observability should record security-relevant events without exposing secrets.
Log authentication failures, authorization failures, suspicious request
patterns, and administrative actions. Do not log bearer tokens, passwords,
client secrets, full connection strings, or sensitive claims.

Scaling affects security because multiple application instances must agree on
token validation, data-protection keys for cookie scenarios, clock behavior,
and policy configuration. Stateless JWT validation helps APIs scale, but
revocation and permission changes require careful design.

Persistence matters because authorization often depends on data ownership.
"Can read orders" may not be enough. The application may need to check whether
the order belongs to the current tenant, customer, region, or account.

Cost appears through identity-provider licensing, secret store operations,
audit-log retention, security scanning, and compliance requirements. Security
costs are usually cheaper than incident costs.

Local development optimizes for learning and fast feedback. Production
optimizes for verified trust, least privilege, credential hygiene, auditing,
and controlled access.

## Layer 6 — Tradeoffs and Alternatives

Use ASP.NET Core authentication and authorization for application-level
security decisions. Use platform security for infrastructure-level access.
Use database security for data-level protection. Strong systems use all three.

Cookies are natural for browser-based web applications where the server and
browser maintain an authenticated session. JWT bearer tokens are natural for
APIs called by clients, single-page applications, mobile apps, or other
services. API keys can be useful for simple service integration, but they do
not identify users well and require careful rotation and scope control.

OAuth 2.0 is for delegated authorization. OpenID Connect is for sign-in and
identity. Do not describe every token flow as "OAuth login" without knowing
which problem the flow solves.

Microsoft Entra ID is common in Microsoft-centered enterprises. Auth0, Okta,
Keycloak, Duende IdentityServer, AWS Cognito, Google Identity, and other
providers may be better fits depending on organization, hosting platform,
customer identity needs, open-source preference, compliance, and operations
skills.

ASP.NET Core Identity is useful when an application owns its own user store,
especially for traditional web applications. External identity providers are
often preferable for enterprise SSO, customer identity, multi-factor
authentication, federation, and centralized account governance.

Common overengineering mistakes:

- building a custom identity provider when a managed one would do;
- using roles for every fine-grained business rule;
- trusting decoded JWT payloads without validation;
- putting authorization only in the frontend;
- storing production secrets in `appsettings.json`;
- logging tokens during debugging and forgetting to remove the log;
- using one overpowered service account for every dependency;
- treating authentication as complete security.

State-of-the-art security in modern .NET favors standards-based identity,
short-lived tokens, policy-based authorization, managed identities, external
secret stores, least privilege, strong telemetry, and threat modeling early in
the design.

## Layer 7 — Interview Perspective

Interviewers use security questions to test whether you know the difference
between identity, access, and secret handling.

Concepts commonly tested:

- authentication versus authorization;
- claims, roles, and policies;
- JWT bearer authentication;
- OAuth 2.0 versus OpenID Connect;
- access tokens versus ID tokens;
- middleware order;
- secret storage;
- least privilege;
- tenant or ownership checks;
- avoiding token and secret leakage.

Representative questions:

- "What is the difference between authentication and authorization?"
- "How does JWT bearer authentication work in an ASP.NET Core API?"
- "Why should an API validate issuer and audience?"
- "What is OpenID Connect's relationship to OAuth 2.0?"
- "When would you use policies instead of roles?"
- "Where should production secrets be stored?"
- "Why is frontend authorization not enough?"
- "How would you secure an endpoint that returns customer orders?"

A strong answer separates concerns:

> "Authentication establishes the caller's identity, often through a token or
> cookie. Authorization decides whether that identity can perform the requested
> action. For an orders API, I would validate the token, require a policy such
> as `orders.read`, and still check that the requested order belongs to the
> caller's tenant or account."

Common misconceptions:

- "If a user is authenticated, they can use the endpoint."
- "JWTs are secure because they are encoded."
- "OAuth and OpenID Connect are the same thing."
- "Roles are always enough."
- "Secrets in environment variables are automatically safe."
- "HTTPS removes the need for token validation."
- "The frontend can hide unauthorized buttons, so the API is protected."

Small design scenario:

You are adding security to the order API from Chapter 6. Customers can read
their own orders. Employees can read orders for assigned regions.
Administrators can update order status. A background service can add shipment
events.

A good design would use a trusted identity provider, JWT bearer authentication
for the API, policies for scopes or permissions, application-level ownership
checks for customer and region access, least-privilege database access, and a
secret store for connection strings and identity-provider settings.

The strong answer protects the business operation, not just the URL.

## Hands-On Lab

Objective:

Add basic authorization structure and local secret storage to an ASP.NET Core
API.

Prerequisites:

- .NET 10 SDK installed, or another currently supported .NET SDK.
- Basic ASP.NET Core experience from Chapter 5.
- No real identity provider is required for the conceptual parts of this lab.

Steps:

1. Create an API:

   ```bash
   dotnet new webapi -n Chapter07.Api
   cd Chapter07.Api
   ```

2. Add JWT bearer support:

   ```bash
   dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
   ```

3. Initialize user secrets:

   ```bash
   dotnet user-secrets init
   ```

4. Store placeholder development settings:

   ```bash
   dotnet user-secrets set "Auth:Authority" "https://login.example.com/"
   dotnet user-secrets set "Auth:Audience" "chapter07-api"
   ```

5. Add authentication and authorization services in `Program.cs`.

6. Add `UseAuthentication()` before `UseAuthorization()`.

7. Add a policy named `CanReadOrders`.

8. Protect an endpoint with `.RequireAuthorization("CanReadOrders")`.

9. Leave one simple endpoint anonymous, such as `/health/basic`.

10. Build the project:

    ```bash
    dotnet build
    ```

Expected results:

- The project builds.
- Authentication and authorization are configured.
- Protected endpoints require authorization.
- Local secret values are stored outside source-controlled files.

Validation commands:

```bash
dotnet build
dotnet user-secrets list
dotnet run
```

Troubleshooting notes:

- If the app fails on startup, check that configuration keys match the code.
- If all endpoints are protected, confirm the intended anonymous endpoint does
  not call `RequireAuthorization`.
- If authorization always fails, remember that a real request needs a valid
  token from the configured authority.
- If `dotnet user-secrets` fails, confirm the command is run from the project
  directory.

## Knowledge Check

1. Why is authentication not enough to protect an API?
2. What does authorization decide?
3. Why should a JWT be validated instead of merely decoded?
4. What is the difference between an access token and an ID token?
5. How does OpenID Connect relate to OAuth 2.0?
6. Why does middleware order matter for authentication and authorization?
7. When are policies better than roles?
8. Why should authorization sometimes check resource ownership, not only
   claims?
9. What kinds of values should be treated as secrets?
10. Why are user secrets appropriate for development but not production?

## Summary

Authentication identifies the caller. Authorization decides what the caller may
do. Secrets management protects the sensitive values the application needs in
order to run.

ASP.NET Core provides authentication schemes, middleware, authorization
policies, endpoint protection, and integration points for modern identity
providers. JWT bearer authentication is common for APIs. OAuth 2.0 addresses
delegated authorization. OpenID Connect extends OAuth 2.0 for sign-in and
identity.

The most important security habit is to protect business operations, not just
routes. Validate tokens. Require policies. Check ownership and tenant
boundaries. Keep secrets out of code. Use least privilege for users, services,
databases, and cloud resources.

The next chapter adds automated testing and CI basics so application behavior,
including security-sensitive behavior, can be validated repeatedly before
deployment.

## Sources

- [Overview of ASP.NET Core authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/?view=aspnetcore-10.0)
- [Introduction to authorization in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/introduction?view=aspnetcore-10.0)
- [Configure JWT bearer authentication in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-10.0)
- [OpenID Connect on the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)
- [Safe storage of app secrets in development in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-10.0)
- [OWASP API Security Top 10](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)

## Further Reading

- [Authentication and authorization in Minimal APIs](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/security?view=aspnetcore-10.0)
- [Policy-based authorization in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies?view=aspnetcore-10.0)
- [Microsoft identity platform documentation](https://learn.microsoft.com/en-us/entra/identity-platform/)
- [Azure Key Vault documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
