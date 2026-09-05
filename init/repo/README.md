# Repository initialization

Applies when asked to initialize, scaffold, or set up a repository at a given
root path.

Currently supports **.NET (dotnet core)** as the primary framework. For any
other framework, stop and say so rather than improvising.

## Confirm before doing anything

Ask once, in one message, for everything that has no default and is not
already in the request; never re-ask what the user has given. Everything with
a default is applied without asking and reported in the closing summary
([`verify.md`](verify.md)), which also says where each value lives so it can be changed. A
default the user may well want to revisit — the licence, the mode — is a line
in that summary and, where it is a real decision, an entry in the target's
`TODO.md`; it is not a question up front.

| Input | Default if unstated |
|---|---|
| Repository root path | *required — never guess* |
| Layout mode | ask — `standalone` or `monorepo`, see [`layout.md`](layout.md) |
| Namespace prefix | ask — e.g. `Contoso`; never invent one |
| One-line purpose | ask — lands in `AGENTS.md` and `README.md`; never invent one |
| Primary framework | .NET; the only one supported today, so it is not a question |
| StyleCop mode | relaxed |
| Central package management | on |
| Source-control mode | `local` — `auto`, `local`, or `manual`; [`settings.md`](settings.md) |
| Licence | `none` — recorded, summarised, and left as a decision in `TODO.md`; [`settings.md`](settings.md) |

## What ends up in the repository root

    AGENTS.md                    generated from AGENTS.template.md
    LICENSE, NOTICE              only if the user chose a licence (settings.md)
    README.md                    generated from README.template.md; human entry point
    .dc-agentics.yaml            settings agents read: source-control mode, every init choice, toolkit commit (settings.md)
    TODO.md                      open items; init writes anything unresolved here (settings.md)
    docs/templates/              component-README.md, category-README.md — used by /project
    .editorconfig                editor conventions (root = true)
    .gitattributes               line-ending normalization  (dotnet new)
    .gitignore                   ignore rules               (dotnet new)
    Directory.Build.props        build defaults + StyleCop import
    Directory.Build.targets      short commit hash + dirty marker in the informational version
    Directory.Packages.props     central package versions   (CPM only)
    Tests.props                  test-only packages (*.Tests projects)
    BannedSymbols.txt            banned APIs; inert until strict mode
    nuget.config                 package sources + source mapping (supply chain)
    allowed-licenses.json        dependency licence allow-list (SPDX)
    license-overrides.json       verified licences for URL-only packages
    .config/dotnet-tools.json    local tool manifest: nuget-license
    StyleCop.props               analyzer reference + wiring
    stylecop.ruleset             rule severities
    stylecop.json                StyleCop settings
    docs/rules/                  exactly as in payload/docs/rules/
      dependencies.md
      change-tracking/         change-tracking.md (rules), github.md (mechanics)
      source-control/            source-control.md (rules), github.md (mechanics)
      coding/code-review.md
      coding/csharp/             coding rules, EF Core rules, unit-test rules, new-project, code-review
      coding/markdown/markdown-review.md
    .claude/skills/
      project/SKILL.md           Claude Code shim: /project <kind> <name>
      review/SKILL.md            Claude Code shim: /review [PR# | branch | paths | comments PR#]
      source-control/SKILL.md    Claude Code shim: /source-control start|commit|pr|setup
    .github/
      PULL_REQUEST_TEMPLATE.md   GitHub fills PR bodies from it
      rulesets/protect-main.json default-branch ruleset: PR-only, squash, no force-push
    .markdownlint.yaml           markdown mechanics; the review checklist relies on it
    .serena/
      project.yml                Serena project config (auto; non-blocking)

## Stages

In order; each file is one stage, and each ends where the next begins. The
step numbers restart per file.

| Stage | File | What it does |
|---|---|---|
| 1 | [`copy.md`](copy.md) | preconditions, baseline drift check, the copy |
| 2 | [`build.md`](build.md) | StyleCop and build files against the chosen mode, the two git files, the folder structure ([`layout.md`](layout.md)); known failure modes |
| 3 | [`documents.md`](documents.md) | `AGENTS.md` and `README.md` from the templates, Serena project file, local tools |
| 4 | [`settings.md`](settings.md) | merge settings and ruleset on the host, licence, `.dc-agentics.yaml` and `TODO.md` |
| 5 | [`verify.md`](verify.md) | security pass, build and analyzer probe, licence check, closing summary |

Strict StyleCop mode is [`stylecop.md`](stylecop.md), referenced from stage 2.
