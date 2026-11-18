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

## Which to install — ask before installing either

**Which code-intelligence tools should this machine have?** It is a decision,
not a default: each holds memory for as long as a session is open. Put the
table to the user and install what they answer. The memory is what a
repository of about 45,000 lines of C# took; the next section has the
measurement and how to place another repository against it.

| Answer | Memory | Gets | Gives up | Choose when |
|---|---|---|---|---|
| **Both** | about 1.2 GB | short answers and unasked diagnostics from the LSP tool, edits by symbol from Serena, and each covers reading when the other is absent or fails to start | nothing | Claude Code, and memory to spare; the usual answer |
| **LSP tool only** | about 370 MB | reading and unasked diagnostics | rename and the other edits by symbol, so a rename is search and replace again; in a repository of several solutions, the references outside the one it holds | Claude Code, and memory is tight |
| **Serena only** | about 790 MB | reading and edits by symbol | the shorter answers; diagnostics come only when asked for | an agent tool other than Claude Code, or one tool is wanted and renames matter |
| **Neither** | none | nothing to install or keep current | answers about symbols; text search and ordinary edits do the work | a small repository, or a machine with no memory to spare |

No answer is permanent, and nothing in the toolkit requires either tool. To
change it later without uninstalling:

    claude plugin disable csharp-lsp@claude-plugins-official     # enable turns it back on
    claude mcp remove serena -s user                             # serena.md registers it again

When memory runs short with both on, turn Serena off first: it is the larger,
and what only it does — rename — is the rarer need.

## What each costs in memory

Measured on Windows, on a C# monorepo of four solutions — 14 projects, 402
files, about 45,000 lines of C# — after a handful of questions:

| Tool | Process | What it had loaded | Memory |
|---|---|---|---|
| LSP tool | `csharp-ls` | one solution and the projects it references: 8 projects, 332 files, about 37,000 lines | about 370 MB |
| Serena | its C# language server | all four solutions: 14 projects, 402 files, about 45,000 lines | about 470 MB |
| Serena | the Serena server itself, in Python | nothing of the code | about 320 MB just after use, about 120 MB idle |
| **Both** | all three | | **about 1.2 GB** |

Lines are every line of the tracked `.cs` files, blank lines and comments
included, generated code excluded. Memory is the working set of the process.

For either language server that is about 10 MB for each thousand lines. Use it
to place a repository — a tenth of the size, ten times the size — and not as a
rate: it is one repository, and part of the memory is the server and the
packages the projects reference, which does not grow with the code.

How to read the numbers:

- They are one reading. A language server grows with the size of what it
  loads and as more files are opened.
- With both on, two language servers hold the same code. Nothing is shared
  between them.
- The memory is held while the session is open, not only while a question is
  being answered.
- Every session starts its own. With three sessions open the machine ran three
  Serena servers, and a `csharp-ls` for each session that had used the LSP
  tool.
- Serena starts its language server when a project is activated. Until then a
  session's Serena costs the 120 MB of the server alone.

Count it beside what else the machine runs at the same time: the build, the
test run, a local database.

## Which one does what

Measured on a C# monorepo of four solutions, the same questions put to each:

| Task | LSP tool | Serena |
|---|---|---|
| References to a method, within one solution | 40 call sites, as file, line and column | the same 40, each with its containing symbol and three lines of code; about ten times the output |
| References across solutions | only those in the solution it holds | all of them |
| Implementations of an interface | found | found |
| Symbols in a file | types and members with signatures | types and members, by depth |
| Diagnostics | pushed after a file is opened or edited, unasked | asked for, per file |
| Rename a symbol | not offered | declaration and every call site, line endings kept |
| Insert or replace at a symbol, safe delete | not offered | offered |
| Works with | Claude Code | any MCP client |

So the two are not a first choice and a spare:

- **Reading code** — either, inside one solution. The LSP tool answers in less text, which is less
  of the session's context spent on each question; Serena's answer saves the
  next read when the surrounding code is what was wanted.
- **Changing code by symbol** — Serena. The LSP tool only reads.
- **Neither installed** — text search and ordinary edits.

Four things seen in the comparison, worth knowing before trusting a result:

- **A repository with several solutions.** The LSP tool held one of the four
  and answered for that one only, without saying so: for a type used in 11
  files it reported the 8 inside its solution and none of the 3 in the other
  two solutions that use it. Serena, holding all four, found those. To see
  what the LSP tool holds, ask its workspace symbol search for a type from
  another solution; for a symbol that other solutions can reach, confirm the
  references with Serena or a text search.
- The first call in a session can fail with `server is starting`. Call again.
- A symbol's line in a file's symbol list is at or just above its doc comment,
  some lines before its name. The workspace symbol search gives the line of
  the name.
- A rename changes the symbol and its uses, and nothing named after it: a test
  method called `GetThing_WhenAsked_ShouldAnswer` keeps its name when
  `GetThing` is renamed.

## Install

The language server is a .NET tool, the plugin a Claude Code plugin:

    dotnet tool install --global csharp-ls
    claude plugin install csharp-lsp@claude-plugins-official

`csharp-ls` must resolve by name: the plugin starts it as `csharp-ls`, so the
.NET tools folder has to be on `PATH`, which the .NET SDK installer arranges.

Serena's install is in [`serena.md`](serena.md).

## One more question before installing the plugin

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
