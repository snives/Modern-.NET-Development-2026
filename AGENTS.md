# Repository Purpose

This repository contains a progressively structured book for an
experienced Windows, SQL Server, and C# developer returning to modern
.NET development in 2026.

# Book Authoring Principles

This book teaches modern .NET to an experienced developer whose existing
mental model is based on C#, .NET 5, Visual Studio 2019, Windows, IIS,
and SQL Server.

All chapters must use progressive disclosure.

Do not begin with commands, configuration files, APIs, or implementation
details. First establish the conceptual location of the subject within the
larger modern .NET ecosystem.

The reader should never need to understand a lower layer before the chapter
has established the higher layer that gives it meaning.

Follow `book/chapter-template.md` for the required chapter structure.

# Reader Baseline

Assume the reader already understands:

- C#
- .NET 5
- Visual Studio 2019
- Windows administration
- SQL Server
- traditional IIS deployment
- enterprise application development

Do not explain these concepts as though the reader is a beginner.

# Accuracy

Time-sensitive claims must cite authoritative, current sources.

Prefer:

1. Official product documentation
2. Official lifecycle and support documents
3. Primary-source surveys and reports
4. Reputable secondary analysis only when primary data is unavailable

Never silently infer that a technology is popular, obsolete, or preferred.

# Change Scope

Each pull request should normally address one chapter, one sample,
one validation rule, or one clearly bounded cross-book concern.

Do not rewrite unrelated chapters.
