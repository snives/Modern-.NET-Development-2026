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

Every chapter must:

1. Begin with the high-level purpose of the technology.
2. Connect the new concept to something the reader already understands.
3. Explain where it fits into a complete application system.
4. Introduce terminology and mechanics.
5. Progress into practical implementation.
6. Cover production concerns and tradeoffs.
7. Explain what interviewers expect the reader to know.
8. End with a working exercise and comprehension check.

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

# Teaching Method

Every major subject must progress through these levels:

1. Why the technology exists
2. How it relates to the reader's existing mental model
3. Where it fits in the modern system
4. Basic usage
5. Production usage
6. Tradeoffs and alternatives
7. Interview expectations
8. Hands-on exercise

Introduce high-level structure before implementation details.

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