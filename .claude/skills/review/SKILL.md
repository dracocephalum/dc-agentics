---
name: review
description: Review a pull request, a branch, or a set of files against this repository's rules, or triage the review comments on a pull request - producing Conventional Comments with a verdict, posted, printed, or saved as a report.
when_to_use: When asked to review, check, critique, or look over a pull request, a diff, a branch, or specific files; or to go through, answer, address, or resolve review comments on a pull request.
argument-hint: [PR#] [branch] [paths...] [comments PR#] [--report <file>]
---

Review against **this repository's rules**, not general taste. The built-in
`/code-review` hunts bugs with its own machinery; this skill judges compliance
with the rules below and reports in a fixed format. They complement each other
and are not chained - run the built-in separately if a bug pass is wanted.

## Find the standard

1. `docs/rules/coding/code-review.md` - an initialized repository
2. `init/repo/payload/docs/rules/coding/code-review.md` - the dc-agentics toolkit

Read the first that exists, then the language checklists it names, then the
repository's `AGENTS.md`. Never review from memory.

## Choose the mode from `$ARGUMENTS`

| Arguments | Mode |
|---|---|
| a number, e.g. `42` | **pull request** - title, description, diff, existing threads |
| `comments 42` | **comment triage** - the open review threads on PR 42 |
| a branch name | **branch** - its diff against the base branch |
| one or more paths | **files** - review those files in full (also the mode when there is no git history, as in the toolkit itself) |
| nothing | **working tree** - uncommitted plus unpushed changes |

`--report <file>` saves the review there instead of printing. Confirm the
path if it is inside the repository.

## Do the review

Apply the standard's *broaden the analysis range* section: whole files, not
hunks; callers and callees (Serena's `find_referencing_symbols` when
connected); the tests for the touched code. Verify by building and testing
when the change is checked out, and say which claims were verified.

## Output and confirmation

Conventional Comments, `path:line`, most severe first, then one verdict:
approve / approve with non-blocking comments / request changes. Zero findings
is a valid result.

Anything that **leaves the session** - posting a review, replying to a thread,
resolving a thread, committing a fix - is shown to the user in full first and
done only on confirmation, thread by thread or as an approved batch. Never
approve or merge; the verdict is a recommendation. The GitHub commands are in
`docs/rules/change-tracking/github.md`.

In comment-triage mode, the confirmation step is the summary of verdicts for
every thread; act only on the ones the user confirms.
