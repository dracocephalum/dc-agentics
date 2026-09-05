# Serena

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

[Serena](https://github.com/oraios/serena) gives an agent semantic code tools —
find symbol, find references, rename, insert relative to a symbol — backed by a
language server, over MCP. This is the machine-level install and the Claude Code
wiring. Verified on Windows with Serena 1.7.0, Claude Code 2.1.

Serena is **agent tooling**: installed once per machine with `uv tool`, never
as a repository dependency. See [`python.md`](python.md) for why.

## Install

    uv tool install -p 3.13 serena-agent
    serena init                          # global config, LSP backend
    serena --version

If `serena` is "not found" afterwards, it is `PATH` — follow the sequence in
the [README](README.md) (`uv tool update-shell`, then restart the console).

## Two questions to ask before wiring it in

Ask both. They are decisions, not defaults, and the answers change the command.

**1. Scope — where should the registration live?**

| Answer | Effect | Choose when |
|---|---|---|
| **user** | written to `~/.claude.json`; Serena is available in every project on this machine | personal machine setup; the usual answer |
| **project** | written to `.mcp.json` at the repo root, committed, shared with the team — teammates are prompted to approve it | the team has standardised on Serena for that repo |

**2. Context — which tool set should Serena expose?**

Serena ships several contexts; the one that matters here is
**`ide-assistant`**, designed for Claude Code and IDE agents. It switches off
the tools the host already provides — file reading, editing, shell — and keeps
the semantic ones. Observed: 23 tools exposed of 52 loaded. The default context
(`desktop-app`) is for Claude Desktop, which has no tools of its own, and would
duplicate everything Claude Code already does.

Use `ide-assistant` for Claude Code unless the user has a specific reason.

## Register with Claude Code

`serena setup claude-code` exists, but it cannot express either choice above.
Use `claude mcp add` directly, so the registration is explicit and inspectable:

    claude mcp add --scope user serena -- serena start-mcp-server --context ide-assistant --project-from-cwd

For project scope, replace `--scope user` with `--scope project`.

`--project-from-cwd` makes Serena activate whatever repository Claude Code was
launched in. It needs a `.git` directory or a `.serena/project.yml` to
recognise the folder as a project — a folder with neither starts the server
but activates nothing (a warning in the log says so).

## Verify — and the one misleading result

    claude mcp get serena

Immediately after registering, this reports **`Failed to connect`** if the
console that ran it predates the `PATH` change. Claude Code spawns `serena` by
name and the old process cannot find it. That is not a configuration problem;
the same registration reports `Connected` from a console that has the updated
`PATH`. Do not remove and re-add it.

**Then restart.** Close Claude Code, open a **new** console, relaunch from
there. One relaunch covers both requirements: the new `PATH`, and the fact that
Claude Code loads MCP servers at session start. Launching from an old console
inherits the stale `PATH` and Serena fails to start even though it is
registered.

## Per repository

Repository initialization from this toolkit runs `serena project create`
automatically and treats failure as non-blocking — see
[`../repo/finish.md`](../repo/finish.md), step 3.7. For an existing repository,
do it by hand:

    serena project create --language csharp      # writes .serena/project.yml
    serena project index                          # optional: pre-builds the symbol cache

Pass `--language` (repeatable) rather than letting Serena infer. With more
than one language present, inference prompts `[y/N]` per additional language
and aborts without a terminal — the wrong behaviour for anything scripted.
Terraform is supported (`--language terraform`), as are Python, TypeScript,
Go, YAML, JSON and around sixty others.

What ends up in `.serena/` and what to commit:

| File | Commit | Notes |
|---|---|---|
| `project.yml` | yes | team configuration; languages auto-detected |
| `.gitignore` | yes | Serena writes it on first index: ignores `/cache` and `/project.local.yml` |
| `project.local.yml` | no | per-machine overrides |
| `cache/` | no | symbol cache, regenerated |
| `memories/` | **decide** | Serena does *not* ignore this, so memories are committed by default. Keep that if they are team knowledge; add `/memories` to `.serena/.gitignore` if they are personal. |

The toolkit's shipped repository `.gitignore` already covers
`.serena/project.local.yml` and `.serena/cache/`, so nothing leaks in the
window between `project create` and the first index.

## Removal

    claude mcp remove serena -s user     # or -s project
    uv tool uninstall serena-agent
