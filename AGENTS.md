# dc-agentics

An agentics toolkit: reusable instructions, rules, boilerplates, and examples for
standing up new projects and improving agentic workflow performance.

Consumed by *other* repos — its output is copied, referenced, or installed into
them. Nothing here is application code.

## Task index

Start here. Open the linked file and follow it; do not reconstruct a procedure
from memory, and do not copy files without reading the instructions that govern
them.

| When asked to | Read |
|---|---|
| Set up a developer machine, install tooling, or fix Python/Git setup | [`init/local/README.md`](init/local/README.md) |
| Install or wire Serena (or another MCP server) into Claude Code | [`init/local/serena.md`](init/local/serena.md) |
| Set up GitHub access, SSH keys, commit signing, or `gh` | [`init/local/github.md`](init/local/github.md) |
| Set up or troubleshoot secret scanning / git hooks | [`init/local/gitleaks.md`](init/local/gitleaks.md) |
| Set up a machine that is **not Windows** (Linux, macOS, FreeBSD) | [`init/local/platforms.md`](init/local/platforms.md) — untested, read first |
| Add or upgrade a package; judge a licence | [`init/repo/payload/docs/rules/dependencies.md`](init/repo/payload/docs/rules/dependencies.md) |
| Start work on a ticket, name a branch, title a PR, set merge behaviour (`/source-control`) | [`init/repo/payload/docs/rules/change-tracking/github.md`](init/repo/payload/docs/rules/change-tracking/github.md) |
| Publish a repository (first push), commit, or open / update / merge a pull request | [`init/repo/payload/docs/rules/source-control/source-control.md`](init/repo/payload/docs/rules/source-control/source-control.md), then the host file it names |
| Review a PR, a diff, or changes — including changes to this toolkit (`/review`) | [`init/repo/payload/docs/rules/coding/code-review.md`](init/repo/payload/docs/rules/coding/code-review.md), then the C# or markdown checklist |
| Initialize / scaffold / set up a repo at a path | [`init/repo/README.md`](init/repo/README.md) |
| Set up StyleCop, or choose relaxed vs strict | [`init/repo/stylecop.md`](init/repo/stylecop.md) |
| Check privacy/security before a first push | [`init/repo/payload/docs/rules/security-reminders.md`](init/repo/payload/docs/rules/security-reminders.md) |

Supported frameworks today: **.NET (dotnet core)** only. For anything else, say
so rather than improvising.

## Layout

Three kinds of file, told apart by location:

    (3) workspace - about this repo; never copied
    README.md  AGENTS.md  TODO.md  LICENSE  NOTICE  .gitignore  .gitattributes
    .markdownlint.yaml             one line: extends the payload copy (so it cannot drift)
    init/
      local/                       developer-machine guides (Windows; platforms.md for the rest)
      repo/
        README.md                  repo initialization procedure
        layout.md                  standalone + monorepo folder structures
        stylecop.md                StyleCop relaxed/strict procedure

    (1)+(2) payload - an EXACT mirror of a target repository root; copied verbatim
    init/repo/payload/
      AGENTS.template.md           transformed at init (-> AGENTS.md)
      README.template.md           transformed at init (-> README.md); the human entry point
      .editorconfig  .gitignore  .gitattributes   (+ .original pristine baselines - never edit)
      stylecop.ruleset  stylecop.json  StyleCop.props
      Directory.Build.props  Directory.Build.targets  Directory.Packages.props  Tests.props  BannedSymbols.txt
      nuget.config  allowed-licenses.json  license-overrides.json
      .config/dotnet-tools.json  .github/PULL_REQUEST_TEMPLATE.md  .github/rulesets/protect-main.json  .markdownlint.yaml
      docs/rules/                  every rules document, exactly where it lands
        dependencies.md
        security-reminders.md      privacy & data-security checklist; the review's security pass
        change-tracking/github.md  ticket = issue; ticket-first branches and PR titles; merge settings; review mechanics
        source-control/          source-control.md - the rules, host-neutral; github.md - the mechanics
        coding/code-review.md
        coding/csharp/             coding rules, EF Core rules, unit-test rules, new-project, code-review
        coding/markdown/markdown-review.md
      docs/templates/              component-README.md, category-README.md - filled by /project

    (2) the one thing copied from OUTSIDE payload/
    .claude/skills/                skill shims; live here, copied to a target's .claude/skills/
      project/SKILL.md             /project - add a component or project
      review/SKILL.md              /review  - PR, branch, files, or comment triage; post/print/report
      source-control/SKILL.md      /source-control - ticket-linked branch, commit, draft PR, merge settings

Three payload files are forked from `dotnet new` templates and carry a
`dc-agentics-baseline:` marker recording the source SDK and the SHA-256 of the
pristine generated file: `.editorconfig`, `.gitignore`, `.gitattributes`.
Init step 0.5 re-checks them and stops on drift. Hashes are over
newline-normalized bytes - never raw, since `dotnet new` emits CRLF and
`text=auto` checks out LF. Each has a pristine `.original` sibling, stored
LF-normalized so it hashes directly to its marker; drift is isolated by diffing
a freshly generated template against the `.original`, never against our
version. Never edit an `.original` - they carry no header precisely because a
header would change the bytes the hash verifies.

Rules documents keep their relative links correct by construction: `docs/rules/`
inside `payload/` *is* the target layout. Only links up to the root `AGENTS.md`
cannot be relative in both trees; those are plain text.

## The distinction that matters most here

This repo holds two kinds of content, and confusing them causes real damage:

**Payload** — `init/repo/payload/` (an exact mirror of a target repository
root) and the skill shims in `.claude/skills/`. Written to be consumed in
*someone else's* project, on an unknown machine. Must be portable and
self-contained.

**Workspace** — everything else: this file, `README.md`, `TODO.md`, the
procedures under `init/`, and the repo tooling. Instructions for an agent
working *on* dc-agentics itself.

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
  applied everywhere or nowhere.
- **Examples must run.** A boilerplate that was never executed is a liability.
  If it can't be verified, mark it explicitly as untested.
- **Prefer a real file over a snippet in prose.** Templates that are actual files
  can be copied and validated; snippets rot.
- **A skill is a shim; the document is the substance.** `SKILL.md` carries
  frontmatter for discovery and a body that names which document to follow -
  it never contains the procedure. The document lives at
  `init/repo/payload/docs/rules/` here and lands at `docs/rules/` in
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
  does not need a machine we do not have. See `init/local/platforms.md`.
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

Open items live in [`TODO.md`](TODO.md); check it before assuming something
was never considered.

Early scaffold. There is no build, no test suite, and no release process yet.
Don't infer conventions from a near-empty tree — if a convention isn't written
down here, it hasn't been decided.

The .NET initialization path was verified end to end on SDK 10.0.400 with
StyleCop.Analyzers 1.2.0-beta.556: clean build, inherited properties reaching a
nested project, `stylecop.json` registered, and SA1414 failing the build as a
liveness probe.
