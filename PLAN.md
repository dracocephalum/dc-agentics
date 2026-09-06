# PLAN

Ideas for the toolkit. **Nothing here is a commitment.** An entry may turn out
not to be worth doing, may not survive contact with the toolchain, or may be
superseded before anyone starts it. Recording it costs nothing and saves
rediscovering the same thought in six months.

## How this differs from TODO.md

| File | Holds | Test for belonging |
|---|---|---|
| [`TODO.md`](TODO.md) | decided work | someone could pick it up cold and know when it is done |
| `PLAN.md` | ideas | the shape is not settled, or it may not be worth doing at all |

An idea graduates to `TODO.md` when its shape is decided and it has a closing
condition. Until then it stays here, where it is allowed to be vague and
allowed to be wrong.

**Initialized repositories get `TODO.md` only.** The payload ships no
`PLAN.md`, and initialization never writes one: what it produces is a list of
actions the user must take to conclude the initialization, which is exactly
what `TODO.md` is for. Whether a repository also wants somewhere to keep its
ideas is its own decision, and copying an empty file in would be presuming it.

## Release and distribution

The toolkit currently takes a repository as far as a green build. Everything
past that — producing an artifact, signing it, publishing it — is unwritten,
and is the largest single gap.

### Packaging a library to NuGet

`dc-nightingale` is the likely first packable library, so this is the one that
will be needed first.

`csharp-new-project.md` already sets `IsPackable=false` for services, jobs and
tools and leaves `libraries/` packable, which is the entry point. What a golden
path would still owe:

- **Package metadata** as inherited defaults rather than per-project
  boilerplate — `PackageId`, `Description`, `PackageLicenseExpression`,
  `PackageProjectUrl`, `RepositoryUrl`, `PackageReadmeFile`, `PackageIcon`.
  Most belong in `Directory.Build.props`, since they are the same for every
  package in a repository.
- **Deterministic builds and SourceLink**, so a consumer can step into the
  source, plus symbol packages (`.snupkg`).
- **`dotnet pack` and publishing**, including how the API key or trusted
  publishing is configured without a secret landing in the repository.
- **`THIRD-PARTY-NOTICES.txt`** — already a `TODO.md` entry, and this is the
  context that makes it matter.

### Release versioning

The stamp in `Directory.Build.targets` handles development builds and
deliberately attempts nothing more: `git describe`, no dependency, fail-safe
when there is no repository, no commits, or no `git`. Release versions are a
different problem — git height, prerelease tags, what a package is called when
it is published.

[MinVer](https://github.com/adamralph/minver) (tag-driven, no config file) and
[Nerdbank.GitVersioning](https://github.com/dotnet/Nerdbank.GitVersioning)
(`version.json`, stamps packages and assemblies alike) are the prior art. Both
add a dependency the current stamp does not have, which is the tradeoff to
weigh — not obviously worth it until something is actually published.

### Code signing

Three artifact kinds, and they do not share an answer:

| Artifact | Candidate | Note |
|---|---|---|
| NuGet packages | [SignPath](https://signpath.io) | free tier for open source; author-signing otherwise needs an OV/EV certificate issued to the legal entity |
| Customer-facing archives (`.zip` on a GitHub release) | SignPath | same certificate, different pipeline step |
| Container images, *if they ever exist here* | [Sigstore](https://www.sigstore.dev) / `cosign` | keyless signing against an OIDC identity; no certificate to buy or renew |

**Evaluate GitHub's build-provenance attestation first.** It is free, needs no
certificate, and produces a verifiable statement about what built an artifact
and from which commit. For a public repository it may cover the archive case
outright, which would leave only NuGet genuinely needing SignPath.

Signing is also where the copyright holder stops being a metadata field: a
certificate is issued to a legal entity, and organization validation takes time
and money. Worth knowing before it is urgent.

### Pipelines

Nothing under `build/` exists yet; the CI group in `TODO.md` lists the
server-side halves already decided on.

**Azure Pipelines** is friendlier to a monorepo than most: a `.yaml` per
component, path-filtered triggers, and several pipelines against a single
component when that is useful. That maps cleanly onto one-solution-per-component
and would close the existing *build only affected components* item, which is
the reason there is no root solution.

**GitHub Actions** needs a closer look before choosing — `paths:` filters and
reusable workflows cover much of the same ground, and the toolkit already
assumes GitHub for source control and change tracking. Adding a second host for
CI is a real coupling decision, not a detail: it doubles the accounts, the
credentials, and the places a failure can hide.

## Skills

### `/new`

Generalize `/project <kind> <name>` into `/new <what> <name>` — project,
component, category, possibly a rules document. One entry point for "add a
thing to this repository", each backed by the document that already governs it.

Open: whether it replaces `/project` or wraps it, and whether the name invites
confusion with `dotnet new`.

### `/upgrade`

Three operations under one verb:

| Operation | Where it runs | Notes |
|---|---|---|
| Bring the toolkit's own pinned versions current | the toolkit | SDK baselines, analyzer and test-stack versions, the `dc-agentics-verified` marker |
| Upgrade a target repository to the current toolkit | either | this is the *Update mode for an initialized repository* entry in `TODO.md`; that entry holds the decided shape |
| Change a target's layout, standalone to monorepo | either | restructure, move the component under a category, add the category map |

Run from inside a target repository, only the last two are available — the
first needs a toolkit checkout to upgrade.

The second is the one with a settled design already: the target's
`.dc-agentics.yaml` records the commit it was initialized from, so the
procedure is a diff of `init/repo/payload` between that commit and `HEAD`.

## Research

Neighbouring projects and prior art, with what each is worth taking from.
Recorded so the survey does not have to be repeated — and dated, because it
will age: **surveyed September 2026**.

### dotnet/skills — Microsoft's own .NET agent skills

Around twelve MIT-licensed plugins, including `dotnet-msbuild`, `dotnet-nuget`,
`dotnet-test` and `dotnet-template-engine`. Targets Copilot CLI, Claude Code,
VS Code, Cursor and Codex CLI from one source, following the `agentskills.io`
open standard.

Two things to take:

1. **Check it for contradictions with our C# rules.** A repository can have
   both loaded at once, and an agent given two answers will pick one without
   saying which.
2. **The skill format is a standard.** Our `.claude/skills/` shims are
   Claude-only by construction. Conforming them to `agentskills.io` would make
   them portable at roughly zero cost, since `AGENTS.md` already carries the
   substance and the shims are thin by design.

### github/spec-kit — spec-driven development

GitHub's, MIT, a CLI named `specify`. Its `init` asks which agent you use and
writes the matching per-agent command files, dropping a `.specify/` folder of
templates plus a `constitution.md` — non-negotiable project principles,
referenced by every later phase.

Architecturally the closest thing found. That constitution is very nearly our
`docs/rules/` and `.dc-agentics.yaml` pairing. The interesting difference is
direction: **spec-kit generates N tool-specific files from one source; we ship
one tool-neutral document plus one thin shim.** Theirs scales to more agent
tools, ours keeps the authority unambiguous. Worth re-reading before deciding
anything if a second agent tool ever matters here.

### Release versioning — MinVer and Nerdbank.GitVersioning

Covered under *Release versioning* above. The distinction between them, for
when it is needed: Nerdbank.GitVersioning drives from a `version.json` and uses
git height for the patch number; MinVer drives purely from git tags, with
height present only on ad-hoc builds as a signal not to release them.

### .NET solution templates

Jason Taylor's and Ardalis's Clean Architecture templates are the most-starred
in the ecosystem, scaffolding Domain/Application/Infrastructure/Web with CQRS,
MediatR, FluentValidation and EF Core.

They are **structure** opinions, and deliberately silent on everything this
toolkit is about: analyzer wiring, warnings-as-errors, central package
management, licence policy, review standards. They also assume a human runs
them once and reads the README afterwards.

Useful mainly as confirmation of the gap — and as the reason "template" is the
wrong word for what we do.

### The AGENTS.md standard

The settled convention for agent instruction files, used by a large and growing
number of repositories. The pattern that has emerged for boundaries is three
tiers — always do, ask first, never do — which is a close parallel to `auto`,
`local` and `manual`, arrived at here independently. Worth checking the
generated `AGENTS.md` against ecosystem conventions before the format hardens
further.

### Sources

- [dotnet/skills](https://github.com/dotnet/skills)
- [github/spec-kit](https://github.com/github/spec-kit) and
  [Microsoft's write-up](https://developer.microsoft.com/blog/spec-driven-development-spec-kit/)
- [Nerdbank.GitVersioning](https://github.com/dotnet/Nerdbank.GitVersioning)
- [MinVer](https://github.com/adamralph/minver)
- [jasontaylordev/CleanArchitecture](https://github.com/jasontaylordev/CleanArchitecture)
  and [ardalis/CleanArchitecture](https://github.com/ardalis/CleanArchitecture)
- [SignPath](https://signpath.io) and [Sigstore](https://www.sigstore.dev)
- [The Architect's Guide to .NET Templates: Building Scalable Golden Paths](https://bradjolicoeur.com/article/architect-dotnet-new-platform)
  — where the *golden path* framing in [`README.md`](README.md) comes from
