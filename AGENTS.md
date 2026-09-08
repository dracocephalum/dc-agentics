# dc-agentics

A golden path for C# repositories: reusable rules, build configuration,
procedures and boilerplate that stand a new project up already meeting the
standard, and hold later changes to it there.

Consumed by *other* repos — its output is copied, referenced, or installed into
them. Nothing here is application code.

## Task index

Start here. Open the linked file and follow it; do not reconstruct a procedure
from memory, and do not copy files without reading the instructions that govern
them.

| When asked to | Read |
|---|---|
| Set up a developer machine, install tooling, or fix Python/Git setup | [`machine/README.md`](machine/README.md) |
| Install or wire Serena (or another MCP server) into Claude Code | [`machine/serena.md`](machine/serena.md) |
| Set up GitHub access, SSH keys, commit signing, or `gh` | [`machine/github.md`](machine/github.md) |
| Set up or troubleshoot secret scanning / git hooks | [`machine/gitleaks.md`](machine/gitleaks.md) |
| Set up a machine that is **not Windows** (Linux, macOS, FreeBSD) | [`machine/platforms.md`](machine/platforms.md) — untested, read first |
| Add or upgrade a package; judge a licence | [`repo/payload/agentics/rules/dependencies.md`](repo/payload/agentics/rules/dependencies.md) |
| Create or find a ticket, or ask which ticket a change is for (`/change-tracking`) | [`repo/payload/agentics/rules/change-tracking/change-tracking.md`](repo/payload/agentics/rules/change-tracking/change-tracking.md), then the tracker file it names |
| Start work on a ticket, name a branch, publish a repository, commit, or open / update / merge a pull request, set merge behaviour (`/source-control`) | [`repo/payload/agentics/rules/source-control/source-control.md`](repo/payload/agentics/rules/source-control/source-control.md), then the host file it names |
| Review a PR, a diff, or changes — including changes to this toolkit (`/review`) | [`repo/payload/agentics/rules/coding/code-review.md`](repo/payload/agentics/rules/coding/code-review.md), then the C# or markdown checklist |
| Scrub, sweep, or audit a repository for drift or inconsistency (`/scrub`) | [`repo/scrub.md`](repo/scrub.md) here; [`repo/payload/agentics/rules/scrub.md`](repo/payload/agentics/rules/scrub.md) is the part every target gets |
| Add a project, a test project, or a whole component to an initialized repo (`/new`) | [`repo/payload/agentics/rules/coding/csharp/csharp-new-project.md`](repo/payload/agentics/rules/coding/csharp/csharp-new-project.md) — from a toolkit checkout, [`repo/version-check.md`](repo/version-check.md) first |
| Initialize / scaffold / set up a repo at a path | [`repo/initialize.md`](repo/initialize.md) |
| Upgrade this toolkit's pinned versions, bring an initialized repo up to the current toolkit, or convert one from standalone to monorepo (`/upgrade`) | [`repo/upgrade.md`](repo/upgrade.md) — three operations; the conversion needs no toolkit checkout |
| Change a StyleCop severity, or asked why a rule is set the way it is | [`repo/stylecop.md`](repo/stylecop.md) — the ruleset's own header carries the principle |
| Check privacy/security before a first push | [`repo/payload/agentics/rules/security-reminders.md`](repo/payload/agentics/rules/security-reminders.md) |
| Asked what a term here means — payload, baseline, component, toolkit upgrade, drift | [`GLOSSARY.md`](GLOSSARY.md) — an index to the document that owns each term, never a second definition |
| Capture an idea that is not committed work, or asked what might be built later | [`PLAN.md`](PLAN.md) — `TODO.md` is for decided work; see the table at the top of either |

Supported frameworks today: **.NET (dotnet core)** only. For anything else, say
so rather than improvising.

## Layout

Three kinds of file, told apart by location:

    (3) workspace - about this repo; never copied
    README.md  AGENTS.md  TODO.md  PLAN.md  LICENSE  NOTICE  .gitignore  .gitattributes
    GLOSSARY.md                    index of terms to the document that owns each; never a second definition
    .agentics.yaml              this repository's own settings (source-control mode); same shape as the payload's
    .markdownlint.yaml             one line: extends the payload copy (so it cannot drift)
    machine/                       setting up a machine (README.md, then github/gitleaks/python/serena)
                                   Windows and interactive today; platforms.md for other platforms
    repo/                          acting on a target repository
      initialize.md                repo initialization: inputs, what lands, the five stages
      copy.md  build.md  documents.md  settings.md  verify.md   one stage each, in that order
      scrub.md                     consistency + drift pass for THIS repo; extends the payload checklist
      upgrade.md                   toolkit pins, a target up to the toolkit, standalone -> monorepo
      version-check.md             does a target agree with this toolkit; used by /upgrade and /new
      stylecop.md                  the ruleset: what each severity means, how to change one, the wiring
      baselines/                   pristine `dotnet new` output, NEVER copied to a target
                                   path mirrors payload/; .original suffix keeps them inert

    (1)+(2) payload - an EXACT mirror of a target repository root; copied verbatim
    repo/payload/
      .agentics.yaml            settings agents read: source-control mode, init choices, toolkit commit; placeholders filled at init
      TODO.md                      the target's open-items file; init writes anything unresolved into it
      .editorconfig  .gitignore  .gitattributes   (forked; baselines live in repo/baselines/)
      stylecop.ruleset  stylecop.json  StyleCop.props
      Directory.Build.props  Directory.Build.targets  Directory.Packages.props  Tests.props  BannedSymbols.txt
      nuget.config  allowed-licenses.json  license-overrides.json
      .config/dotnet-tools.json  .github/PULL_REQUEST_TEMPLATE.md  .github/rulesets/protect-main.json  .markdownlint.yaml
      agentics/rules/                  every rules document, exactly where it lands
        dependencies.md
        layout.md                  standalone + monorepo trees, naming, test projects, stack currency
        scrub.md                   the consistency + drift checks every target gets
        security-reminders.md      privacy & data-security checklist; the review's security pass
        change-tracking/         change-tracking.md - the ticket rule, the yes/no setting, boards as views; github.md - issues, linked branches
        source-control/          source-control.md - the rules, host-neutral; github.md - reaching GitHub, publishing, PRs, review, settings
        coding/code-review.md
        coding/csharp/             coding rules, EF Core rules, unit-test rules, new-project, code-review
        coding/markdown/markdown-review.md
      agentics/templates/              AGENTS.template.md, README.template.md - transformed at init, and kept
                                   component-README.md, category-README.md - filled by /new
                                   all four stay in the target, both modes; repo/documents.md says why

    (2) the one thing copied from OUTSIDE payload/
    .claude/skills/                skill shims; live here, copied to a target's .claude/skills/
      new/SKILL.md                 /new     - a project, or a whole component
      review/SKILL.md              /review  - PR, branch, files, or comment triage; post/print/report
      change-tracking/SKILL.md     /change-tracking - create or find a ticket
      source-control/SKILL.md      /source-control - ticket-linked branch, commit, draft PR, merge settings
      scrub/SKILL.md               /scrub   - consistency + drift pass; reports, does not fix
      upgrade/SKILL.md             /upgrade - toolkit pins, a target to the toolkit, or standalone -> monorepo

Three payload files are forked from `dotnet new` templates - `.editorconfig`,
`.gitignore`, `.gitattributes` - and each carries a `agentics-baseline:`
marker with the SDK it came from and a hash of the pristine output, which lives
in `repo/baselines/` and is never copied to a target. How the drift check
works, why the hash is over normalized bytes, why the baselines are never
edited, and why their `.original` suffix and the root `-text` rule are both
load-bearing: [`repo/copy.md`](repo/copy.md), *Baseline drift check*.

Rules documents keep their relative links correct by construction: `agentics/rules/`
inside `payload/` *is* the target layout. Only links up to the root `AGENTS.md`
cannot be relative in both trees; those are plain text.

## The distinction that matters most here

This repo holds two kinds of content, and confusing them causes real damage:

**Payload** — `repo/payload/` (an exact mirror of a target repository
root) and the skill shims in `.claude/skills/`. Written to be consumed in
*someone else's* project, on an unknown machine. Must be portable and
self-contained.

**Workspace** — everything else: this file, `README.md`, `TODO.md`, `PLAN.md`, the
procedures under `machine/` and `repo/`, and the repo tooling. Instructions for
an agent working *on* dc-agentics itself.

Before writing a file, decide which it is. A rule that reads naturally as advice
to "you, working here" is usually wrong as payload, because payload gets copied
somewhere the surrounding context no longer holds.

## Authoring payload

- **No absolute paths.** Not to this machine, not to any machine. Use relative
  paths, environment variables, or a documented placeholder.
- **No assumed toolchain.** Don't assume a package manager, shell, OS, or editor
  unless the file explicitly scopes itself to one. State the assumption if you
  make it.
- **Self-contained.** Payload must not depend on a sibling file existing at a
  path that only holds inside this repo.
- **Say when it applies, not just what to do.** A rule with no trigger gets
  applied everywhere or nowhere. The trigger is also what keeps a long document
  cheap: nobody pays for `csharp-ef-core-rules.md` unless they touch EF Core.
- **One owner per rule, and a rule needed on both sides is owned by the
  payload.** A toolkit document may link into `repo/payload/`; nothing shipped
  may ever link out, because a target has no `repo/`. So when a rule is needed
  here and in a target, the payload copy is the definition and the toolkit
  copy is a link to it. A shim keeps only the instruction, never the reasoning.
  The exception is the generated `AGENTS.md`, which restates the few rules an
  agent must act on without opening anything - one sentence each, with a link.
- **Budget by what is always loaded, not by total size.** `AGENTS.md` is read
  every session with no trigger to gate it, and so is each shim's name and
  description - a shim's body loads only when it is invoked. Everything under
  `agentics/rules/` is loaded on demand, where depth costs nothing until its trigger
  fires; length there is only a problem if the trigger is too broad. Splitting a
  document that is always loaded saves nothing, and splitting one whose parts
  share a single trigger just adds files to open.
- **Examples must run.** A boilerplate that was never executed is a liability.
  If it can't be verified, mark it explicitly as untested.
- **Prefer a real file over a snippet in prose.** Templates that are actual files
  can be copied and validated; snippets rot.
- **A skill is a shim; the document is the substance.** `SKILL.md` carries
  frontmatter for discovery and a body that names which document to follow -
  it never contains the procedure. The document lives at
  `repo/payload/agentics/rules/` here and lands at `agentics/rules/` in
  initialized repositories, and `AGENTS.md` points every tool at it; the shim
  only adds `/name` invocation in Claude Code. There is one copy:
  `.claude/skills/<name>/SKILL.md`, live here and copied to a target's
  `.claude/skills/` at init - the one thing shipped from outside `payload/`.
  It locates its document by repository-root-relative path with a toolkit
  fallback - never `../../../` - so one file works in both places.
- **Shell snippets are POSIX `sh`.** No GNU-only flags (`sed -i` without a
  suffix, `readlink -f`, `grep -P`, `timeout`), no `sha256sum` without naming
  the macOS/FreeBSD equivalents, no backslash paths. The payload is verified on
  Windows only; a snippet that is portable by construction is the only one that
  does not need a machine we do not have. See `machine/platforms.md`.
- **Writing files from a shell: no backslashes in heredocs.** The shell tool
  pre-processes the command text: a `\\` arrives as a single backslash, a line
  ending in a backslash joins the next, and a batch of several quoted heredocs
  containing one such line failed to parse and ran nothing — observed on
  Windows, 2026-09-05. The markdown here has such lines (the `gh repo edit`
  continuation). Use the editor tools for any file that contains a backslash
  and for multi-file writes; keep shell heredocs to one per call.

## Publishing constraints

This repo may be pushed to a public remote. In every file — code, comments,
docs, config, tests, commit messages:

- No local or machine-specific paths
- No personal information: real names, email addresses, usernames, hostnames
- No credentials, tokens, or API keys, including in example and placeholder values

If a real path or identifier is needed to run something, put it in a gitignored
local config file and reference that file instead.

## Status

Open items live in [`TODO.md`](TODO.md) and uncommitted ideas in
[`PLAN.md`](PLAN.md); check both before assuming something
was never considered.

Early scaffold. There is no build, no test suite, and no release process yet.
Don't infer conventions from a near-empty tree — if a convention isn't written
down here, it hasn't been decided.

The .NET initialization path was verified end to end on SDK 10.0.400 with
StyleCop.Analyzers 1.2.0-beta.556: clean build, inherited properties reaching a
nested project, `stylecop.json` registered, and SA1414 failing the build as a
liveness probe.
