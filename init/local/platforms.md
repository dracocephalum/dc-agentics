# Other platforms — best effort, untested

Every `init/local/` guide was written and verified on **Windows**. Nothing here
has been run on Linux, macOS, or FreeBSD. This file maps each Windows step to
its documented equivalent so that a user on another platform does not get a
Windows path pasted at them — it is a starting point, not a verified procedure.

An agent on a non-Windows machine: read the relevant Windows guide for the
*why*, use this file for the *how*, verify every step's expected output, and
say plainly when something here turns out to be wrong.

The repository payload (`init/repo/payload/`) is platform-neutral — MSBuild,
EditorConfig, git attributes — and needs nothing from this file.

## Support statement

| Platform | .NET 10 | Status |
|---|---|---|
| Windows | official | verified — the guides |
| Linux (x64/arm64) | official | untested; expected to work |
| macOS | official | untested; expected to work |
| FreeBSD | **not official** | see below — user-prepared prerequisites |

### FreeBSD

Microsoft does not ship .NET for FreeBSD. The FreeBSD port `lang/dotnet` is a
community effort (maintainer arrowd@) and was at **9.0.14, x64 only** when
checked — this toolkit targets `net10.0`, so the port alone is not enough.

Community source builds of .NET 10 for FreeBSD exist —
<https://github.com/sec/dotnet-core-freebsd-source-build/releases/tag/10.0.110-vmr>
provides native SDK builds for **FreeBSD 14 and 15, x64 and arm64**, plus
portable variants — but they move slowly and are not a package-manager
install. Caveats quoted from that release: assets were re-uploaded after
publication with a patched `msbuild` (crashes on FreeBSD 15 otherwise), so
re-download if in doubt; and libssl errors need
`setenv DOTNET_OPENSSL_VERSION_OVERRIDE 35`.

**The user prepares the .NET 10 SDK on FreeBSD themselves — binaries
extracted, on `PATH`, `dotnet --version` reporting `10.x`, a trivial
`dotnet new console && dotnet build` succeeding — before asking an agent to run
local initialization.** An agent must check `dotnet --version` first and stop
with a clear message if it is not 10.x; it must not attempt to build, download,
or install .NET on FreeBSD.

## Step mapping

| Task | Windows (verified) | Linux | macOS | FreeBSD |
|---|---|---|---|---|
| package manager | `winget` | distro (`apt`, `dnf`, …) | Homebrew `brew` | `pkg` |
| .NET SDK 10 | `winget install Microsoft.DotNet.SDK.10` | Microsoft package feed, or `dotnet-install.sh` | `brew install --cask dotnet-sdk` or Microsoft `.pkg` | user-prepared, see above |
| Git | `winget install Git.Git` | distro package | `brew install git` (or Xcode CLT) | `pkg install git` |
| GitHub CLI | `winget install GitHub.cli` | GitHub's apt/dnf repo | `brew install gh` | `pkg install gh` |
| uv | `winget install astral-sh.uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `brew install uv` | `pkg install uv` if packaged, else `pip install uv` |
| Python | `uv python install 3.13` | same | same | `pkg install python313`; uv-managed builds may not exist |
| Serena | `uv tool install -p 3.13 serena-agent` | same | same | same; the C# language server is unlikely to run |
| gitleaks | `winget install Gitleaks.Gitleaks` | release binary from GitHub, or distro package | `brew install gitleaks` | `pkg install gitleaks` |
| `pre-commit` | `uv tool install pre-commit` | same | same | same |

## Things that are Windows-only — do not carry them over

| Windows guide says | Elsewhere |
|---|---|
| `git config core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe` | **do not set.** One `ssh`, one agent; the two-agents trap does not exist |
| `git config gpg.ssh.program …\ssh-keygen.exe` | do not set; `ssh-keygen` is on `PATH` |
| `Set-Service ssh-agent …` (elevated) | Linux: an agent is usually already running in the session. macOS: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` persists the passphrase in Keychain. FreeBSD: `eval "$(ssh-agent -s)"` in the shell profile, then `ssh-add` |
| `%USERPROFILE%\.ssh\…`, `%LOCALAPPDATA%` | `~/.ssh/…`; no equivalent of `%LOCALAPPDATA%` needed |
| `[Environment]::SetEnvironmentVariable(…, 'User')` | export in the shell profile (`~/.bashrc`, `~/.zshrc`, `~/.profile`) |
| `uv tool update-shell` | same command; it edits the shell profile instead of the registry |
| the Microsoft Store `python` stub | does not exist; `python3` is real. Still prefer `uv run` |
| `cygpath`, MSYS path rules | not applicable |
| `connect.exe` as `ProxyCommand` | macOS/FreeBSD: OpenBSD netcat — `ProxyCommand nc -X connect -x <proxy:port> %h %p`. Linux: `nc` variants differ; use `corkscrew <proxy> <port> %h %p`. Neither reads `HTTP_PROXY` by itself — the proxy is written into the config |
| `reg query` / PowerShell to read env | `env`, `printenv` |
| Git Bash `sha256sum` | macOS `shasum -a 256`; FreeBSD `sha256` |

## Things that are identical

- **One SSH key for both authentication and signing** — the whole of
  `github.md` steps 3–9 is git- and GitHub-side and does not change. Floors:
  OpenSSH ≥ 8.8 (`ssh-keygen -Y sign`) and git ≥ 2.34. What differs is only how
  the agent holding the key persists: Windows service, macOS Keychain
  (`ssh-add --apple-use-keychain`), Linux usually per-session unless a keyring
  or systemd user service holds it — so a fresh Linux session may prompt for
  the passphrase on the first signed commit.
- `.ssh/config` shape (`Host github.com`, `HostName ssh.github.com`, `Port 443`)
- SSH signing config: `gpg.format ssh`, `user.signingkey` (the `.pub`),
  `commit.gpgsign`, `gpg.ssh.allowedSignersFile`
- `gh auth login --web --git-protocol ssh`, `gh ssh-key add --type signing`
- the global hook: `~/.githooks/pre-commit` (POSIX `sh`), `chmod +x`, and
  `git config --global core.hooksPath ~/.githooks` — verify with `--get`
- `serena init`, `serena project create --language csharp`, `claude mcp add`
- `uv run` with PEP 723 headers, `uv tool install`
- all `dotnet` commands, the repository payload, and the drift check (on these
  platforms `dotnet new` emits LF, so `tr -d '\r'` is a harmless no-op)

## Shell gotchas an agent should expect

- `sed -i` needs an explicit suffix on BSD (`sed -i ''`) — prefer writing a
  new file over in-place edits.
- `timeout` is GNU coreutils; macOS has none by default (`gtimeout` via brew).
- `readlink -f` is missing on older macOS; use `realpath` or `$(cd … && pwd)`.
- `#!/bin/sh` is `dash` on Debian/Ubuntu — no bashisms in hook scripts.
- Line endings: `* text=auto` in `.gitattributes` handles the repository; a
  hook script copied from Windows with CRLF will fail with `^M: bad
  interpreter`. Check with `file` or `cat -A`.

## Verify (all platforms)

    dotnet --version               # 10.x - on FreeBSD, this is the user's job
    git --version
    gh auth status
    uv --version
    ssh -T git@github.com          # Hi <user>!
    git config --global --get core.hooksPath
    gitleaks version
