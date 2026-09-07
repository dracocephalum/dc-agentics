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

## Machines

`machine/` is named for its subject, so it has room for more than one kind of
machine. Everything in it today assumes an **interactive** one: a person
answers the UAC prompt, completes a browser sign-in, and opens a new terminal
after a PATH change. Several steps stop and ask outright.

A **headless machine** — an agent running these procedures inside an automated
pipeline, with no one to answer — needs the same tools and different answers:

- **Non-interactive installs.** `winget` needs its own flags and an elevation
  story that is not a UAC prompt; a container image may be the better answer
  than installing at all.
- **Credentials without a browser.** `gh auth login` is interactive by design.
  A pipeline wants a token from the runner's secret store, or a GitHub App,
  and commit signing wants a key that no human unlocks.
- **PATH inside one process.** "Open a new terminal" is not available; the
  session that installs is the session that must use the tool.
- **What verification means.** Every step here ends in a check a person reads.
  Headless, those become assertions that fail a build.

Worth writing only when something actually runs this way — most likely
alongside the *Pipelines* decision above, since a runner is the first headless
machine the toolkit will meet.

## Skills

### `/new`

Generalize `/project <kind> <name>` into `/new <what> <name>` — project,
component, category, possibly a rules document. One entry point for "add a
thing to this repository", each backed by the document that already governs it.

Open: whether it replaces `/project` or wraps it, and whether the name invites
confusion with `dotnet new`.

**Not a context argument.** Measured while adding `/scrub` and `/upgrade`: a
skill's `SKILL.md` body is loaded when the skill is invoked, not on every
session — what is always present is its name and description. Six shims cost
something like fifteen lines of descriptions, against `AGENTS.md` at 107 in a
generated target. Consolidating skills therefore saves almost nothing in
context, and the case for `/new` has to stand on clarity instead: fewer verbs
to choose between, and no ambiguity about which one adds a thing.

The same measurement is why the always-loaded budget in `AGENTS.md` names
`AGENTS.md` first. For a target it is the single largest thing read every
session — 107 lines, of which the layout table and the guideline rows are most
of it — and the only lever on it is the number of rows, since each new rules
document earns one.

### A full `/scrub`

`/scrub` as shipped is a **consistency** pass: lint, links, placeholders, line
endings, privacy, settings that still match reality, a complete `AGENTS.md`
index, stale `TODO.md` entries, and baseline drift. It deliberately stops
short of anything that needs a build, so it stays cheap enough to run without
deciding to.

A *full* scrub would add what `verify.md` runs once at initialization:
`dotnet build` and `dotnet test` with the expected count, the analyzer probe,
`nuget-license` over the transitive graph, lock files current, and the age of
the `dc-agentics-verified` marker on the test stack.

The open question is not whether those checks are worth running — they are —
but whether a skill is the right place, given that CI will eventually run all
of them on every push. A full scrub may turn out to be most useful exactly
where CI is not: before a first push, on a repository nobody has touched for a
year, or when a toolchain has moved underneath one.

### Tree shaking against a model line

The compaction problem inverted: instead of writing terse documents and hoping
a model fills the gaps, keep a **comprehensive** set — every rule stated, no
reliance on any default — and shake it down against a named model when someone
asks to compact. The full text stays the source of truth; the compact form is
generated output for one model line, regenerated when that line moves.

It is the only version of compaction that fails safely, because nothing is ever
lost: a regression after a model change is fixed by re-shaking, not by
remembering what was deleted. It also makes the model dependency explicit
rather than baked in.

The cost is high enough to park it. Two forms of every document to keep in
step, a shaking step that must itself be verified — the only honest test being
whether an agent still reaches a conforming repository from the shaken
version — and a comprehensive source set that does not exist today, because
this toolkit began by writing against Opus and Fable rather than against
nothing. Worth revisiting only if a second model line ever has to be supported
properly.

### Verbose multi-file rule sets

Prior art worth reading before assuming our shape is right:
[Aaronontheweb/dotnet-skills](https://github.com/Aaronontheweb/dotnet-skills/tree/master/skills/csharp-coding-standards)
splits general C# coding standards across several files. Ours is one
`csharp-coding-rules.md`, with EF Core and unit tests split out because each has
its own trigger.

The distinction that matters is not file count but **what fires a load**. Their
split is by topic within one subject, so a request about C# plausibly pulls
several files; ours splits by trigger, so touching EF Core loads EF Core rules
and nothing else. Verbosity aimed at weaker models is the other half of it, and
it is real cost on every request for a model that did not need it.

Not a change to make now. Revisit if a second model line has to be supported,
where the extra explicitness stops being waste — most likely together with
*Tree shaking* above, which is the same problem approached from the other end.

### A compacting `/scrub`

Documents cost context every time they are read, so trimming them has real
value. But "compact" covers two very different operations, and only one of them
is safe.

**Removing genuine redundancy is safe and belongs here.** A rule stated in two
documents is a drift hazard, not just length: the copies diverge and nothing
says which is authoritative. So is prose that restates what a linked document
already says, and instructions for things that no longer exist. These are
verifiable — two documents saying the same thing is a fact, not a judgement —
which is why *No rule stated twice* is now a shipped check rather than an idea.

**Removing content because the model would do it anyway is a different
proposition**, and the reasons to be careful are specific:

- **It cannot be verified, only observed.** The toolkit's standard is
  "verified, not asserted". "Opus does this by default" is an assertion whose
  truth changes with the model, the version, the context length, and how much
  of the document survived into the prompt. Nothing in the repository could
  prove it still held six months later.
- **The payload is tool-neutral by design.** `AGENTS.md` is a cross-tool
  convention and the shipped rules are written for any agent. Compacting
  against one vendor's defaults silently couples every initialized repository
  to that vendor — a repo driven by a different tool would quietly lose rules
  its model does not default to.
- **The failure is invisible.** A dropped rule does not error. It shows up
  months later as a repository that stopped meeting a standard nobody noticed
  had gone.
- **Instructions do more than change behaviour.** They also tell a *reader*
  what the standard is, and make the rule reviewable in a diff. A rule the
  model would have followed anyway still earns its place if a person needs to
  know it is the rule.

If it is ever attempted, the toolkit's own documents under `machine/` and
`repo/` are the place to try it, not the payload: they are read by whatever
agent the user runs today, and a mistake stays here rather than shipping. It
would want a stated model baseline in `.dc-agentics.yaml`, a record of what was
removed and why, and some way to re-test the claim when the baseline moves —
which is most of an evaluation harness, and worth building only if the context
saving turns out to be large.

### An automated `/scrub`

`/scrub` reports and changes nothing. That is the right default for a check
whose findings include "the baseline you recorded no longer matches the SDK",
which is a decision rather than an edit.

Some findings are not decisions, though. Mixed line endings in a file,
`markdownlint --fix`'s mechanical corrections, trailing whitespace, a
`TODO.md` entry whose closing condition is demonstrably met — these have one
right answer. A `--fix` mode could apply exactly that class and report the
rest, provided the fixes land as their own reviewable change and never mix
with whatever the user was doing.

The risk to design against is a scrub that quietly rewrites files nobody
asked it to touch, which is how a useful check becomes one people turn off.

### `/upgrade`, third operation: standalone to monorepo

The first two operations are written — [`repo/upgrade.md`](repo/upgrade.md).
The third is not, and it shares nothing with them but the verb: they diff a
recorded baseline and apply a delta, while this moves files, rewrites paths,
creates category folders and a category map, and relocates the component's
solution.

Three things it needs before it can be written:

- **A test subject that is not `dc-nightingale`.** Converting it would destroy
  the standalone baseline the second initialization trial established, which is
  the only conforming target there is.
- **`docs/templates/category-README.md` back.** Standalone initialization
  deletes it, on the grounds that a repository with no categories can never use
  it — but the conversion is exactly when a category map is needed. Either keep
  the file in both modes, or have the conversion restore it from the toolkit.
- **The lessons from the toolkit's own restructure.** Moving `init/` to
  `machine/` and `repo/` produced the whole failure list this procedure would
  have to encode: path references living in files a markdown search never
  reaches, a directory's `.gitattributes` overriding the root's, `git mv` and
  rename detection, and a bulk rewrite quietly changing line endings.

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
