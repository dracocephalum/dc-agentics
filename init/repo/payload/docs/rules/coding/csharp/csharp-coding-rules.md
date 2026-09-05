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
