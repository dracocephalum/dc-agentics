# Security, verification, and the closing summary

Stage 5 of [`initialize.md`](initialize.md), the last: nothing is reported as done
before the security pass and a build that proves the analyzers are wired,
and the last message is the summary of every value the repository carries.

## 1. Security pass

Walk [`security-reminders.md`](payload/agentics/rules/security-reminders.md). It
ships with the repository as `agentics/rules/security-reminders.md`, so the review
process holds later changes to the same standard. At minimum, before
any first push, check the commit identity:

    git var GIT_AUTHOR_IDENT

An unset identity does not stop a commit; it is written into history as a
derived value instead — [`../machine/README.md`](../machine/README.md), *Git*.

## 2. Verify

Never report success on an unbuilt repository.

    dotnet format analyzers <solution>.slnx
    dotnet build

The format pass runs once here, over everything the procedure just created.
It costs about as much as a build — measured, and `--include` does not reduce
it — which is why the shipped `AGENTS.md` makes it a repair step and a
pre-commit step rather than a prefix to every build. Here it is also the first
proof that the fixable rules and the fixer agree.

Then confirm the analyzers are actually wired, by introducing a deliberate
violation of a rule the chosen mode leaves enabled. Add it as its own file under
the new project's `src` folder:

    namespace <Prefix>.<Name>;

    /// <summary>Temporary analyzer probe.</summary>
    public static class Probe
    {
        /// <summary>Probes.</summary>
        /// <returns>A tuple.</returns>
        public static (int, string) Run() => (1, "a");
    }

Expect **exactly two `SA1414`**, and nothing else. Every line of that shape is
load-bearing, and each omission adds an error that makes a passing probe read
as a broken build:

| Omit | And you also get |
|---|---|
| the `namespace` line | `CA1050`, declare types in namespaces |
| the blank line after it | `SA1514`, documentation header should be preceded by a blank line |
| `static` on the class | `CA1822`, member does not access instance state |
| either `///` comment | nothing today — documentation rules are off — but `SA1600` the moment someone raises them |

MSBuild prints each diagnostic twice — once as it builds, once in the closing
summary — so count distinct source positions, not output lines. Two `SA1414`
is four lines of output.

A green build alone proves nothing, because a wrong ruleset path is silent —
[`stylecop.md`](stylecop.md), *Why `$(MSBuildThisFileDirectory)`*. The probe
must actually fail. Delete the file once confirmed.

Finally, the licence check over the whole transitive graph:

    dotnet nuget-license -i <solution>.slnx -t -a allowed-licenses.json -override license-overrides.json

Exit code 0 is the pass. A non-zero exit lists the offending packages; a `Url`
in the licence column means an old package with no SPDX metadata — resolve it
per [`payload/agentics/rules/dependencies.md`](payload/agentics/rules/dependencies.md), never by widening
the allow-list.

Last, lint the markdown the procedure has just written. The command and the
checklist are in
[`payload/agentics/rules/coding/markdown/markdown-review.md`](payload/agentics/rules/coding/markdown/markdown-review.md);
read its `Summary:` line rather than the exit code. `AGENTS.md` and `README.md`
are the freshly written prose, so a long line or a mangled table will be there —
the shipped rules documents already lint clean.

**The recurring form of these checks is
[`payload/agentics/rules/scrub.md`](payload/agentics/rules/scrub.md)**, which lands in
the target as `agentics/rules/scrub.md` and backs `/scrub`. This stage runs them
once, at initialization, alongside the build and licence checks that only make
sense here. Anything added to one that belongs in both goes in the scrub file,
so the two cannot drift apart.

## 3. Closing summary

The last message of the procedure is a table of every value the repository
now carries — asked or defaulted — and where it lives, so nothing applied
silently stays silent:

| Setting | Value | Source | Change it in |
|---|---|---|---|
| Layout | `monorepo` | asked | restructure; `AGENTS.md`, `README.md` |
| Namespace prefix | `Contoso` | asked | project names; recorded in `.agentics.yaml` |
| First project | `Contoso.Widgets`, library | derived | rename now; it is one day old |
| Solution | `Contoso.Widgets.slnx` | follows the project | rename with the project |
| StyleCop mode | `relaxed` | default | `stylecop.ruleset` + [`stylecop.md`](stylecop.md); `.agentics.yaml` |
| Central package management | on | default | `Directory.Packages.props` |
| Publish-safe | `true` | default | `.agentics.yaml`; the rule is `agentics/rules/security-reminders.md` |
| Source-control mode | `local` | default | `.agentics.yaml` |
| Change tracking | GitHub Issues | asked | `.agentics.yaml` |
| Licence | `none` | default | [`settings.md`](settings.md); `TODO.md` holds the decision |
| Merge settings, ruleset | applied / refused / no remote | — | `/source-control setup`; `TODO.md` |
| Serena project | written / skipped | — | [`documents.md`](documents.md); `TODO.md` |
| First commit | not made — the payload is uncommitted | — | yours; the repository was `git init`-ed if it was not one already |

Below the table, the open entries of `TODO.md` verbatim. A user who reads only
this message knows what was decided for them and what is still theirs to
decide.
