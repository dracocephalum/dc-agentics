# Repository initialization, continued

Steps 3.6 to 6 of [`README.md`](README.md). Start there, not here: by this
point the payload files are at the target root and the folders exist. This
file turns the templates into the repository's own documents, records the
choices made, and verifies the result. The split is for length only; the
step numbering continues.

## Steps, continued

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
appended when `git -C <toolkit> status --porcelain` prints anything. `initialized`
is today, `yyyy-mm-dd`.

`source-control.mode` is `local` unless the user asked for another; the
three modes are defined in
[`source-control.md`](payload/docs/rules/source-control/source-control.md),
*For an agent*.

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
| Namespace prefix | `Contoso` | asked | project names; recorded in `.dc-agentics.yaml` |
| StyleCop mode | `relaxed` | default | `stylecop.ruleset` + [`stylecop.md`](stylecop.md); `.dc-agentics.yaml` |
| Central package management | on | default | `Directory.Packages.props` |
| Source-control mode | `local` | default | `.dc-agentics.yaml` |
| Licence | `none` | default | step 3.10; `TODO.md` holds the decision |
| Merge settings, ruleset | applied / refused / no remote | — | `/source-control setup`; `TODO.md` |
| Serena project | written / skipped | — | step 3.7; `TODO.md` |

Below the table, the open entries of `TODO.md` verbatim. A user who reads only
this message knows what was decided for them and what is still theirs to
decide.
