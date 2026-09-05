# TODO

Open items for the toolkit itself. Not payload. Each entry says what would
close it, so it can be picked up cold.

## Decisions pending

- [ ] **Projects board automation.** Merging #2 closed issue #1 but left its
      card *In Progress*; the agent moved it by hand. Close by one of: enable
      the board's built-in "item closed → Done" workflow (web UI, once), or
      have `/source-control` move the card after merge (needs the optional
      `project` scope). Record the choice in `change-tracking/github.md`.

## Toolkit

- [ ] **Global `pre-push` hook refusing direct pushes to the default branch** —
      the fallback protection for a private repository on GitHub Free, where
      the shipped ruleset is refused. Shape decided: sits beside the gitleaks
      hook under `core.hooksPath`, allows the push when the remote has no
      default branch yet (the first publish), refuses afterwards. Close by:
      the script in `init/local/gitleaks.md` (rename that guide to cover both
      hooks), a proof step like the fake-key one, and a line in the
      source-control host file pointing at it.
- [ ] **`ModelConventions.cs` as a real file.** The verified check lives as a
      snippet in `csharp-ef-core-rules.md`; the authoring rule prefers a real
      file. Close by: `docs/templates/ModelConventions.cs` in the payload plus
      the test, and the rules file pointing at them. Ship `dotnet-ef` in
      `.config/dotnet-tools.json` at the same time, pinned to the EF version
      in `Directory.Packages.props`.
- [ ] **`python-new-project.md`** when the first Python component arrives —
      shape already decided in `init/local/python.md`.
- [ ] **`dotnet-outdated-tool`** as a further entry in
      `init/repo/payload/.config/dotnet-tools.json` (4.8.1 at time of writing), so
      "keep the stack current" in `layout.md` becomes one command. Verify it
      respects central package management before shipping.
- [ ] **Meziantou.Analyzer** (MIT, 3.0.204) — overlaps the CancellationToken
      and ConfigureAwait rules usefully. Needs a build test on the template
      shells first; unlike `AnalysisMode`, it is not SDK-built-in and will have
      opinions of its own.
- [ ] **Update mode for an initialized repository.** The target's
      `.dc-agentics.yaml` records the toolkit commit it came from. Close by: a
      procedure that diffs `init/repo/payload` between that commit and `HEAD`,
      maps each path to the target, and applies the change — baseline markers
      decide overwrite versus three-way merge, `docs/rules/**` and the shims
      overwrite, `AGENTS.md`, `README.md`, and `TODO.md` merge by hand — then
      rewrites `toolkit.commit`.

## CI — deferred as a group

Nothing under `build/` exists yet. When CI is picked up, these are the pieces
already decided on the local side that need their server-side half:

- [ ] **Secret scanning in CI** — `gitleaks/gitleaks-action` on push and PR
      with `fetch-depth: 0`. Free for personal accounts; an organization
      account needs the free licence key from gitleaks.io. Evaluate TruffleHog
      (live-credential verification) as the CI-stage scanner alongside it.
- [ ] **Licence gate on PRs** — `actions/dependency-review-action` with
      `allow-licenses` from `allowed-licenses.json`. Private repos need GitHub
      Advanced Security; NuGet transitives need lock files
      (`RestorePackagesWithLockFile`). The `nuget-license` check should also
      run as a plain CI step, since it sees the whole graph.
- [ ] **`THIRD-PARTY-NOTICES.txt` generation** for packable `libraries/` —
      `nuget-license` can emit the data; wire it into pack.
- [ ] **Build only affected components** in a monorepo — the reason there is
      no root solution.
- [ ] **Cross-platform verification via a runner matrix.** A workflow on
      `ubuntu-latest` and `macos-latest` that runs the local setup (minus the
      interactive steps) and the full repo-init procedure end to end is the
      Linux/macOS test environment we do not otherwise have — free on a public
      repository. Until it exists, `init/local/platforms.md` is best effort.
      FreeBSD has no hosted runner and no official .NET 10; it stays
      "user-prepared prerequisites" (community source builds such as
      sec/dotnet-core-freebsd-source-build) unless a VM is set up.
