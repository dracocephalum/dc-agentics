---
name: project
description: Add a project to this repository - a library, service, job, tool, or the test project for one - following the repository's layout and conventions.
when_to_use: When asked to create, add, scaffold, or set up a new project, component, service, library, or test project in this repository.
argument-hint: [kind] [name]   e.g. classlib Billing, webapi billing-api, tests Billing
---

Add a project to this repository. Currently supports **C# only** - for any other
language or framework, say so and stop.

## Find the procedure

This skill is the same file wherever it lives; the procedure it follows is
found by location, in this order:

1. `docs/rules/coding/csharp/csharp-new-project.md` - an initialized repository
2. `init/repo/payload/docs/rules/coding/csharp/csharp-new-project.md` - the dc-agentics toolkit itself

(The same subtree under two roots: `docs/rules/` there, `init/repo/payload/docs/rules/` here.)

Paths are relative to the repository root. Read the first one that exists and
follow it exactly; it is the single source of truth for where projects go, how
they are named, and what a finished project looks like. Do not work from
memory. If neither exists, this repository was not initialized from the
toolkit - say so and stop.

Inside the dc-agentics toolkit there are no C# components to add; if invoked
there, say so rather than scaffolding into the toolkit.

## Arguments

`$ARGUMENTS`

- **kind** - `classlib`, `webapi`, `worker`, `console`, or `tests`.
- **name** - the project's short name, or for a new monorepo component the
  kebab-case folder name.

Ask for anything missing rather than guessing. Take the namespace prefix from
the repository's root `AGENTS.md`; never invent one.

## Done means

`dotnet build` green, `dotnet test` green with the expected test count, and
the new project listed in its solution.
