# Glossary

What each term means here, and **which document owns it**. The owning document
is the definition; this file is an index to them, so that a term used in one
place can be looked up without reading the document it came from.

Nothing here restates a definition. If a row and its document ever disagree,
the document wins and the row is the bug.

## The toolkit and what it produces

| Term | In one line | Owned by |
|---|---|---|
| **golden path** | the opinionated, fully-supported route where the easiest way to start is also the compliant one | [`README.md`](README.md) |
| **payload** | `repo/payload/` — an exact mirror of a target repository root, copied verbatim and never pruned afterwards | [`AGENTS.md`](AGENTS.md), *Layout* |
| **workspace** | everything that is *not* copied: the procedures, and this repository's own files | [`AGENTS.md`](AGENTS.md), *The distinction that matters most here* |
| **shim** | a `.claude/skills/*/SKILL.md` — frontmatter plus a pointer to the document that holds the substance | [`AGENTS.md`](AGENTS.md), *Layout* |
| **target** | a repository dc-agentics initialized, as distinct from the toolkit itself | [`repo/version-check.md`](repo/version-check.md) |
| **baseline** | the pristine `dotnet new` output in `repo/baselines/`, hash-verified byte-for-byte; never copied to a target | [`repo/copy.md`](repo/copy.md), *Baseline drift check* |
| **marker** | a recorded "this was verified together, and when" — `dc-agentics-baseline`, `dc-agentics-verified`, `guidelines.verified` | [`repo/upgrade.md`](repo/upgrade.md), *The markers* |
| **drift** | a recorded value no longer matching reality: an SDK that moved, settings that no longer describe the repository | [`repo/payload/agentics/rules/scrub.md`](repo/payload/agentics/rules/scrub.md) |

## Operations

Each is a distinct verb, so a refusal can name exactly which one it means.

| Term | In one line | Owned by |
|---|---|---|
| **initialization** | landing the payload in a repository for the first time; five stages | [`repo/initialize.md`](repo/initialize.md) |
| **toolkit version** | which toolkit commit a repository currently carries — `toolkit.commit` in its settings | [`repo/settings.md`](repo/settings.md) |
| **toolkit upgrade** | bringing a target up to a newer toolkit commit; operation 2 | [`repo/upgrade.md`](repo/upgrade.md) |
| **layout conversion** | changing a target from standalone to monorepo; operation 3, and the one that needs no toolkit checkout | [`repo/upgrade.md`](repo/upgrade.md) |
| **scrub** | a consistency and drift pass that reports and changes nothing | [`repo/payload/agentics/rules/scrub.md`](repo/payload/agentics/rules/scrub.md) |
| **re-baselining** | replacing a pristine baseline after an upstream template changed, and updating its marker | [`repo/copy.md`](repo/copy.md) |

## How a repository is shaped

| Term | In one line | Owned by |
|---|---|---|
| **component** | one solution and one `src/` + `test/` pair; its projects build and version together, and may produce more than one deliverable | [`repo/payload/agentics/rules/layout.md`](repo/payload/agentics/rules/layout.md) |
| **standalone** | a single-component repository; the component *is* the repository | [`repo/payload/agentics/rules/layout.md`](repo/payload/agentics/rules/layout.md) |
| **monorepo** | many components, each under a category folder, each with its own solution | [`repo/payload/agentics/rules/layout.md`](repo/payload/agentics/rules/layout.md) |
| **category** | a root folder grouping components by kind — `services/`, `libraries/`, `jobs/`, `tools/`, `ui/`, `infrastructure/` | [`repo/payload/agentics/rules/layout.md`](repo/payload/agentics/rules/layout.md) |
| **solution** | the `.slnx`, named after its component's **main project**, never after the folder | [`repo/payload/agentics/rules/layout.md`](repo/payload/agentics/rules/layout.md), *Naming rules* |

## Settings

| Term | In one line | Owned by |
|---|---|---|
| **mode** | what an agent may do without asking — `auto`, `local`, `manual`; absent means manual | [`repo/payload/agentics/rules/source-control/source-control.md`](repo/payload/agentics/rules/source-control/source-control.md), *For an agent* |
| **tracker** | whether the repository tracks work as GitHub Issues, or not at all | [`repo/payload/agentics/rules/change-tracking/change-tracking.md`](repo/payload/agentics/rules/change-tracking/change-tracking.md) |
| **model baseline** | the model line the guidelines were written against, and when a full trial last passed on it | [`README.md`](README.md), *A note on models* |
| **always-loaded** | read every session with no trigger to gate it: `AGENTS.md`, and each skill's name and description | [`AGENTS.md`](AGENTS.md), *Authoring payload* |
