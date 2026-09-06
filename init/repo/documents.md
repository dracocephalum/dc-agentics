# Documents and tool configuration

Stage 3 of [`README.md`](README.md): turn the two templates into the
repository's own `AGENTS.md` and `README.md`, write the Serena project file,
and restore the local tools.

## 1. Documentation and AGENTS.md

`docs/rules/`, `.github/`, and `.markdownlint.yaml` arrive with the payload
copy, in both modes, exactly as they sit in `payload/` — so every relative
link between rules files resolves identically here and there. `.claude/skills/`
is copied from the toolkit root: each `SKILL.md` is a shim — frontmatter so
Claude Code can invoke it, and a pointer to its document under `docs/rules/`,
located by repository-root-relative path with a toolkit fallback. The document
is the substance and `AGENTS.md` points every tool at it, so a team without
Claude Code loses nothing by skipping the shims.

Then generate the repository's own `AGENTS.md` at its root from
[`payload/AGENTS.template.md`](payload/AGENTS.template.md) — it arrived at the
target root with the copy; transform it in place:

1. Fill every double-brace placeholder — `REPO_NAME`, `ONE_LINE_PURPOSE`,
   `PREFIX`, and `SOLUTION_NAME`, the main project the solution is named after
   (standalone only). Ask for the purpose line rather than inventing one, and
   **wrap it**: it is a sentence of prose landing in two markdown files, and a
   long one breaks MD013 in both.

   An existing document is a legitimate source for the purpose line, the layout
   and the prefix — a README in the repository, or one the user points at.
   Quote what you took back to them for confirmation; that is not inventing.
2. Delete the layout variant that does not apply (standalone or monorepo), and
   the surrounding `==== variant ====` comments.
3. Trim the folder table to folders that **actually exist**. A row for a folder
   you did not create is a false statement about the repository.
4. Delete the instruction comment at the top of the template.
5. Add a table row for any further rules documents, then delete the
   `ADDITIONAL_GUIDELINE_ROWS` line — it sits below the table as a reminder,
   not as a row.
6. In standalone mode, replace `<solution>` under *Building and testing* with
   the solution file name. In a monorepo it stays: there is no single solution
   there, and the command is generic on purpose.

Then the repository's `README.md`, from `README.template.md` (it arrived at the
target root with the copy) by the same transform: fill placeholders, keep the
matching layout variant, delete the template comment. It is the human entry
point; `AGENTS.md` is the agent's. The line under its title points at
`.dc-agentics.yaml` for provenance and choices ([`settings.md`](settings.md)) and at `TODO.md`
for open items; it has no placeholders of its own. In a monorepo, also give
every category folder you create its map —
`docs/templates/category-README.md` copied to `<category>/README.md` and
filled. Component READMEs come from the new-project procedure. In standalone
mode, delete `docs/templates/category-README.md`: there are no categories, so
it can never be used there.

Verify nothing was missed:

    grep -n "{{" <repo>/AGENTS.md <repo>/README.md      # must return nothing
    ls <repo>/AGENTS.template.md <repo>/README.template.md   # both must NOT exist
    grep -n "<!--" <repo>/AGENTS.md <repo>/README.md    # must return nothing: every prompt comment answered and removed

### Why the guideline rows are phrased as situations

Each row says *when* it applies — "when you are writing, reviewing or
refactoring C#" — because a plain-language request can be matched against a
situation and not against a filename. Keep that phrasing when adding rows.

## 2. Serena project config — automatic, non-blocking

Every initialized repository gets a Serena project file. Most repositories are
code repositories, so this is opt-out rather than opt-in; for a docs-only
repository it is harmless and can be deleted.

At the repository root, **always passing the languages explicitly**:

    serena project create --language csharp
    serena project create --language csharp --language terraform   # monorepo with infrastructure/

Never let it infer. On a tree with more than one language, inference picks a
"main" language and then **prompts `[y/N]` for each additional one** — and
with no interactive stdin it aborts with `Aborted!` and writes nothing.
`--language` skips inference entirely. The toolkit knows the answer anyway:
C#, plus `terraform` when the repository has an `infrastructure/` folder.

That writes `.serena/project.yml`, alongside a `.serena/project.local.yml` for
per-machine overrides. Commit `project.yml`; the shipped repository
`.gitignore` already excludes `project.local.yml` and `.serena/cache/`.

Serena writes its own `.serena/.gitignore` the first time an agent indexes or
activates the project — which is after initialization, so it is not here yet
and cannot be committed now. It turns up untracked later; that is expected, not
a missed step.

**This step never blocks initialization.** If `serena` is not on `PATH`, is
not installed, or the command fails for any reason: report it in one line —
`Serena project config skipped: <reason>` — add the same line under
*Initialization* in the target's `TODO.md` with the command to run, and
continue with the next step. Do not install Serena, do not modify `PATH`, do not ask
the user mid-procedure. The
generated `AGENTS.md` already tells agents to fall back when Serena is absent,
so nothing downstream depends on this file existing.

Skip `serena project index` at initialization: it needs a restored solution
and there is no code yet.

Details, and the two choices behind the machine-level wiring, are in
[`../local/serena.md`](../local/serena.md).

## 3. Dependency licence policy

`allowed-licenses.json`, `license-overrides.json` and
`.config/dotnet-tools.json` arrive with the payload copy. Then:

    dotnet tool restore

That installs `nuget-license` as a repository-local tool (pinned in the
manifest, nothing global). The policy itself is
[`payload/docs/rules/dependencies.md`](payload/docs/rules/dependencies.md), shipped to the
repository as `docs/rules/dependencies.md` and referenced from `AGENTS.md`.

The check runs in [`verify.md`](verify.md), not here; there are no packages to
judge until a project exists.
