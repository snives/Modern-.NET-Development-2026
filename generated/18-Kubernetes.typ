= Kubernetes
<kubernetes>
== Chapter Purpose
<chapter-purpose>
Kubernetes is where several threads of the book meet: Linux, containers,
cloud platforms, deployment pipelines, infrastructure as code,
observability, and distributed applications.

Kubernetes exists because running one container is not the same thing as
operating many containers in production. A team may need to place
containers across machines, restart failed instances, scale replicas,
route traffic, perform rolling updates, attach configuration, manage
secrets, and maintain a desired state over time. Doing that with
hand-written scripts and individual servers becomes fragile quickly.

Kubernetes was originally created at Google and released as open source.
It became the dominant container orchestration platform because it
provided a portable API for describing and operating containerized
workloads. It was not created for \.NET, but modern \.NET applications
fit well into it when they are packaged as containers and designed for
platform operation.

This chapter emphasizes concepts over operational expertise. You will
learn why orchestration exists, what pods, deployments, services,
scaling, health checks, and rolling deployments mean, and when
Kubernetes is or is not the right choice.

== Where This Fits
<where-this-fits>
Kubernetes sits above individual containers and below application
behavior.

```text
Container image
      |
      v
Kubernetes Deployment
      |
      v
ReplicaSet
      |
      v
Pods
      |
      +-- ASP.NET Core container
      +-- environment variables
      +-- health probes
      +-- resource requests and limits
      |
      v
Nodes in a cluster
      |
      v
Service exposes stable network access
```

Chapter 18 follows infrastructure as code because Kubernetes is another
desired-state system. You write resource definitions that describe what
should exist, and controllers work to make the cluster match that
description.

Chapter 19 follows with advanced observability because Kubernetes makes
telemetry more important. If an app has many pods across nodes, local
logs and manual server inspection are not enough.

== Connection to the Reader's Existing Model
<connection-to-the-readers-existing-model>
A load-balanced IIS farm is the closest familiar analogy.

In a web farm, multiple servers run copies of an application. A load
balancer sends traffic to healthy instances. Administrators deploy new
versions, restart unhealthy processes, patch servers, manage
certificates, and watch capacity.

Kubernetes generalizes that operational model for containers.

A node is roughly like a server in the farm. It runs workloads.

A pod is the smallest deployable compute unit in Kubernetes. If you
usually think in single containers, a pod often feels like "the running
app container," though a pod can contain multiple containers that must
run together.

A deployment is roughly like the desired rollout rule for an
application: run this container image, keep this many replicas, update
them this way.

A service is roughly like a stable internal load-balancing name for a
set of pods. Pods are replaceable and get new IP addresses. Services
give other code a stable way to reach them.

Health probes map to load balancer health checks and service monitoring.
Kubernetes can use probes to decide whether a container is alive or
ready for traffic.

The analogy breaks down if you think Kubernetes is just a web farm
manager. Kubernetes is an API-driven control plane for many kinds of
containerized workloads: APIs, background workers, batch jobs, scheduled
jobs, platform components, and operators. It also introduces its own
security, networking, storage, upgrade, and cost responsibilities.

== Layer 1 --- Conceptual Model
<layer-1-conceptual-model>
Kubernetes is an open-source platform for managing containerized
workloads and services using declarative configuration and automation.

It solves these problems:

- scheduling containers across machines;
- keeping desired replica counts running;
- restarting failed containers;
- exposing stable service names;
- rolling out new versions;
- scaling workloads;
- attaching configuration and secrets;
- providing a common API across environments.

It does not solve these problems automatically:

- it does not make applications stateless;
- it does not make databases easy to run;
- it does not remove the need for observability;
- it does not secure workloads without configuration;
- it does not eliminate cloud networking complexity;
- it does not make a small app simpler.

The conceptual model is:

```text
You declare desired state.
Kubernetes stores that desired state.
Controllers compare desired state to actual state.
Controllers act to close the gap.
```

This is the same kind of mental model you saw in infrastructure as code,
but applied continuously to running workloads.

== Layer 2 --- System Relationships
<layer-2-system-relationships>
The cluster is the whole Kubernetes environment. It includes the control
plane and nodes.

The control plane exposes the Kubernetes API, stores cluster state,
schedules pods, and runs controllers that reconcile desired state. In
managed services such as Azure Kubernetes Service and Amazon EKS, the
cloud provider manages much of the control plane.

Nodes are machines that run pods. They may be virtual machines,
cloud-managed compute, or other host types. Nodes run a kubelet,
networking components, and a container runtime.

Pods run one or more containers. A pod has its own network identity
inside the cluster and shares storage volumes among containers in the
pod.

Deployments manage replicated application pods. They create and update
ReplicaSets so the desired number of pod replicas exists.

Services provide stable network access to pods. They select pods using
labels and route traffic to matching pod endpoints.

Ingress or gateway resources expose HTTP traffic from outside the
cluster into services. The exact implementation depends on the cluster
and cloud provider.

ConfigMaps and Secrets provide configuration to pods. They are not a
complete secrets-management strategy by themselves, especially without
encryption and access controls.

Failure boundaries include bad manifests, unavailable images, crash
loops, failed probes, insufficient CPU or memory, bad service selectors,
DNS issues, network policies, secret misconfiguration, node failure,
cluster upgrades, and applications that cannot shut down gracefully.

== Layer 3 --- Core Mechanics
<layer-3-core-mechanics>
A deployment describes the desired state for application replicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: orders-api
  template:
    metadata:
      labels:
        app: orders-api
    spec:
      containers:
        - name: orders-api
          image: registry.example.com/orders-api:2026.07.22
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

A service gives stable access to pods with matching labels:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-api
spec:
  selector:
    app: orders-api
  ports:
    - port: 80
      targetPort: 8080
```

Apply the files:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Inspect resources:

```bash
kubectl get pods
kubectl get deployments
kubectl get services
```

Update the image:

```bash
kubectl set image deployment/orders-api \
  orders-api=registry.example.com/orders-api:2026.07.23
```

Watch rollout status:

```bash
kubectl rollout status deployment/orders-api
```

Roll back:

```bash
kubectl rollout undo deployment/orders-api
```

These commands are mechanics. The more important concept is that the
deployment controller tries to move the system from old state to new
state without dropping all replicas at once.

== Layer 4 --- Developer Workflow
<layer-4-developer-workflow>
A \.NET developer's Kubernetes workflow usually begins before the
cluster.

```text
Build ASP.NET Core app
        |
        v
Containerize app
        |
        v
Push image to registry
        |
        v
Write Kubernetes manifests or Helm chart
        |
        v
Deploy to a development namespace
        |
        v
Inspect pods, logs, services, and rollout
```

Useful local commands:

```bash
kubectl version --client
kubectl config current-context
kubectl get namespaces
```

Check application status:

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

Port-forward for local testing:

```bash
kubectl port-forward service/orders-api 8080:80
```

Call the app:

```bash
curl http://localhost:8080/health
```

For development, do not start by building a production cluster from
scratch. Use a local cluster such as Docker Desktop Kubernetes, kind, or
minikube, or a managed development cluster provided by the team.

The workflow habit is to connect app symptoms to Kubernetes resources:

```text
App unavailable -> check service, pods, readiness
Container exits -> check logs and describe pod
New version stuck -> check rollout status
No traffic -> check labels, selectors, ingress, ports
Slow app -> check resources, metrics, dependencies
```

== Layer 5 --- Production Usage
<layer-5-production-usage>
Production Kubernetes begins with platform ownership.

Configuration should be environment-specific and declarative. Use
manifests, Helm charts, Kustomize, GitOps tools, or platform templates
rather than hand-editing live resources.

Secrets should be integrated with a real secret-management system when
possible. Kubernetes Secrets require careful RBAC, encryption at rest,
and access control.

Security includes image scanning, non-root containers, network policies,
RBAC, service accounts, admission controls, pod security standards,
workload identity, and least privilege.

Reliability depends on readiness probes, liveness probes, resource
requests, limits, graceful shutdown, replica counts, disruption budgets,
node health, cluster upgrades, and dependency resilience.

Deployment should use immutable image tags or digests. Rolling updates
are common, but blue/green, canary, or GitOps-based approaches may be
appropriate.

Observability must be centralized. Logs, metrics, events, traces,
health, and cluster state need to be visible outside individual pods and
nodes.

Scaling includes pod autoscaling, node autoscaling, event-driven
autoscaling, and dependency scaling. More pods can increase database,
cache, and queue load.

Persistence is difficult in Kubernetes. Stateless workloads are the
natural fit. Stateful workloads can run in Kubernetes, but databases
often remain better as managed services unless the team has strong
operational capability.

Cost includes cluster control plane charges, node compute, load
balancers, storage, monitoring, image registries, idle capacity, and
platform labor.

Local Kubernetes optimizes for learning. Production Kubernetes optimizes
for platform consistency, security, automation, and operational control.

== Layer 6 --- Tradeoffs and Alternatives
<layer-6-tradeoffs-and-alternatives>
Use Kubernetes when the organization needs a common platform for many
containerized workloads, portable deployment APIs, self-healing
behavior, rolling updates, service discovery, autoscaling, and strong
platform teams.

Do not use Kubernetes just to run one ASP.NET Core API. Azure App
Service, Azure Container Apps, AWS App Runner, AWS ECS, Google Cloud
Run, and other managed services are often simpler.

Managed Kubernetes services include Azure Kubernetes Service, Amazon
EKS, and Google Kubernetes Engine. They reduce control-plane burden but
do not remove application, workload, security, networking, cost, or
cluster governance responsibilities.

AKS Automatic and EKS Auto Mode reflect a current trend: managed
Kubernetes providers are trying to reduce node and platform operations
so teams can get Kubernetes benefits with fewer manual decisions. That
helps, but the workload model still matters.

Alternatives include Docker Compose for local development, managed
container apps for simple services, serverless functions for
event-driven workloads, VMs for legacy control needs, and PaaS hosting
for straightforward web apps.

Common overengineering mistakes:

- choosing Kubernetes before understanding containers;
- deploying stateful databases without operational readiness;
- ignoring resource requests and limits;
- using `latest` image tags;
- exposing services publicly by accident;
- treating probes as optional;
- granting cluster-admin permissions broadly;
- building a custom platform before a managed service is considered.

The state-of-the-art direction is managed Kubernetes plus platform
engineering: secure defaults, GitOps, policy controls, workload
identity, autoscaling, integrated observability, and paved paths for
application teams.

== Layer 7 --- Interview Perspective
<layer-7-interview-perspective>
Interviewers use Kubernetes questions to test whether you understand
orchestration boundaries.

Concepts commonly tested:

- why orchestration exists;
- cluster, control plane, and node;
- pod;
- deployment;
- service;
- labels and selectors;
- liveness and readiness probes;
- rolling updates;
- scaling;
- Kubernetes versus Docker;
- Kubernetes versus managed app platforms.

Representative questions:

- "What problem does Kubernetes solve?"
- "What is a pod?"
- "How is a deployment different from a pod?"
- "What does a service do?"
- "Why do labels and selectors matter?"
- "What is the difference between readiness and liveness?"
- "How does a rolling deployment work?"
- "When would you avoid Kubernetes?"

A strong answer names both value and cost:

#quote(block: true)[
"Kubernetes lets us declare desired state for containerized workloads
and have controllers maintain it. A Deployment keeps replicas running
and rolls out updates, while a Service gives stable network access to
changing pods. It is powerful, but it adds platform, security,
networking, observability, and cost responsibilities."
]

Common misconceptions:

- "Kubernetes replaces Docker."
- "A pod is the same thing as a container."
- "Kubernetes makes the app scalable automatically."
- "Services are always public load balancers."
- "A liveness probe and readiness probe answer the same question."
- "Managed Kubernetes means no operations."
- "Every cloud-native app should start on Kubernetes."

Small design scenario:

You have five ASP.NET Core APIs, three background workers, Redis, and
SQL Server. The organization already has a platform team and wants
consistent container deployment across environments.

A good Kubernetes design might run the APIs and workers as deployments,
expose internal services through ClusterIP services, use ingress for
public HTTP, connect to managed SQL Server outside the cluster, use
managed Redis or a carefully operated cache, configure readiness and
liveness probes, set resource requests, and deploy through a GitOps or
CI/CD process.

The strong answer puts stateless workloads in Kubernetes first and
treats stateful dependencies deliberately.

== Hands-On Lab
<hands-on-lab>
Objective:

Read and apply a basic Kubernetes deployment and service for an ASP.NET
Core container image.

Prerequisites:

- `kubectl` installed.
- Access to a local or development Kubernetes cluster.
- A container image from Chapter 10.

Steps:

+ Confirm the current context:

  ```bash
  kubectl config current-context
  ```

+ Create `deployment.yaml` for an ASP.NET Core image.

+ Include:

  ```text
  replicas: 2
  containerPort: 8080
  readinessProbe
  livenessProbe
  resource requests and limits
  ```

+ Create `service.yaml` selecting the deployment's label.

+ Apply the manifests:

  ```bash
  kubectl apply -f deployment.yaml
  kubectl apply -f service.yaml
  ```

+ Inspect resources:

  ```bash
  kubectl get pods
  kubectl get deployments
  kubectl get services
  ```

+ View logs:

  ```bash
  kubectl logs deployment/orders-api
  ```

+ Port-forward:

  ```bash
  kubectl port-forward service/orders-api 8080:80
  ```

+ Call the health endpoint:

  ```bash
  curl http://localhost:8080/health
  ```

Expected results:

- Kubernetes creates pods for the deployment.
- The service provides stable access to the pods.
- The health endpoint responds through port-forwarding.
- You can inspect rollout, pod state, and logs.

Validation commands:

```bash
kubectl get pods
kubectl get deployments
kubectl get services
kubectl rollout status deployment/orders-api
kubectl logs deployment/orders-api
```

Troubleshooting notes:

- If pods show `ImagePullBackOff`, check image name, tag, and registry
  access.
- If pods show `CrashLoopBackOff`, inspect logs and environment
  variables.
- If the service cannot be reached, check labels and selectors.
- If readiness never succeeds, check the health endpoint path and port.
- If you are on a shared cluster, use a development namespace and clean
  up resources when finished.

== Knowledge Check
<knowledge-check>
+ Why does container orchestration exist?
+ What is the relationship between a cluster, node, pod, and container?
+ Why is a deployment usually preferred over creating pods directly?
+ What problem does a service solve?
+ Why do labels and selectors matter?
+ How are liveness and readiness probes different?
+ What happens during a rolling deployment?
+ Why are resource requests and limits important?
+ When is a managed app service simpler than Kubernetes?
+ Why are databases harder to operate in Kubernetes than stateless APIs?

== Summary
<summary>
Kubernetes is a declarative orchestration platform for containerized
workloads. It lets teams describe desired state and relies on
controllers to keep actual state aligned.

The core vocabulary is manageable. A cluster contains nodes. Nodes run
pods. Pods contain containers. Deployments manage replicated pods and
rollouts. Services provide stable network access. Probes tell the
platform whether a container is alive or ready. Scaling changes replica
counts and resource capacity.

Kubernetes is powerful, but it is not the default answer for every \.NET
application. It fits best when an organization needs a consistent
platform for many containerized workloads and has the operational
maturity to secure, observe, upgrade, and govern it.

The next chapter builds on this by introducing advanced observability
for cloud-native and distributed systems, including OpenTelemetry,
tracing, dashboards, alerting, and multi-service monitoring.

== Sources
<sources>
- #link("https://kubernetes.io/docs/concepts/")[Kubernetes concepts]
- #link("https://learn.microsoft.com/en-us/azure/aks/")[Azure Kubernetes Service documentation]
- #link("https://learn.microsoft.com/en-us/azure/aks/core-aks-concepts")[Core concepts for Azure Kubernetes Service]
- #link("https://learn.microsoft.com/en-us/azure/aks/what-is-aks")[What is Azure Kubernetes Service?]
- #link("https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-concepts.html")[Kubernetes concepts in Amazon EKS]
- #link("https://docs.aws.amazon.com/eks/latest/userguide/")[What is Amazon EKS?]
- #link("https://aws.amazon.com/eks/features/")[Amazon EKS features]

== Further Reading
<further-reading>
- #link("https://kubernetes.io/docs/concepts/workloads/")[Kubernetes workloads]
- #link("https://kubernetes.io/docs/concepts/services-networking/")[Kubernetes services, load balancing, and networking]
- #link("https://kubernetes.io/docs/concepts/configuration/")[Kubernetes configuration]
- #link("https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-kubernetes-service")[Azure Well-Architected Framework for AKS]
- #link("https://aws.github.io/aws-eks-best-practices/")[Amazon EKS best practices guides]
