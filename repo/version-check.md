# Does this target agree with this toolkit?

Applies before any operation that runs **from a toolkit checkout against a
target** and applies toolkit-derived rules to it — the layout conversion in
[`upgrade.md`](upgrade.md), and `/new`. Both read a procedure from the toolkit
and write into a repository that carries its own copy of that procedure. If the
two disagree, the result follows rules the repository does not describe, and
nothing notices.

**Run from inside the target there is nothing to check.** It uses its own
documents, which are consistent with it by definition. That is what makes this
a precondition rather than a barrier: every failing case has the same way out.

## The test

Commit hashes have no ordering, so comparing them is an ancestry question, not
a comparison. `toolkit.commit` in the target's `.dc-agentics.yaml` is the value
under test:

    git cat-file -e <recorded>                     # resolvable at all?
    git merge-base --is-ancestor <recorded> HEAD
    git merge-base --is-ancestor HEAD <recorded>

| Outcome | Do |
|---|---|
| equal | proceed |
| the target is an ancestor of `HEAD` | decline; offer a **toolkit upgrade** first, then the operation |
| `HEAD` is an ancestor of the target | decline — the toolkit is behind, and proceeding would apply older rules to a newer repository |
| neither, or the commit does not resolve | decline; say to run the operation from inside the target, which sidesteps the question entirely |

## Why best-effort is the right standard

Because the last row always has somewhere to go. The check can fail for
reasons that are nobody's fault:

- **The commit no longer exists.** dc-agentics squash-merges and deletes
  branches, so a repository initialized from an unmerged branch records a hash
  that ceases to exist when that branch is squashed.
- **The checkout is shallow**, or the branch holding that commit was never
  fetched.
- **The histories diverged** — a fork, or a toolkit checkout on a branch of
  its own.

None of these justify guessing, and none of them block the user: the
self-contained path is always available and always correct.

## What this is not

It is not a safety check on the *target*. Nothing here prevents damage; the
per-file evidence in `upgrade.md` does that. This prevents **mixing two
changes** — a payload delta and whatever the operation was actually asked to
do — into one result where neither can be blamed for a breakage.

It also has nothing to say about scaffolding *into the toolkit itself*. That is
refused for a different reason: dc-agentics has no C# components, so there is
nothing there to add to.
