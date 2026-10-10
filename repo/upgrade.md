# Upgrading

Applies when asked to upgrade, update, or bring current — the toolkit's own
pinned versions, or a repository it initialized. Three operations share the
verb.

| # | Operation | Runs against | Status |
|---|---|---|---|
| 1 | Bring the toolkit's own pins current | this repository | below |
| 2 | Upgrade a target repository to the current toolkit | a target, with a toolkit checkout | below |
| 3 | Convert a target from standalone to monorepo | a target, no toolkit needed | below |

Operation 2 needs both repositories present: its script runs from the toolkit
checkout, copies from it, and reads the recorded commit against its history.
Running it "from the target" still means a toolkit checkout exists somewhere;
ask for its path rather than guessing.

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
changed, what it would do to each file, and what needs a decision; for
operation 2 that is the script's `--plan`. Applying is a second step, and
`source-control.mode` in the target's `.agentics.yaml` governs what may be
committed without asking.

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
| `agentics-verified: sdk= date=` | `payload/Directory.Packages.props` | the test stack was moved and verified |
| `agentics-baseline: sdk= sha256=` | each forked file | that file was re-baselined |
| `guidelines.model-baseline` | `.agentics.yaml` | the model line these rules target has changed |
| `guidelines.verified` | `.agentics.yaml` | a full initialization trial completed on that line |

`guidelines.verified` is not a formality. It is the date the documents were
last shown to produce a conforming repository, and moving it without running
the trial removes the only evidence anyone has.

## 2. Sync a target repository to the current toolkit

`agentics/` and the toolkit's shims under `.claude/skills/` in a target are the
toolkit's: a sync replaces them whole, and nothing in them is the target's to
edit. That one rule is what makes the operation a script rather than a
procedure. There is no merge base to find, no per-file evidence to weigh, no
orphan or missing file to reason about, because the target's copy is *defined*
as the payload at the recorded commit. The repository's own rules live outside,
in the folders `rules.local` names in its `.agentics.yaml` (`docs/rules/` by
default), each with an `AGENTS.md` index whose rows the sync copies into the
root `AGENTS.md`; opting out of a toolkit rule is `rules.excluded`, never a
deletion. The rule a target reads is
[`payload/agentics/rules/layout.md`](payload/agentics/rules/layout.md), *The
toolkit's rules and the repository's*.

### Run it

    sh repo/sync.sh --plan <target>      # reports: what changed, what it would do; nothing is touched
    sh repo/sync.sh --apply <target>     # applies, then verifies
    sh repo/sync.sh                      # the help; neither flag means nothing happens

From the toolkit checkout, against a clean target: plan, read, apply. POSIX
`sh` and `awk`, so it runs wherever git does; nothing to install and nothing
to fall back from. In order:

| Step | Does | Reports |
|---|---|---|
| refuse | not a git repository; no `.agentics.yaml`; a dirty tree; an `AGENTS.md` without the guidelines block | the one reason, and where the fix is |
| changes | — | the toolkit's log between the recorded commit and `HEAD` over the payload and the shims; the payload files *outside* `agentics/` that changed, which are yours to apply by intent |
| replace | deletes `agentics/` and every toolkit shim under `.claude/skills/` — the names at the recorded commit and the names now — then copies the payload's `agentics/` and the toolkit's shims | — |
| exclude | removes each `rules.excluded` path from `agentics/rules/` | a path the payload does not have |
| block | regenerates the block between `<!-- agentics:guidelines -->` and `<!-- /agentics:guidelines -->`: the template's rows minus the excluded ones, then the rows of every `rules.local` index, then the template's closing paragraphs — in the file's own line endings | a local folder with no index; a trigger stated twice, which is a local row competing with a toolkit row — see *Precedence* in `layout.md` |
| settings | `toolkit.commit` to the toolkit's `HEAD`, `-dirty` when the checkout is not clean; a top-level block the payload has and the target lacks is appended with its defaults | the appended block; a top-level key the payload no longer defines, for you to remove |
| verify | markdownlint over the target when `npx` is on `PATH`; the relative-link check from `scrub.md`, with a local index's links resolved from the root, where its rows land | the summary line; every unresolved link |

It never commits. Review `git status` and the diff, then commit under the
target's `source-control.mode`: the diff *is* the sync, and
`git checkout -- . && git clean -fd` is the whole undo. A recorded commit the
checkout cannot resolve — a squashed branch, a shallow clone — costs the change
list and the removal of shims the toolkit has since renamed; the script says so,
and the rest proceeds.

A dangling link after an exclusion is reported and is correct: a toolkit rule
that links to the excluded one now points at nothing, which is the honest
statement that this repository does not hold that rule. Deleting the file by
hand instead is undone by the next sync.

### The rest of the payload

Everything the payload ships outside `agentics/` is the target's once copied:
`.editorconfig`, `.gitignore`, `.gitattributes`, the `Directory.*` files,
`Tests.props`, `nuget.config`, the StyleCop files, the licence lists,
`.config/dotnet-tools.json`, `.github/`, `.markdownlint.yaml`, and
`docs/rules/AGENTS.md`. The script lists which of them changed between the two
commits; apply each **by intent** — the severity it raised, the version it
pinned, the key it added — rather than by text merge. A target edits these
files attribute by attribute while the toolkit rewrites them wholesale, and a
three-way merge of one changed attribute against a 72-line rewrite produces a
mess. Apply the new file whole where the target never touched it; otherwise
take the change across and verify it landed. `.editorconfig`, `.gitignore` and
`.gitattributes` carry baseline markers, and a mismatch there is the drift
procedure's business, not this one's.

`.agentics.yaml` is never replaced: it carries the target's choices. The script
merges a new top-level block and names a dead one; a new key *inside* an
existing block is in the change list for you to add by hand, with the
payload's comment beside it.

### Adopting the block

A target initialized before the block existed has the same table with no
markers, and the script refuses it until, once, by hand:

1. Put `<!-- agentics:guidelines -->` on its own line, with a blank line after
   it, above the `| When you are | Read |` header; put
   `<!-- /agentics:guidelines -->`, with a blank line before it, after the
   paragraph that ends "will not be read". The table and the two paragraphs
   after it are the block.
2. Move every row that is the repository's own — one the template does not
   have — into `docs/rules/AGENTS.md`, created from the payload's copy, and
   delete it from the root table. A row the template *does* have, reworded,
   is replaced by the template's wording; keep the rewording in the index as
   a second row only if it says something the template's does not.
3. Commit, then run the sync. The `rules:` block is appended to
   `.agentics.yaml` with its defaults on that first run.

### Verify

Not optional, and mostly already written:

    dotnet build <solution> --nologo -v:q
    dotnet test  <solution>

Then the scrub, [`payload/agentics/rules/scrub.md`](payload/agentics/rules/scrub.md),
which is exactly the post-sync check: links that no longer resolve, a document
with no row, a `.agentics.yaml` that no longer matches the repository, a
placeholder in a file that arrived mid-transform.

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

**The folder name is derived, not asked** — the main project's last name
segment, kebab-cased, exactly as the naming table in `layout.md` has
`Contoso.ProxyGateway` living in `proxy-gateway/`. So `Contoso.Widgets`
becomes `widgets/`. **Not the repository directory name**: `contoso-widgets`
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
    dotnet test  <category>/<component>/<Prefix>.<Name>.slnx

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
| The script refuses with "no guidelines block" | a target from before the block existed; adopt it once, *Adopting the block* |
| No way to tell the sync's changes from the user's | applied to a dirty tree; the precondition exists so that `git checkout -- . && git clean -fd` is the whole undo |
| An edit under `agentics/` is gone after a sync | by design: the folder is the toolkit's; the edit belongs in `docs/rules/`, or in a toolkit pull request |
| A row typed into the root `AGENTS.md` table is gone after a sync | it was inside the generated block; a row of the repository's own goes in `docs/rules/AGENTS.md` |
| A customized config file becomes a merge mess | three-way merged text; apply the new file and re-apply the repository's changes by intent instead |
| A settings key nothing reads, in every target | the payload dropped it and the script's "no longer defines" line was ignored |
| A new rules document is never read | the block was edited by hand instead of regenerated, or the local index lacks the row |
| Mixed line endings in `AGENTS.md` | the block was spliced by hand from a checkout with the other ending; the script writes the file's own |
| `NU1008`, or a restore that cannot resolve | package versions moved without `Directory.Packages.props` moving with them |
| Versions written but never proven | bumped in the toolkit, which has no project to build |
| A component silently loses StyleCop, CPM and warnings-as-errors | a `Directory.*` file was moved into the component instead of left at the root |
| The component's own description vanished | the root README was regenerated before its content was moved down |
| A new component is invisible | added without a row in its category's `README.md` |
| `MSB1003` at the root, treated as a fault | expected: a monorepo has no root solution |
