# Chapter Roadmap

## Purpose

This roadmap defines the learning progression for the book and serves as the
chapter specification for each chapter.

The intended reader is an experienced C#/.NET developer who is proficient with Windows, SQL Server, Visual Studio 2019, and traditional enterprise application development, but has not kept up with the evolution of the .NET ecosystem since approximately .NET 5.

Each chapter should build upon concepts established in previous chapters. The goal is to teach **how modern .NET systems fit together**, not simply to document individual technologies.

---

# Part I — Rebuilding the Mental Model

## Chapter 1 — The Modern .NET Landscape

**Goal**

Provide a high-level overview of how professional .NET development has changed.

**Topics**

* What changed since 2019
* The shift from servers to platforms
* Cloud-native development
* Containers
* DevOps
* AI-assisted development
* Overview of the modern application lifecycle

---

## Chapter 2 — The Modern Technology Stack

**Goal**

Introduce the major technologies without diving into implementation details.

**Topics**

* .NET
* ASP.NET Core
* Linux
* Docker
* Kubernetes
* SQL Server
* Redis
* Cloud platforms
* GitHub
* CI/CD
* AI services

Explain how each technology fits into the overall ecosystem.

---

## Chapter 3 — Modern Development Workflow

**Goal**

Show what a typical professional development workflow looks like in 2026
without requiring the reader to implement the full delivery pipeline yet.

**Topics**

* Local development
* Source control
* Pull requests
* Testing
* Code reviews
* AI coding assistants
* Development environments
* How work moves from local code to production

By the end of this chapter the reader should understand the complete software lifecycle at a high level.

---

# Part II — Building Modern .NET Applications

## Chapter 4 — Modern .NET

Modern .NET versions

SDKs

Project structure

Cross-platform development

Language improvements

---

## Chapter 5 — ASP.NET Core

Minimal APIs

Controllers

Dependency Injection

Configuration

Middleware

Logging

---

## Chapter 6 — Data Access

SQL Server

Entity Framework Core

Dapper

Migrations

Performance

---

## Chapter 7 — Authentication and Security

Authentication

Authorization

JWT

OAuth

OpenID Connect

Secrets management

---

## Chapter 8 — Automated Testing and CI Basics

Why automated validation exists

Unit tests

Integration tests

Test projects

GitHub Actions

Pull request checks

Build pipelines

This chapter should focus on validating application changes before deployment,
not on production release automation.

---

# Part III — Linux and Containers

## Chapter 9 — Linux for .NET Developers

Basic Linux concepts

Filesystem

Permissions

Processes

Networking

Command line

The objective is familiarity rather than Linux administration.

---

## Chapter 10 — Docker

Why containers exist

Images

Containers

Volumes

Networks

Dockerfiles

Container registries

---

## Chapter 11 — Docker Compose

Running multi-container applications

Application configuration

Local SQL Server

Networking

Development environments

---

# Part IV — Cloud Native Development

## Chapter 12 — Deploying ASP.NET Core

Publishing

Reverse proxies

Hosting

Configuration

Production deployments

---

## Chapter 13 — Cloud Platforms

Azure

AWS

Google Cloud

Managed databases

Storage

Networking

Identity

How the major cloud providers compare.

---

## Chapter 14 — Observability Basics and Production Diagnostics

Why production diagnostics exist

ASP.NET Core logging

Health checks

Structured logging

Basic metrics

Local diagnostics

Production monitoring concepts

This chapter should establish enough observability knowledge for the reader to
understand deployed applications before introducing distributed tracing or
multi-service monitoring.

---

# Part V — Building Production Systems

## Chapter 15 — Distributed Applications

Caching

Redis

Messaging

Background services

Queues

Resilience

---

## Chapter 16 — CI/CD Deployment Pipelines

Continuous Deployment

Release pipelines

Azure DevOps

Container publishing

Environment promotion

Deployment approvals

Rollback strategies

This chapter should build on the earlier CI basics chapter and focus on safely
moving validated changes into production environments.

---

## Chapter 17 — Infrastructure as Code

Why infrastructure became code

Terraform

Bicep

Configuration management

Environment provisioning

---

## Chapter 18 — Kubernetes

Why orchestration exists

Pods

Deployments

Services

Scaling

Health checks

Rolling deployments

This chapter should emphasize concepts over operational expertise.

---

## Chapter 19 — Advanced Observability

OpenTelemetry

Metrics

Tracing

Distributed tracing

Dashboards

Alerting

Multi-service monitoring

This chapter should extend the earlier diagnostics chapter into production
observability for cloud-native and distributed systems.

---

# Part VI — AI in Modern .NET

## Chapter 20 — AI Application Architecture

LLMs

Embeddings

Vector databases

Retrieval-Augmented Generation (RAG)

Agents

Function calling

Model selection

---

## Chapter 21 — AI Development with .NET

Microsoft.Extensions.AI

Semantic Kernel

Building AI-powered APIs

Integrating existing business applications

---

# Part VII — Architecture

## Chapter 22 — Modern Software Architecture and Scale

Monoliths

Modular monoliths

Microservices

Distributed systems

Horizontal scaling

Stateless applications

Caching strategies

Performance

Cost

Reliability

When each approach is appropriate

---

## Chapter 23 — Common Architectural Patterns

Repository

CQRS

Event-driven systems

Background processing

Domain events

When patterns help—and when they add unnecessary complexity.

---

# Part VIII — Professional Development

## Chapter 24 — Interview Preparation and Career Roadmap

Technical interview topics

Architecture discussions

System design

Behavioral expectations

Coding exercises

Skills employers expect

Recommended learning order

Building a portfolio

Certifications

Open-source contributions

Keeping current with the .NET ecosystem

---

# Final Project

The final project ties together everything learned in the book.

Starting from an empty repository, the reader will build a production-style application that includes:

* ASP.NET Core
* SQL Server
* Entity Framework Core
* Docker
* Docker Compose
* Linux deployment
* CI/CD
* Cloud hosting
* Authentication
* Logging
* Monitoring
* AI integration

Each stage of the project corresponds to concepts introduced throughout the book, reinforcing earlier chapters while demonstrating how the complete technology stack works together.
