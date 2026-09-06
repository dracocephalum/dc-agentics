# Security, verification, and the closing summary

Stage 5 of [`README.md`](README.md), the last: nothing is reported as done
before the security pass and a build that proves the analyzers are wired,
and the last message is the summary of every value the repository carries.

## 1. Security pass

Walk [`security-reminders.md`](payload/docs/rules/security-reminders.md). It
ships with the repository as `docs/rules/security-reminders.md`, so the review
process holds later changes to the same standard. At minimum, before
any first push, check the commit identity:

    git var GIT_AUTHOR_IDENT

Git does not refuse to commit when identity is unset — it silently derives
`<username>@<hostname>` and writes it into history permanently.

## 2. Verify

Never report success on an unbuilt repository.

    dotnet build

Then confirm the analyzers are actually wired, by introducing a deliberate
violation of a rule the chosen mode leaves enabled. Add it as its own file under
the new project's `src` folder:

    /// <summary>Temporary analyzer probe.</summary>
    public static class Probe
    {
        /// <summary>Probes.</summary>
        /// <returns>A tuple.</returns>
        public static (int, string) Run() => (1, "a");
    }

Expect **exactly two `SA1414`**, and nothing else. The shape matters: an
instance method raises `CA1822` as well, and an undocumented type or member
raises `SA1600` in strict mode — extra errors that make a passing probe read
as a broken build.

A wrong `CodeAnalysisRuleSet` path produces **no error at all** — the build
succeeds and every rule is silently ignored. A green build alone proves nothing;
the probe must actually fail. Delete the file once confirmed.

Finally, the licence check over the whole transitive graph:

    dotnet nuget-license -i <solution>.slnx -t -a allowed-licenses.json -override license-overrides.json

Exit code 0 is the pass. A non-zero exit lists the offending packages; a `Url`
in the licence column means an old package with no SPDX metadata — resolve it
per [`payload/docs/rules/dependencies.md`](payload/docs/rules/dependencies.md), never by widening
the allow-list.

Last, lint the markdown the procedure has just written. The command and the
checklist are in
[`payload/docs/rules/coding/markdown/markdown-review.md`](payload/docs/rules/coding/markdown/markdown-review.md);
read its `Summary:` line rather than the exit code. `AGENTS.md` and `README.md`
are the freshly written prose, so a long line or a mangled table will be there —
the shipped rules documents already lint clean.

## 3. Closing summary

The last message of the procedure is a table of every value the repository
now carries — asked or defaulted — and where it lives, so nothing applied
silently stays silent:

| Setting | Value | Source | Change it in |
|---|---|---|---|
| Layout | `monorepo` | asked | restructure; `AGENTS.md`, `README.md` |
| Namespace prefix | `Contoso` | asked | project names; recorded in `.dc-agentics.yaml` |
| First project | `Contoso.Widgets`, library | derived | rename now; it is one day old |
| Solution | `Contoso.Widgets.slnx` | follows the project | rename with the project |
| StyleCop mode | `relaxed` | default | `stylecop.ruleset` + [`stylecop.md`](stylecop.md); `.dc-agentics.yaml` |
| Central package management | on | default | `Directory.Packages.props` |
| Source-control mode | `local` | default | `.dc-agentics.yaml` |
| Change tracking | GitHub Issues | asked | `.dc-agentics.yaml` |
| Licence | `none` | default | [`settings.md`](settings.md); `TODO.md` holds the decision |
| Merge settings, ruleset | applied / refused / no remote | — | `/source-control setup`; `TODO.md` |
| Serena project | written / skipped | — | [`documents.md`](documents.md); `TODO.md` |
| First commit | not made — the payload is uncommitted | — | yours; the repository was `git init`-ed if it was not one already |

Below the table, the open entries of `TODO.md` verbatim. A user who reads only
this message knows what was decided for them and what is still theirs to
decide.
