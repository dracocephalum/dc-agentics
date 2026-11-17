# LSP tool

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

Claude Code has a built-in `LSP` tool: go to definition, find references, find
implementations, hover, symbols in a file or the workspace, call hierarchy, and
diagnostics that arrive by themselves after a file is touched. It talks to a
language server that a **plugin** declares. This is the machine-level install
for C#. Verified on Windows with Claude Code 2.1, the `csharp-lsp` plugin 1.0.0
and `csharp-ls` 0.28.0.

It is **Claude Code only**. Another agent tool takes
[Serena](serena.md), which is an MCP server and works with any client. Both are
optional, and both can be on at once.

## Which one does what

Measured on a C# monorepo of four solutions, the same questions put to each:

| Task | LSP tool | Serena |
|---|---|---|
| References to a method | 40 call sites, as file, line and column | the same 40, each with its containing symbol and three lines of code; about ten times the output |
| Implementations of an interface | found | found |
| Symbols in a file | types and members with signatures | types and members, by depth |
| Diagnostics | pushed after a file is opened or edited, unasked | asked for, per file |
| Rename a symbol | not offered | declaration and every call site, line endings kept |
| Insert or replace at a symbol, safe delete | not offered | offered |
| Memory, one solution loaded | about 370 MB | about 470 MB for its language server, 320 MB for the server itself |

So the two are not a first choice and a spare:

- **Reading code** — either. The LSP tool answers in less text; Serena's answer
  saves the next read when the surrounding code is what was wanted.
- **Changing code by symbol** — Serena. The LSP tool only reads.
- **Neither installed** — text search and ordinary edits. Nothing in the
  toolkit requires either.

Three things seen in the comparison, worth knowing before trusting a result:

- The first call in a session can fail with `server is starting`. Call again.
- A symbol's line in a file's symbol list is at or just above its doc comment,
  some lines before its name. The workspace symbol search gives the line of
  the name.
- A rename changes the symbol and its uses, and nothing named after it: a test
  method called `GetThing_WhenAsked_ShouldAnswer` keeps its name when
  `GetThing` is renamed.

With both on, two language servers hold the same solution. On a machine short
of memory, or a very large solution, turn one off.

## Install

The language server is a .NET tool, the plugin a Claude Code plugin:

    dotnet tool install --global csharp-ls
    claude plugin install csharp-lsp@claude-plugins-official

`csharp-ls` must resolve by name: the plugin starts it as `csharp-ls`, so the
.NET tools folder has to be on `PATH`, which the .NET SDK installer arranges.

## One question to ask before installing the plugin

**Scope — where should the plugin be enabled?**

| Answer | Effect | Choose when |
|---|---|---|
| **user** (default) | recorded in the user's Claude Code settings; on in every project on this machine | personal machine setup; the usual answer |
| **project** | recorded under `enabledPlugins` in `.claude/settings.json` at the repo root, committed, shared with the team | the team has standardised on it for that repo |

For project scope add `--scope project`. Each machine still installs
`csharp-ls` itself; the setting only turns the plugin on.

That setting is the repository's record. `.agentics.yaml` holds none: whether
the tool is there is a fact about a machine, and an agent sees it each session
in its own tool list.

## Verify

    csharp-ls --version
    claude plugin list

The plugin shows as `enabled`. **Then restart**: Claude Code loads plugins at
session start, so a session opened before the install has no `LSP` tool. In the
new session, ask for the references to any method; an answer with files and
lines means it works.

The language server reads the solution's projects, so `dotnet restore` first if
references look incomplete.

## Removal

    claude plugin uninstall csharp-lsp@claude-plugins-official
    dotnet tool uninstall --global csharp-ls
