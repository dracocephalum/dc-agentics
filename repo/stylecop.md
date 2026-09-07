# StyleCop — the ruleset, its severities, and the wiring

Applies when a StyleCop severity needs changing, when someone asks why a rule
is set the way it is, or when the analyzer has to be wired into a repository
that was not initialized by the toolkit.

There is **one ruleset**, `payload/stylecop.ruleset`. Its header states the
principle every severity was set against — a rule fails the build only when
the toolchain can fix the violation or an agent follows it unprompted — and
the comment on each rule says which case it is. Read the header before
changing anything; it also says what raising a severity costs.

## What each severity means here

| Action | Effect under warnings-as-errors | Used for |
|---|---|---|
| `Error` | fails the build; severity is not negotiable in `.editorconfig` | `SA1414`, which is also the analyzer probe at initialization |
| `Warning` | fails the build | rules `dotnet format analyzers` can fix, so the failure is never seen |
| `Info` | shows in the editor; never fails the build | rules with no fix whose outcome is cosmetic — the ordering rules |
| `None` | off | documentation on every member, `this.`, the underscore ban |

Rules not listed take the analyzer package's default, which is `Warning` for
most — and therefore a build failure. A rule that starts firing that is not in
the file is a candidate for a row, with a decision.

## Changing a severity

Edit the `Action` attribute. **Never comment a `<Rule>` element out**: every
line ends in a description comment, XML comments do not nest, and the result
is a ruleset that fails to load with a confusing error.

Before raising anything to `Warning`, answer the two questions in the header.
`dotnet format analyzers <solution> --diagnostics <id>` answers the first
directly: "no associated code fix found" means the cost is a manual round-trip
on every violation. The ordering rules SA1201–SA1204 fail that test; the
spacing rules pass it. That is measured, not assumed.

Two rules have a dependency outside the file:

- **SA1101** (`this.`) is off. Turning it on also needs the four
  `dotnet_style_qualification_for_*` settings in `.editorconfig` set to
  `true`, or the IDE offers to strip `this.` while the build errors for its
  absence.
- **SA1309** (no leading underscore) is off because `_camelCase` private fields
  are the convention, and `.editorconfig`'s naming style for private fields
  says so. Turning it on means changing that style to plain `camelcase` too.

Never express a StyleCop severity as `dotnet_diagnostic.SAxxxx.severity` in
`.editorconfig` — that silently overrides the ruleset for that rule. Severities
belong in the ruleset.

## The banned-API list

`BannedSymbols.txt` is live as shipped. It bans the clock APIs the coding
rules already forbid in favour of `TimeProvider`, and is attached to non-test
projects only. A hit is a defect, not style, which is why it has no relaxed
form. The file's own header says the one thing that breaks it: a blank line.

## Wiring it into a build

Copying the files alone does nothing. `StyleCop.props` carries the wiring, but
**MSBuild does not auto-import it** — only `Directory.Build.props` and
`Directory.Build.targets` are picked up by name. Import it from a
`Directory.Build.props` at the repository root:

    <Project>
      <Import Project="$(MSBuildThisFileDirectory)StyleCop.props" />
    </Project>

An existing `Directory.Build.props` is merged into, never replaced —
[`copy.md`](copy.md), *Preconditions*.

### Why `$(MSBuildThisFileDirectory)`

`CodeAnalysisRuleSet` is resolved **relative to the project directory**, not
relative to the file that sets the property. A bare `stylecop.ruleset` written
in a root-level props file resolves to `src/Foo/stylecop.ruleset` for a project
in `src/Foo/`, finds nothing, and applies no rules — with no error. The build
succeeds and the ruleset is silently ignored, which is the worst failure mode
available.

`$(MSBuildThisFileDirectory)` expands to the directory of the file it is written
in, with a trailing slash, so it is correct at any project depth. The same
applies to the `stylecop.json` and `StyleCop.props` paths.

### Central package management

`StyleCop.props` omits the package `Version` when
`$(ManagePackageVersionsCentrally)` is `true`, because supplying a version in
both places raises NU1008. In a CPM repo, add the version to
`Directory.Packages.props`:

    <PackageVersion Include="StyleCop.Analyzers" Version="..." />

Otherwise the version comes from `$(StyleCopAnalyzersVersion)` in
`StyleCop.props`. Check the current release rather than trusting the default
pinned there.

### Verify

Build once, then confirm StyleCop diagnostics actually appear, by introducing
a deliberate violation of a rule the ruleset leaves enabled and confirming the
build reports it. If nothing is reported, the ruleset path is the first thing
to suspect. `SA1414` is the convenient probe, since the ruleset sets it to
`Error`:

    public static (int, string) Probe() => (1, "a");   // expect: error SA1414

Known-good baseline: this layout was verified on .NET SDK 10.0.400 with
StyleCop.Analyzers 1.2.0-beta.556, for a project at `src/Foo/`, with central
package management both on and off. In both cases restore succeeded and SA1414
was reported as an error.
