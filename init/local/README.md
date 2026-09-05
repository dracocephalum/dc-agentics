# Local environment setup

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

Applies when setting up a developer machine from scratch — assume only Windows
and an agent tool (Claude Code or similar) are present.

Windows, using `winget`, which ships with Windows 10/11. Every step has a
verification; do not move on until it passes. Installers need elevation — expect
a UAC prompt.

**After installing anything, open a new terminal.** PATH changes do not reach
an already-running shell, and an agent session started before the install
will not see the tool either — restart it.

## Checklist

| # | Tool | Install | Verify | Expect |
|---|---|---|---|---|
| 0 | winget | ships with Windows | `winget --version` | `v1.x` |
| 1 | Git | `winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements` | `git --version` | `git version 2.x` |
| 2 | .NET SDK 10 | `winget install --id Microsoft.DotNet.SDK.10 -e --silent --accept-package-agreements --accept-source-agreements` | `dotnet --version` | `10.0.x` |
| 3 | uv (Python) | `winget install --id astral-sh.uv -e --silent --accept-package-agreements --accept-source-agreements` | `uv --version` | `uv 0.x` |
| 4 | Python 3.13 | `uv python install 3.13` | `uv python list --only-installed` | a `3.13.x` row |
| 5 | uv tool dir on PATH | `uv tool update-shell` | new terminal, then `uv tool dir --bin` and check that path is in `PATH` | `...\.local\bin` present |

Step 5 is the one people skip. `uv tool install` puts executables in
`%USERPROFILE%\.local\bin`; until that directory is on `PATH`, an installed
tool such as `serena` exists but cannot be invoked by name. `uv` prints a
warning about this after step 4 — act on it.

## If a tool is installed but "not found"

`uv`, `serena`, or any `uv tool` executable resolving to nothing usually means
`PATH`, not a failed install. Work through this in order; **do not jump to the
last step.**

1. **Diagnose.** `uv tool dir --bin` prints the tool directory. If that
   directory is missing from `PATH`, that is the problem. If `uv` itself is
   not found, the winget install lives under
   `%LOCALAPPDATA%\Microsoft\WinGet\Packages\astral-sh.uv_*\uv.exe` — locate it
   with `Get-ChildItem -Recurse "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter uv.exe`.
2. **Ask the user** whether to update `PATH`. It is a persistent change to
   their user environment — make it their decision, not yours.
3. **If yes:** run `uv tool update-shell`. It writes the directory to the user
   `PATH` in the registry. Then **tell the user to restart their CLI console**
   — and the agent session with it — because a running process never sees a
   `PATH` change. Nothing works by name until that restart.
4. **Last resort — full path, without changing anything.** Only if the user
   declines, or until the restart happens:

       %LOCALAPPDATA%\Microsoft\WinGet\Packages\astral-sh.uv_*\uv.exe
       %USERPROFILE%\.local\bin\serena.exe          # or: uv tool dir --bin

   `uvx <tool>` also works without `PATH` for a one-off run. Treat full paths
   as a stopgap, never as the documented way to call a tool.

Then the per-tool notes below — each has one thing the installer does not do
for you.

## 1. Git — set your identity before the first commit

Git does not refuse to commit with no identity configured; it silently derives
`<username>@<hostname>` and writes that into history permanently.

    git config --global user.name  "<name>"
    git config --global user.email "<id>+<user>@users.noreply.github.com"
    git var GIT_AUTHOR_IDENT          # must show what you just set

The noreply form keeps a real address out of public history. Details, and what
to do if commits already carry the wrong identity, are in
[`../repo/payload/docs/rules/security-reminders.md`](../repo/payload/docs/rules/security-reminders.md).

## 1b. GitHub — optional, ask first

Source-control integration is a choice, not a default. If the answer is yes,
follow [`github.md`](github.md): SSH transport, SSH commit signing with the
same key, `gh`, and the Windows agent so signing and pushes never prompt.

## 1c. Secret scanning — recommended for every machine

`winget install --id Gitleaks.Gitleaks -e`, then a global `core.hooksPath`
hook so every repository refuses commits containing secrets. Setup, proof, and
the interaction with the `pre-commit` framework are in
[`gitleaks.md`](gitleaks.md). Two lines of the setup are load-bearing:
`git config --global --get core.hooksPath` must print the path back, and a
staged fake key must actually be refused.

## 2. .NET — two environment variables

`dotnet --list-sdks` shows every installed SDK. A repository can pin one with a
`global.json` at its root; without one the newest installed SDK is used, which
is the intended default for repositories from this toolkit.

Set these once, user scope, then restart the console:

    [Environment]::SetEnvironmentVariable('DOTNET_NOLOGO', '1', 'User')
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'User')

`DOTNET_NOLOGO` removes the welcome banner and first-run text from every
`dotnet` invocation — noise that otherwise lands in an agent's context on the
first command of a session. The telemetry opt-out is a preference; the banner
suppression is the token saver.

## 2b. Agent permission prompts — optional, user's call

If Claude Code prompts for permission on routine read-only commands, the
built-in `/fewer-permission-prompts` skill writes an allow-list to the
repository's `.claude/settings.json` from recent sessions. Each prompt is a
full round trip, so the saving is real — but an allow-list is a statement of
trust that belongs to the person, and some permission modes never prompt.
Mention it during setup; do not run it unasked.

## 3. Python — read `python.md` before touching anything

Two traps, both on a fresh Windows machine:

- **`python` may already "exist" and open the Microsoft Store.** Windows
  ships an execution alias at
  `%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe` that is not Python. Check:

      python --version        # prints a version, or opens the Store / prints nothing

  If it is the stub, disable it: *Settings → Apps → Advanced app settings →
  App execution aliases* → turn off `python.exe` and `python3.exe`. Or never
  type bare `python` and use `uv run` instead — see [`python.md`](python.md).

- **Install Python through uv, not the Store and not python.org**, unless you
  have a reason. `uv python install 3.13` gives a managed interpreter that
  `uv` finds automatically and that never collides with a system install.

The full rationale — why `uv`, what `.venv` is, what gets committed — is in
[`python.md`](python.md).

## Windows quirks an agent will hit

Recorded because each one cost time to discover; none is obvious from an error
message.

- **Windows binaries do not understand MSYS paths.** From Git Bash, `node`,
  `dotnet`, `gh` and other native tools receive `/w/dev/x` and read it as
  `W:\w\dev\x`. Pass `W:/dev/x` (forward slashes are fine) or convert with
  `cygpath -w`. Bash-side tools (`ls`, `grep`, `git`) take either form.
- **`python` may be a Store stub**, not Python — see *3. Python* above. Use
  `uv run`.
- **A running process never sees a `PATH` change.** After any install, restart
  the console and the agent session; until then reach the tool by full path.
- **Reading environment variables: use PowerShell, not `reg query`.**
  `[Environment]::GetEnvironmentVariable('Path','User')` is authoritative;
  parsing `reg query` output in Bash is unreliable.
- **Two `ssh` binaries, two agents.** Git Bash's `/usr/bin/ssh` and Windows
  `C:\Windows\System32\OpenSSH\ssh.exe` use different agents. See
  [`github.md`](github.md), step 6.
- **PowerShell 5.1 has no `&&`.** Chain with `;`, or use Git Bash.

## Final check

Run all of these in a **new** terminal. Every line must print a version:

    git --version
    dotnet --version
    uv --version
    uv python list --only-installed
    uv tool dir --bin                 # and confirm it appears in PATH
    git var GIT_AUTHOR_IDENT

If `GIT_AUTHOR_IDENT` shows a hostname-derived address, step 1 was skipped.
