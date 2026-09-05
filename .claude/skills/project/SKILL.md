---
name: project
description: Add a project to this repository - a library, service, job, tool, or the test project for one - following the repository's layout and conventions.
when_to_use: When asked to create, add, scaffold, or set up a new project, component, service, library, or test project in this repository.
argument-hint: [kind] [name]   e.g. classlib Billing, webapi billing-api, tests Billing
---

Add a project to this repository. Currently supports **C# only** - for any other
language or framework, say so and stop.

## Find the procedure

1. `docs/rules/coding/csharp/csharp-new-project.md` - an initialized repository
2. `init/repo/payload/docs/rules/coding/csharp/csharp-new-project.md` - the dc-agentics toolkit itself

Read the first one that exists and follow it exactly - where projects go, how
they are named, what a finished project looks like, and what "done" means are
all there. Do not work from memory. If neither exists, this repository was not
initialized from the toolkit - say so and stop.

Inside the dc-agentics toolkit there are no C# components to add; if invoked
there, say so rather than scaffolding into the toolkit.

## Arguments

`$ARGUMENTS`

- **kind** - `classlib`, `webapi`, `worker`, `console`, or `tests`.
- **name** - the project's short name, or for a new monorepo component the
  kebab-case folder name.

Ask for anything missing rather than guessing.
