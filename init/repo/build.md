# Verify the build files

Stage 2 of [`README.md`](README.md): the payload is at the target root. Check
the StyleCop and build files against the chosen mode, understand the two git
files, and create the folder structure.

## 1. The StyleCop files

Already at the target root after the payload copy: `stylecop.ruleset`
(ships in relaxed mode), `stylecop.json`, `StyleCop.props`, `.editorconfig`.

`.editorconfig` declares `root = true`, so it must land at the **repository
root** — any `.editorconfig` above it is then ignored, which is the intent.

It has been reconciled with `stylecop.ruleset`: the ruleset governs the build,
`.editorconfig` governs the editor, and where they overlap the ruleset wins and
`.editorconfig` is the file that was changed to match. Do not substitute a
stock `dotnet new editorconfig` here — its `insert_final_newline = false`
contradicts `stylecop.json` and produces SA1518 on every file.

For **strict** mode, apply the rule edits in
[`stylecop.md`](stylecop.md) — note the XML
comment-nesting trap documented there; the naive edit produces invalid XML.

Strict mode requires a matching `.editorconfig` change: flip the four
`dotnet_style_qualification_for_*` settings to `true`, because strict re-enables
SA1101. Skipping this leaves the IDE offering to remove `this.` while the build
errors for its absence. The STRICT MODE block at the end of `.editorconfig`
spells this out.

## 2. Generate the build files

Already at the target root after the payload copy: `Directory.Build.props`,
`Directory.Build.targets`, `Directory.Packages.props`, `Tests.props`,
`BannedSymbols.txt`, `nuget.config`. The props files reference each other by
`$(MSBuildThisFileDirectory)` and must stay together.

`Directory.Build.targets` stamps every assembly's informational version with
the short commit hash — `1.2.3+abcdef12`, `-dirty` when the tree is not clean —
via `git describe` ahead of the SDK's own source-control step. Verified
fail-safe: no repository or no commits build clean as `1.2.3`; no `git` on
`PATH` leaves the SDK's full hash. Read it back from
`AssemblyInformationalVersionAttribute`.

`nuget.config` clears inherited package sources and maps every package to
nuget.org. A private feed is added there, with its own package pattern — see
the comment in the file. `Directory.Build.props` turns on lock files: after
the first restore every project has a `packages.lock.json`, and **those are
committed** — they are what makes restores reproducible and what lets CI see
transitive packages.

For **strict** mode, also uncomment the entries in `BannedSymbols.txt` — see
[`stylecop.md`](stylecop.md).

If central package management is **off**, omit `Directory.Packages.props` and
set the analyzer version via `$(StyleCopAnalyzersVersion)` in `StyleCop.props`
instead.

If it is **on**, `Directory.Packages.props` must declare
`StyleCop.Analyzers` — `StyleCop.props` deliberately omits the version under CPM
and restore fails without it.

## 3. .gitignore and .gitattributes

Both arrive with the payload copy. They are the SDK templates plus our
additions, each carrying a baseline marker — see the drift check in [`copy.md`](copy.md).

`.gitignore` already includes the local-config entries the official template
omits (`*.local.json`, `.env`, and similar). Ignore entries must exist **before**
the files they cover — ignoring an already-tracked file has no effect. See
[`payload/docs/rules/security-reminders.md`](payload/docs/rules/security-reminders.md).

### Why .gitattributes matters here

Its first line is `* text=auto`, which normalizes line endings to LF **inside
the repository** while checking out native endings on each platform. Without it,
a repo touched from both Windows and Linux accumulates whole-file diffs where
nothing changed but CRLF/LF.

This is cheapest at initialization, on an empty repo. Adding `text=auto` to a
repository that already has tracked files does nothing to them until:

    git add --renormalize .

which rewrites every affected file in one large, noisy commit. Doing it now
avoids that entirely.

The template also sets `*.cs text diff=csharp` (better diff hunk headers) and
`*.sln text eol=crlf` (Visual Studio expects CRLF there).

## 4. Create the folder structure

Follow [`layout.md`](layout.md) for the chosen mode. It covers the standalone
and monorepo trees, the kebab-case-directory / PascalCase-project naming rule,
per-folder conventions, and the two SDK-template defects that break the first
build (CPM version conflicts, and placeholder files that violate StyleCop).

Root configuration files exist **once**, at the repository root, in both modes.
Never copy them into component folders.

## Known failure modes

| Symptom | Cause |
|---|---|
| Build green, no diagnostics ever | ruleset path wrong, or `StyleCop.props` never imported |
| `NU1008` | package `Version` supplied while CPM is active |
| Package version not found on restore | `StyleCop.Analyzers` missing from `Directory.Packages.props` |
| Settings ignored | `stylecop.json` not registered as an `AdditionalFiles` item |
| Subtree silently unstyled | a nested `Directory.Build.props` replaced the root one |
| Ruleset fails to load | nested XML comments from a bad strict-mode edit |
