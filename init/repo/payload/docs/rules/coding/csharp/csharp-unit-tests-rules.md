# C# unit tests

Applies to C# test projects only. The [coding rules](csharp-coding-rules.md)
apply to test code as well; this file adds only what is specific to tests.

## Where tests live

Layout, naming, and project wiring are defined in the repository's root
the repository's root `AGENTS.md` — see *Repository layout*, *Conventions*, and
*Building and testing*. The short version:

- `test/<Project>.Tests/` mirrors `src/<Project>/`. The namespace drops a
  trailing `.Core`: `Contoso.Core.Tests` → `Contoso.Tests`.
- Every `*.Tests` project inherits the full test stack from `Tests.props`. A
  test `.csproj` holds a `TargetFramework` and a `ProjectReference` and
  **nothing else** — add no package references.

## Stack

| Concern | Use |
|---|---|
| Framework | xUnit — `[Fact]`, `[Theory]` |
| Theory data | `[InlineData]`, `[MemberData]`, `[CombinatorialData]` |
| Assertions | Shouldly — `ShouldBe`, `ShouldNotBeNull`, `Should.Throw<T>` |
| Structural equality | DeepEqual — `ShouldDeepEqual` for mapping and DTO tests |
| Fakes | FakeItEasy, **strict** — `A.Fake<T>(o => o.Strict())` |
| Test data | AutoFixture |
| Time | `FakeTimeProvider` — never real clocks, `Thread.Sleep`, or `Task.Delay` |
| ASP.NET Core | `WebApplicationFactory<TEntryPoint>` |
| EF Core | in-memory provider, one database per test — see Rules |

## Workflow

1. **Scope.** Take the target from the request or the open file. Given a
   specific class, file, or scenario, cover only that. Otherwise cover the
   unit's public behaviour plus its important edge and failure cases.
2. **Write.** One test per behaviour. Arrange with the least setup that states
   the scenario. Act once. Assert on outcomes and on required dependency calls
   — `A.CallTo(...).MustHaveHappenedOnceExactly()`.
3. **Check it can fail.** Break the implementation, confirm the test fails for
   the right reason, restore.
4. **Run the suite.** All green, expected test count, no flakiness.
5. **Report gaps.** State which cases are not covered and why — external
   dependency, untestable design — rather than leaving them silent.

## Rules

- **Strict fakes.** Configure only the calls you expect; any other call fails
  the test. That is what turns a fake into a specification.
- **`sut`** names the system under test, whether field or local.
- **`// Arrange`, `// Act`, `// Assert`** in that order. `// Act & Assert` when
  the two are a single expression, as with `Should.Throw`.
- **Naming** — one of these, matching whatever the class already uses:
  - `Method_WhenCondition_ShouldResult` —
    `Handle_WhenCommandValid_ShouldReturnUpdatedName`
  - `GivenCondition_WhenAction_ShouldResult` —
    `GivenEmptyConnectionString_WhenValidate_ShouldFail`
- **`[Theory]`** when several inputs exercise one behaviour; `[Fact]` otherwise.
- **Assert only what you set.** Never assert on an AutoFixture-generated value
  you did not fix with `.With(...)`. The exception is DeepEqual, when the test
  is about transforming the whole object.
- **Independent and deterministic.** No shared mutable state, no order
  dependence, no real time, I/O, network, or environment.
- **In-memory EF Core** is acceptable for query and read-model handlers where
  faking `DbSet`/`DbContext` is impractical. One database per test:
  `UseInMemoryDatabase(Guid.NewGuid().ToString())`. Seed with `SaveChanges()`,
  not `SaveChangesAsync()`, from a synchronous constructor.
- **Public behaviour only.** Do not test private methods.
- **No duplicates.** A second test for the same behaviour is maintenance
  without coverage.
- **No PII or high-cardinality values** in test names, data, or log output.

## Running

    dotnet test path/to/Project.Tests.csproj
    dotnet test path/to/Project.Tests.csproj --filter "FullyQualifiedName~ClassName"

Confirm the reported count matches the tests you expect — a misconfigured runner
reports zero tests and exits green.
