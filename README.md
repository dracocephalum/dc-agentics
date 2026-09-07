# dc-agentics

A **golden path** for C# repositories: an opinionated, supported route where
the easiest way to start a project is also the one that meets the standard.
Build configuration, coding rules, review and pull-request conventions, secret
scanning, licence policy, and the machine setup that makes them run — landed
by one procedure and verified on a real build before they ship.

The hard part of a golden path is not any single decision; each of those is a
search away. It is the composition: dozens of decisions that have to stay
written down, current, and consistent with each other as the toolchain
underneath them moves. That upkeep has usually needed a platform team, which
is why smaller teams rarely get to keep one.

This toolkit treats the composition as the product and uses an agent to do
the upkeep. The decisions are made once, deliberately, and recorded with their
reasons; applying them to a new repository, checking one for drift, and
carrying it forward to a newer version of the standard are procedures an agent
runs. What it produces is a repository that meets the standard on day one and
has a documented way to stay there.

Today it supports **C# / .NET 10** repositories, standalone or monorepo, on
**Windows** (other platforms best-effort, see `machine/platforms.md`).

## A note on models

Every guideline here was written against Claude Opus and Fable: what it says,
and what it leaves unsaid because those models do it by default. A different
model has different defaults, and the difference shows up as rules it does not
infer. Recommended: a model of at least 5T parameters. Below about 2.5T the
gaps are large enough to degrade results markedly.

The line, and the date it was last verified end to end, are recorded under
`guidelines:` in [`.agentics.yaml`](.agentics.yaml) and carried into
every repository this initializes. It is a record rather than a requirement —
its purpose is that odd behaviour after a model change has a known-good
combination to be compared against, the same way `dc-agentics-verified` pins
the test stack.

## Use it

Agents start at [`AGENTS.md`](AGENTS.md) — a task index mapping requests to
the document that governs them. People can too; it is the shortest route to
anything here.

What you will ask for:

| To … | Read |
|---|---|
| set up a developer machine | [`machine/README.md`](machine/README.md) |
| initialize a repository | [`repo/initialize.md`](repo/initialize.md) |
| check a repository for drift | [`repo/scrub.md`](repo/scrub.md) |
| upgrade a repository, or the toolkit itself | [`repo/upgrade.md`](repo/upgrade.md) |

All four are procedures an agent can run: "set up this machine", "initialize a
repo at `<path>`", "scrub this repo", "bring it up to the current toolkit".

## What is in here

Three kinds of file, told apart by where they live:

- **`repo/payload/`** — an exact mirror of a target repository root. Every
  file in it lands verbatim in an initialized repository, including the rules
  under `agentics/rules/`.
- **`machine/`** and **`repo/`** (everything else) — procedures and guides,
  grouped by what they act on: a machine, or a target repository. Read here,
  never copied.
- **The root** — this file, `AGENTS.md`, `GLOSSARY.md`, `TODO.md`, `PLAN.md`, and the workspace config
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
- **Composition is the product.** Any one choice above is a search away and
  worth little alone. What is expensive — and what is maintained here — is the
  hundred of them holding together: agreeing with each other, current with the
  toolchain, and applied the same way to every repository.

## Licensing

The toolkit is licensed under the [Apache License 2.0](LICENSE).

Everything under `repo/payload/` and `.claude/skills/` is copied into the
repositories it initializes, so those files are **additionally** offered under
the Zero-Clause BSD licence (0BSD): an initialized repository owes no notice
and no attribution for them.

> Copyright (C) 2026 Chris Har
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

Early. Open items are in [`TODO.md`](TODO.md); ideas that are not commitments
are in [`PLAN.md`](PLAN.md).
