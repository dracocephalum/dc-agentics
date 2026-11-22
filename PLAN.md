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

The standalone reference repository is the likely first packable library, so
this is the one that will be needed first.

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

**Decided for everything short of a release**, and shipped as an opt-in:
the number is kept in a file, the build says what kind it is, and the
pipeline's counter arrives as a property —
[`repo/payload/agentics/rules/delivery/delivery.md`](repo/payload/agentics/rules/delivery/delivery.md).
What is left open here is the release itself: what starts it (a pushed tag,
`v1.2.0`, or `<component>/v1.2.0` for a component versioned apart, is the
leaning), the checks before it publishes (the tag is the version in the
code, the commit is on the default branch, the version is not published
already), and nuget.org's trusted publishing. The rest of this section is
the reasoning that led there.

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

**A host can supply the version instead, and that is worth knowing before
choosing.** Azure Pipelines is the example to reason from, because its
auto-incrementing package versions are a common first encounter with the
problem. Two separate mechanisms combine there:

| Piece | What it is |
|---|---|
| `$(Rev:r)` in the pipeline's build-number format | a counter the host maintains, resetting per unique prefix per day — this is what produces the incrementing last part |
| `versioningScheme: byBuildNumber` on the pack task | passes that build number to `dotnet pack` as an MSBuild property |

**Neither edits a file**, which is the question worth settling: the version
arrives as a property at pack time, the working tree stays clean, and nothing
about it makes the stamp above report dirty.

Two cautions if we go that way. A four-part `1.0.0.42` is **not** a SemVer
prerelease — NuGet treats it as a stable version *greater than* `1.0.0`, so a
CI build published to a shared feed outranks the release it came after; a
prerelease form such as `1.0.0-ci.42` does not. And a host-supplied version
sets the *package* version, leaving the assembly's informational version to
the stamp, so the two can disagree unless the pipeline sets both.

The tradeoff against MinVer and Nerdbank is portability: a host-supplied
version is one pipeline setting and no dependency, but it lives outside the
repository, cannot be reproduced by building locally, and has to be
reimplemented on every CI host. Deciding this belongs with *Pipelines* below.

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

A first pipeline is shipped as an opt-in template, a GitHub Actions workflow
of two jobs —
[`repo/payload/agentics/rules/delivery/github.md`](repo/payload/agentics/rules/delivery/github.md).
It builds every solution on every change, which is right for one component
and wasteful for many; the CI group in `TODO.md` lists what it does not do
yet. The comparison below was written before it and still holds for the
question it leaves open, a monorepo of many components.

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

**A coverage gate belongs here, not in the repository.** The shipped
`coverage.config` measures through the platform's own collector, which cannot
fail a run on a threshold. Enforcing one means a report step in the pipeline
over the cobertura files, which also keeps the local run and the gate apart —
the better default. The numbers are already recorded, under `coverage:` in
each repository's `.agentics.yaml` (85 the hard limit, 90 green, shipped as
defaults), so the pipeline step reads them from there rather than carrying its
own copy.

## Toolchains

The toolkit supports one toolchain, .NET, and says so in every second
document. A second one is wanted, Go first, and one day a monorepo that
holds both. This is where each document would be cut so that a toolchain is
something a repository lists, and what is not about a toolchain is written
once. Nothing below is done; the order at the end starts with what costs
least and is useful with .NET alone.

A toolchain is named for what builds, `dotnet` and `go`, not for a
language: the build files, the package rules and the pipeline are .NET's,
and only the coding rules are C#'s.

### What is taken as settled

- **A repository lists its toolchains.** `repository.toolchains: [dotnet]`
  in `.agentics.yaml` in place of `repository.framework: dotnet`; a list
  from the first day, since one value would have to be migrated the day a
  second toolchain joins. An empty list is a repository that takes the
  general rules alone.
- **Which toolchain a component is, is read from the tree** and recorded
  nowhere: a `.slnx` or a `go.mod` in its folder says it. The scrub checks
  the list against what the tree holds.
- **A file that every repository gets stays one file and holds every
  toolchain**, where that is the easier thing: `.gitignore`,
  `.gitattributes`, `.editorconfig`, and a rule that is mostly general with
  a section per toolchain. A Go repository carrying lines that ignore `bin/`
  and `obj/` loses nothing.
- **A rule that is half a toolchain's is cut in two**, the way a host is
  already cut from its rule: `source-control.md` beside `github.md`.
- **The Go half is written against the first Go repository**, not ahead of
  it. What is done before then is the room for it.

### The component, in both

The component is what carries over: what builds and versions together, in
its own folder under a category. Its inside is the toolchain's.

| | .NET | Go, as it looks from here |
|---|---|---|
| A component is | one solution | one module, the folder with `go.mod` |
| Inside it | `src/` and `test/`, a project each | packages as folders, `cmd/<name>/` for each executable, `internal/` for what is private; tests beside the code as `_test.go` |
| Another component is reached | as a package at a version, never by `ProjectReference` | as a module at a version, never by a `replace` to a sibling folder |
| The recorded workaround | a commented `ProjectReference`, listed in `TODO.md` | a `replace`, or a `go.work` that is not committed |
| Nothing spans the repository | no root solution | no committed root `go.work`, for the same reasons |
| Shared configuration | `Directory.*.props`, once at the root | a linter's configuration at the root; nothing is inherited by the build |
| A version | `Version.props` and the kind of build | a git tag, `<folder>/v1.2.3` for a module in a subfolder |
| Published to | a package registry | nowhere: a module is fetched from its repository |
| Names | PascalCase projects and namespaces, kebab-case folders | the module path and lowercase package names, kebab-case folders above the module |

Every row of the Go column is a guess until a repository tries it. The
last three are where the rules differ most, and they are all in
`delivery.md` and the naming table of `layout.md`.

### Where each document is cut

**General already, and left alone:** `change-tracking/`,
`source-control/github.md`, `security-reminders.md`,
`coding/where-facts-live.md`, `coding/markdown/`, `optimize.md`, the pull
request template, the ruleset, `.markdownlint.yaml`, the payload's
`TODO.md`, and the templates `rules-AGENTS.md` and `category-README.md`.

**General but for a sentence**, each mended in place:

| Document | What names .NET | Becomes |
|---|---|---|
| `source-control/source-control.md` | "`dotnet build` and `dotnet test` green" before a change request | the build and the tests green, by the commands `AGENTS.md` gives |
| `coding/code-review.md` | StyleCop and the analyzers as what a review does not repeat | what the build already enforces; the list of language checklists at its end grows by one |
| `coding/architecture.md` | four pointers to the C# rules for the language's half | a list of the language files at its end, as the review has |

**One file, a section per toolchain**, as the user of it reads all of it
anyway:

| Document | General | A toolchain's |
|---|---|---|
| `dependencies.md` | the policy by SPDX identifier, and pull requests | already cut: *Enforcement — .NET*, *Enforcement — npm*; Go adds a third |
| `scrub.md` | checks 1 to 3, 5 to 7, 9, 10 | the `dotnet format` note in check 4; check 8, the files forked from `dotnet new`; the list of what a build reads in check 11; the registry's package type in check 12. Each says which toolchain it is skipped without |
| `.gitignore`, `.gitattributes`, `.editorconfig` | the whole file | Go's lines are added below the forked part; the baseline hash is of the pristine file and does not move |

**Cut in two**, a general rule and a toolchain file beside it:

| Document | Stays general | Moves to the .NET file |
|---|---|---|
| `layout.md`, 553 lines | the component and what makes it one; references between components as a principle; the two modes; folder naming; the categories; *The toolkit's rules and the repository's*; *Root documents*; *Samples*; the choices of `agentics/`, `docs/` and `ui/` | the naming rows for solution, project, namespace and test project; *The `.Core` exception*; the trees with their build files; *One solution per component*; *Config lives at the root only*; the choices of `test/` and `.slnx`; all of *Test projects* and *Keeping the test stack current*, over a quarter of the file |
| `delivery/delivery.md` | the three kinds of build and how far each reaches; a registry for each kind; a pipeline for each kind and its list; *A committed reference names a release*; the shape of adopting it | `Version.props` and `Packaging.props`; the kind as a build property; how NuGet orders `ci.9` and why never four numbers; nuget.org; the `dotnet pack` steps of adopting |
| `templates/root-AGENTS.md` | the head, the rows of the general rules, *Conventions* in part | the layout variants' build files, the rows for the C# rules, *Code intelligence*, *Building and testing*. The template becomes a frame and a block per toolchain, and the sync leaves out a row whose rule the repository does not have, as it does for an excluded one |
| `templates/component-README.md`, `root-README.md` | everything but the commands | two lines of build commands and the solution's name |

**A toolchain's whole**, and moved as they are: `coding/csharp/`; the
templates `Version.props`, `Packaging.props` and `build.yml`, the last
under a name that says whose steps they are; at the root, the
`Directory.*` files, `Tests.props`, the StyleCop files, `BannedSymbols.txt`,
`nuget.config`, `global.json`, `.config/dotnet-tools.json` and the two
licence lists, whose format is the .NET tool's.

**A host's and a toolchain's at once:** `delivery/github.md`. The workflow
mechanics are the host's. *Reading a package*, the two ignored files and *A
package's visibility is its own* are the host's NuGet registry, and mean
nothing to a toolchain that publishes no package. They stay where they are
under headings that say NuGet until a second toolchain shows whether they
want a file of their own.

**The settings file:** `repository.framework` becomes the list.
`repository.namespace` is .NET's and says so. `coverage` keeps its two
numbers and names a collector per toolchain. `delivery.versioning` is
worded for `Version.props` and is reworded for "the repository has a
version of its own".

**The toolkit's own side:** `repo/build.md` is the .NET stage of an
initialization and becomes one stage document per toolchain;
`repo/copy.md`, `repo/verify.md` and `repo/upgrade.md` each have a general
frame and .NET steps; `repo/stylecop.md`, `repo/version-check.md` and
`repo/baselines/` are .NET's. `/new` names the C# procedure and comes to
ask which toolchain. `repo/sync.sh` copies `agentics/` whole and comes to
leave out what belongs to a toolchain the repository does not list.

### Where a toolchain's files live

Two questions, and the first decides more than the second.

- **In a repository**, where an agent reads them: beside the general rule,
  in a file named for the toolchain. `delivery/dotnet.md` joins
  `delivery/github.md`; `layout.md` keeps its path, which a comment in
  consumers' project files names verbatim, and gains `layout/dotnet.md`.
  `coding/csharp/` stays, named for the language because its rules are the
  language's. Templates go under `templates/dotnet/`.
- **In the toolkit**, where a sync copies them from: one payload tree as
  now, or one tree for the general files and one per toolchain, each a
  mirror of a repository's root and laid over one another. The rules do
  not need the second: a folder named for a toolchain is enough for a sync
  to leave it out. The root files do, since nothing in `nuget.config` says
  whose it is. `toolkit.payload-path` in the settings exists for a move of
  this kind. It is the last step and not the first: it is mechanical, and
  it proves nothing until a second tree has something in it.

### Order

Each step leaves every initialized repository syncing clean.

1. The sentences of *General but for a sentence*, and the toolchain each
   scrub check is skipped without. Useful today, and it moves nothing.
2. `repository.toolchains`, read with `framework` as its fallback, and the
   scrub's check 6 comparing it with the tree.
3. `layout.md` and `delivery.md` cut in two; the .NET templates moved; the
   links, the index rows and the shims that name them.
4. `root-AGENTS.md` as a frame and a block per toolchain, and the sync
   leaving out a toolchain's rules and rows where it is not listed. Proved
   by a sync of a .NET repository that changes only the paths that moved,
   and by an initialization with an empty list.
5. The payload as trees laid over one another, once a second toolchain
   has files of its own to put in one.
6. The Go files, against the first Go repository.

### Beside it: a component that follows an upstream

The first Go candidates are forks that are to stop merging their upstream
and review its changes instead. That is a rule of its own and no
toolchain's: the last upstream release looked at is recorded in the
component; each new release is read as a diff from that one; every change
is sorted into what does not concern the component, what is taken by hand,
and what is a security fix; and nothing is merged, so the component's
paths are its own. It wants a home in `layout.md` or beside it, and a
scrub check that says how far behind the record is.

### Not settled

- Whether `layout/dotnet.md` beside `layout.md` reads better than the test
  stack moving to `coding/csharp/`, where its trigger already is.
- A pipeline in a repository with two toolchains: one called workflow of
  shared steps per toolchain is likely, and whether `dev` and `ci` are
  then one file with a job each or a file per toolchain is open.
- What `ci` means for a toolchain with no registry. A Go module's
  unreleased commit already has a version anyone can fetch, so the kind
  may have nothing to publish and only something to test.
- Whether an empty list is worth supporting on its own, or only as the
  state between a repository's first commit and its first component.

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

### A full `/scrub`

`/scrub` as shipped is a **consistency** pass: lint, links, placeholders, line
endings, privacy, settings that still match reality, a complete `AGENTS.md`
index, stale `TODO.md` entries, and baseline drift. It deliberately stops
short of anything that needs a build, so it stays cheap enough to run without
deciding to.

A *full* scrub would add what `verify.md` runs once at initialization:
`dotnet build` and `dotnet test` with the expected count, the analyzer probe,
`nuget-license` over the transitive graph, lock files current, and the age of
the `agentics-verified` marker on the test stack.

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

### Re-testing a trim to a model's defaults

Compaction left this file when `/optimize` shipped: measuring, compacting
with no rule lost, and removing what a named model does unprompted are all in
`repo/payload/agentics/rules/optimize.md`, with the reasons the last is
guarded the way it is.

What is still only an idea is the missing half of that last operation. Its
removals are asserted, not verified, and the log it keeps makes them
reversible but does nothing to say *when* to reverse them. Re-testing a claim
when the model line moves — does an agent still reach a conforming repository
without the removed text — is most of an evaluation harness: a set of tasks,
a way to run them against the trimmed and untrimmed documents, and a
definition of conforming that a machine can check. Worth building only if
the measured saving from the operation turns out to be large, which the
`measure` report is there to say.

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
`agentics/rules/` and `.agentics.yaml` pairing. The interesting difference is
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
