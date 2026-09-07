# Documents and tool configuration

Stage 3 of [`initialize.md`](initialize.md): turn the two templates into the
repository's own `AGENTS.md` and `README.md`, write the Serena project file,
and restore the local tools.

## 1. Documentation and AGENTS.md

`agentics/rules/`, `.github/`, and `.markdownlint.yaml` arrive with the payload
copy, in both modes, exactly as they sit in `payload/` — so every relative
link between rules files resolves identically here and there. `.claude/skills/`
is copied from the toolkit root: each `SKILL.md` is a shim — frontmatter so
Claude Code can invoke it, and a pointer to its document under `agentics/rules/`,
located by repository-root-relative path with a toolkit fallback. The document
is the substance and `AGENTS.md` points every tool at it, so a team without
Claude Code loses nothing by skipping the shims.

Then generate the repository's own `AGENTS.md` at its root from
[`payload/agentics/templates/AGENTS.template.md`](payload/agentics/templates/AGENTS.template.md).
It arrived with the copy at `<repo>/agentics/templates/`, and **it stays there** —
copy it to the root as `AGENTS.md` and transform the copy, leaving the template
untouched.

**Why the template stays.** A standalone repository that later converts to a
monorepo needs the monorepo layout variant, and that text exists nowhere else.
Keeping the template is what lets a repository describe a shape it does not
yet have, without a toolkit checkout. A toolkit upgrade replaces anything under
`agentics/` that the repository has not modified, so it stays current on its
own.

Transform the copy:

1. Fill every double-brace placeholder — `REPO_NAME`, `ONE_LINE_PURPOSE`,
   `PREFIX`, and `SOLUTION_NAME`, the main project the solution is named after
   (standalone only). Ask for the purpose line rather than inventing one, and
   **wrap it**: it is a sentence of prose landing in two markdown files, and a
   long one breaks MD013 in both.

   An existing document is a legitimate source for the purpose line, the layout
   and the prefix — a README in the repository, or one the user points at.
   Quote what you took back to them for confirmation; that is not inventing.
2. Delete the layout variant that does not apply (standalone or monorepo), and
   the surrounding `==== variant ====` comments. **Take one adjoining blank
   line with each comment.** Every variant comment sits with a blank line
   either side, so removing the line alone leaves two consecutive blanks —
   MD012, which stage 5 then reports against a file you have no reason to
   suspect.
3. Trim the folder table to folders that **actually exist**. A row for a folder
   you did not create is a false statement about the repository.
4. Delete the instruction comment at the top of the template.
5. Add a table row for any further rules documents, then delete the
   `ADDITIONAL_GUIDELINE_ROWS` line — it sits below the table as a reminder,
   not as a row.
6. In standalone mode, replace `<solution>` under *Building and testing* with
   the solution file name. In a monorepo it stays: there is no single solution
   there, and the command is generic on purpose.

Then the repository's `README.md`, copied out of `agentics/templates/` the same way
and transformed the same way: fill placeholders, keep the matching layout
variant, delete the template comment. It is the human entry point; `AGENTS.md`
is the agent's. The line under its title points at `.agentics.yaml` for
provenance and choices ([`settings.md`](settings.md)) and at `TODO.md` for open
items; it has no placeholders of its own.

In a monorepo, also give every category folder you create its map —
`agentics/templates/category-README.md` copied to `<category>/README.md` and
filled: `CATEGORY` is the folder name, and `CATEGORY_DESCRIPTION` is that
category's own row in `agentics/rules/layout.md`, so the two cannot disagree.
Component READMEs come from the new-project procedure..

**Every template stays, in both modes**, `category-README.md` included. A
standalone repository has no categories today and may have them tomorrow: the
layout conversion needs that map, and a repository that has to fetch it from
the toolkit is not self-describing. It also makes the reference in
`csharp-new-project.md` true in both modes rather than only one.

Verify nothing was missed:

    grep -n "{{" <repo>/AGENTS.md <repo>/README.md      # only the Licence section may still match
    ls <repo>/agentics/templates/                            # all four templates must still be there
    grep -n "<!--" <repo>/AGENTS.md <repo>/README.md    # only the Licence section may still match

The generated documents must be clean; the templates they came from must be
untouched, placeholders and all. Those are opposite conditions, and checking
the wrong one is how a template gets transformed in place by accident.

**The Licence section is stage 4's, not this stage's.** `README.md` keeps
`{{LICENCE_NAME}}`, `{{YEAR}}`, `{{COPYRIGHT_HOLDER}}` and the
*Delete this section if the repository has no LICENSE file* comment until
[`settings.md`](settings.md) fills them or deletes the section — so those are
the only matches either grep may return here, and `AGENTS.md` must be clean of
both. Re-run both after stage 4, when nothing at all may match.

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

Never let it infer — [`../machine/serena.md`](../machine/serena.md) says what
inference does without a terminal. The toolkit knows the answer anyway: C#,
plus `terraform` when the repository has an `infrastructure/` folder.

That writes `.serena/project.yml`, alongside a `.serena/project.local.yml` for
per-machine overrides. Commit `project.yml`; what the shipped `.gitignore`
already covers is in `serena.md` as well.

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
[`../machine/serena.md`](../machine/serena.md).

## 3. Dependency licence policy

`allowed-licenses.json`, `license-overrides.json` and
`.config/dotnet-tools.json` arrive with the payload copy. Then:

    dotnet tool restore

That installs `nuget-license` as a repository-local tool (pinned in the
manifest, nothing global). The policy itself is
[`payload/agentics/rules/dependencies.md`](payload/agentics/rules/dependencies.md), shipped to the
repository as `agentics/rules/dependencies.md` and referenced from `AGENTS.md`.

The check runs in [`verify.md`](verify.md), not here; there are no packages to
judge until a project exists.
