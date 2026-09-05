# Repository initialization

Applies when asked to initialize, scaffold, or set up a repository at a given
root path.

Currently supports **.NET (dotnet core)** as the primary framework. For any
other framework, stop and say so rather than improvising.

## Confirm before doing anything

Ask once, in one message, for everything that has no default and is not
already in the request; never re-ask what the user has given. Everything with
a default is applied without asking and reported in the closing summary
(step 6), which also says where each value lives so it can be changed. A
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
| Source-control mode | `local` — `auto`, `local`, or `manual`; step 3.11 |
| Licence | `none` — recorded, summarised, and left as a decision in `TODO.md`; step 3.10 |

## What ends up in the repository root

    AGENTS.md                    generated from AGENTS.template.md
    LICENSE, NOTICE              only if the user chose a licence (step 3.10)
    README.md                    generated from README.template.md; human entry point
    .dc-agentics.yaml            settings agents read: source-control mode, every init choice, toolkit commit (step 3.11)
    TODO.md                      open items; init writes anything unresolved here (step 3.11)
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
      change-tracking/github.md
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

## Steps

`payload/` is an exact mirror of a target repository root. After the
preconditions and the drift check, the copy is one command:

    cp -r payload/. <target>/
    find <target> -name '*.original' -delete

plus `.claude/skills/` from the toolkit root. Everything else in the steps
below is what to *verify* or *edit* in what just landed — `AGENTS.template.md`
becomes `AGENTS.md` (step 3.6), strict mode edits three files (steps 1, 2).

### 0. Preconditions

List which of the target files already exist. **Do not overwrite anything
without saying so first** — an existing `Directory.Build.props` very likely
carries settings that matter.

If one exists, merge into it rather than replacing: add the `Import` line to the
existing file, keep its current properties.

Note whether the path is a git repository. Do not run `git init` unless asked.

### 0.5 Baseline drift check

Three of the files we ship were forked from `dotnet new` templates. Each carries
a marker naming the SDK it was captured from and the SHA-256 of the pristine
generated file:

    # dc-agentics-baseline: source=<name> sdk=<version> sha256=<hash>

| File | Marker lives in |
|---|---|
| `.editorconfig` | `payload/.editorconfig` |
| `.gitignore` | `payload/.gitignore` |
| `.gitattributes` | `payload/.gitattributes` |

Regenerate each into a scratch directory and compare:

    dotnet new <name> -o <scratch>
    tr -d '\r' < <scratch>/<file> | sha256sum       # macOS: shasum -a 256   FreeBSD: sha256

**Hash the newline-normalized bytes, never the raw file.** `dotnet new` emits
CRLF, while `* text=auto` checks out LF on other platforms — a raw hash
false-positives on every non-Windows machine.

**On a mismatch, stop and ask.** Do not regenerate, do not merge, do not
silently proceed. Report which file drifted, the recorded SDK version versus the
current one, and let the user decide whether to continue with our version or
pause to re-baseline.

#### Showing what changed

Each forked file has a pristine `.original` sibling — the generated template
exactly as captured, with newlines normalized to LF:

    payload/.editorconfig.original
    payload/.gitignore.original
    payload/.gitattributes.original

They hash **directly** to the marker value, with no further normalization:

    sha256sum < payload/.editorconfig.original

When drift fires and the user asks what changed, diff the freshly generated
template against the original. That isolates the upstream change on its own:

    diff <scratch>/.editorconfig payload/.editorconfig.original

Diffing against *our* version instead is not equivalent — it mixes the upstream
change with our own edits, which is exactly what makes such a diff unreadable.

From there the user can apply the upstream change by hand, and re-baseline by
replacing the `.original` and updating the marker's `sdk=` and `sha256=` fields.

**Never edit an `.original` file.** They carry no header explaining this, because
adding one would change their bytes and break the hash they exist to verify.

A mismatch is not automatically a problem. It matters most for `.editorconfig`,
whose reconciliation depends on the generated content — an upstream change can
make our edits redundant or leave a new conflict uncovered. For `.gitignore` and
`.gitattributes` our changes are purely additive, so drift is informational.

If the recorded SDK equals the installed SDK and the hash still differs,
something is wrong with the file, not the template. Say so rather than guessing.

### 1. The StyleCop files

Already at the target root after the payload copy: `stylecop.ruleset`
(ships in relaxed mode), `stylecop.json`, `StyleCop.props`, `.editorconfig`.

`.editorconfig` declares `root = true`, so it must land at the **repository
root** — any `.editorconfig` above it is then ignored, which is the intent.

It has been reconciled with `stylecop.ruleset`: the ruleset governs the build,
`.editorconfig` governs the editor, and where they overlap the ruleset wins and
`.editorconfig` is the file that was changed to match. Do not substitute a
stock `dotnet new editorconfig` here — its `insert_final_newline = false`
contradicts `stylecop.json` and produces SA1518 on every file.

For **strict** mode, apply the rule edits in
[`stylecop.md`](stylecop.md) — note the XML
comment-nesting trap documented there; the naive edit produces invalid XML.

Strict mode requires a matching `.editorconfig` change: flip the four
`dotnet_style_qualification_for_*` settings to `true`, because strict re-enables
SA1101. Skipping this leaves the IDE offering to remove `this.` while the build
errors for its absence. The STRICT MODE block at the end of `.editorconfig`
spells this out.

### 2. Generate the build files

Already at the target root after the payload copy: `Directory.Build.props`,
`Directory.Build.targets`, `Directory.Packages.props`, `Tests.props`,
`BannedSymbols.txt`, `nuget.config`. The props files reference each other by
`$(MSBuildThisFileDirectory)` and must stay together.

`Directory.Build.targets` stamps every assembly's informational version with
the short commit hash — `1.2.3+abcdef12`, `-dirty` when the tree is not clean —
via `git describe` ahead of the SDK's own source-control step. Verified
fail-safe: no repository or no commits build clean as `1.2.3`; no `git` on
`PATH` leaves the SDK's full hash. Read it back from
`AssemblyInformationalVersionAttribute`.

`nuget.config` clears inherited package sources and maps every package to
nuget.org. A private feed is added there, with its own package pattern — see
the comment in the file. `Directory.Build.props` turns on lock files: after
the first restore every project has a `packages.lock.json`, and **those are
committed** — they are what makes restores reproducible and what lets CI see
transitive packages.

For **strict** mode, also uncomment the entries in `BannedSymbols.txt` — see
[`stylecop.md`](stylecop.md).

If central package management is **off**, omit `Directory.Packages.props` and
set the analyzer version via `$(StyleCopAnalyzersVersion)` in `StyleCop.props`
instead.

If it is **on**, `Directory.Packages.props` must declare
`StyleCop.Analyzers` — `StyleCop.props` deliberately omits the version under CPM
and restore fails without it.

### 3. .gitignore and .gitattributes

Both arrive with the payload copy. They are the SDK templates plus our
additions, each carrying a baseline marker — see the drift check in step 0.5.

`.gitignore` already includes the local-config entries the official template
omits (`*.local.json`, `.env`, and similar). Ignore entries must exist **before**
the files they cover — ignoring an already-tracked file has no effect. See
[`payload/docs/rules/security-reminders.md`](payload/docs/rules/security-reminders.md).

#### Why .gitattributes matters here

Its first line is `* text=auto`, which normalizes line endings to LF **inside
the repository** while checking out native endings on each platform. Without it,
a repo touched from both Windows and Linux accumulates whole-file diffs where
nothing changed but CRLF/LF.

This is cheapest at initialization, on an empty repo. Adding `text=auto` to a
repository that already has tracked files does nothing to them until:

    git add --renormalize .

which rewrites every affected file in one large, noisy commit. Doing it now
avoids that entirely.

The template also sets `*.cs text diff=csharp` (better diff hunk headers) and
`*.sln text eol=crlf` (Visual Studio expects CRLF there).

### 3.5 Create the folder structure

Follow [`layout.md`](layout.md) for the chosen mode. It covers the standalone
and monorepo trees, the kebab-case-directory / PascalCase-project naming rule,
per-folder conventions, and the two SDK-template defects that break the first
build (CPM version conflicts, and placeholder files that violate StyleCop).

Root configuration files exist **once**, at the repository root, in both modes.
Never copy them into component folders.

### 3.6 onward — continue in `finish.md`

The remaining steps — documentation and `AGENTS.md`, Serena, the licence
policy, merge settings, the licence, the settings file and `TODO.md`, the
security pass, verification, and the closing summary — are in
[`finish.md`](finish.md). Separated for length only; the numbering continues
there, and *Known failure modes* below applies to both.

## Known failure modes

| Symptom | Cause |
|---|---|
| Build green, no diagnostics ever | ruleset path wrong, or `StyleCop.props` never imported |
| `NU1008` | package `Version` supplied while CPM is active |
| Package version not found on restore | `StyleCop.Analyzers` missing from `Directory.Packages.props` |
| Settings ignored | `stylecop.json` not registered as an `AdditionalFiles` item |
| Subtree silently unstyled | a nested `Directory.Build.props` replaced the root one |
| Ruleset fails to load | nested XML comments from a bad strict-mode edit |
