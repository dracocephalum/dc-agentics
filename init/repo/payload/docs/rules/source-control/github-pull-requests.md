# Pull requests on GitHub

Applies when publishing a repository for the first time, creating a branch,
writing commits, or opening, updating, or merging a pull request. GitHub only,
for now.

The standard, borrowed from Google's engineering practices: a change should be
**small, described so a stranger understands what and why, and verified before
anyone else spends time on it.**

## Publishing a repository — the first push

Applies when a local repository has no remote yet. GitHub does **not**
push-to-create: a push to a name that does not exist fails with `Repository
not found`. The remote must exist first — and `gh` can create it from the
local tree in one step, which is also the order that avoids the classic
first-push snag (a remote initialized with a README has a commit the local
history lacks, and the push is rejected).

1. **Locally, before anything reaches GitHub:** `git init -b main`; identity
   and signing configured; the secret scan clean over the tree and, once
   committed, over the history (`gitleaks dir .`, then `gitleaks git .`); at
   least one commit on `main` — a pull request needs a base branch to exist,
   so the very first commit lands on `main` directly and everything after it
   goes through a pull request.
2. **Ask whether a remote already exists, and check rather than assume:**

       gh repo view <owner>/<name> --json isEmpty,defaultBranchRef,url

   - **Not found** → offer to create it. Same name as the local folder and
     private unless the user says otherwise:

         gh repo create <owner>/<name> --private --source . --remote origin --push

   - **Exists and empty** → add it as `origin` and push:

         git remote add origin git@github.com:<owner>/<name>.git
         git push -u origin main

   - **Exists with commits** → reconcile, never force-push. Fetch, show the
     user what is there, and with their confirmation rebase local `main` onto
     it — or merge with `--allow-unrelated-histories` when the two really are
     unrelated — then push.
3. **Check the remote URL.** `gh repo create --push` wires `origin` using the
   per-host protocol (`gh config get -h github.com git_protocol`), and a
   `gh auth refresh` can silently reset that to `https`. If the machine's transport is SSH (agent, signing, proxy
   config), the remote must be too:

       git remote get-url origin                 # want git@github.com:<owner>/<name>.git
       git remote set-url origin git@github.com:<owner>/<name>.git
       gh config set -h github.com git_protocol ssh   # the per-host value is the one gh uses; check with gh auth status

4. **Apply the merge settings** (`gh repo edit …`, see
   [`../change-tracking/github.md`](../change-tracking/github.md)) and verify
   the first commit reports `verified: true`.

## Guardrails an agent must not skip

State can be lost between steps — a long session, a compaction, a model
switch. These checks cost nothing and catch the failure that follows:

- **Confirm the branch before every commit.** `git branch --show-current`
  must equal the branch you intend. A commit on the wrong branch is the most
  common way a change ends up orphaned; verify, do not assume.
- **Never run a side-effecting command to "diagnose".** `gh issue develop`,
  `git checkout -b`, `git switch -c`, `git commit`, `git push` all change
  state. To inspect, use read-only commands (`git status`, `git branch -vv`,
  `git log`, `gh ... view`). A command run to investigate a failure must not
  be able to cause a new one.
- **After any branch switch, verify what is under you** before working:
  `git log --oneline -3` should show the commits you expect. A branch that
  unexpectedly sits at the base commit means the switch did not carry your
  work.
- **When recovering, inspect before you act.** `git branch -vv` and
  `git log --graph --all` first; understand the divergence, then fix it. Bring
  files across with `git checkout <branch> -- <path>` only after confirming
  what that overwrites — it silently replaces the whole file.

## Branches

- Every branch starts from a ticket — see
  [`../change-tracking/github.md`](../change-tracking/github.md). Name it
  `<ticket>-<kebab-topic>`, e.g. `123-billing-retry`, created with
  `gh issue develop` so the issue links to it. The change type lives in the
  commits, not the branch name.
- Branch from the default branch. Short-lived: a branch older than a few days
  is a sign the change is too large — split it.
- Never commit directly to the default branch.

## Commits

Conventional Commits, so history is scannable and release notes can be
generated:

    <type>(<scope>): <imperative summary, ≤ 72 chars>

    <why, not what - the diff shows what>

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`,
`perf`. `!` after the type marks a breaking change. The first line is a
sentence a future developer reads in `git log --oneline` — "Fix bug" and "WIP"
are not summaries.

Commits are signed (the machine setup enforces this) and contain no secrets
(the pre-commit hook enforces this). A commit that fails either is not fixed
by `--no-verify`.

## Size

One concern per pull request. As a guide, **under ~400 changed lines** of
non-generated code; a reviewer's attention drops sharply past that and defects
get through. If a change needs more, split it into a sequence — refactor
first, behaviour second — and open them as separate, dependent PRs.

## Opening

Before `gh pr create`:

1. `dotnet build` and `dotnet test` green — the reviewer should never be the
   one to discover a red build.
2. The licence check passes (`docs/rules/dependencies.md`) if any package
   changed.
3. Read your own diff top to bottom as a reviewer would. Remove debug code,
   stray files, unrelated formatting.
4. The description still matches the code — descriptions written at the
   start of a change drift by the end.

Then:

- **Title** is `#<ticket> <type>(<scope>): <summary>` — ticket first, then
  the conventional summary, because squash-merge makes it the commit message.
- **Body** follows `.github/PULL_REQUEST_TEMPLATE.md` (GitHub fills it in):
  what, why, how it was verified, risks and rollback, links. `Closes #<n>`
  links and auto-closes the issue.
- **Draft** until it is ready for review — `gh pr create --draft`. A draft
  says "look if you like, do not spend review effort yet."
- Request reviewers explicitly; code owners are the default choice.

## During review

- Respond to every comment — a fix, a question, or a reasoned disagreement.
  Silently pushing a change without answering leaves the reviewer guessing.
- Push follow-up commits; do not rewrite history under a reviewer. Rebase
  only to resolve conflicts, with `--force-with-lease`, and say so in a
  comment.
- Resolve a conversation only when its point is addressed, not to clear the
  list.

## Merging

- **Squash, always**: one conventional commit per PR on the default branch,
  title as the message. Merge commits and rebase-merge are disabled at the
  repository level.
- **The branch is deleted on merge** — also a repository setting.
- Both are applied once with `gh repo edit`; see
  [`../change-tracking/github.md`](../change-tracking/github.md).
- The merge is the author's, after approval and green checks — not the
  reviewer's.

## For an agent

- Open PRs as **drafts** unless told otherwise, and never merge.
- Use `gh pr create --draft --title "<conventional>" --body-file <file>`
  with the body written to a file first; multi-line bodies on the command
  line get mangled.
- Do not force-push, rebase, or close a PR that has review activity without
  being asked.
- The commit and push must go through the signing and secret-scan setup as
  configured; if either fails, report it — do not bypass.
