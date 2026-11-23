# TODO

Open items for the toolkit itself. Not payload. Each entry says what would
close it, so it can be picked up cold.

Ideas that are **not** committed work — no settled shape, and possibly not
worth doing — go in [`PLAN.md`](PLAN.md) instead, and graduate to this file
when they have a closing condition.

## Toolkit

- [ ] **Global `pre-push` hook refusing direct pushes to the default branch** —
      the fallback protection for a private repository on GitHub Free, where
      the shipped ruleset is refused. Shape decided: sits beside the gitleaks
      hook under `core.hooksPath`, allows the push when the remote has no
      default branch yet (the first publish), refuses afterwards. Close by:
      the script in `machine/gitleaks.md` (rename that guide to cover both
      hooks), a proof step like the fake-key one, and a line in the
      source-control host file pointing at it.
- [ ] **`ModelConventions.cs` as a real file.** The verified check lives as a
      snippet in `csharp-ef-core-rules.md`; the authoring rule prefers a real
      file. Close by: `agentics/templates/ModelConventions.cs` in the payload plus
      the test, and the rules file pointing at them. Ship `dotnet-ef` in
      `.config/dotnet-tools.json` at the same time, pinned to the EF version
      in `Directory.Packages.props`.
- [ ] **`python-new-project.md`** when the first Python component arrives —
      shape already decided in `machine/python.md`.
- [ ] **`dotnet-outdated-tool`** as a further entry in
      `repo/payload/agentics/templates/dotnet/root/.config/dotnet-tools.json` (4.8.1 at time of writing), so
      "keep the stack current" in `agentics/rules/layout/dotnet.md` becomes one command. Verify it
      respects central package management before shipping.
- [ ] **Meziantou.Analyzer** (MIT, 3.0.204) — overlaps the CancellationToken
      and ConfigureAwait rules usefully. Needs a build test on the template
      shells first; unlike `AnalysisMode`, it is not SDK-built-in and will have
      opinions of its own.
- [ ] **Procedure branches still untested.** Every branch listed here before
      2026-09-09 has now been exercised at least once: every version-check
      outcome, a deleted payload file, drift firing, the ask branch on the
      ruleset and on a non-ruleset config file, a dropped settings key, a
      directory rename, a new payload file, new settings keys,
      format-as-repair, MIT and `none` licences, Serena absent, `webapi`,
      `worker` and a second category through `/new`, standalone→monorepo, and
      both convergence proofs; the sync script against a target with local
      rows, an exclusion, and a second run that changes nothing. What has no
      test yet: a component removed from a category map; the sync on a
      platform other than Windows, which needs the runner matrix in the CI
      group below. Close by: run each on a throwaway repository and record the
      result here or as a ticket.

## CI — deferred as a group

Two pipelines exist, as templates a repository adopts, with the steps they
share: `dev.yml`, `ci.yml` and `build.yml` under
`repo/payload/agentics/templates/`, described in
`repo/payload/agentics/rules/delivery/`. `dev` builds and tests a change
request and reaches nothing; `ci` builds, tests, packs, and publishes `ci`
packages to the host's registry. These are the pieces they do not have yet,
each decided on the local side and needing its server-side half:

- [ ] **One thing of the pipelines as three files has not been seen.**
      Seen in two repositories: a pull request with the one check of
      `dev` and no deploy, a merge that deploys, the shared steps called
      with permissions and outputs passed across, and another
      repository's packages restored through them. Not seen: a merge of a
      change to a tool or a test alone starting no `ci` run. Close by:
      that, and the note in `github.md` reworded.
- [ ] **A monorepo's `ci` list has to take its tests away by hand.** The
      template leaves tests off the list for a standalone repository,
      where they have a folder of their own. In a monorepo they lie under
      each component, inside a category that is on the list, and the one
      repository that has the pipeline added an entry of its own for it,
      `'!libraries/*/test/**'`. Close by: the template's comment and
      `github.md` saying so, and the scrub's check 11 knowing the entry.
- [ ] **A package first published from a public repository has not been
      seen.** The host documents that it is private, and `github.md`,
      *When a package is first published*, has it checked the day it
      happens. Close by: that day, with what was seen written there.
- [ ] **The delivery rule is verified on one repository.** One personal
      account, one repository, private and then public, one solution,
      two packages, a restore of them on Windows through the two ignored
      files, and a second repository's workflow restoring them on Linux.
      Not yet seen: the removal of an old `ci` version, an organization's
      repository, a repository with several solutions or with no package,
      and the ignored files on macOS or in an editor's restore. Close by:
      each seen once, and the *Not yet verified* notes in
      `repo/payload/agentics/rules/delivery/github.md` removed as they are.
- [ ] **The exception for a package with no release is tried, and no
      procedure makes its offer.** `delivery.md`, *A committed reference
      names a release*, has its two places and when each is offered, and
      both are verified in a second repository: a committed `-ci.`
      reference restored on a developer's machine, and that repository's
      pipeline restoring it, as `github.md`, *Another repository's
      pipeline*, has it. That pipeline was a trial written by hand, which
      builds and tests and publishes nothing. Its three additions are in
      the template commented out; the template's own wording of the
      second, which takes the pattern from a variable, was run on a
      machine and not on the host. Close by: that seen in a run, then the
      offer worded where it is made: for the first place where a package
      is added, `dependencies.md`, and for the second in the steps that
      add the pipeline.
- [ ] **Nothing warns that a committed `-ci.` reference is about to
      expire.** The registry keeps the newest few, and a repository that
      names an older one stops restoring. Close by: a scrub check that
      compares the committed version with what the registry still has, or
      a longer keep for a version something names.
- [ ] **A release is not written.** `PLAN.md`, *Release versioning*, has
      what is decided about it, and `delivery.md` has its place: the
      third pipeline, `release`, which calls the same shared steps. Close
      by: `release.yml`, the checks before it publishes, and the rule's
      section on nuget.org.
- [ ] **A sync does not say that a template changed.** A repository that
      copied a pipeline or `Packaging.props` out of `agentics/templates/`
      keeps its copy when the template moves on. Close by: the sync's plan
      listing the templates that changed since the recorded commit, beside
      the payload files it already lists.
- [ ] **Adopting it has no shim, and the offer at initialization has not
      been tried.** Initialization asks, and an opt-out leaves an entry in
      the target's `TODO.md`; the adoption itself is a procedure in the
      rule, followed by hand, and so far it was followed once, in a
      repository that existed before the rule did. Close by: an
      initialization trial that takes each answer, and deciding whether
      `/new` or a shim of its own should run the adoption.

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
- [ ] **Lock-file drift check** — restore the solution with `--locked-mode`,
      so a `packages.lock.json` that disagrees with the root
      `Directory.Packages.props` fails as `NU1004`, naming the package and both
      version ranges. Verified: locks are per project, and a partial update —
      one project restored rather than the solution, the rest left on the old
      resolution — is reported for exactly the stale projects, while the
      refreshed one passes. Close by: `--locked-mode` on every restore step,
      **and** the root build files in every component pipeline's path filter.
      The second half is not optional: a filter watching only a component's own
      folder does not trigger on a root props change, so the drift produces
      silence rather than a failure — the pipelines that would have caught it
      never run and stay green from their last execution.
- [ ] **Cross-component references are not a pipeline's to police.** The
      layout rule is packages between components, with a recorded
      `ProjectReference` workaround until a feed exists, and a standing
      leave for a component that is never released to reference
      another by project. A pipeline builds its component as though
      the references were packages; where a project reference stands, the
      component's trigger must include the referenced components' paths,
      and nothing more is asked of CI. Close by: the feed, and the
      `TODO.md` entries in each consuming repository that name the switch —
      not a CI check for stray project references.
- [ ] **Build only affected components** in a monorepo — the reason there is
      no root solution. "Affected" has to include *depends on a changed root
      file*, not only *has changed files under its own path*: a root
      `Directory.*` change touches every component, and the entry above is what
      goes wrong when it does not.
- [ ] **Cross-platform verification via a runner matrix.** A workflow on
      `ubuntu-latest` and `macos-latest` that runs the local setup (minus the
      interactive steps) and the full repo-init procedure end to end is the
      Linux/macOS test environment we do not otherwise have — free on a public
      repository. Until it exists, `machine/platforms.md` is best effort.
      FreeBSD has no hosted runner and no official .NET 10; it stays
      "user-prepared prerequisites" (community source builds such as
      sec/dotnet-core-freebsd-source-build) unless a VM is set up.
