# Upgrading

Applies when asked to upgrade, update, or bring current — the toolkit's own
pinned versions, or a repository it initialized. Three operations share the
verb; the first two are here.

| # | Operation | Runs against | Status |
|---|---|---|---|
| 1 | Bring the toolkit's own pins current | this repository | below |
| 2 | Upgrade a target repository to the current toolkit | a target, with a toolkit checkout | below |
| 3 | Change a target's layout, standalone to monorepo | a target | not written yet |

Operation 2 needs both repositories present, because it diffs two commits of
the toolkit. Running it "from the target" still means a toolkit checkout exists
somewhere; ask for its path rather than guessing.

**Report before applying.** Both operations produce a plan first — what
changed, what it would do to each file, and what needs a decision. Applying is
a second step, and `source-control.mode` in the target's `.dc-agentics.yaml`
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

The procedure is *Keeping the test stack current* in [`payload/docs/rules/layout.md`](payload/docs/rules/layout.md),
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
| `guidelines.model-baseline` | `.dc-agentics.yaml` | the model line these rules target has changed |
| `guidelines.verified` | `.dc-agentics.yaml` | a full initialization trial completed on that line |

`guidelines.verified` is not a formality. It is the date the documents were
last shown to produce a conforming repository, and moving it without running
the trial removes the only evidence anyone has.

## 2. Upgrade a target repository to the current toolkit

### Find the merge base

The target's `.dc-agentics.yaml` records where it came from:

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

Never overwrite on the strength of the path alone. A repository that has been
running for a year will have edited something, and the whole value of the
recorded commit is that it can tell an edit from an untouched file.

**Two kinds of file the comparison cannot judge**, and reporting them as
conflicts is noise:

- **`.dc-agentics.yaml` always differs.** Initialization filled its
  placeholders, so it is never byte-identical to the payload and never will be.
  Skip the comparison and go straight to its policy below — merge new keys,
  keep every recorded value.
- **`AGENTS.md` and `README.md` have no counterpart to compare against.** They
  were generated from templates, not copied, so no payload path corresponds to
  them. The template's diff is read as an instruction instead; see below.

Everything else is genuinely comparable, and in practice most of it comes back
untouched — which is what makes the handful that did change worth a human's
attention.

### The per-path policy

| Path | Policy | Why |
|---|---|---|
| `docs/rules/**` | replace when unmodified | the standard is the toolkit's; a target that edited one has forked it, which is a decision to surface |
| `.claude/skills/**` | replace when unmodified | thin shims; the substance lives in the documents |
| new files | add | a new rules document also needs its row — see below |
| `.editorconfig`, `.gitignore`, `.gitattributes` | replace only when unmodified, else three-way | they carry baseline markers; a mismatch there is the drift procedure's business, not this one's |
| `Directory.*.props`, `Tests.props`, `nuget.config`, `stylecop.*`, `allowed-licenses.json`, `.config/dotnet-tools.json` | three-way | routinely customized per repository |
| `.dc-agentics.yaml` | merge keys, keep values | new settings arrive with their defaults; every recorded choice is the target's and survives |
| `AGENTS.md`, `README.md`, `TODO.md` | by hand | generated from templates and then filled; there is no mechanical mapping back |

### Templates changed, so their output must change too

The templates in `docs/templates/` are replaced like any other file under
`docs/` — but their *output* is not. `AGENTS.md` and `README.md` were generated
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

Then the scrub, [`payload/docs/rules/scrub.md`](payload/docs/rules/scrub.md),
which is exactly the post-upgrade check: links that no longer resolve, a
document with no row, a `.dc-agentics.yaml` that no longer matches the
repository, a placeholder in a file that arrived mid-transform.

## Known failure modes

| Symptom | Cause |
|---|---|
| Every payload file appears new | diffed the current root only, or without `-M`, across a toolkit restructure |
| A customization silently disappears | overwrote on path alone, without comparing against the payload at the recorded commit |
| A new rules document is never read | copied in without adding its row to the target's `AGENTS.md` |
| `NU1008`, or a restore that cannot resolve | package versions moved without `Directory.Packages.props` moving with them |
| The build breaks on rules nobody changed | a `docs/rules/**` replacement where the target had forked the document |
| Versions written but never proven | bumped in the toolkit, which has no project to build |
