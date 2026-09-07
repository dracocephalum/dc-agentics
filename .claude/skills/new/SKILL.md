---
name: new
description: Add something to this repository - a C# project (library, service, job, tool, or a test project), or a whole new component with its own solution under a category. Asks for the choices, and applies the repository's mechanics without asking, because the build enforces those anyway.
when_to_use: When asked to create, add, scaffold, or set up a new project, component, service, library, console app, worker, or test project in this repository.
argument-hint: [project|component] [kind] [name]   e.g. project classlib Billing, component billing
---

Currently supports **C# only** - for any other language or framework, say so
and stop.

## Find the procedure

1. `docs/rules/coding/csharp/csharp-new-project.md` - an initialized repository
2. `repo/payload/docs/rules/coding/csharp/csharp-new-project.md` - the toolkit

Read the first that exists and follow it exactly. Where things go, how they are
named, and what "done" means are all there; do not work from memory. If neither
exists, this repository was not initialized from the toolkit - say so and stop.

## Where it is being run matters

| Situation | Do |
|---|---|
| inside an initialized repository | proceed; it carries everything needed |
| from a toolkit checkout, against a target path | check the two agree first - `repo/version-check.md` |
| scaffolding **into** the dc-agentics toolkit itself | refuse; there are no C# components here to add to |

The second case is the quiet one. If the toolkit's procedure is newer than the
target's copy, what gets created follows conventions that repository's own
documents do not describe, and nothing later notices. Every failing outcome has
the same way out: run it from inside the target.

## Modes

**`project`** - one project in an existing component.

- Ask the name, and the kind if the request does not say: `classlib`, `webapi`,
  `worker`, `console`, or a test project.
- **In a monorepo, ask which component it joins.** Standalone has exactly one,
  so do not ask there.
- For a `src/` project, **ask whether to add the matching test project**,
  defaulting to yes.
- A test project can be created on its own for an existing `src/` project. It
  must be `<Project>.Tests` under `test/` - that name is what applies the test
  stack, not a convention.

**`component`** - a new solution with its own `src/`, `test/` and `README.md`.

- **Ask which category** it belongs in. It cannot be inferred.
- A category folder that does not exist yet is created with its map.
- A standalone repository has one component by definition; adding a second
  means converting the layout first - `/upgrade`.

## What is asked, and what is not

Choices are the user's: kind, name, component, category, whether to pair tests.

Mechanics are not, and they are not conventions either - the build enforces
them. Stripping `Version=` avoids `NU1008`; replacing template sample code
avoids failing under warnings-as-errors; the `.Tests` suffix is what makes
`Tests.props` apply at all. Follow the procedure rather than negotiating them.
