# Scrubbing dc-agentics itself

Applies when asked to scrub, sweep, or audit **this repository**. For a
repository dc-agentics initialized, the shipped checklist is the whole
procedure.

**Start with the shipped checklist**,
[`payload/docs/rules/scrub.md`](payload/docs/rules/scrub.md), read as though
this repository were a target — the toolkit is held to what it ships. Two
adjustments, because it is not a target:

- **Judge the payload's documents against `payload/AGENTS.template.md`, not
  against this repository's `AGENTS.md`.** The template is the table a target
  actually gets; this repository's own index lists only what an agent working
  *here* needs, and it correctly omits the C# rules because there is no C# code
  here. Checking payload docs against the wrong index reports four false
  orphans. This repository's `AGENTS.md` links into the payload by the longer
  `repo/payload/docs/rules/...` path; that path is what its own reverse check
  must resolve.
- There is no build, so the `.dc-agentics.yaml` rows about StyleCop and central
  package management describe what the payload *ships*, not what runs here.
- **`payload/.dc-agentics.yaml` is unfilled on purpose**, so the placeholder
  check finds seven `{{…}}` tokens in it every time. That file is a template
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
`.dc-agentics.yaml` comments, the payload's `.editorconfig`, `.gitignore`,
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

Run it whenever a forked file is edited at all — including a comment. Never
edit an `.original`; they carry no explanatory header precisely because adding
one would change the bytes they exist to verify.

**The root `.gitattributes` carries `repo/baselines/** -text` for this reason.**
Without it, `* text=auto` checks the baselines out as CRLF on Windows and this
check fails on a clean clone with nothing actually wrong.

Two things that rule depends on, both easy to undo by accident:

- **Attributes in a subdirectory beat the root's** for everything beneath it.
  While the baselines lived under `payload/`, that directory's own
  `.gitattributes` overrode any root rule about them; the rule had to sit in
  `payload/.gitattributes` and ship pointlessly to every target. Moving them to
  `repo/baselines/`, which has no attributes file of its own, is what lets the
  rule live at the root.
- **The `.original` suffix is load-bearing.** A file named exactly
  `.gitattributes`, `.gitignore` or `.editorconfig` is read as live
  configuration for its directory — so a pristine `.gitattributes` stored under
  its real name would apply its own `* text=auto` to the very directory the
  root rule is trying to protect, and win. The suffix is what keeps the
  baselines inert.

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
  *Payload, skills, workspace* in `AGENTS.md`.
- **`payload/` is a mirror of a target root.** Anything in it that would not
  belong at the root of an initialized repository is in the wrong place.

## 4. Skill shim fallbacks

Each `.claude/skills/*/SKILL.md` names two paths: the target's
`docs/rules/...`, then the toolkit's `repo/payload/docs/rules/...`. The shims
are copied into targets, so a wrong fallback ships:

    grep -rn "repo/payload/docs/rules" .claude/skills/*/SKILL.md

Every path printed must exist here, and its `docs/rules/...` counterpart must be
the same document.

## 5. Root and payload parity

This repository runs on its own payload, through two files that claim to follow
the shipped shape:

- `.dc-agentics.yaml` — same keys as `payload/.dc-agentics.yaml`, minus the
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
