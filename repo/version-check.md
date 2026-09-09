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
a comparison. `toolkit.commit` in the target's `.agentics.yaml` is the value
under test:

    git cat-file -e <recorded>                     # resolvable at all?
    git merge-base --is-ancestor <recorded> HEAD
    git merge-base --is-ancestor HEAD <recorded>

| Outcome | Do |
|---|---|
| the recorded commit is **strictly older** than `support.baseline` in the toolkit's `.agentics.yaml` | decline — the repository predates what the upgrade supports; re-initialize it |
| equal | proceed |
| the target is an ancestor of `HEAD` | decline; offer a **toolkit upgrade** first, then the operation |
| `HEAD` is an ancestor of the target | decline — the toolkit is behind, and proceeding would apply older rules to a newer repository |
| neither, or the commit does not resolve | decline; say to run the operation from inside the target, which sidesteps the question entirely |

**The baseline row comes first**, and it is why the procedures carry no
knowledge of older layouts. The toolkit has restructured — `init/` became
`machine/` and `repo/`, `docs/` became `agentics/`, the settings file changed
its name — and every rule for handling those is generic: renames as moves,
deletions before the loop, dropped keys removed. What is *not* kept is a table
of where things used to live. A repository below the baseline is not upgraded
through that history; it is re-initialized, which on a repository that old is
the cheaper operation anyway.

    floor=$(grep -E '^  baseline:' <toolkit>/.agentics.yaml | cut -d'"' -f2)   # anchored: a bare "baseline:" also matches model-baseline
    [ "$(git rev-parse <recorded>)" != "$(git rev-parse $floor)" ] \
      && git merge-base --is-ancestor <recorded> $floor                        # true -> below the floor

**The floor is inclusive, and the test has to say so.** `git merge-base
--is-ancestor X X` exits 0, because a commit is its own ancestor — so an
ancestry test alone declines a repository sitting exactly *on* the baseline,
which is the one commit the floor is meant to admit. The equality check is not
belt-and-braces; without it, every repository initialized at the baseline
commit is refused an upgrade it is entitled to. Compare resolved hashes rather
than the recorded string, which may be abbreviated to a different length.

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
