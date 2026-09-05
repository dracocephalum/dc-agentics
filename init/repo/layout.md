# Repository layout

Two modes. Ask which one; do not infer it from the path name.

The unit of organization is the **component**: one solution, one deliverable,
one `src/` and `test/` pair. A component may hold as many projects as it needs —
what makes it one component is that they ship together.

| Mode | Components | Shape |
|---|---|---|
| **standalone** | exactly one | the component *is* the repository |
| **monorepo** | many | each lives under a category folder at the root |

So standalone is not "a small repo" — it is a **single-component** repo. Several
projects combined into one deliverable is still standalone.

## Naming rules

These apply in both modes and are the source of most inconsistency if left
implicit:

| Thing | Convention | Example |
|---|---|---|
| Directories | lowercase, hyphenated | `proxy-gateway` |
| Solution file | matches its directory | `proxy-gateway.slnx` |
| .NET project + assembly | PascalCase, prefixed | `Contoso.ProxyGateway` |
| Default namespace | project name, minus `.Core` | `Contoso.ProxyGateway` |
| Test project | project name + `.Tests` | `Contoso.ProxyGateway.Tests` |

The rule underneath: **directories are kebab-case, .NET artifacts are
PascalCase.** A solution file is a directory-level artifact, so it follows the
directory.

### The `.Core` exception

A `.Core` segment names the assembly, not the namespace, so it is dropped from
the default namespace:

| Project (assembly) | Namespace |
|---|---|
| `Contoso.Core` | `Contoso` |
| `Contoso.Core.Tests` | `Contoso.Tests` |
| `Contoso.ProxyGateway` | `Contoso.ProxyGateway` (unchanged) |
| `Contoso.CoreBanking` | `Contoso.CoreBanking` (unchanged) |

This is applied automatically by `Directory.Build.props` — it sets
`RootNamespace` and leaves `AssemblyName` alone, so the DLL keeps its full name.
A `.csproj` can override it, since the project body is evaluated afterwards.

The condition matches a whole trailing `.Core` segment, not a substring — which
is why `Contoso.CoreBanking` is left alone. A naive string replace would turn it
into `ContosoBanking`.

`Contoso` is a placeholder: the prefix comes from the user, usually an
organization or product name, and is never hard-coded into this toolkit.

## Standalone

    <repo-root>/
      AGENTS.md
      README.md                      the component README - what it is, how to run it
      .editorconfig
      .gitattributes
      .gitignore
      Directory.Build.props
      Directory.Build.targets
      Directory.Packages.props
      Tests.props
      StyleCop.props
      stylecop.json
      stylecop.ruleset
      <repo-name>.slnx
      docs/
        rules/                     exactly as in payload/docs/rules/
          coding/csharp/csharp-coding-rules.md
      src/
        Contoso.Thing/
          Contoso.Thing.csproj
      test/
        Contoso.Thing.Tests/
          Contoso.Thing.Tests.csproj

Production code in `src/`, tests in `test/`. Both singular, matching `src/`.

## Monorepo

Root-level folders, created **only as needed** — an empty directory tree is
noise, and a folder that exists implies a decision that has not been made:

| Folder | Contents |
|---|---|
| `services/` | deployable C# services |
| `libraries/` | packages published to NuGet |
| `jobs/` | scheduled executables (Kubernetes CronJobs and similar) |
| `tools/` | never shipped to production |
| `infrastructure/` | Terraform and similar provisioning |
| `ui/` | front-end applications |
| `docs/` | documentation |
| `build/` | CI/CD pipeline definitions |

Each C# component gets a kebab-case folder, and **inside it the standalone
layout repeats**:

    <repo-root>/
      Directory.Build.props          <- one set at the root, inherited by all
      Directory.Build.targets
      Directory.Packages.props
      .editorconfig
      stylecop.ruleset
      README.md                      map of categories
      services/
        README.md                    map of components in this category - one row each
        proxy-gateway/
          README.md                  what it is, how to run it, configuration
          proxy-gateway.slnx
          src/
            Contoso.ProxyGateway/
          test/
            Contoso.ProxyGateway.Tests/
      libraries/
        README.md
        message-contracts/
          README.md
          message-contracts.slnx
          src/
            Contoso.MessageContracts/
          test/
            Contoso.MessageContracts.Tests/

### One solution per component, none at the repository root

Each component carries its own `.slnx` covering only its own `src/` and `test/`.

**Do not create a root solution spanning the repository.** It gets out of hand
quickly: load times grow with every component added, an unrelated change forces
a rebuild across the tree, and the file becomes a merge-conflict magnet that
every component author has to touch.

This is a decision, not a default — do not add one even if asked to "make a
solution for the repo" without the tradeoff being discussed first.

To build everything, build each `*.slnx` found under the repository; CI should
build only the components a change touches, which is the point of the layout.
`dotnet build` with no argument at the root fails with `MSB1003` — the expected
consequence of having no root solution, not a misconfiguration.

### Config lives at the root only

`Directory.Build.props`, `Directory.Build.targets`, `Directory.Packages.props`,
`.editorconfig` and the StyleCop files exist **once**, at the repository root.
Every component inherits them.

Do not copy them into component folders. All three `Directory.*` files
resolve by searching upward and stopping at the first hit, so a copy inside
`services/proxy-gateway/` silently cuts that component off from the root
configuration — with a green build and no warning.

Non-.NET folders (`infrastructure/`, `ui/`, `docs/`) are unaffected: MSBuild
files only apply to MSBuild projects.

## Creating a component

The procedure — templates, the sample code each one emits that fails the
ruleset, central-package-management fixes, test wiring, verification — is
[`payload/docs/rules/coding/csharp/csharp-new-project.md`](payload/docs/rules/coding/csharp/csharp-new-project.md),
shipped to every repository as `docs/rules/coding/csharp/csharp-new-project.md`
and backing `/project`. The first component at initialization follows it too.

## Choices made here

Recorded so they are not re-litigated per repository:

**`test/`, not `tests/`.** Matches `dotnet/runtime`, `dotnet/aspnetcore` and
`dotnet/roslyn`, and pairs symmetrically with `src/`. Both spellings are common
in the wider ecosystem — this is a coin flip that has been flipped. Be
consistent rather than right.

**`docs/`, not `doc/`.** Unambiguous: it is what GitHub Pages expects and what
the .NET repositories use.

**`.slnx`, not `.sln`.** The SDK 10 default, XML, and reviewable in a diff —
unlike the legacy format's GUID soup.

## Test projects

Everything a test project needs lives in `Tests.props` at the repository root.
It is imported from `Directory.Build.props` under a single condition:

    <Import Project="$(MSBuildThisFileDirectory)Tests.props"
            Condition="$(MSBuildProjectName.EndsWith('.Tests'))" />

So any project named `*.Tests`, at any depth, picks up the whole stack and
nothing else does. Verified: a `src/` project resolves 1 package reference
(the analyzer), a `.Tests` project resolves 10.

**Why the condition lives in the root file** rather than a
`Directory.Build.props` inside `test/`: a nested one would *replace* the root
file for that subtree — first-found-wins, no merging — silently cutting test
projects off from central package management, StyleCop and warnings-as-errors.

Test projects also get `IsPackable=false`, so they can never be published by
accident.

### What is included

| Package | Role |
|---|---|
| `Microsoft.NET.Test.Sdk` | test host |
| `xunit`, `xunit.runner.visualstudio` | framework and VS/CLI runner |
| `coverlet.collector` | coverage collection |
| `FakeItEasy` | faking |
| `FakeItEasy.Analyzer.CSharp` | catches FakeItEasy misuse at compile time |
| `AutoFixture` | test data generation |
| `Shouldly` | assertions |
| `DeepEqual` | structural comparison |

`xunit.runner.visualstudio`, `coverlet.collector` and
`FakeItEasy.Analyzer.CSharp` carry `PrivateAssets=all` plus the analyzer asset
list — they are build-time tooling and must not flow anywhere.

Since test projects are never shipped, the bar for adding a package here is
low: a redundant reference costs a restore entry and nothing else. Still confirm
the convenience libraries (`AutoFixture`, `Shouldly`, `DeepEqual`) with the user
at initialization rather than assuming.

### Enabled only when production code uses them

Commented out in `Tests.props`; uncomment when the corresponding library is
actually referenced by the application:

- `FluentValidation` — validator test helpers
- `Serilog.Sinks.TestCorrelator` — asserting on emitted log events

### Do not bump these piecemeal

`xunit` 2.x pairs with `xunit.runner.visualstudio` **3.x**. Version 4.x of the
runner targets `xunit.v3` and does not belong with `xunit` 2.9.3 — taking
"latest" for each package independently produces exactly that mismatch. Move
the whole set together, and run `dotnet test` afterwards to confirm.

## Keeping the test stack current

The versions in `Directory.Packages.props` are a **known-good floor, not a
ceiling**. They record a combination that was verified to restore, build and
test together — nothing more. A repository initialized a year later should not
inherit a year-old stack by default.

So at initialization, **try to move the whole set forward**, then keep what
survives verification.

### Why not just take latest for each package

Because these packages are not independent, and the failures are compile-time
ambiguities rather than helpful version errors. Two real examples, both found by
attempting exactly that:

    xunit 2.9.3 + xunit.runner.visualstudio 4.0.0
      -> runner 4.x targets xunit.v3; tests silently fail to discover

    xunit 2.9.3 + Xunit.Combinatorial 2.1.41
      -> error CS0433: 'TheoryAttribute' exists in both xunit.core
         and xunit.v3.core

"Latest of everything" is not a valid combination. **Latest mutually compatible**
is the goal.

### Procedure

1. **Check the marker.** `Directory.Packages.props` carries
   `dc-agentics-verified: sdk=<version> date=<date>`. If it is recent and the
   SDK matches, there is little to gain — proceed.

2. **Look up current versions** for the test packages:

       dotnet package search <id> --exact-match

3. **Move families together, not package by package.** The couplings recorded
   in `Directory.Packages.props` are the ones known to matter:
   the xunit family, `Xunit.Combinatorial`, and `Mvc.Testing` against the TFM.
   Treat a major-version jump in `xunit` as a decision to discuss, not a bump —
   moving to xunit v3 changes package identities, not just numbers.

4. **Verify by running, not by reading.** A restore that succeeds proves
   nothing:

       dotnet build      # must be clean under warnings-as-errors
       dotnet test       # must actually discover and pass tests

   Discovery failures are the dangerous case: a mismatched runner produces
   *zero tests* and a green exit code. Confirm the expected test count.

5. **Keep or revert per family.** If a family fails, fall back to the pinned
   versions for that family and keep the rest. Partial progress is fine.

6. **Update the marker** — `sdk=` and `date=` — so the next initialization knows
   when the set was last confirmed.

### If a bump fails

Bisect within the family rather than abandoning the attempt. `Xunit.Combinatorial`
was pinned at `1.7.31` exactly this way: `2.1.41` and `2.0.24` both failed with
CS0433, `1.7.31` passed, so `1.7.31` is the newest compatible version — not a
guess, and not simply "whatever the template said".

Record any newly discovered coupling in the comment block in
`Directory.Packages.props`, so the next person does not rediscover it.
