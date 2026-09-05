# Change tracking on GitHub

Applies when starting a piece of work, naming a branch, opening a pull request,
or asking "which ticket is this for". GitHub only, for now: the **ticket is a
GitHub Issue**, and its number is the identifier that ties branch, commits,
pull request, and review together.

The rule underneath: **every change is traceable to a ticket, and the ticket
number leads** — branch name, PR title — so history, boards, and searches all
line up on one key.

## Permissions the agent needs

Change tracking is only as good as the credential behind it. `gh` acts with an
OAuth token whose **scopes** decide what the agent can touch:

| To … | Scope | Granted by |
|---|---|---|
| read and create issues and pull requests | `repo` | the default `gh auth login` |
| register an SSH signing key | `admin:ssh_signing_key` | must be requested |
| list a Projects board and read its items | `read:project` | **optional** — only with a Projects board |
| add items to a board, move them, set fields | `project` | **optional** — only with a Projects board |

Issues alone need nothing beyond the default login. A Projects board is a
choice some teams make on top; ask whether one is in use before requesting
the two extra scopes, and skip them otherwise. Add to an existing login with
`gh auth refresh -h github.com -s read:project,project` — it opens a browser;
an agent hands the command to the user. Check with `gh auth status`, which
lists the token's scopes; a board operation that fails with "missing required
scopes" means exactly this.

Least privilege still applies: `read:project` is enough for an agent that
reviews and reports; grant `project` only where it is expected to move cards.
A board owned by an organization additionally needs the user to have write
access to that board — scopes cannot grant what the account does not have.

The same shape holds for other trackers: a Jira API token carries the
project permissions of the user who created it, so "can the agent do X on
the board" is always "can the user, and does the token include it".

## Before any work: a ticket exists

If the request does not name an issue, create one. A ticket is a sentence of
intent, not a design document:

    gh issue create --title "<what and why, one line>" --body "<context, links>"

Take the number it returns. A ticket that only exists in the conversation is
lost the moment the session ends.

Working without a ticket is the user's call to make, not the agent's — ask,
and if they decline, say so in the PR body: `No ticket:` followed by the
reason.

## Branch

    <ticket>-<kebab-topic>          e.g. 123-billing-retry

The ticket number **leads**; the change type lives in the commits, not the
branch. GitHub can create the branch linked to the issue, so the issue page
shows the branch and the PR that follows:

    gh issue develop 123 --name 123-billing-retry --base main --checkout

The user may override the naming (an existing convention, a hotfix with no
ticket); record the reason in the PR body.

## Pull request

- **Title**: `#<ticket> <type>(<scope>): <summary>` — e.g.
  `#123 feat(billing): retry failed charges once`. The ticket leads so a list
  of PRs reads as a list of tickets; the conventional part follows so the
  squash commit stays scannable.
- **Body**: from the template, and always `Closes #<ticket>` — GitHub closes
  the issue on merge and links the two permanently.
- Everything else — size, drafts, review conduct, merge — is in
  [`../source-control/github-pull-requests.md`](../source-control/github-pull-requests.md).

Note the trade-off, chosen deliberately: a leading `#123` is not what strict
Conventional Commits parsers expect. This toolkit does not run one; if a
repository adopts `commitlint` or similar, move the ticket to the end
(`feat(billing): retry failed charges once (#123)`) and say so in `AGENTS.md`.

## Repository settings — once, after the repository exists on GitHub

Two behaviours are repository settings, not habits:

    gh repo edit --delete-branch-on-merge --enable-squash-merge \
                 --enable-merge-commit=false --enable-rebase-merge=false

- **Squash is the only merge method.** One conventional commit per PR on the
  default branch, with the PR title as its message.
- **The source branch is deleted on merge.** Branches are scaffolding; the PR
  and the ticket are the record.

Apply this as part of repository initialization when a GitHub remote exists,
or the first time a pull request is opened. Verify:

    gh repo view --json deleteBranchOnMerge,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed

## Reaching GitHub: an MCP server if present, `gh` otherwise

Two ways an agent can act on GitHub, and the choice is made per session,
not per repository:

- **A GitHub MCP server is connected** (its tools are listed in the session)
  → prefer its tools for issues, pull requests, comments, and threads. They
  return structured data and need no shell.
- **No MCP server** → use `gh`, as in the tables below. This is the baseline
  every machine set up by the toolkit has; nothing here depends on the MCP
  server existing.

Whether to install the MCP server is the user's decision, made during machine
setup — the toolkit's local guide asks, and records the known catch (the
remote server's OAuth route does not work from Claude Code; it needs a
personal access token in a header). Never install or authenticate it
mid-task, and never mix the two routes for the same action; the confirmation
rules apply equally to both.

## Review mechanics on GitHub

The review *standard* is [`../coding/code-review.md`](../coding/code-review.md);
these are the commands its modes use here.

| Need | Command |
|---|---|
| everything about a PR | `gh pr view <n> --json title,body,baseRefName,headRefName,files,reviews,comments` |
| the diff | `gh pr diff <n>` |
| the discussion, as threads | `gh api graphql` — `pullRequest(number:) { reviewThreads(first:100) { nodes { id isResolved path line comments(first:50) { nodes { author { login } body } } } } }` |
| post a review with a body | `gh pr review <n> --comment --body-file <file>` (or `--request-changes` / `--approve` — **never `--approve` from an agent**) |
| reply in a thread | mutation `addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId, body})` |
| resolve a thread | mutation `resolveReviewThread(input:{threadId})` |
| start a new thread on a line | mutation `addPullRequestReviewThread(input:{pullRequestId, path, line, body})` |

Every one of these that *writes* to GitHub — posting, replying, resolving — is
confirmed with the user first, thread by thread or as an approved batch. Print
what will be posted before posting it.

## Other trackers

Only GitHub Issues today. The rules above transfer to Jira and similar with
the identifier form changed (`PROJ-123-billing-retry`, `PROJ-123 feat(...)`)
and `Closes` replaced by the tracker's own link syntax; add a sibling file
here when one is adopted rather than generalising this one.
