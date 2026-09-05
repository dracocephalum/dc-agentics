# Change tracking on GitHub

The mechanics of [`change-tracking.md`](change-tracking.md) on GitHub: the
ticket is a GitHub Issue, its number is the identifier, and a Projects board
is optional on top. Read the rules first. How to reach GitHub — an MCP server
or `gh` — and the pull-request and review commands are in
[`../source-control/github.md`](../source-control/github.md).

## Permissions the agent needs

Change tracking is only as good as the credential behind it. `gh` acts with an
OAuth token whose **scopes** decide what the agent can touch:

| To … | Scope | Granted by |
|---|---|---|
| read and create issues and pull requests | `repo` | the default `gh auth login` |
| register an SSH signing key | `admin:ssh_signing_key` | must be requested |
| list a Projects board and read its items | `read:project` | **optional** — only with a board |
| add items to a board, move them, set fields | `project` | **optional** — only with a board and `board-auto-add: false` |

Issues alone need nothing beyond the default login. A board is a choice made
in `.dc-agentics.yaml`; request the two extra scopes only when `board` is
set, and only `read:project` when `board-auto-add` is `true`. Add to an
existing login with `gh auth refresh -h github.com -s read:project,project` —
it opens a browser; an agent hands the command to the user. `gh auth status`
lists the token's scopes; a board operation that fails with "missing required
scopes" means exactly this. A board owned by an organization additionally
needs the user to have write access to it — scopes cannot grant what the
account does not have.

The same shape holds for other trackers: a Jira API token carries the
project permissions of the user who created it, so "can the agent do X on
the board" is always "can the user, and does the token include it".

## Tickets

| Need | Command |
|---|---|
| create | `gh issue create --title "<what and why, one line>" --body "<context, links>"` — take the number it returns |
| find | `gh issue list --search "<words>"`; `gh issue view <n>` |
| the branch linked to it | `gh issue develop <n> --name <n>-<kebab-topic> --base main`, then `git fetch origin <branch>` and `git switch <branch>` |
| what is linked | `gh issue develop --list <n>` |

Create the branch and check it out in two steps rather than with
`--checkout`, which can fail on its own internal `git` call after the branch
and the link already exist on GitHub — it did on the first run through this
flow, leaving the work on `main`. The two-step form uses the same git
configuration as every other command and is verifiable at each step. The
user may override the naming (an existing convention, a hotfix with no
ticket); record the reason in the pull-request body.

## Boards

Only when `board` in `.dc-agentics.yaml` is a URL. `gh project` takes the
board's number and owner from that URL.

| Need | Command |
|---|---|
| the boards | `gh project list --owner <owner>` |
| add a ticket | `gh project item-add <number> --owner <owner> --url <issue-url>` |
| is a ticket on the board | `gh issue view <n> --json projectItems` |
| read the items | `gh project item-list <number> --owner <owner> --format json` |
| move a card | GraphQL `updateProjectV2ItemFieldValue(input:{projectId, itemId, fieldId, value:{singleSelectOptionId}})` — ids from `gh project field-list <number> --owner <owner>` and `item-list`; `gh project item-edit` is the CLI form, not yet run here |

With `board-auto-add: true` none of the write rows run: the board's
*Auto-add to project* workflow (filter `is:issue`) and *Item closed → Done*
workflow, enabled once in the board's web UI, do the work. Verify on the next
ticket with the "is a ticket on the board" query. Adding and moving are host
actions and follow the mode like any other.
