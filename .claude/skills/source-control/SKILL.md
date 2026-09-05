---
name: source-control
description: Start work on a ticket with a correctly named, issue-linked branch; commit; open a pull request; or apply the repository's merge settings - all per this repository's change-tracking and pull-request rules. GitHub only, for now.
when_to_use: When asked to start work on a ticket or issue, create or name a branch, commit changes, open or update a pull request, or set up a repository's merge settings.
argument-hint: publish | start <#issue | "what to do"> | commit | pr | setup
---

Source control per **this repository's rules**. GitHub is the only supported
host today; for anything else, say so and stop.

## Find the rules

Read both, in the first location that exists:

| Rule | Initialized repository | dc-agentics toolkit |
|---|---|---|
| change tracking - tickets, branch names, PR titles, repo settings | `docs/rules/change-tracking/github.md` | `init/repo/payload/docs/rules/change-tracking/github.md` |
| pull requests - commits, size, body, review conduct, merge | `docs/rules/source-control/github-pull-requests.md` | `init/repo/payload/docs/rules/source-control/github-pull-requests.md` |

## Modes from `$ARGUMENTS`

**`publish`** - The local repository has no remote yet. Check the
preconditions (`git init -b main`, identity and signing, secret scan clean,
one commit on `main`), then **ask whether a remote exists and check** with
`gh repo view`: not found → offer to create it (same name as the folder,
private, `gh repo create --source . --remote origin --push`); empty → add
`origin` and push; has commits → reconcile with the user, never force-push.
Then run `setup`.

**`start <#issue | "description">`** - Ensure a ticket exists: an issue number
is used as given; a description becomes a new issue (`gh issue create`) after
the user confirms its title. Then create the branch `<ticket>-<kebab-topic>`
linked to the issue (`gh issue develop`) and check it out. The user may
override the branch name; record the reason for the PR body.

**`commit`** - Stage what the user indicates, write a Conventional Commit
message (ticket in the body, type and scope in the summary), and commit. The
commit is signed and secret-scanned by the machine setup; if either fails,
report it - never `--no-verify`.

**`pr`** - Open a **draft** pull request. Title: ticket first, then the
conventional summary - `#123 feat(billing): retry failed charges once`. Body:
from `.github/PULL_REQUEST_TEMPLATE.md`, written to a file first and ending
with the `Closes #123` line, via `gh pr create --draft --body-file`. Run the
build, the tests, and the licence check before opening; a red build is never
someone else's discovery. Never merge.

**`setup`** - Apply the repository merge settings once
(`gh repo edit --delete-branch-on-merge --enable-squash-merge
--enable-merge-commit=false --enable-rebase-merge=false`) and verify with
`gh repo view --json ...`. Requires the repository to exist on GitHub.

## Always

- Show the exact command before running anything that creates or changes
  something on GitHub - an issue, a branch, a pull request, a setting.
- Ask for what is missing rather than inventing it: the ticket, the scope,
  the summary.
