# GitHub integration

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

Applies when a developer machine needs source-control integration. Ask first:

> Do you need source-control integration on this machine? Only **GitHub** is
> supported at the moment.

If no, stop here.

What this sets up: SSH for transport, **SSH commit signing** with the same key,
`gh` for the API, and the Windows `ssh-agent` so a passphrase-protected key works
non-interactively — including for git commands an agent runs. Verified on
Windows Server 2025 with Git 2.55, gh 2.100, Windows OpenSSH.

Prerequisite: git identity set to the noreply form — see
[`security-reminders.md`](../repo/payload/docs/rules/security-reminders.md).
The email in the key, the identity, and the GitHub account must all agree or
commits show *Unverified*.

## Steps

Some steps are interactive (passphrase, browser). An agent hands those to the
user as a command to run and continues afterwards; it never types a passphrase.

| # | Step | Command | Who |
|---|---|---|---|
| 1 | GitHub CLI | `winget install --id GitHub.cli -e --silent --accept-package-agreements --accept-source-agreements` | agent |
| 2 | Windows ssh-agent | `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent` — **elevated** PowerShell | user |
| 3 | SSH key | `ssh-keygen -t ed25519 -C "<git email>" -f %USERPROFILE%\.ssh\id_ed25519` — set a passphrase | user |
| 4 | Log in, upload the key | `gh auth login --web --git-protocol ssh --scopes admin:ssh_signing_key` | user |
| 5 | Load key into the agent | `C:\Windows\System32\OpenSSH\ssh-add.exe %USERPROFILE%\.ssh\id_ed25519` | user |
| 6 | Point git at Windows OpenSSH | see below | agent |
| 7 | Enable SSH signing | see below | agent |
| 8 | Signing-key scope — only if step 4 ran without `--scopes` | `gh auth refresh -h github.com -s admin:ssh_signing_key` | user |
| 9 | Register key as signing key | `gh ssh-key add %USERPROFILE%\.ssh\id_ed25519.pub --type signing --title "<machine>"` | agent |
| 10 | Proxy / restricted egress | ask, then see *Proxies* below | agent |

The agent persists keys across reboots, so step 5 happens once per key.

Step 10 is a question, not a default:

> Does this machine reach the internet through an HTTP proxy, or might
> outbound port 22 be blocked? If **yes or unsure**, apply the SSH-over-443
> config in *Proxies* — it also works with no proxy present, so there is no
> cost to being wrong in that direction. If **no**, leave SSH on port 22.

### Step 6 — two agents, two `ssh` binaries

Git for Windows ships its own `ssh` under `/usr/bin`, which talks to its *own*
agent — not the Windows `ssh-agent` service from step 2. Left alone, git asks an
agent that is not running and every push prompts for the passphrase, or fails
outright when nothing can prompt. Point git at Windows OpenSSH for both
transport and signing:

    git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
    git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"

### Step 7 — signing with the SSH key

    git config --global gpg.format ssh
    git config --global user.signingkey "%USERPROFILE%\.ssh\id_ed25519.pub"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true

`user.signingkey` is the **public** key; the private half comes from the agent,
which is why step 5 makes signing non-interactive.

For `git log --show-signature` to say *Good signature* locally, git needs an
allowed-signers file:

    <git email> <contents of id_ed25519.pub>

saved as `%USERPROFILE%\.ssh\allowed_signers`, and:

    git config --global gpg.ssh.allowedSignersFile "%USERPROFILE%\.ssh\allowed_signers"

### Step 4 — scopes

The default login covers repositories, issues, and pull requests (`repo`) —
everything change tracking needs. The one extra at setup is
`admin:ssh_signing_key` for step 9. Projects-board scopes (`read:project`,
`project`) are **not** part of setup: a board request is rare, handled on
demand, and the agent checks `gh auth status` and hands over
`gh auth refresh -h github.com -s read:project,project` only then. The
permission model is in `docs/rules/change-tracking/github.md` of any
initialized repository.

### Step 9 — the trap

GitHub keeps **authentication keys and signing keys as separate lists**. Step 4
uploads the key as authentication only. Without step 9 the same key signs
every commit and GitHub shows every one as *Unverified*. Step 8 exists because
the default login scopes cannot touch the signing-key list.

## Verify

    C:\Windows\System32\OpenSSH\ssh-add.exe -l          # one ED25519 key listed
    C:\Windows\System32\OpenSSH\ssh.exe -T git@github.com   # "Hi <user>! ..."
    gh auth status                                       # logged in; "Git operations protocol: ssh" - gh auth refresh can reset it to https
    gh ssh-key list                                      # the key twice: authentication AND signing

Then, in any repository:

    git commit --allow-empty -m "signing test"
    git log -1 --show-signature                          # Good "git" signature for <email>

The authoritative check is GitHub's, after a push:

    gh api repos/<owner>/<repo>/commits/<sha> --jq .commit.verification

`"verified": true` is the goal; `reason` says why when it is not.

## Proxies

`gh`, and git over HTTPS, honour `HTTPS_PROXY` / `HTTP_PROXY` from the
environment the process inherits — nothing to configure.

**SSH does not use an HTTP proxy on its own.** SSH is not HTTP; the only way
through an HTTP proxy is a CONNECT tunnel, which needs a `ProxyCommand`. Git
for Windows bundles the tool (`connect.exe`), and it reads `HTTP_PROXY` from
the environment itself — so one config tunnels when a proxy is set and goes
direct when it is not. GitHub serves SSH on port 443 at `ssh.github.com`,
which is what proxies allow CONNECT to.

`%USERPROFILE%\.ssh\config`:

    Host github.com
        HostName ssh.github.com
        Port 443
        User git
        IdentityFile ~/.ssh/id_ed25519
        ProxyCommand "C:\\Program Files\\Git\\mingw64\\bin\\connect.exe" %h %p

Verified on this config: tunnelled with `HTTP_PROXY` set, direct with it
unset, and with outbound port 22 blocked — `ssh -T`, `git ls-remote`, `gh`, and
a real `git push` all worked. It takes effect because step 6 pointed git at
Windows OpenSSH, which reads this file; Git-Bash `ssh` would need the same
block but its own agent.

Two notes: the `known_hosts` entry is for `[ssh.github.com]:443`, not
`github.com` — expect one first-connection prompt or use
`-o StrictHostKeyChecking=accept-new` once. And in a proxied environment a
"what is my IP" check reports the proxy's address, not the machine's.

## Optional

### GPG signing instead of SSH signing

The traditional choice; GitHub verifies either. On Windows, SSH signing is
simpler — one key, no `gpg-agent`, no expiry. Prefer GPG where a platform or
policy needs it. Git for Windows bundles `gpg`, so nothing to install.

Generate non-interactively except for the passphrase, from a parameter file so
the passphrase never touches a command line:

    %echo Generating an ed25519 signing key
    Key-Type: eddsa
    Key-Curve: ed25519
    Key-Usage: sign
    Name-Real: <git user.name>
    Name-Email: <git user.email>
    Expire-Date: 2y
    %ask-passphrase
    %commit

    gpg --batch --generate-key <params-file>
    gpg --list-secret-keys --keyid-format long             # take the key id after "sec"
    git config --global gpg.format openpgp
    git config --global gpg.program "C:/Program Files/Git/usr/bin/gpg.exe"
    git config --global user.signingkey <key id>
    gpg --armor --export <key id> | gh gpg-key add -

Name-Email must equal the git email exactly. Unset `gpg.ssh.*` settings when
switching.

### GitHub MCP server

Gives an agent API-level GitHub actions — issues, pull requests, code search —
as MCP tools. `gh` already covers most of that from the shell, so this is
optional — **ask the user** at setup time and leave the decision with them.
When it is connected, the toolkit's skills prefer it over `gh`; when it is
not, everything works with `gh` alone. Whichever they choose, tell them the
catch below before they spend time on the OAuth route.

**The OAuth route does not work from Claude Code.** Registering the remote
server plainly —

    claude mcp add --scope user --transport http github https://api.githubcopilot.com/mcp/

— produces *"Incompatible auth server: does not support dynamic client
registration"*. GitHub's auth server requires a pre-registered app; Claude
Code's OAuth flow needs dynamic registration; the in-session `authenticate`
tool fails at the same step. Verified on Claude Code 2.1.

The documented method for Claude Code is a **personal access token in an
`Authorization` header**:

    claude mcp add-json --scope user github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer <PAT>"}}'

Treat the token with care — it is written **in plain text** to
`~/.claude.json`:

- fine-grained token, not classic; only the repositories it needs
- read-only permissions unless a write is genuinely required
- short expiry, and revoke it when the server is removed

If that trade-off is not worth it, remove the registration so it stops
failing at every session start: `claude mcp remove github -s user`. A local
Docker variant exists for hosts that cannot reach the remote server; it also
needs a PAT and has no advantage on a machine that can.

## Known failures

| Symptom | Cause |
|---|---|
| `Permission denied (publickey)` from `ssh -T` | key not in the agent (step 5), or the wrong agent (step 6) |
| every push asks for the passphrase | git is using Git-Bash `ssh` — step 6 |
| commit signed, GitHub says *Unverified* | key not registered as a signing key — step 9; or email mismatch |
| `gh ssh-key add --type signing` → HTTP 404 | missing scope — step 8 |
| `git log --show-signature` → *No principal matched* | `allowed_signers` missing or wrong email |
| `ssh-add` says agent not running | step 2 not done, or done without elevation |
