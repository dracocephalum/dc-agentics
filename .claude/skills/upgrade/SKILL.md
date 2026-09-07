---
name: upgrade
description: Bring the dc-agentics toolkit's own pinned versions current, or upgrade a repository it initialized to a newer toolkit commit - diffing the payload between the commit the repository recorded and now, and deciding each file against the target's own copy. Plans first; applies second.
when_to_use: When asked to upgrade, update, refresh, or bring current a repository initialized with dc-agentics, or the toolkit's own SDK baselines and package versions.
argument-hint: [toolkit | target <path>]
---

Upgrading is diff-and-decide, not copy-over. The toolkit records what a
repository was initialized from, and that recorded commit is the merge base
that tells a customized file from an untouched one.

## Find the standard

`repo/upgrade.md` in a dc-agentics checkout. **Both repositories must be
present**, because the procedure diffs two commits of the toolkit; ask for the
checkout path rather than guessing it. Read the file and follow it - the
per-path merge policy and the diff mechanics are both there, and neither is
guessable.

## Choose the operation from `$ARGUMENTS`

| Arguments | Operation |
|---|---|
| `toolkit`, or run with no target in a dc-agentics checkout | 1 - bring the toolkit's own pins current |
| `target <path>`, or a path | 2 - upgrade that repository to the current toolkit |
| `monorepo` | 3 - convert a standalone repository to a monorepo |
| nothing, ambiguous | ask which; they touch different repositories |

Operation 3 needs **no toolkit checkout** - an initialized repository carries
both layout trees and both document templates, so it can describe a shape it
does not yet have. Run it from inside the repository being converted. Run from
a toolkit checkout instead, it first checks that the two agree, and declines
rather than mixing a payload delta into a layout change.

## Then

Produce the plan first: what changed between the two commits, what it would do
to each file, and what needs a decision. Apply as a second step, and let
`source-control.mode` in the target's `.dc-agentics.yaml` decide what may be
committed without asking.

Finish with `dotnet build`, `dotnet test`, and `/scrub` - the scrub checks are
the post-upgrade checks.
