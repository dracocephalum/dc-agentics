# Land the payload

Stage 1 of [`initialize.md`](initialize.md): confirm what is at the target, check the
shipped baselines for drift, then copy. Nothing here edits an existing file;
the stages after this one do.

## 1. Preconditions

List which of the target files already exist. **Do not overwrite anything
without saying so first** — an existing `Directory.Build.props` very likely
carries settings that matter.

If one exists, merge into it rather than replacing: add the `Import` line to the
existing file, keep its current properties.

Note whether the path is a git repository. **If it is not, run
`git init -b main`** — everything after this stage assumes one, and the build
stamp, the ruleset and the first push each depend on it existing. **Never
create a commit**: the payload is left in the working tree for the user to
review and commit themselves.

**Pass `-b main` explicitly.** A machine with no `init.defaultBranch` set
still creates `master`, and the default branch is named `main` throughout —
`.github/rulesets/protect-main.json`, the ruleset command in
[`settings.md`](settings.md), and the `--base main` in the change-tracking
rules. Renaming afterwards works, but only if someone notices; nothing later
in the procedure fails loudly on the wrong name.

## 2. Baseline drift check

Three of the files we ship were forked from `dotnet new` templates. Each carries
a marker naming the SDK it was captured from and the SHA-256 of the pristine
generated file:

    # dc-agentics-baseline: source=<name> sdk=<version> sha256=<hash>

| File | Marker lives in |
|---|---|
| `.editorconfig` | `payload/.editorconfig` |
| `.gitignore` | `payload/.gitignore` |
| `.gitattributes` | `payload/.gitattributes` |

Regenerate each into a scratch directory and compare:

    dotnet new <name> -o <scratch>
    tr -d '\r' < <scratch>/<file> | sha256sum       # macOS: shasum -a 256   FreeBSD: sha256

**Hash the newline-normalized bytes, never the raw file.** `dotnet new` emits
CRLF, while `* text=auto` checks out LF on other platforms — a raw hash
false-positives on every non-Windows machine.

**On a mismatch, stop and ask.** Do not regenerate, do not merge, do not
silently proceed. Report which file drifted, the recorded SDK version versus the
current one, and let the user decide whether to continue with our version or
pause to re-baseline.

### Showing what changed

Each forked file has a pristine counterpart under [`baselines/`](baselines) —
the generated template exactly as captured, newlines normalized to LF, at the
path it mirrors in `payload/`. They live outside `payload/` precisely so that
the copy needs no pruning afterwards:

    baselines/.editorconfig.original
    baselines/.gitignore.original
    baselines/.gitattributes.original

They hash **directly** to the marker value, with no further normalization:

    sha256sum < baselines/.editorconfig.original

When drift fires and the user asks what changed, diff the freshly generated
template against the original. That isolates the upstream change on its own:

    diff <scratch>/.editorconfig baselines/.editorconfig.original

Diffing against *our* version instead is not equivalent — it mixes the upstream
change with our own edits, which is exactly what makes such a diff unreadable.

From there the user can apply the upstream change by hand, and re-baseline by
replacing the file under `baselines/` and updating the marker's `sdk=` and
`sha256=` fields.

**Never edit a baseline.** They carry no header explaining this, because adding
one would change their bytes and break the hash they exist to verify. Keep the
`.original` suffix too: under its real name, a pristine `.gitattributes`,
`.gitignore` or `.editorconfig` would be read as live configuration for
`baselines/` — including the `* text=auto` that the root's
`repo/baselines/** -text` rule exists to override.

A mismatch is not automatically a problem. It matters most for `.editorconfig`,
whose reconciliation depends on the generated content — an upstream change can
make our edits redundant or leave a new conflict uncovered. For `.gitignore` and
`.gitattributes` our changes are purely additive, so drift is informational.

If the recorded SDK equals the installed SDK and the hash still differs,
something is wrong with the file, not the template. Say so rather than guessing.

## 3. Copy

`payload/` is an exact mirror of a target repository root — everything in it is
copied, and nothing has to be removed afterwards — so the copy is one command,
plus `.claude/skills/` from the toolkit root. The target has no `.claude/` yet,
so create it before copying into it:

    cp -r payload/. <target>/
    mkdir -p <target>/.claude
    cp -r .claude/skills <target>/.claude/

Everything from here on is what to *verify* or *edit* in what just landed:
the build files ([`build.md`](build.md)), then the documents, settings, and
verification. The templates under `docs/templates/` become `AGENTS.md` and
`README.md` in
[`documents.md`](documents.md); strict mode edits three files in
[`build.md`](build.md).
