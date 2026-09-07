# Upgrading

Applies when asked to upgrade, update, or bring current — the toolkit's own
pinned versions, or a repository it initialized. Three operations share the
verb.

| # | Operation | Runs against | Status |
|---|---|---|---|
| 1 | Bring the toolkit's own pins current | this repository | below |
| 2 | Upgrade a target repository to the current toolkit | a target, with a toolkit checkout | below |
| 3 | Convert a target from standalone to monorepo | a target, no toolkit needed | below |

Operation 2 needs both repositories present, because it diffs two commits of
the toolkit. Running it "from the target" still means a toolkit checkout exists
somewhere; ask for its path rather than guessing.

**The tree must be clean before anything is applied.** Every operation
rewrites many files at once, so it starts only from a repository where
`git status --porcelain` prints nothing — no modified, no staged, and no
untracked files. For operation 1 that is the toolkit's own tree; for 2 and 3,
the target's. If it is not clean, **decline** with that one line and let the
user commit or stash; never stash on their behalf, since unstashing over
files the upgrade rewrote is exactly the conflict this rule exists to prevent.

Untracked counts because it is what makes recovery unambiguous. From a clean
tree, *the diff is the upgrade*, and undoing it is one command:

    git checkout -- . && git clean -fd      # before committing: exact pre-upgrade state

After committing, the previous commit is the snapshot, and its
`toolkit.commit` says which version it was. Nothing else — no tag, no backup —
is needed, and nothing less would do: with a scratch file in the tree, that
`git clean` would take it too, and the plan could not say which changes were
the upgrade's.

This is the deliberate opposite of initialization, which *leaves* the payload
uncommitted for review. Both serve the same end: initialization produces the
diff to inspect, an upgrade requires a clean base so that it can.

**Report before applying.** Every operation produces a plan first — what
changed, what it would do to each file, and what needs a decision. Applying is
a second step, and `source-control.mode` in the target's `.agentics.yaml`
governs what may be committed without asking.

## 1. Bring the toolkit's own pins current

Four things carry a recorded version, and they move independently.

### The three files forked from `dotnet new`

Run the drift check exactly as [`copy.md`](copy.md) defines it — the same
procedure, against the installed SDK. **A mismatch stops here.** Re-baselining
is a decision, not a step: it means taking the upstream change, reconciling it
against our edits, replacing the file under [`baselines/`](baselines), and
updating that marker's `sdk=` and `sha256=`. `copy.md`'s *Showing what changed*
isolates the upstream half of the diff, which is what makes the decision
reviewable.

### The analyzer and test-stack packages

The procedure is *Keeping the test stack current* in [`payload/agentics/rules/layout.md`](payload/agentics/rules/layout.md),
which already covers the part that matters: these packages are not independent,
and their failures are compile-time ambiguities rather than version errors.
Move families together, never package by package.

    dotnet package search <id> --exact-match

**The toolkit has no C# project, so nothing here can be verified in place.** A
version bump is only proven by a restore, a build and a test run, and this
repository has none to run. Initialize a scratch repository from the current
payload, bump there, and verify before writing the numbers back — or perform
the bump as part of operation 2 against a real target and carry the result
back. Writing new versions into `Directory.Packages.props` on the strength of a
successful `dotnet package search` is exactly the mistake that section warns
about: a restore that succeeds proves nothing.

### The markers

Once something is verified, record it. These are the only reason a later
session can tell a known-good combination from an untested one:

| Marker | Lives in | Update when |
|---|---|---|
| `dc-agentics-verified: sdk= date=` | `payload/Directory.Packages.props` | the test stack was moved and verified |
| `dc-agentics-baseline: sdk= sha256=` | each forked file | that file was re-baselined |
| `guidelines.model-baseline` | `.agentics.yaml` | the model line these rules target has changed |
| `guidelines.verified` | `.agentics.yaml` | a full initialization trial completed on that line |

`guidelines.verified` is not a formality. It is the date the documents were
last shown to produce a conforming repository, and moving it without running
the trial removes the only evidence anyone has.

## 2. Upgrade a target repository to the current toolkit

### Find the merge base

The target's `.agentics.yaml` records where it came from:

    toolkit:
      commit: "<12-char hash>"
      payload-path: "repo/payload"

`payload-path` is the payload root **as of that commit**, and it exists because
the toolkit has restructured before and will again. A target written before it
was introduced does not have it; fall back to the known former roots, newest
first:

| Root | In use |
|---|---|
| `repo/payload` | since the `machine/` + `repo/` restructure |
| `init/repo/payload` | before it |

**Diff with rename detection across every root that applies.** Getting this
wrong is silent, not loud:

    git diff -M --name-status <commit>..HEAD -- <old-root> <new-root> .claude/skills

Without `-M`, or against the current root alone, a restructure between the two
commits reports every file as added and every old path as deleted — a
plausible-looking diff that would have the upgrade rewrite files that never
changed. `R100` entries are pure renames and carry no content change; a target
sees nothing from them.

### Decide per file, using the target's own copy as evidence

For each changed path, compare **three** versions: the payload at the recorded
commit, the payload at `HEAD`, and the file as it exists in the target. The
first is the merge base, and it is what makes an overwrite defensible:

| Target's copy vs payload at the recorded commit | Meaning | Do |
|---|---|---|
| identical | the target never touched it | apply the new version |
| differs | the target customized it | stop, show both changes, ask |
| missing | never copied, or deleted deliberately | ask before reintroducing it |

**When the answer to "ask" is yes, do not merge text.** The files a repository
customizes — `stylecop.ruleset`, `stylecop.json`, `.editorconfig`, the
`Directory.*` files — are edited attribute by attribute, while the toolkit
rewrites them wholesale. A three-way merge of one changed attribute against a
72-line rewrite produces a mess. Apply the new file whole, then re-apply each
of the repository's changes **by intent**: the severity it raised, the
setting it flipped, the version it pinned. Verify each landed. That is what
preserves the decision without preserving the old file around it.

**Apply renames as moves, before anything else.** When the toolkit renames a
directory — `docs/` became `agentics/` — every file under it shows as `R100`,
a pure rename with no content change. That does *not* mean the target sees
nothing: the directory has to move. `git mv` it in the target first, so the
history survives as a rename and the completeness check does not then report
the entire old tree as orphans and the entire new tree as missing. Only after
the move do the per-file decisions above apply, to whatever also changed.

A rename also leaves the old path in files the upgrade does not own: the
generated `AGENTS.md` links to every rules document by path, the generated
`README.md` and any category map name the folder, and the repository's own
prose may too. None of those are in the diff. After the move, sweep the whole
target for the old path — every file type, not only markdown — and replace it.
This is safe to do mechanically, because the old path no longer exists and so
every occurrence is stale by definition. Measured on a real target: seventeen
links in `AGENTS.md` alone.

**Handle deletions before the loop.** A path the toolkit deleted appears in
the diff as `D`, and `git show HEAD:<path>` fails for it. A loop that redirects
that output into the target creates an *empty file* first — and the orphan
check below then sees a modified file and keeps it. Take the `D` entries out,
apply them as removals under the rule above, and only then write the rest.

Never overwrite on the strength of the path alone. A repository that has been
running for a year will have edited something, and the whole value of the
recorded commit is that it can tell an edit from an untouched file.

**Two kinds of file the comparison cannot judge**, and reporting them as
conflicts is noise:

- **`.agentics.yaml` always differs.** Initialization filled its
  placeholders, so it is never byte-identical to the payload and never will be.
  Skip the comparison and go straight to its policy below — merge new keys,
  keep every recorded value.
- **`AGENTS.md` and `README.md` have no counterpart to compare against.** They
  were generated from templates, not copied, so no payload path corresponds to
  them. The template's diff is read as an instruction instead; see below.

Everything else is genuinely comparable, and in practice most of it comes back
untouched — which is what makes the handful that did change worth a human's
attention.

### Then check for what the diff cannot see

The diff shows what changed **in the payload**. It says nothing about a file
that never changed and is simply absent from the target — deleted at
initialization, or removed later by someone. Those files are invisible to every
step above and stay missing for ever.

So after applying the diff, compare the payload's whole file list against the
target:

    git ls-tree -r --name-only HEAD -- <payload-root> | sed 's|^<payload-root>/||' | sort

Anything present there and absent from the target is a finding: report it with
what it is for, and ask before reintroducing it. Some absences are deliberate
and should stay — a repository may have removed a rule it does not want.

This is not hypothetical. Standalone initialization used to delete
`agentics/templates/category-README.md`, so every repository initialized that way
is missing a file the payload has always contained, and no diff between two
toolkit commits will ever mention it.

**And the other direction.** A file the target has that the payload no longer
does is an orphan — most often the old half of a rename that git reported as a
delete and an add, because too little content survived. The `/project` to
`/new` rename did exactly that, and a target kept `project/SKILL.md` with
nothing to ever remove it. For each file under the payload's paths that exists
in the target and not in the payload at `HEAD`: unmodified since the recorded
commit — remove it; modified — ask, because the target may be keeping it on
purpose.

### The per-path policy

| Path | Policy | Why |
|---|---|---|
| `agentics/rules/**` | replace when unmodified | the standard is the toolkit's; a target that edited one has forked it, which is a decision to surface |
| `.claude/skills/**` | replace when unmodified | thin shims; the substance lives in the documents |
| new files | add | a new rules document also needs its row — see below |
| `.editorconfig`, `.gitignore`, `.gitattributes` | replace only when unmodified, else three-way | they carry baseline markers; a mismatch there is the drift procedure's business, not this one's |
| `Directory.*.props`, `Tests.props`, `nuget.config`, `stylecop.*`, `allowed-licenses.json`, `.config/dotnet-tools.json` | three-way | routinely customized per repository |
| `.agentics.yaml` | merge keys, keep values, drop the dead | new settings arrive with their defaults; every recorded choice is the target's and survives; **a key the payload no longer defines is removed**, and the report names it — nothing reads it, and nothing would ever notice it otherwise |
| `AGENTS.md`, `README.md`, `TODO.md` | by hand | generated from templates and then filled; there is no mechanical mapping back |

### Templates changed, so their output must change too

The templates in `agentics/templates/` are replaced like any other file under
`agentics/` — but their *output* is not. `AGENTS.md` and `README.md` were generated
from them at initialization, with placeholders filled and a layout variant
deleted, so no mechanical mapping runs backwards. A change to a template is
therefore two things: a file to replace, and an instruction to carry out. Read
what changed in the template and make the equivalent edit to the target's
generated document, in the target's own vocabulary.

The common case is a new row in the *Agent guidelines* table, which is how a
new rules document becomes reachable. **A document copied in without its row is
invisible**, and nothing later will notice.

### Finish

1. Rewrite `toolkit.commit` and `payload-path` to what was applied.
2. Carry over the `guidelines:` block, which describes the toolkit rather than
   the target.
3. Put anything that needed a decision and did not get one into the target's
   `TODO.md`, each with what would close it.

### Verify

Not optional, and mostly already written:

    dotnet build <solution> --nologo -v:q
    dotnet test  <solution> --nologo

Then the scrub, [`payload/agentics/rules/scrub.md`](payload/agentics/rules/scrub.md),
which is exactly the post-upgrade check: links that no longer resolve, a
document with no row, a `.agentics.yaml` that no longer matches the
repository, a placeholder in a file that arrived mid-transform.

## 3. Convert a target from standalone to monorepo

Nothing above applies here. Operations 1 and 2 diff a recorded baseline and
apply a delta; this moves files, rewrites paths, creates category folders and
their map, and relocates the component's solution.

**It needs no toolkit checkout.** An initialized repository carries both
layout trees and every template it would need — [`documents.md`](documents.md),
*Why the template stays*. Run it from inside the repository.

### Preconditions, and only when run from the toolkit

Run from a toolkit checkout against a target, confirm the two agree first —
[`version-check.md`](version-check.md) has the test and the four outcomes. Here
the point is narrow: keep a payload delta out of a layout change, where neither
could be blamed for a breakage.

### Ask for the category; derive the folder

**The category cannot be inferred.** `libraries/` and `services/` are not
distinguishable from the code, and the answer changes what the repository
claims about itself. Ask, offering the list from `layout.md`.

**The folder name is derived, not asked** — the component's project name minus
the namespace prefix, kebab-cased, exactly as the naming table has
`Contoso.ProxyGateway` living in `proxy-gateway/`. So `Dracocephalum.Nightingale`
becomes `nightingale/`. **Not the repository directory name**: `dc-nightingale`
is what the repository is called, not what the component is called, and the two
stop being interchangeable the moment a second component exists. Report the
derived name in the closing summary; renaming a folder on its first day is free.

### Move the component; leave the configuration

Use `git mv`, so the history survives as renames rather than as a delete and an
add:

    git mv src test <Prefix>.<Name>.slnx <category>/<component>/

Relative paths *inside* the component survive untouched — the test project's
`ProjectReference`, the solution's project entries — because the whole
component moves together. That is the one thing this operation gets for free.

**Everything else stays at the repository root**, and this is the most damaging
mistake available here:

    Directory.Build.props   Directory.Build.targets   Directory.Packages.props
    Tests.props   StyleCop.props   stylecop.ruleset   stylecop.json
    BannedSymbols.txt   nuget.config   .editorconfig
    allowed-licenses.json   license-overrides.json   .config/
    AGENTS.md   TODO.md   LICENSE   NOTICE   agentics/   docs/   .github/   .claude/

`layout.md` explains why: all three `Directory.*` files resolve by searching
upward and stop at the first hit, so a copy inside the component silently cuts
it off from central package management, StyleCop and warnings-as-errors — with
a green build and no warning. Moving one is not a visible failure.

### The README becomes three documents

A standalone repository's root `README.md` **is** its component README: what
the thing is, how to run it. A monorepo has three layers, and the conversion
has to produce all of them from that one file:

| Layer | Comes from | Holds |
|---|---|---|
| `<category>/<component>/README.md` | the existing root README's content, into `agentics/templates/component-README.md` | what it is, how to run it, configuration |
| `<category>/README.md` | `agentics/templates/category-README.md` | one row per component, this one added |
| root `README.md` | the monorepo variant of `agentics/templates/README.template.md` | the map of categories |

**Move the content down before regenerating the root.** Regenerating first
destroys the only copy of the component's own description, and nothing later
notices, because the result looks like a perfectly good monorepo README.

Three fills are not obvious:

- **The category description** in `category-README.md` — take the wording from
  that category's row in [`payload/agentics/rules/layout.md`](payload/agentics/rules/layout.md),
  so the two agree rather than being written twice.
- **The component's *Kind*** — it follows from the category, not from anything
  recorded: `libraries/` is a library, `services/` a service, and so on.
- **The build commands** in the component README. They were correct at the root
  and are now wrong there: say they run from the component folder, and that the
  root fails `MSB1003` on purpose. Anyone who copied the old command gets a
  confusing error otherwise.

Trim the root README's category table to categories that exist, the same as
the `AGENTS.md` table below. A row for a folder that was never created is a
false statement about the repository.

### Swap the layout variant in AGENTS.md

`AGENTS.md` was generated with the standalone variant kept and the monorepo one
deleted. Take the monorepo variant from `agentics/templates/AGENTS.template.md`,
fill its placeholders from `.agentics.yaml`, and replace the standalone
table with it — trimming the folder rows to categories that now exist.

Also revert `<solution>` under *Building and testing* to the generic form.
Initialization replaced it with the solution file name because there was
exactly one; there is no longer a single solution, which is the whole point of
the layout.

### Finish the conversion

1. `.agentics.yaml`: `layout: standalone` becomes `monorepo`.
2. Anything that needed a decision and did not get one goes in `TODO.md`.
3. Report the derived component name, the chosen category, and the new build
   commands — they have changed, and every README that quoted the old ones has
   to have been updated with them.

### Verify the conversion

    dotnet build <category>/<component>/<Prefix>.<Name>.slnx --nologo -v:q
    dotnet test  <category>/<component>/<Prefix>.<Name>.slnx --nologo

Then confirm the **root** build fails:

    dotnet build          # must fail with MSB1003

That is the expected consequence of having no root solution, not a
misconfiguration. Assert it rather than discovering it later and treating it as
a bug.

Then the scrub, [`payload/agentics/rules/scrub.md`](payload/agentics/rules/scrub.md).
Its link check earns its place here more than anywhere else: every relative
link that crossed the boundary between root and component has just changed
depth.

**Sweep for stale paths in every file type, not only markdown.** The toolkit's
own `init/` restructure is the same shape of operation, and what it caught was
a `.markdownlint.yaml` extending a moved path and a `NOTICE` scoping a licence
grant by path — neither reachable by searching `*.md`, and neither loud when
wrong. In a target the candidates are `.github/` workflows, editor settings,
and anything naming `src/` or `test/` from the root.

Finally, check for **mixed line endings**. A bulk rewrite across many files is
where they appear, and no diff renders them.

Confirm the moves registered as **renames** rather than as a delete and an add:

    git add -A && git diff --cached --name-status -M

Every moved file should show `R`. A tree of `D` and `A` pairs means `git mv`
was not used, and the component's history stops at the conversion — recoverable
only by redoing the move properly before committing.

Verified on a real conversion: seven renames with no content change, four
documents edited or created, the component building green with 4/4 tests, and
the root failing `MSB1003` as intended.

## Known failure modes

| Symptom | Cause |
|---|---|
| Every payload file appears new | diffed the current root only, or without `-M`, across a toolkit restructure |
| No way to tell the upgrade's changes from the user's | applied to a dirty tree; the precondition exists so that `git checkout -- . && git clean -fd` is the whole undo |
| A customization silently disappears | overwrote on path alone, without comparing against the payload at the recorded commit |
| A customized config file becomes a merge mess | three-way merged text; apply the new file and re-apply the repository's changes by intent instead |
| A zero-byte file where the toolkit deleted one | the apply loop redirected a failing `git show` for a `D` path; handle deletions first |
| A settings key nothing reads, in every target | the payload dropped it and "keep values" was read as "keep keys" |
| A new rules document is never read | copied in without adding its row to the target's `AGENTS.md` |
| `NU1008`, or a restore that cannot resolve | package versions moved without `Directory.Packages.props` moving with them |
| The build breaks on rules nobody changed | a `agentics/rules/**` replacement where the target had forked the document |
| Versions written but never proven | bumped in the toolkit, which has no project to build |
| A component silently loses StyleCop, CPM and warnings-as-errors | a `Directory.*` file was moved into the component instead of left at the root |
| The component's own description vanished | the root README was regenerated before its content was moved down |
| A new component is invisible | added without a row in its category's `README.md` |
| `MSB1003` at the root, treated as a fault | expected: a monorepo has no root solution |
