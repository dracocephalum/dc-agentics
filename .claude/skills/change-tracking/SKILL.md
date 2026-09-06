---
name: change-tracking
description: Create or find the ticket a piece of work belongs to, put it on the repository's board, or set board tracking up - per this repository's change-tracking rules. GitHub Issues only, for now.
when_to_use: When asked which ticket a change is for, to create or find a ticket or issue, to put work on a board, or to set up board tracking. Branches, commits, and pull requests are /source-control.
argument-hint: new "<what and why>" | find <#n | words> | board add <#n> | board setup
---

Change tracking per **this repository's rules**. GitHub Issues is the only
supported tracker today; for anything else, say so and stop.

## Find the rules

First `.dc-agentics.yaml` at the repository root: `change-tracking.tracker`,
`board`, and `board-auto-add` say where tickets live and whether the agent
touches a board; `source-control.mode` says whether creating a ticket asks
first. Then read each rule in the first location that exists, then the
tracker file the change-tracking rules name. Never work from memory.

| Rule | Initialized repository | dc-agentics toolkit |
|---|---|---|
| change tracking - the ticket rule, settings, the initialization exception, boards; names the tracker file | `docs/rules/change-tracking/change-tracking.md` | `init/repo/payload/docs/rules/change-tracking/change-tracking.md` |

## Actions from `$ARGUMENTS`

| Argument | Do | Where the procedure is |
|---|---|---|
| `new "<what and why>"` | create the ticket, report its number, add it to the board when the settings say the agent does | change tracking, *Before any work*; tracker file, *Tickets* and *Boards* |
| `find <#n \| words>` | show the ticket, or the tickets matching the words | tracker file, *Tickets* |
| `board add <#n>` | put an existing ticket on the board | tracker file, *Boards* |
| `board setup` | check the token's scopes for the configured board, and record `board` and `board-auto-add` in the settings file | tracker file, *Permissions*; change tracking, *Settings* |

## Always

A ticket is a sentence of intent, not a design document. Creating one, and
anything on a board, is a host action: it follows `source-control.mode` in
the source-control rules, *For an agent*. Nothing is invented that the user
did not give - not the ticket's intent, not the board.
