# Land the payload

Stage 1 of [`README.md`](README.md): confirm what is at the target, check the
shipped baselines for drift, then copy. Nothing here edits a file; the stages
after this one do.

## 1. Preconditions

List which of the target files already exist. **Do not overwrite anything
without saying so first** — an existing `Directory.Build.props` very likely
carries settings that matter.

If one exists, merge into it rather than replacing: add the `Import` line to the
existing file, keep its current properties.

Note whether the path is a git repository. Do not run `git init` unless asked.

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

Each forked file has a pristine `.original` sibling — the generated template
exactly as captured, with newlines normalized to LF:

    payload/.editorconfig.original
    payload/.gitignore.original
    payload/.gitattributes.original

They hash **directly** to the marker value, with no further normalization:

    sha256sum < payload/.editorconfig.original

When drift fires and the user asks what changed, diff the freshly generated
template against the original. That isolates the upstream change on its own:

    diff <scratch>/.editorconfig payload/.editorconfig.original

Diffing against *our* version instead is not equivalent — it mixes the upstream
change with our own edits, which is exactly what makes such a diff unreadable.

From there the user can apply the upstream change by hand, and re-baseline by
replacing the `.original` and updating the marker's `sdk=` and `sha256=` fields.

**Never edit an `.original` file.** They carry no header explaining this, because
adding one would change their bytes and break the hash they exist to verify.

A mismatch is not automatically a problem. It matters most for `.editorconfig`,
whose reconciliation depends on the generated content — an upstream change can
make our edits redundant or leave a new conflict uncovered. For `.gitignore` and
`.gitattributes` our changes are purely additive, so drift is informational.

If the recorded SDK equals the installed SDK and the hash still differs,
something is wrong with the file, not the template. Say so rather than guessing.

## 3. Copy

`payload/` is an exact mirror of a target repository root, so the copy is one
command, plus `.claude/skills/` from the toolkit root:

    cp -r payload/. <target>/
    find <target> -name '*.original' -delete

Everything from here on is what to *verify* or *edit* in what just landed:
the build files ([`build.md`](build.md)), then the documents, settings, and
verification. `AGENTS.template.md` becomes `AGENTS.md` in
[`documents.md`](documents.md); strict mode edits three files in
[`build.md`](build.md).
