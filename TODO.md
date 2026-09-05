# TODO

Open items for the toolkit itself. Not payload. Each entry says what would
close it, so it can be picked up cold.

- [ ] **Validate the `/plan` model pin persists past the first turn.**
      `~/.claude/commands/plan.md` sets `model: fable` and enters plan mode;
      unverified whether the pin survives into the second turn while plan mode
      continues. Close by: run `/plan <something>`, send a follow-up message,
      check the model indicator. If it reverts, document `/model fable` as the
      prerequisite and reduce `/plan` to the enter-plan-mode half. Low priority
      while Fable is the session default.
- [ ] **Delete `dracocephalum/signing-test`.** Disposable private repo created
      only to prove commit verification on GitHub's side. Web UI, or
      `gh auth refresh -s delete_repo` then `gh repo delete`.
- [ ] **`python-new-project.md`** when the first Python component arrives —
      shape already decided in `init/local/python.md`.
- [ ] **`dotnet-outdated-tool`** as a second entry in
      `init/repo/payload/.config/dotnet-tools.json` (4.8.1 at time of writing), so
      "keep the stack current" in `layout.md` becomes one command. Verify it
      respects central package management before shipping.
- [ ] **Meziantou.Analyzer** (MIT, 3.0.204) — overlaps the CancellationToken
      and ConfigureAwait rules usefully. Needs a build test on the template
      shells first; unlike `AnalysisMode`, it is not SDK-built-in and will have
      opinions of its own.
- [ ] **Update mode for an initialized repository.** The generated README
      records the toolkit commit it came from. Close by: a procedure that diffs
      `init/repo/payload` between that commit and `HEAD`, maps each path to the
      target, and applies the change — baseline markers decide overwrite versus
      three-way merge, `docs/rules/**` and the shims overwrite, `AGENTS.md` and
      `README.md` merge by hand — then rewrites the provenance line.

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
