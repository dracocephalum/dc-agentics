<!--
  TEMPLATE - transformed at initialization into the repository's README.md.
  Fill every double-brace placeholder, keep the variant that applies, delete
  this comment. Written for people; agents use AGENTS.md.
-->

# {{REPO_NAME}}

> Initialized with <https://github.com/dracocephalum/dc-agentics>.\
> {{AGENT_TOOL}} · {{MODEL}} · dc-agentics@{{TOOLKIT_COMMIT}}

{{ONE_LINE_PURPOSE}}

<!-- ==== STANDALONE variant - delete if this is a monorepo ==== -->

## What it is

<!-- Two or three sentences: what this component does, who consumes it, what it depends on. -->

## Run it locally

    dotnet build {{REPO_NAME}}.slnx --nologo -v:q
    dotnet test  {{REPO_NAME}}.slnx --nologo

<!-- Anything beyond build and test: configuration to set, a database to start, a URL to open. -->

## Layout

| Path | Purpose |
|---|---|
| `src/` | production code |
| `test/` | tests |
| `docs/rules/` | the rules this repository is held to — see `AGENTS.md` |

<!-- ==== MONOREPO variant - delete if this is standalone ==== -->

## What is in here

Each category folder holds independent components, one solution each. The
**map of components lives in each category's `README.md`**; this file is the
map of categories.

| Category | What lives there | Map |
|---|---|---|
| `services/` | deployable services | [`services/README.md`](services/README.md) |
| `libraries/` | packages published to NuGet | [`libraries/README.md`](libraries/README.md) |
| `jobs/` | scheduled executables | [`jobs/README.md`](jobs/README.md) |
| `tools/` | internal tooling, never shipped | [`tools/README.md`](tools/README.md) |
| `infrastructure/` | provisioning | — |
| `ui/` | front-end applications | — |

<!-- Keep only the rows for folders that exist. -->

## Working here

- One solution per component; **no root solution** — build the component you
  are changing.
- Build configuration is inherited from the root by every component.
- Every component has its own `README.md`: what it is, how to run it, how to
  test it.

<!-- ==== end variants ==== -->

## Conventions and rules

`AGENTS.md` is the index. The rules under `docs/rules/` are the standard for
code, tests, dependencies, pull requests, and review — for people as much as
for agents.
