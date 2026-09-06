# Change tracking on GitHub

The mechanics of [`change-tracking.md`](change-tracking.md) on GitHub: the
ticket is a GitHub Issue and its number is the identifier. Read the rules
first. How to reach GitHub — an MCP server or `gh` — and the pull-request and
review commands are in
[`../source-control/github.md`](../source-control/github.md).

## Permissions the agent needs

`gh` acts with an OAuth token whose **scopes** decide what the agent can
touch. Issues need nothing beyond the default `gh auth login` (`repo`).
Anything on a Projects board — asked for explicitly, never routine — needs
`read:project` to look and `project` to change; add them with
`gh auth refresh -h github.com -s read:project,project`, which opens a
browser, so the agent hands the command to the user. `gh auth status` lists
the token's scopes; "missing required scopes" means exactly this. A board
owned by an organization additionally needs the user to have write access to
it — scopes cannot grant what the account does not have.

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

## Boards, when asked

A Projects board keeps itself in step with issues once its own workflows are
on (*Auto-add to project* with the filter `is:issue`, *Item closed → Done* —
web UI, once); nothing here runs routinely. On request:

| Need | Command |
|---|---|
| is a ticket on the board | `gh issue view <n> --json projectItems` |
| put a ticket on it | `gh project item-add <number> --owner <owner> --url <issue-url>` — number and owner from the board URL |
| a card that is not an issue yet | mutation `convertProjectV2DraftIssueItemToIssue(input:{itemId, repositoryId})` — a draft has no number, no `Closes`, no linked branch; convert first, then proceed with the issue it becomes |
