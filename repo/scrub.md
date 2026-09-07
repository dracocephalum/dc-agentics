# Scrubbing dc-agentics itself

Applies when asked to scrub, sweep, or audit **this repository**. For a
repository dc-agentics initialized, the shipped checklist is the whole
procedure.

**Start with the shipped checklist**,
[`payload/agentics/rules/scrub.md`](payload/agentics/rules/scrub.md), read as though
this repository were a target — the toolkit is held to what it ships. Three
adjustments, because it is not a target:

- **Judge the payload's documents against `payload/agentics/templates/AGENTS.template.md`, not
  against this repository's `AGENTS.md`.** The template is the table a target
  actually gets; this repository's own index lists only what an agent working
  *here* needs, and it correctly omits the C# rules because there is no C# code
  here. Checking payload docs against the wrong index reports four false
  orphans. This repository's `AGENTS.md` links into the payload by the longer
  `repo/payload/agentics/rules/...` path; that path is what its own reverse check
  must resolve.
- The settings-truth check has less to do here. This repository's
  `.agentics.yaml` has no `repository:` block at all — no licence, layout,
  StyleCop or CPM rows — because it is the toolkit, not a target. What remains
  to check is `change-tracking`, `source-control` and `guidelines`.
- **`payload/.agentics.yaml` is unfilled on purpose**, so the placeholder
  check finds eight `{{…}}` tokens in it every time. That file is a template
  in everything but name — its placeholders are filled at initialization. Add
  it to that check's exclusions here; in a target the same file is filled, so
  a hit there is a real finding.

Then the checks below, which exist only here. Report as the shipped file says:
a findings table, no fixes without being asked.

## 1. Stale paths across every file type

Markdown is not where the dangerous references live. Two found in one
restructure, neither reachable by searching `*.md`:

| File | Reference | What a stale value costs |
|---|---|---|
| `.markdownlint.yaml` | `extends: repo/payload/.markdownlint.yaml` | the shared configuration is silently dropped; the lint still runs and still reports clean |
| `NOTICE` | "Files under `repo/payload/` ... 0BSD" | the permissive grant points at a directory that does not exist |

So sweep every file, not one extension:

    grep -rn "<old-path>" . | grep -v "^\./\.git/\|/obj/\|/bin/"

Run it after **any** move or rename, and again once the rewrite is done — the
second run is the one that catches what the first rewrite missed. Also check
`.agentics.yaml` comments, the payload's `.editorconfig`, `.gitignore`,
`Directory.Build.props` and `Directory.Packages.props`, and the root
`.gitignore`: all of them name toolkit paths in prose.

## 2. `.original` files still hash to their markers

Each forked file has a pristine `.original` sibling that hashes **directly** to
the marker in its live counterpart, with no newline normalization:

    sha256sum < baselines/.editorconfig.original

Compare against the `sha256=` field in `payload/.editorconfig`, and the same
for `.gitignore` and `.gitattributes`. This is a different check from baseline
drift: drift asks whether upstream moved, this asks whether *our* recorded
baseline is still internally consistent.

Run it whenever a forked file is edited at all — including a comment. If it
fails on a clean clone, the first suspect is line endings: the root
`.gitattributes` rule `repo/baselines/** -text` and the `.original` suffix are
what keep those files byte-exact, and [`copy.md`](copy.md), *Baseline drift
check*, explains why each is load-bearing and what removing either costs.

## 3. Payload purity

Everything under `payload/` is copied verbatim into repositories where the
toolkit's own directory structure does not exist. So:

- **No path that resolves only here.** A markdown link from a payload file must
  resolve inside a target. Toolkit paths may be *named* in prose — several
  are — but the sentence must say so, as in "in the toolkit's
  `machine/gitleaks.md`". A bare path reads as a promise the target cannot
  keep.
- **No instruction addressed to someone working on dc-agentics.** Payload prose
  speaks to an agent in a repository that merely uses the standard. A rule that
  reads naturally as advice to "you, working here" is usually misfiled — see
  *The distinction that matters most here* in `AGENTS.md`.
- **`payload/` is a mirror of a target root.** Anything in it that would not
  belong at the root of an initialized repository is in the wrong place.

## 4. Skill shim fallbacks

Each `.claude/skills/*/SKILL.md` names the document it follows — for the rules
shims, the target's `agentics/rules/...` then the toolkit's
`repo/payload/agentics/rules/...`; for `scrub` and `upgrade`, a toolkit document
under `repo/` as well. The shims are copied into targets, so a wrong path
ships. Also confirm each frontmatter is valid YAML: an `argument-hint` such as
`[a] [b]` opens a flow sequence and continues past it, the whole block fails to
parse, and the skill's description degrades to its body's first line — which is
how `review` shipped for weeks. Quote any value that starts with `[`.

    grep -rn "repo/payload/agentics/rules" .claude/skills/*/SKILL.md

Every path printed must exist here, and its `agentics/rules/...` counterpart must be
the same document.

## 5. Root and payload parity

This repository runs on its own payload, through two files that claim to follow
the shipped shape:

- `.agentics.yaml` — same keys as `payload/.agentics.yaml`, minus the
  provenance and repository blocks. A key added to the payload and not
  considered here is a divergence.
- `.markdownlint.yaml` — one line, extending the payload copy, so the two
  cannot drift. If it has grown rules of its own, that is the finding.

## 6. `initialize.md`'s root listing matches the payload

*What ends up in the repository root* in
[`initialize.md`](initialize.md) is a promise about what the copy produces.
It goes stale the moment a payload file is added without updating it — which is
exactly what happened when `change-tracking/SKILL.md` was added and the listing
kept naming three shims.

    find payload -type f | sed 's|^payload/||' | sort
    ls .claude/skills

Compare against the listing, in both directions. No exclusion is needed: since
the baselines moved to `repo/baselines/`, everything under `payload/` is
genuinely copied, which is what makes this a straight comparison.

## 7. Always-loaded documents stay within budget

`AGENTS.md` is read every session with no trigger to gate it, and so is each
shim's **name and description** — the shim body loads only when the skill is
invoked. Everything under `payload/agentics/rules/` is loaded on demand and is not
measured here; depth there is cheap until its trigger fires.

    wc -l AGENTS.md .claude/skills/*/SKILL.md | sort -n

`AGENTS.md` is the one to watch, since every row added to the task index is
paid for everywhere. Shims sit around 40 lines; one that has grown well past
that is usually carrying substance that belongs in the document it points at,
which is a clarity problem rather than a context one.

Report growth as a trend rather than a threshold: a shim that has doubled is a
finding, a shim at 44 lines is not.
