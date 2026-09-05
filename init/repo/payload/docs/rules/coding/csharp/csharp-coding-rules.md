# C# coding rules

Apply to every C# project in this repository, tests included.

Formatting is enforced by the build — root `.editorconfig`, `stylecop.ruleset`,
warnings as errors — so it is not repeated here. This file covers what the
build cannot check.

## Observability

**Never emit PII, secrets, tokens, or payloads** in logs, metrics, or spans.
No exceptions.

Logging:

- Structured only: `ILogger` message templates with named placeholders. Never
  interpolated or concatenated strings.
- Production minimum level is **Warning**. `Information` is enabled only for
  specific classes or namespaces through configuration overrides — never as the
  default.
- Before adding a log line confirm it helps on-call or operations, is not
  already covered by a metric or span, is off the hot path, and carries no
  sensitive data. If unsure, leave it out.

Metrics and spans:

- No high-cardinality tags. Never `userId`, `sessionId`, `batchId`, `jobId`,
  request ids, or any unbounded value.
- Span attributes are few, stable, and non-PII.

## Design

- **Secure by default.** Least privilege, safe defaults, validate at boundaries.
- **Resilient.** A timeout on every external call. Retries only for idempotent
  operations. Explicit fallbacks.
- **Testable.** Retry, polling, and time-dependent logic take a `TimeProvider`
  and overridable timeouts, so tests never wait on real time.
- **Extensible without speculation.** Extract shared behaviour on the third
  concrete use — not "just in case". Prefer composition and constructor
  injection. Keep abstractions small and domain-shaped.
- Apply a pattern (Strategy, Factory, Decorator, Mediator) only when it buys
  clarity, testability, or extensibility. Simplest solution first.
- **Mediator via a library means ConduitR** (`ConduitR` +
  `ConduitR.DependencyInjection`; `ConduitR.Validation.FluentValidation` when
  validating). MIT-licensed. **Not MediatR**, which is commercially licensed
  from v13. The abstractions match MediatR's by name — `IRequest<T>`,
  `IRequestHandler<,>`, `INotification`, `IPipelineBehavior<,>` — but
  registration is `AddConduit(...)` and optional features are separate
  packages, so treat a migration as a port, not a package swap.
- **Never expose the persistence schema.** Queries return DTOs or projections;
  entities stay behind the boundary.
- **Expected failures are values or well-known exceptions; unexpected ones are
  exceptions.** Validation, not-found, conflict, business-rule rejections: either
  return a domain-specific result record carrying an error code, or throw a
  well-known domain exception that the pipeline translates — in ASP.NET Core, an
  `IExceptionHandler` producing `ProblemDetails`. Pick one style per component
  and keep to it. Everything else throws a specific domain type such as
  `ServerConnectionTimeoutException`, never bare `Exception`.

## Types and APIs

- **Records for DTOs, messages, and events.** `init`, not `set`.
- **Typed IDs and value objects are `readonly record struct`.** Validate in
  the constructor and trust the value everywhere after. **No implicit conversion
  operators** — a `UserId` must never silently accept a `Guid`; convert
  explicitly at the boundary.
- **Accept the narrowest collection abstraction** — `IEnumerable<T>` to iterate,
  `IReadOnlyList<T>` to index. **Never return `List<T>` or `T[]` from a public
  API**; return `IReadOnlyList<T>` or `IReadOnlyCollection<T>`.
- **Stream with `IAsyncEnumerable<T>`** whenever the producer is genuinely
  streaming — unbounded, paged, or I/O-driven. Mark the producer's token
  `[EnumeratorCancellation]` and consume with `.WithCancellation(token)`.
  Bounded results materialize to `IReadOnlyList<T>`; never wrap a small
  in-memory list in `IAsyncEnumerable<T>`.
- **Map explicitly.** Extension methods such as `entity.ToDto()`. No
  reflection-based mappers.
- **Every `async` method takes a `CancellationToken`** and passes it on.
  **Never block on a task** — no `.Result`, `.Wait()`, or
  `.GetAwaiter().GetResult()`. `ConfigureAwait(false)` in `libraries/` only.
- **Never `!` a nullable warning away.** Fix the flow or make the type nullable.

## Time

- **`DateTimeOffset`, never `DateTime`.** No new `DateTime` properties, fields,
  parameters, or return types. Where a `DateTime` arrives — framework APIs,
  legacy code, a database — convert at that boundary and pass on a
  `DateTimeOffset`.
- **Conversion depends on `Kind`, and `Unspecified` is a stop.**
  `Utc` → `new DateTimeOffset(value, TimeSpan.Zero)`. `Local` →
  `new DateTimeOffset(value)`. `Unspecified` → the offset is unknowable:
  **ask the user** which zone the value is in. Never let
  `new DateTimeOffset(unspecified)` run — it silently assumes local time.
- **In production code, "now" is `TimeProvider.GetUtcNow()`.** Never
  `DateTime.Now`, `DateTime.UtcNow`, `DateTimeOffset.Now`, or
  `DateTimeOffset.UtcNow` there — the testability rule already requires the
  `TimeProvider`. Tests may use `DateTimeOffset.UtcNow` for arbitrary
  timestamps in test data; anything the system under test *reads* still goes
  through `FakeTimeProvider`. In strict mode this is enforced at build time
  by `BannedSymbols.txt` (`RS0030`); in relaxed mode by review.

## Entity Framework Core

- **Enums are stored as strings, never numbers.** Configure it once for every
  enum in `OnModelCreating`, so no property can be forgotten and no migration
  silently gets an `int` column:

      foreach (var property in modelBuilder.Model.GetEntityTypes()
          .SelectMany(t => t.GetProperties())
          .Where(p => p.ClrType.IsEnum || (Nullable.GetUnderlyingType(p.ClrType)?.IsEnum ?? false)))
      {
          property.SetProviderClrType(typeof(string));
          if (property.GetMaxLength() is null)
          {
              property.SetMaxLength(64);
          }
      }

  Without a length the column is `nvarchar(max)`. For an enum whose member
  names exceed 64 characters, set the length on that property explicitly —
  `.Property(o => o.Status).HasMaxLength(80)` — before or after the loop; the
  guard means the loop never overwrites an explicit length.
- **Same on the wire.** Register `JsonStringEnumConverter` globally so HTTP
  payloads carry names, not numbers. Put `[EnumDataType(typeof(T))]` on
  **request DTO** enum properties — it rejects undefined values such as `999`
  during model validation. It has no effect on EF; do not put it on entities
  for that purpose.
- **`DateTimeOffset` on PostgreSQL:** Npgsql accepts only offset-zero values
  for `timestamp with time zone`. Normalise with `.ToUniversalTime()` before
  saving.

### Migrations

Every migration runs against a live database while the **previous release is
still serving**. The generator does not know that, so generating is step one
and editing the generated file against these rules is step two.

- **Generate, never hand-write.** `dotnet ef migrations add <Name>` — `dotnet-ef`
  is a local tool in `.config/dotnet-tools.json`, pinned to the same version as
  `Microsoft.EntityFrameworkCore.Design`. A hand-written migration or a
  hand-edited `ModelSnapshot` desynchronises the snapshot, and every later
  migration is generated from the wrong model. If the `DbContext` cannot be
  constructed at design time (it needs configuration or DI), add an
  `IDesignTimeDbContextFactory<T>` with a **placeholder** connection string —
  EF never opens it, and a real one has no business in source:

      public sealed class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
      {
          public AppDbContext CreateDbContext(string[] args) =>
              new(new DbContextOptionsBuilder<AppDbContext>()
                  .UseSqlServer("Server=localhost;Database=design-time;Integrated Security=true")
                  .Options);
      }

- **Backward compatible with the code in production.** Deploy order is
  migrate first, then roll out; during the rollout old and new code share the
  schema. So a migration must never break the previous release: no rename, no
  drop, no narrowing, no new `NOT NULL` column without a value old code will
  supply. Change in two phases across releases — **expand** now (add the new
  thing, keep the old), **contract** later (remove the old, once no running
  code touches it). Renaming a column is the classic outage: the old code is
  still running, and its next query fails.
- **Never drop a column in the change that stops using it.** Leave it; a
  separate migration, a release later, drops it once production has run
  without it. An unused column costs nothing; a dropped one that something
  still read is an outage.
- **New columns on existing tables are nullable.** Old code will not set the
  column, and adding a column with a default value rewrites and locks the
  table on SQL Server Standard and on PostgreSQL before 11 (or with a volatile
  default such as `now()` on any version) — metadata-only on the other tiers
  is not something to rely on across environments. A column that must end up
  required: add it nullable, backfill in batches (below), then a later
  migration adds the constraint — itself a full scan, so on a large table it
  goes through the manual route described under indexes. On a **new** table
  any nullability is fine; no old code knows the table.
- **Changing a column's type or length.** Widening `varchar`/`nvarchar` —
  not to `max`/`text`, not narrowing, not changing the type — is metadata-only
  on SQL Server and PostgreSQL, so a plain `AlterColumn` is acceptable.
  Anything else rewrites the table under a schema lock, and is done as
  expand / copy / swap / contract:

  1. **Expand** — migration 1: `AddColumn` `<name>_new` with the target type,
     nullable; recreate any index the old column has on the new one (online,
     see below).
  2. **Copy** — in batches of 4999, under SQL Server's lock-escalation
     threshold of 5,000 locks, so no batch takes the whole table. Idempotent,
     so it can be rerun:

         WHILE 1 = 1
         BEGIN
             UPDATE TOP (4999) t SET t.[col_new] = CAST(t.[col] AS <target type>)
             FROM [Table] t
             WHERE t.[col] IS NOT NULL AND t.[col_new] IS NULL;
             IF @@ROWCOUNT = 0 BREAK;
         END

     Where it runs is a **confirmation with the user, on the row count**.
     A small table: the loop goes in `migrationBuilder.Sql(...)` in migration
     1 — inside the migration's transaction the batches only avoid
     lock escalation, they do not shorten the transaction, and a table that
     takes minutes to copy hits the command timeout and rolls the whole
     migration back. A large table: comment the `Sql(...)` call out, leave the
     loop in a `/* */` block with the ticket number, and the operator runs it
     by hand — the same hand-over as for indexes below.
  3. **Swap** — migration 2: in the same deployment for a small table, in the
     **next** release for a large one (the copy must have finished). A
     catch-up copy for rows changed since —
     the same `UPDATE` without `TOP`, comparing `col_new` to `CAST(col)` — then
     `RenameColumn` `col` → `col_old` and `col_new` → `col`. Both renames are
     in the one migration, so one transaction: the name is never absent. Views,
     computed columns, and procedures referencing the column by name are
     recreated in the same migration. The entity keeps its property and
     `HasColumnName`; nothing in code changes.
  4. **Contract** — migration 3, a release later: `DropColumn` `col_old`,
     with its indexes.

  A column that is a key or a foreign key is outside this procedure — stop
  and design the change with the user. So is a table hot enough that the
  catch-up in step 3 is itself large; that needs dual writes from code during
  the transition.
- **Indexes on existing tables: online, and ask about the volume first.**
  Generated `CreateIndex` builds offline, holding a schema lock for the
  duration; a changed index is generated as `DropIndex` + `CreateIndex`,
  leaving the table unindexed in between. Before adding or changing an index
  on an existing table, **ask the user for the expected row count and the
  database SKU**, then:
  - Configure it online in the model, so the generated migration is right on
    a small table: SQL Server `.IsCreatedOnline()` → `WITH (ONLINE = ON)`
    (Enterprise and Azure SQL; Standard rejects it); PostgreSQL
    `.IsCreatedConcurrently()` → `CONCURRENTLY`, which cannot run inside a
    transaction — the migration needs `suppressTransaction: true` for that
    step.
  - If the table is large or the tier is low, **comment out** the
    `CreateIndex` / `DropIndex` calls and put the SQL to run in a `/* */`
    block above them, with the ticket number. The migration then applies as
    a no-op and the operator builds the index separately. The snapshot
    already records the index, so a later `migrations add` will not
    regenerate it — the comment is the only record that it is still owed.
  - An index **change** is one statement on SQL Server —
    `CREATE INDEX … WITH (DROP_EXISTING = ON, ONLINE = ON)`, the old index
    serving until the new one is ready. On PostgreSQL, or where online is not
    supported, it is two: create the new index under a new name, then drop
    the old — never drop first.
- **Apply from the pipeline, not from `Program.cs` — unless one instance is
  guaranteed.** `Database.Migrate()` at startup races when several instances
  start together, and breaks the migrate-then-roll-out order the
  compatibility rule depends on. The default is
  `dotnet ef migrations script --idempotent` run as a deployment step before
  the rollout. A service that is **guaranteed to run at most one instance** —
  a single-replica deployment, a global mutex, leader election — may migrate
  at startup; state that guarantee in a comment next to the call, because
  scaling it out later silently removes it.

## Conventions

- File-scoped namespaces. One `using` per line.
- `nameof` for member names, never string literals.
- Pattern matching and `switch` expressions where they read more clearly than
  `if`/`else` chains — not as a reflex.
- XML doc comments on every public API, with `<example>`/`<code>` where a
  usage example clarifies. The build emits `$(AssemblyName).xml` beside each
  non-test assembly, so consumers get IntelliSense from them. Missing comments
  do not fail the build — SA1600 and CS1591 are off — reviewers enforce.

## Testing

For writing and validating unit tests — stack, naming, fakes, in-memory
database — follow [csharp-unit-tests-rules.md](csharp-unit-tests-rules.md).
