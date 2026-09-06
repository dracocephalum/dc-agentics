# Adding a C# project

Applies when adding a project — library, service, job, tool, or test project —
to a repository that has already been initialized. Layout, naming, and the
build configuration it inherits are defined in the repository's root
`AGENTS.md`; this file is the procedure.

Never guess the namespace prefix. Take it from `AGENTS.md`.

## 0. Where it goes

| Repository | Adding | Location | Solution |
|---|---|---|---|
| standalone | a project | `src/<Prefix>.<Name>/` | the root `.slnx` |
| monorepo | a project to an existing component | `<component>/src/<Prefix>.<Name>/` | that component's `.slnx` |
| monorepo | a new component | `<category>/<kebab-name>/` — create `src/` and `test/` there first | its own, new — see step 5 |

Categories are `services/`, `libraries/`, `jobs/`, `tools/`. Never create a
solution at a monorepo root, and never add a `Directory.Build.props`,
`Directory.Build.targets`, or `Directory.Packages.props` below the root — see `AGENTS.md` for why.

**Creating a category folder for the first time?** Give it its map:
copy `docs/templates/category-README.md` to `<category>/README.md`, fill the
placeholders, and remove the example row. Every component added afterwards
appends a row there (step 7).

## 1. Create it

    dotnet new <template> -o src/<Prefix>.<Name> -n <Prefix>.<Name>

| Kind | Template | Then |
|---|---|---|
| library | `classlib` | delete `Class1.cs` |
| service | `webapi` | replace `Program.cs` with the shell below; delete the `.http` file |
| job | `worker` | replace `Worker.cs` with the shell below |
| tool | `console` | nothing — the template is clean |

**Every template except `console` emits sample code that fails the ruleset**
under warnings-as-errors. Do not patch the samples line by line — replace them
with a minimal shell, build, and only then write real code. A build failure
straight after `dotnet new` is the template's, not yours.

`webapi` shell (`Program.cs`):

    var builder = WebApplication.CreateBuilder(args);
    builder.Services.AddOpenApi();

    var app = builder.Build();
    app.MapOpenApi();
    app.MapGet("/health", () => Results.Ok());
    app.Run();

`worker` shell (`Worker.cs`):

    namespace <Prefix>.<Name>;

    public sealed class Worker : BackgroundService
    {
        protected override Task ExecuteAsync(CancellationToken stoppingToken) => Task.CompletedTask;
    }

The template's `Worker.cs` also uses `Task.Delay` and `DateTimeOffset.Now`,
which the coding rules forbid in time-dependent code. The shell sidesteps that;
real work should take a `TimeProvider`.

## 2. Central package management

Templates write `<PackageReference Include="X" Version="..." />`. Central
package management rejects the `Version` attribute with **NU1008**.

- Strip every `Version="..."` attribute from the new `.csproj`.
- For each package, confirm a `<PackageVersion>` exists in the root
  `Directory.Packages.props`. `Microsoft.AspNetCore.OpenApi` and
  `Microsoft.Extensions.Hosting` are pre-registered. If one is missing, add it
  with the version the template chose — that version is known to work with the
  current SDK.

## 3. Project settings

The `.csproj` should end up holding `TargetFramework` and little else;
everything shared is inherited from the root.

| Category | Add |
|---|---|
| `libraries/` | nothing — packable by default |
| `services/`, `jobs/`, `tools/` | `<IsPackable>false</IsPackable>` |

The namespace is derived automatically: a trailing `.Core` is dropped
(`<Prefix>.Core` → namespace `<Prefix>`).

## 4. Test project

    dotnet new xunit -o test/<Prefix>.<Name>.Tests -n <Prefix>.<Name>.Tests

Then:

- **Delete every `<PackageReference>` the template wrote.** `Tests.props`
  supplies the entire stack to any `*.Tests` project; keeping them is both
  redundant and, under CPM, invalid. Delete the template's
  `<Using Include="Xunit" />` alongside them — `Tests.props` supplies that as
  well, so `[Fact]` and `[Theory]` still resolve with no `using` in the file.
- Delete `UnitTest1.cs` — it fails SA1505/SA1508.
- Add `<ProjectReference Include="../../src/<Prefix>.<Name>/<Prefix>.<Name>.csproj" />`.
- Write the first real test now, following
  [`csharp-unit-tests-rules.md`](csharp-unit-tests-rules.md). An empty test
  project makes the count check in step 6 meaningless.

A finished test `.csproj` contains a `TargetFramework` and a `ProjectReference`
and nothing else.

## 5. The solution

A solution is named after its **main project**, not its folder, so a component
has no solution until its first project exists. When there is none — a new
component, or a standalone repository being initialized — create it in the
component root (the repository root, when standalone):

    dotnet new sln -n <Prefix>.<Name> -f slnx

`slnx` is already the default format on SDK 10. Pass `-f` regardless, so a
change of default can never quietly produce a `.sln`.

Then register both projects, in the new solution or the component's existing
one:

    dotnet sln <solution>.slnx add src/<Prefix>.<Name>/<Prefix>.<Name>.csproj
    dotnet sln <solution>.slnx add test/<Prefix>.<Name>.Tests/<Prefix>.<Name>.Tests.csproj

## 6. Verify — none of these are optional

    dotnet build <solution>.slnx
    dotnet test  <solution>.slnx

- Build is green with **zero warnings** (they are errors).
- Test count equals the tests you wrote. Zero tests and a green exit means a
  misconfigured runner, not success.
- `bin/<config>/<tfm>/<Prefix>.<Name>.xml` exists beside the non-test assembly.

## 7. README and the category map

Every component has a `README.md` — the page someone reads before touching it.
Copy `docs/templates/component-README.md` into the component folder as
`README.md`, fill every double-brace placeholder (name, purpose, category,
kind, prefix, project name), and delete the template comment. Say how to run
it beyond build and test, and what configuration it needs; "none" is a valid
answer, silence is not.

In a monorepo, then **append one row to `<category>/README.md`**: the
component's kebab-case name linked to its `README.md`, a one-line purpose, and
a status (`active` for a new component). Match the columns already there.

That table is how anyone — person or agent — learns what exists without
listing directories. A component missing from it is invisible.

In a standalone repository the root `README.md` *is* the component README;
update it instead.

## Known failures

| Symptom | Cause |
|---|---|
| `NU1008` at restore | a `Version` attribute survived in the `.csproj` |
| package not found at restore | missing `<PackageVersion>` in `Directory.Packages.props` |
| `SA1025`, `SA1110`, `SA1400`, `SA1413`, `SA1649` in `Program.cs` | `webapi` sample code — replace with the shell |
| `SA1513` or `SA1508` in `Worker.cs` | `worker` sample code — replace with the shell |
| `SA1505`, `SA1508` in `UnitTest1.cs` | delete the file |
| `CA1707` on a test method name | the project is not named `*.Tests`, so `Tests.props` (which suppresses it) was never applied |
| `NU1100`/`NU1101` package not found, on a private package | `nuget.config` source mapping has no pattern routing it to the private feed |
| zero tests, green exit | wrong runner version, or no tests written yet |
| `CS0246` on `Fact`, `Theory` or `InlineData` | the project is not named `*.Tests`, so `Tests.props` — which supplies the `Xunit` global using — was never applied |
