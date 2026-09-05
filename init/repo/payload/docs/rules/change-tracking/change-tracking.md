# Change tracking

Applies when a piece of work starts, when asked "which ticket is this for",
when a ticket needs creating or finding, and when a board is in play. This
file is the rules; the tracker-specific mechanics are in the file the
[Trackers](#trackers) section names. Branches, commits, and change requests
are [`../source-control/source-control.md`](../source-control/source-control.md).

## The rule

Every change is traceable to a ticket, and the ticket's identifier leads — in
the branch name and the change-request title — so history, boards, and
searches line up on one key. A ticket is a sentence of intent, not a design
document: what and why, one line, with context and links in the body.

## Settings

`change-tracking` in the repository's `.dc-agentics.yaml`:

| Key | Values | Meaning |
|---|---|---|
| `tracker` | `github-issues` | where tickets live; the only value today |
| `board` | `none`, or a board URL | a board on top of the tracker; optional |
| `board-auto-add` | `false`, `true` | `true` when the board's own workflows add new tickets and move closed ones; the agent then only reads the board |

A board needs extra credential scope — the tracker file says which; `none`
needs nothing beyond the default login.

## Before any work

If the request names a ticket, use it. Otherwise one is needed: in `auto`
mode create it and report the identifier; in `local` and `manual` show the
command and wait (`source-control.mode`; the table is in
[`../source-control/source-control.md`](../source-control/source-control.md),
*For an agent*). A ticket that exists only in the conversation is lost when
the session ends.

Working without a ticket is the user's call, not the agent's — ask, and if
they decline, say so in the change-request body: `No ticket:` and the reason.

**The one built-in exception is initialization.** The repository, and so its
tracker, does not exist until the first commit is on the default branch; that
commit has no ticket, and the initialization is not opened as one afterwards.
Everything from the second commit on has a ticket.

## Identifier form

The ticket leads: `<ticket>-<kebab-topic>` for the branch,
`#<ticket> <type>(<scope>): <summary>` for the change-request title, and the
tracker's closing keyword with the ticket as the first line of the body. The
trade-off is deliberate: a leading `#123` is not what strict Conventional
Commits parsers expect. This toolkit does not run one; if a repository adopts
`commitlint` or similar, move the ticket to the end
(`feat(billing): retry failed charges once (#123)`) and say so in `AGENTS.md`.

## Boards

A board is a view over tickets, never the record; the ticket is. With `board`
set and `board-auto-add: false`, the agent adds every ticket it creates to
the board and moves the card when the change merges — host actions, confirmed
per the mode like any other. With `board-auto-add: true` the board's own
workflows do both and the agent only reads. Prefer the workflows where the
host offers them: nothing to get right per ticket, and no write scope on the
token.

## Trackers

| Tracker | File |
|---|---|
| GitHub Issues, with an optional Projects board | [`github.md`](github.md) |

Only GitHub today. For Jira and similar, the rules transfer with the
identifier form changed (`PROJ-123-billing-retry`, `PROJ-123 feat(...)`) and
the closing keyword replaced by the tracker's own link syntax; add a sibling
file here and a row above rather than generalising this one.
