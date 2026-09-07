# StyleCop ruleset

Applies when initializing a repository whose primary framework is .NET (dotnet core).

Source files in this toolkit, all under `payload/`, landing at the target root
under the same names:

| File | Purpose |
|---|---|
| `stylecop.ruleset` | rule severities; ships in relaxed mode |
| `stylecop.json` | StyleCop settings |
| `StyleCop.props` | package reference and wiring |

All three go to the repository root, together. They reference each other by
`$(MSBuildThisFileDirectory)`, so splitting them across directories breaks the
wiring.

## Steps

### 1. Ask which mode

Ask the user before copying — do not assume:

- **Relaxed** (default) — the ruleset as shipped. Ordering, `this.` prefixing,
  bracket spacing and single-line-comment layout are off or informational.
- **Strict** — the same file with a set of suppressions removed, so those rules
  return to their default severity.

### 2. Copy to the repo root

`stylecop.ruleset` arrives with the payload copy, in relaxed mode. Its name is
mode-neutral on purpose: the consuming repo should not care which mode it was
generated from.

### 3. For strict mode only, comment out these rules

| Rule | Section in file | Relaxed action |
|---|---|---|
| SA1512 | LayoutRules | `Info` |
| SA1201 | OrderingRules | `Info` |
| SA1202 | OrderingRules | `Info` |
| SA1203 | OrderingRules | `Info` |
| SA1204 | OrderingRules | `Info` |
| SA1101 | ReadabilityRules | `None` |
| SA1111 | ReadabilityRules | `None` |
| SA1009 | SpacingRules | `None` |
| SA1011 | SpacingRules | `None` |

**Comment out the `<Rule/>` element only — never the whole line.**

Each rule line ends with a trailing XML comment describing the rule. XML comments
cannot nest: wrapping the entire line produces invalid XML, the ruleset fails to
load, and the build breaks with a confusing error.

Wrong — the comment ends at the first `-->` and `-->` is left as stray text:

    <!-- <Rule Id="SA1201" Action="Info" /> <!-- SA1201: Elements should appear in the correct type-member order --> -->

Right — the description comment stays outside:

    <!-- <Rule Id="SA1201" Action="Info" /> --> <!-- SA1201: Elements should appear in the correct type-member order -->

After editing, confirm the file is still well-formed XML before continuing.

Leave every other entry untouched. Strict mode is not "all rules on" — SA1200,
SA1117, SA1118, the documentation rules and the compiler warning suppressions
stay relaxed in both modes.

#### Strict mode also requires an `.editorconfig` change

`.editorconfig` is reconciled against this ruleset, so re-enabling a rule that
has an editor counterpart puts the two in conflict until both are changed.

Only SA1101 is affected. Flip all four to `true`:

    dotnet_style_qualification_for_event    = true:silent
    dotnet_style_qualification_for_field    = true:silent
    dotnet_style_qualification_for_method   = true:silent
    dotnet_style_qualification_for_property = true:silent

Left at `false`, the IDE offers to strip `this.` while the build errors for its
absence — an unpleasant loop for whoever hits it. The remaining strict rules
(SA1201-SA1204, SA1512, SA1111, SA1009, SA1011) have no editor counterpart or
are already satisfied by the spacing defaults.

Never express a StyleCop severity as `dotnet_diagnostic.SAxxxx.severity` in
`.editorconfig` — that silently overrides this ruleset for that rule. Severities
belong here.

#### Strict mode also enables the banned-API list

`BannedSymbols.txt` at the repository root ships with every entry commented
out. Strict mode uncomments them:

    P:System.DateTime.Now;Use TimeProvider.GetUtcNow()
    P:System.DateTime.UtcNow;Use TimeProvider.GetUtcNow()
    P:System.DateTime.Today;Use TimeProvider.GetUtcNow()
    P:System.DateTimeOffset.Now;Use TimeProvider.GetUtcNow()
    P:System.DateTimeOffset.UtcNow;Use TimeProvider.GetUtcNow()

Each use then fails the build with `RS0030` and the message. Test projects are
exempt by construction — `Directory.Build.props` does not attach the file to
`*.Tests`. This is the enforced form of the *Time* rule in
`csharp-coding-rules.md`; relaxed mode relies on review instead.

Add further entries in the same format (`P:`, `M:`, `T:` prefixes) for anything
else a team wants banned at build time.

**Never leave a blank line in `BannedSymbols.txt`.** The parser reads an empty
line as an empty symbol id; a second blank line is then "listed multiple
times" and fails the build with `RS0031` — in *both* modes, since the file is
always attached. `#` comment lines are tolerated; blank lines are not.

### 4. Wire it into the build

Copying the files alone does nothing. `StyleCop.props` carries the wiring, but
**MSBuild does not auto-import it** — only `Directory.Build.props` and
`Directory.Build.targets` are picked up by name. Import it from a
`Directory.Build.props` at the repository root:

    <Project>
      <Import Project="$(MSBuildThisFileDirectory)StyleCop.props" />
    </Project>

If the repo already has a `Directory.Build.props`, add the `Import` to it rather
than replacing the file.

#### Why `$(MSBuildThisFileDirectory)`

`CodeAnalysisRuleSet` is resolved **relative to the project directory**, not
relative to the file that sets the property. A bare `stylecop.ruleset` written
in a root-level props file resolves to `src/Foo/stylecop.ruleset` for a project
in `src/Foo/`, finds nothing, and applies no rules — with no error. The build
succeeds and the ruleset is silently ignored, which is the worst failure mode
available.

`$(MSBuildThisFileDirectory)` expands to the directory of the file it is written
in, with a trailing slash, so it is correct at any project depth. The same
applies to the `stylecop.json` and `StyleCop.props` paths.

#### Central package management

`StyleCop.props` omits the package `Version` when
`$(ManagePackageVersionsCentrally)` is `true`, because supplying a version in
both places raises NU1008. In a CPM repo, add the version to
`Directory.Packages.props`:

    <PackageVersion Include="StyleCop.Analyzers" Version="..." />

Otherwise the version comes from `$(StyleCopAnalyzersVersion)` in
`StyleCop.props`. Check the current release rather than trusting the default
pinned there.

#### Verify

Build once, then confirm StyleCop diagnostics actually appear. A quick check is
to introduce a deliberate violation of a rule the chosen mode leaves enabled and
confirm the build reports it. If nothing is reported, the ruleset path is the
first thing to suspect.

A convenient probe in relaxed mode is SA1414, which the ruleset sets to `Error`:

    public (int, string) Probe() => (1, "a");   // expect: error SA1414

Known-good baseline: this layout was verified on .NET SDK 10.0.400 with
StyleCop.Analyzers 1.2.0-beta.556, for a project at `src/Foo/`, with central
package management both on and off. In both cases restore succeeded and SA1414
was reported as an error.

## What commenting out actually does

Removing an entry does not force a rule on. It removes the *override*, so the
rule falls back to its default severity from the StyleCop.Analyzers package,
which may then be further modified by `.editorconfig` or MSBuild properties in
the consuming repo.

Practical consequences:

- For a rule at `Action="None"` (SA1101, SA1111, SA1009, SA1011), removing the
  override generally re-enables it.
- For a rule at `Action="Info"` (SA1201-SA1204, SA1512), removing the override
  generally raises it to warning level.
- If the repo has an `.editorconfig` setting a severity for the same rule, that
  is what wins. Check for one before assuming the ruleset is authoritative.

Expect strict mode to produce a substantial number of new diagnostics on an
existing codebase — SA1101 in particular fires on nearly every unqualified
member access. Introduce it on a new project, or be prepared to fix broadly.
