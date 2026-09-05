# Python setup

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

Three different needs get called "Python setup". Decide which one you have
before creating anything — the wrong answer to this is how a C# repository ends
up with a `.venv` in it.

| Need | Mechanism | Anything in the repo? |
|---|---|---|
| **Machine tooling** — an interpreter exists | `uv python install` | no |
| **Agent tooling** — Serena, other MCP servers, Python-based CLIs | `uv tool install` / `uvx` | a config folder at most, never an environment |
| **Python components** — a service or tool written in Python | `pyproject.toml` + `.venv` per component | yes, see below |

## Agent tooling: `uv tool`, never a repo `.venv`

An MCP server or agent CLI is a **tool the developer runs**, not a dependency
of the code. It belongs in its own isolated environment, available from any
directory, and it must not appear in the repository's dependency set — the
repository's contributors did not choose it, and its version churn is not
theirs to track.

`uv tool` is the mechanism (the successor to `pipx`): one isolated environment
per tool, exposed on `PATH`, sharing nothing with any project.

    uv tool install -p 3.13 serena-agent     # Serena's own documented install
    serena init
    uv tool list                             # what is installed, and where

Serena keeps its per-project configuration in a `.serena/` folder inside the
repository. That folder is configuration, not an environment — the interpreter
and packages live in `uv`'s tool store, outside every repo.

A repo-root `.venv` is the wrong shape for a tool, and so is the system
Python, where tools collide over time; `uv tool` is the middle path — global
availability, isolated environments. For a one-off run without installing:
`uvx <tool>`.

### Agent scripts: `uv run` with inline metadata

`uv tool` runs *installed packages' commands*. For a script of your own that
needs dependencies — an automation or check an agent runs — declare them in
the script itself (PEP 723) and run it with `uv run`:

    # /// script
    # requires-python = ">=3.13"
    # dependencies = ["httpx"]
    # ///
    import httpx
    ...

    uv run scripts/check-something.py

`uv` builds an ephemeral, cached environment for that script and runs it. No
`pyproject.toml`, no `.venv`, nothing to commit but the script. **The script
lives in the repository; its environment never does** — which is what makes
this the right shape for agent automation in a C# repository. `uv run --with
<pkg> script.py` does the same for an ad-hoc dependency.

Measured on Windows: the first run of a script depending on `httpx` took ~9 s,
later runs ~1 s — environments are cached in `%LOCALAPPDATA%\uv\cache` and
shared between scripts with the same dependencies.

Executables from `uv tool install` land in `%USERPROFILE%\.local\bin`, which
must be on `PATH` — `uv tool update-shell` adds it, and a console restart makes
it visible. Until then a tool is installed but not invocable by name; the
diagnose → ask → update → restart → full-path-as-last-resort sequence is in
the local setup [README](README.md).

## Python components: out of scope today, and where they will go

The toolkit currently supports C# components only. When a Python service or
tool is added, it will follow the same component rule as C#: its own
`pyproject.toml`, `.python-version`, `uv.lock` and `.venv` **inside the
component folder** — `tools/data-migrator/`, never the monorepo root — with a
`python-new-project.md` alongside the C# one. The rest of this document
describes that shape so the decision is already made when it is needed.

Repo-level Python scripts that assist the build (a `scripts/` folder driven by
`uv run`) are the one legitimate reason for a root-level `pyproject.toml` in a
C# repository. Do not add one speculatively.

## Machine: `uv` manages Python itself

    winget install --id astral-sh.uv -e
    uv python install 3.13
    uv python list --only-installed

`uv` (Astral, 2024→) replaced the stack of `pyenv` + `venv` + `pip` +
`pip-tools`/`poetry` for new projects. It installs and pins interpreters,
creates environments, resolves and locks dependencies, and runs commands — one
tool, orders of magnitude faster than pip. A separate system Python is
optional; if you want one, `winget install --id Python.Python.3.13 -e`, and
`uv` will find it too.

**Never type bare `python` on a fresh Windows machine** until you have checked
what it resolves to. Windows ships a Store-redirect stub under that name —
see the local setup [README](README.md). `uv run` sidesteps the question
entirely.

## Repository: what is committed and what is not

| Path | Committed | Purpose |
|---|---|---|
| `pyproject.toml` | yes | project metadata and dependencies |
| `uv.lock` | yes | exact resolved versions — reproducible installs |
| `.python-version` | yes | interpreter version; `uv` reads it automatically |
| `.venv/` | **no** | the environment — machine-specific, regenerated from the above |

Starting a Python project:

    uv init                      # writes pyproject.toml and .python-version
    uv add requests              # adds a dependency, updates uv.lock, creates .venv
    uv run python -m app         # runs inside .venv - no activation needed

On a fresh clone: `uv sync` recreates `.venv` from `uv.lock` exactly.

Activation (`.venv\Scripts\activate` on Windows, `source .venv/bin/activate`
elsewhere) still works but is rarely needed — `uv run <cmd>` executes inside
the environment directly, which is also what an agent should use so it never
depends on shell state.

### Where `.venv` lives

A `.venv` at the project root is the convention every tool auto-detects — VS
Code, PyCharm, `uv`, `poetry`, GitHub's `Python.gitignore` — and nobody creates
it by hand any more: `uv` does, from `pyproject.toml`; the recipe is committed,
the environment is not.

Same rule as a .NET solution: **one per component.** In a standalone repository
that is the root. In a monorepo it is the component folder —
`tools/data-migrator/.venv`, alongside that component's `pyproject.toml` —
never the monorepo root, because an environment is a set of dependencies and
components have different ones.

### `.gitignore`

The toolkit's shipped `.gitignore` is the .NET template plus local-config
entries; it does **not** cover Python. A repository that gains Python code needs
at minimum:

    .venv/
    __pycache__/
    *.py[cod]
    .pytest_cache/
    .ruff_cache/
    .mypy_cache/

Add them before creating the environment — ignoring an already-tracked
`.venv/` does nothing.

## Alternatives, so they are recognised and not mixed

| Tool | Status |
|---|---|
| `poetry` | previous-generation equivalent; still common in existing repos. Fine to keep where it is; do not add to new ones. |
| `pip` + `requirements.txt` | works, but no lockfile and no interpreter management. Migrate with `uv add -r requirements.txt`. |
| `conda` / `mamba` | data-science ecosystems with native dependencies. Only if that is the actual need. |

One tool per repository. A `poetry.lock` and a `uv.lock` in the same folder
means nobody knows which one is true.
