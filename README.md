# dc-agentics

A toolkit for standing up repositories that agents and people can work in from
the first commit: build configuration, coding rules, review and pull-request
conventions, secret scanning, licence policy, and the machine setup that makes
them run — all verified on a real build before they ship.

Today it supports **C# / .NET 10** repositories, standalone or monorepo, on
**Windows** (other platforms best-effort, see `init/local/platforms.md`).

## A note on models

Every guideline here was written against Claude Opus and Fable: what it says,
and what it leaves unsaid because those models do it by default. A different
model has different defaults, and the difference shows up as rules it does not
infer. Recommended: a model of at least 5T parameters. Below about 2.5T the
gaps are large enough to degrade results markedly.

## Use it

Agents start at [`AGENTS.md`](AGENTS.md) — a task index mapping requests to
the document that governs them. People can too; it is the shortest route to
anything here.

The two things you will ask for:

| To … | Read |
|---|---|
| set up a developer machine | [`init/local/README.md`](init/local/README.md) |
| initialize a repository | [`init/repo/README.md`](init/repo/README.md) |

Both are procedures an agent can run: "set up this machine", "initialize a repo
at `<path>`".

## What is in here

Three kinds of file, told apart by where they live:

- **`init/repo/payload/`** — an exact mirror of a target repository root. Every
  file in it lands verbatim in an initialized repository, including the rules
  under `docs/rules/`.
- **`init/`** (everything else) — procedures and guides. Read here, never
  copied.
- **The root** — this file, `AGENTS.md`, `TODO.md`, and the workspace config
  for working on the toolkit itself. `.claude/skills/` is the one thing shipped
  from outside the payload.

## Principles

- **Verified, not asserted.** Every template and procedure was run against the
  real toolchain before it was written down; the docs say what was tested and
  on what version.
- **Enforce where possible, remind where not.** Warnings are errors, secrets
  are blocked at commit, licences are gated at restore. Markdown rules cover
  what tools cannot judge.
- **Decisions are recorded once.** `test/` not `tests/`, `.slnx`, one
  solution per component — each written down with its reason so it is not
  re-litigated per repository.
- **Small always-loaded files, everything else on demand.** `AGENTS.md` is a
  map; the rules it points at load only when the task matches.

## Licensing

The toolkit is licensed under the [Apache License 2.0](LICENSE).

Everything under `init/repo/payload/` and `.claude/skills/` is copied into the
repositories it initializes, so those files are **additionally** offered under
the Zero-Clause BSD licence (0BSD): an initialized repository owes no notice
and no attribution for them.

> Copyright (C) 2026 dracocephalum
>
> Permission to use, copy, modify, and/or distribute this software for any
> purpose with or without fee is hereby granted.
>
> THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
> REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
> AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
> INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
> LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
> OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
> PERFORMANCE OF THIS SOFTWARE.

The code-review standard quotes Google's engineering practices, which are
CC-BY 3.0; that attribution stays with the quote.

## Status

Early. Open items are in [`TODO.md`](TODO.md).
