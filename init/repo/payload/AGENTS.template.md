<!--
  TEMPLATE - copied to the new repository root as AGENTS.md.

  Fill every double-brace placeholder, delete the layout variant that does not
  apply, and trim the folder table to folders that actually exist.

  Delete this comment block, then confirm no double-brace token remains
  anywhere in the file.

  Named AGENTS.template.md rather than AGENTS.md so it is not picked up as live
  agent instructions inside the toolkit itself.
-->

# {{REPO_NAME}}

{{ONE_LINE_PURPOSE}}

Primary framework: .NET. Namespace prefix: `{{PREFIX}}`.

## Repository layout

<!-- ==== STANDALONE variant - delete if this is a monorepo ==== -->

| Path | Purpose |
|---|---|
| `src/` | production code |
| `test/` | test projects, one per project under test |
| `docs/` | documentation |
| `docs/rules/` | the rules this repository is held to; see *Agent guidelines* below |
| `{{REPO_NAME}}.slnx` | the solution — this repository is a single component |

<!-- ==== MONOREPO variant - delete if this is standalone ==== -->

Each component is a kebab-case folder containing its own `.slnx`, `src/`,
`test/` and `README.md`. There is deliberately **no solution at the repository
root**, and no component list here: **each category's `README.md` is the map**
of what it contains, kept current by the new-project procedure. Read the
category map before assuming a component does or does not exist.

| Path | Purpose |
|---|---|
| `services/` | deployable C# services |
| `libraries/` | packages published to NuGet |
| `jobs/` | scheduled executables (Kubernetes CronJobs and similar) |
| `tools/` | internal tooling, never shipped to production |
| `infrastructure/` | provisioning (Terraform and similar) |
| `ui/` | front-end applications |
| `docs/` | documentation |
| `docs/rules/` | the rules this repository is held to; see *Agent guidelines* below |
| `build/` | CI/CD pipeline definitions |

<!-- ==== end variants ==== -->

Build configuration lives **once, at the repository root** — `Directory.Build.props`,
`Directory.Build.targets`, `Directory.Packages.props`, `Tests.props`,
`StyleCop.props`, `stylecop.ruleset`, `stylecop.json`, `.editorconfig`. Every
project inherits it. The targets file stamps every assembly's informational
version with the short commit hash (`1.2.3+abcdef12`, `-dirty` when the tree
is not clean); it never fails the build.

Never add a `Directory.Build.props`, `Directory.Build.targets`, or
`Directory.Packages.props` inside a subfolder: resolution stops at the first
file found walking upward, so a nested
copy silently severs that subtree from central package management, StyleCop and
warnings-as-errors — with a green build and no warning.

## Agent guidelines

Read the linked file **before** acting on a matching request, rather than
working from memory. Each row states *when* it applies; that trigger is what
makes it selectable from a plain-language request.

| When you are | Read |
|---|---|
| Writing, reviewing or refactoring C# in this repository | [`docs/rules/coding/csharp/csharp-coding-rules.md`](docs/rules/coding/csharp/csharp-coding-rules.md) |
| Touching an entity, a `DbContext`, or a migration | [`docs/rules/coding/csharp/csharp-ef-core-rules.md`](docs/rules/coding/csharp/csharp-ef-core-rules.md) |
| Adding a project, component, or test project | [`docs/rules/coding/csharp/csharp-new-project.md`](docs/rules/coding/csharp/csharp-new-project.md) |
| Checking a change for secrets, personal data, or local paths — or anything before a first push | [`docs/rules/security-reminders.md`](docs/rules/security-reminders.md) |
| Adding, upgrading, or replacing a package (any ecosystem) | [`docs/rules/dependencies.md`](docs/rules/dependencies.md) |
| Starting work on a ticket, naming a branch, titling a PR, or setting merge behaviour | [`docs/rules/change-tracking/github.md`](docs/rules/change-tracking/github.md) |
| Publishing the repository, committing, or opening / updating / merging a pull request | [`docs/rules/source-control/source-control.md`](docs/rules/source-control/source-control.md), then the host file it names |
| Reviewing a pull request, a diff, or a set of changes | [`docs/rules/coding/code-review.md`](docs/rules/coding/code-review.md) — then the C# or markdown checklist it names |
| Finding what exists — which component does what, where something lives | `README.md` here; in a monorepo, each category's `README.md` is the map of its components, and each component's `README.md` says how to run it |

{{ADDITIONAL_GUIDELINE_ROWS}}

The documents above are the substance, for every tool. In Claude Code some
are also invocable through a shim in `.claude/skills/` - `/project <kind>
<name>`, `/review [PR# | branch | paths | comments PR#]`,
`/source-control start|commit|pr|setup`, or just ask in plain language - each
following the same document. `/review` is the rules pass; the built-in
`/code-review` is the bug-hunting pass, and the two complement each other.

Add a row whenever a rules document is added under `docs/rules/`. A document
nobody is pointed at will not be read.

## Conventions

| Thing | Convention | Example |
|---|---|---|
| Directories | lowercase, hyphenated | `proxy-gateway` |
| Projects, assemblies, namespaces | PascalCase, prefixed | `{{PREFIX}}.ProxyGateway` |
| Test projects | `test/<Project>.Tests/` mirrors `src/<Project>/` | `{{PREFIX}}.ProxyGateway.Tests` |

A trailing `.Core` names the assembly, not the namespace: `{{PREFIX}}.Core` has
namespace `{{PREFIX}}`, and `{{PREFIX}}.Core.Tests` has `{{PREFIX}}.Tests`. This
is applied automatically by `Directory.Build.props`.

## Serena — use it when connected, fall back when not

This repository carries a [Serena](https://github.com/oraios/serena) project
file (`.serena/project.yml`); whether the server is available depends on the
machine. **Connected:** call `initial_instructions` once per coding task, then
prefer the symbolic tools — `get_symbols_overview` before reading a file,
`find_symbol` / `find_referencing_symbols` over grep, `replace_symbol_body` /
`insert_after_symbol` for symbol-scoped edits — one method body instead of a
400-line file. **Not connected:** use the ordinary tools; do not stop, install,
or ask about it mid-task. Its C# language server needs a restored solution —
`dotnet restore` first if references look incomplete.

## Building and testing

    dotnet build <solution> --nologo -v:q
    dotnet test  <solution> --nologo

**Keep build output out of context.** Always `--nologo -v:q`; grep the output
for `error|warning|Passed|Failed` and report those lines, never a full log.

**Warnings are errors.** StyleCop rules set to `Warning` fail the build; rules
at `Info` never surface at build time and appear only in the editor.

A `*.Tests` project inherits the whole test stack from `Tests.props`; its
`.csproj` holds only `TargetFramework` and a `ProjectReference`.

Do not report work as complete until `dotnet build` and `dotnet test` both pass,
and confirm the test count is what you expect — a misconfigured runner reports
zero tests and exits successfully.
