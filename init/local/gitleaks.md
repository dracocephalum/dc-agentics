# Secret scanning with gitleaks

> Written and verified on **Windows**. Other platforms: see [`platforms.md`](platforms.md) — best effort, untested.

Machine-level setup: one binary, one global git hook, every repository on the
machine protected with nothing committed anywhere. Verified on Windows with
gitleaks 8.30.1 and Git 2.55.

gitleaks scans text for secrets using ~150 built-in regex rules gated by
entropy thresholds, entirely offline — no network, no account, works behind a
proxy untouched. MIT-licensed.

## Install

    winget install --id Gitleaks.Gitleaks -e --silent --accept-package-agreements --accept-source-agreements
    gitleaks version                      # new console first - PATH

## The global hook

Git runs one `pre-commit` script per repository, from `.git/hooks/` by default.
`core.hooksPath` redirects that to a directory of your choosing; set it
globally and every repository uses the same hook.

`%USERPROFILE%\.githooks\pre-commit` (no extension; must be executable):

    #!/bin/sh
    # Global pre-commit hook: scan STAGED changes for secrets. Deliberately thin -
    # anything beyond secrets is a per-repo concern (pre-commit framework).
    # Fails CLOSED: a missing binary is an error, not a pass.
    if ! command -v gitleaks >/dev/null 2>&1; then
      echo "pre-commit: gitleaks not found on PATH" >&2
      exit 1
    fi
    exec gitleaks git --pre-commit --redact --staged --verbose

Then:

    git config --global core.hooksPath "C:/Users/<you>/.githooks"
    git config --global --get core.hooksPath          # MUST print the path back

That second line is not optional. **A `core.hooksPath` set to an empty string
silently disables every hook** — git looks in a directory that does not exist,
finds nothing, and allows the commit. The first attempt at this setup did
exactly that: a mangled path, an empty value, and a fake key committed and
pushed without a murmur. Verify the value, then verify the behaviour:

## Prove it

In any repository:

    printf 'aws_secret_access_key = <40 random alphanumerics>\n' > config.txt
    git add config.txt && git commit -m "test"        # want: refused, exit 1
    git rm --cached config.txt && rm config.txt

Expected output ends with `leaks found: 1` and the commit does not happen —
`git log` is unchanged. Secrets are printed as `REDACTED` because of
`--redact`; keep that flag, an agent reads this output.

## What it does and does not catch

- **Staged changes only.** The hook cannot see a key committed last month. Run
  a history scan once on any repository before its first push:

      gitleaks git . --redact                 # whole history, all branches
      gitleaks dir <path> --redact            # files on disk, no git needed

- **Generic patterns, offline.** It flagged the fake key above as
  `generic-api-key` on entropy. GitHub's push protection did **not** flag the
  same push — it verifies known live-token formats with providers, not random
  high-entropy strings. The two layers catch different things; keep both.
- **No verification.** gitleaks cannot tell a live key from a revoked one.
  That is what TruffleHog-class tools add, at the cost of network calls — a CI
  concern, tracked in the toolkit's `TODO.md`.

## False positives

Three mechanisms, all committed and reviewable, in order of preference:

| Mechanism | Use when |
|---|---|
| `# gitleaks:allow` on the line | a specific known-safe value, e.g. a documented example key |
| fingerprint in `.gitleaksignore` | a finding in history you have judged safe — the scan output prints the fingerprint |
| `.gitleaks.toml` at the repo root | a rule needs tuning repo-wide; extends the defaults via `[extend]` |

Never widen a rule to make the hook quiet. If it is noisy on a real repo, the
first question is whether the thing it found should be in the repo at all.

## When a repository needs more than one check

The `pre-commit` framework (installed: `uv tool install pre-commit`) manages
several hooks with per-path filtering and pinned versions — `terraform fmt`
for `infrastructure/`, prettier for `ui/`, and so on. It is the right tool the
moment a repository needs a second check, and the wrong one before.

It installs into `.git/hooks/`, which the global `core.hooksPath` makes git
ignore — `pre-commit install` refuses outright when it sees that setting. The
migration is two steps, done **in that repository**:

    git config core.hooksPath .git/hooks       # local overrides global
    pre-commit install                          # now permitted

and `.pre-commit-config.yaml` must include gitleaks itself, since the global
hook no longer applies there:

    repos:
      - repo: https://github.com/gitleaks/gitleaks
        rev: v8.30.1
        hooks:
          - id: gitleaks

Not doing this leaves the repository with no secret scan at all. Make the
migration explicit rather than discovering the refusal message cold.

## CI

Deferred — see the toolkit `TODO.md`. The local hook is the gate on this
machine; CI is the gate for everyone else's.
