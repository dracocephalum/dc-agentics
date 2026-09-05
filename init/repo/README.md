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

### 3.6 Documentation and AGENTS.md

`docs/rules/`, `.github/`, and `.markdownlint.yaml` arrive with the payload
copy, in both modes, exactly as they sit in `payload/` — so every relative
link between rules files resolves identically here and there. `.claude/skills/`
is copied from the toolkit root: each `SKILL.md` is a shim — frontmatter so
Claude Code can invoke it, and a pointer to its document under `docs/rules/`,
located by repository-root-relative path with a toolkit fallback. The document
is the substance and `AGENTS.md` points every tool at it, so a team without
Claude Code loses nothing by skipping the shims.

Then generate the repository's own `AGENTS.md` at its root from
[`payload/AGENTS.template.md`](payload/AGENTS.template.md) — it arrived at the
target root with the copy; transform it in place:

1. Fill every double-brace placeholder — `REPO_NAME`, `ONE_LINE_PURPOSE`,
   `PREFIX`. Ask for the purpose line rather than inventing one.
2. Delete the layout variant that does not apply (standalone or monorepo), and
   the surrounding `==== variant ====` comments.
3. Trim the folder table to folders that **actually exist**. A row for a folder
   you did not create is a false statement about the repository.
4. Delete the instruction comment at the top of the template.
5. Add a table row for any further rules documents, then delete the
   `ADDITIONAL_GUIDELINE_ROWS` line — it sits below the table as a reminder,
   not as a row.

Then the repository's `README.md`, from `README.template.md` (it arrived at the
target root with the copy) by the same transform: fill placeholders, keep the
matching layout variant, delete the template comment. It is the human entry
point; `AGENTS.md` is the agent's. The line under its title points at
`.dc-agentics.yaml` for provenance and choices (step 3.11) and at `TODO.md`
for open items; it has no placeholders of its own. In a monorepo, also give
every category folder you create its map —
`docs/templates/category-README.md` copied to `<category>/README.md` and
filled. Component READMEs come from the new-project procedure.

Verify nothing was missed:

    grep -n "{{" <repo>/AGENTS.md <repo>/README.md      # must return nothing
    ls <repo>/README.template.md                           # must NOT exist

#### Why the guideline rows are phrased as situations

Each row says *when* it applies — "when you are writing, reviewing or
refactoring C#" — because a plain-language request can be matched against a
situation and not against a filename. Keep that phrasing when adding rows.

### 3.7 Serena project config — automatic, non-blocking

Every initialized repository gets a Serena project file. Most repositories are
code repositories, so this is opt-out rather than opt-in; for a docs-only
repository it is harmless and can be deleted.

At the repository root, **always passing the languages explicitly**:

    serena project create --language csharp
    serena project create --language csharp --language terraform   # monorepo with infrastructure/

Never let it infer. On a tree with more than one language, inference picks a
"main" language and then **prompts `[y/N]` for each additional one** — and
with no interactive stdin it aborts with `Aborted!` and writes nothing.
`--language` skips inference entirely. The toolkit knows the answer anyway:
C#, plus `terraform` when the repository has an `infrastructure/` folder.

That writes `.serena/project.yml`. Commit it (and the `.serena/.gitignore`
Serena writes on first index — the shipped repository `.gitignore` already
covers the per-machine files in the meantime).

**This step never blocks initialization.** If `serena` is not on `PATH`, is
not installed, or the command fails for any reason: report it in one line —
`Serena project config skipped: <reason>` — add the same line under
*Initialization* in the target's `TODO.md` with the command to run, and
continue with step 4. Do not install Serena, do not modify `PATH`, do not ask
the user mid-procedure. The
generated `AGENTS.md` already tells agents to fall back when Serena is absent,
so nothing downstream depends on this file existing.

Skip `serena project index` at initialization: it needs a restored solution
and there is no code yet.

Details, and the two choices behind the machine-level wiring, are in
[`../local/serena.md`](../local/serena.md).

### 3.8 Dependency licence policy

`allowed-licenses.json`, `license-overrides.json` and
`.config/dotnet-tools.json` arrive with the payload copy. Then:

    dotnet tool restore

That installs `nuget-license` as a repository-local tool (pinned in the
manifest, nothing global). The policy itself is
[`payload/docs/rules/dependencies.md`](payload/docs/rules/dependencies.md), shipped to the
repository as `docs/rules/dependencies.md` and referenced from `AGENTS.md`.

The check is part of step 5 — run it there, not here; there are no packages to
judge until a project exists.

### 3.9 Merge settings — when the repository is on GitHub

If a GitHub remote exists (or once it does), apply the merge behaviour the
pull-request rules assume — squash only, delete the branch on merge — and,
after the first push, the default-branch ruleset:

    gh repo edit --delete-branch-on-merge --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
    gh api -X PATCH repos/<owner>/<name> -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY
    gh api repos/<owner>/<name>/rulesets --input .github/rulesets/protect-main.json

The ruleset is refused on a private repository under GitHub Free; that is the
user's choice to make (Pro, public, or none), not a step to skip silently —
it goes under *Decisions pending* in the target's `TODO.md` with the three
options and the command to run once one is taken.

Details and the verification query are in
[`payload/docs/rules/source-control/github.md`](payload/docs/rules/source-control/github.md).
If there is no remote yet, skip, say so, and add an *Initialization* entry to
`TODO.md` naming the three commands; `/source-control setup` runs them later.

### 3.10 Licence — default `none`, never assumed

A repository with no `LICENSE` file is all rights reserved, which is the
normal state of a private company repository; a repository meant to be shared
gets one. Unless the request names a licence, apply `none`: record it in
`.dc-agentics.yaml`, add *Choose a licence* under *Decisions pending* in the
target's `TODO.md` with the two options below, and flag it in the closing
summary. When the user has chosen, two things are needed:

1. **Which licence.** `Apache-2.0` (patent grant, trademark clause,
   contribution terms — the default for anything shared) or `MIT` (shorter;
   attribution only). Anything else is the user's own choice, fetched the
   same way.
2. **The copyright holder** — the legal owner of the work: the person's name,
   or the company when the work is made for it. A GitHub handle is acceptable
   for a personal project; a legal name is what a notice is for. Never guess,
   and never take it from the git identity.

Then, at the target root:

    gh api licenses/apache-2.0 --jq .body > LICENSE      # verbatim text; or licenses/mit

MIT carries `[year]` and `[fullname]` placeholders — fill both. The Apache
text names nobody; put `Copyright <year> <holder>` in a `NOTICE` file beside
it. Fill the *Licence* section of the generated `README.md`, or delete it when
the answer was `none`. Nothing from the toolkit needs a notice in the target:
the payload is offered under 0BSD.

Verify: `gh repo view --json licenseInfo` reports the chosen licence once the
file is on the default branch — GitHub detects it from the verbatim text, so
an edited Apache text shows as *Other*.

### 3.11 Settings file and TODO

`.dc-agentics.yaml` and `TODO.md` arrive with the payload copy. The settings
file is what agents read before any source-control action and what a future
update of the repository diffs from; every choice made above is recorded in
it, so fill it last, when the choices are final.

Fill every quoted double-brace placeholder in `.dc-agentics.yaml`; the
unquoted values are defaults, already correct unless a step above changed
them (`stylecop`, `central-package-management`, `source-control.mode`). Three
values are the agent's own and must not be guessed: the tool it runs in
(`Claude Code`), the model identifier (`claude-fable-5-1` form), and the
toolkit commit — `git -C <toolkit> rev-parse --short=12 HEAD`, with `-dirty`
appended when `git -C <toolkit> status --porcelain` prints anything. `date`
is today, `yyyy-mm-dd`.

`source-control.mode` is `local` unless the user asked for another: the
agent edits and commits locally on its own and asks before anything reaches
the host. `auto` and `manual` are described in the file and defined in
[`source-control.md`](payload/docs/rules/source-control/source-control.md).

Then `TODO.md`: by now the steps above have added their entries — a skipped
Serena config, a refused or not-yet-applicable ruleset, the licence decision.
Anything else that was not finished, could not be verified, or was left for
a person goes in the same way, each entry with what would close it. Remove
an empty section; keep the file even when both are empty, because it is
where every later agent puts what it leaves open.

Verify:

    grep -n "{{" <repo>/.dc-agentics.yaml                 # must return nothing

### 4. Security pass

Walk [`security-reminders.md`](payload/docs/rules/security-reminders.md). It
ships with the repository as `docs/rules/security-reminders.md`, so the review
process holds later changes to the same standard. At minimum, before
any first push, check the commit identity:

    git var GIT_AUTHOR_IDENT

Git does not refuse to commit when identity is unset — it silently derives
`<username>@<hostname>` and writes it into history permanently.

### 5. Verify

Never report success on an unbuilt repository.

    dotnet build

Then confirm the analyzers are actually wired, by introducing a deliberate
violation of a rule the chosen mode leaves enabled:

    public (int, string) Probe() => (1, "a");   // expect: error SA1414

A wrong `CodeAnalysisRuleSet` path produces **no error at all** — the build
succeeds and every rule is silently ignored. A green build alone proves nothing;
the probe must actually fail. Remove it once confirmed.

Finally, the licence check over the whole transitive graph:

    dotnet nuget-license -i <solution>.slnx -t -a allowed-licenses.json -override license-overrides.json

Exit code 0 is the pass. A non-zero exit lists the offending packages; a `Url`
in the licence column means an old package with no SPDX metadata — resolve it
per [`payload/docs/rules/dependencies.md`](payload/docs/rules/dependencies.md), never by widening
the allow-list.

### 6. Closing summary

The last message of the procedure is a table of every value the repository
now carries — asked or defaulted — and where it lives, so nothing applied
silently stays silent:

| Setting | Value | Source | Change it in |
|---|---|---|---|
| Layout | `monorepo` | asked | restructure; `AGENTS.md`, `README.md` |
| Namespace prefix | `Contoso` | asked | project names; `.dc-agentics.yaml` |
| StyleCop mode | `relaxed` | default | `stylecop.ruleset` + [`stylecop.md`](stylecop.md); `.dc-agentics.yaml` |
| Central package management | on | default | `Directory.Packages.props` |
| Source-control mode | `local` | default | `.dc-agentics.yaml` |
| Licence | `none` | default | step 3.10; `TODO.md` holds the decision |
| Merge settings, ruleset | applied / refused / no remote | — | `/source-control setup`; `TODO.md` |
| Serena project | written / skipped | — | step 3.7; `TODO.md` |

Below the table, the open entries of `TODO.md` verbatim. A user who reads only
this message knows what was decided for them and what is still theirs to
decide.

## Known failure modes

| Symptom | Cause |
|---|---|
| Build green, no diagnostics ever | ruleset path wrong, or `StyleCop.props` never imported |
| `NU1008` | package `Version` supplied while CPM is active |
| Package version not found on restore | `StyleCop.Analyzers` missing from `Directory.Packages.props` |
| Settings ignored | `stylecop.json` not registered as an `AdditionalFiles` item |
| Subtree silently unstyled | a nested `Directory.Build.props` replaced the root one |
| Ruleset fails to load | nested XML comments from a bad strict-mode edit |
