# Source control on GitHub

The mechanics of [`source-control.md`](source-control.md) on GitHub:
publishing, pull requests, and the repository settings that enforce the merge
rules. Read the rules first; this file only says which commands. Tickets,
creating a branch from an issue, the MCP-or-`gh` choice, and the review
mechanics are in [`../change-tracking/github.md`](../change-tracking/github.md).

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
   `gh auth refresh` can silently reset that to `https`. If the machine's
   transport is SSH (agent, signing, proxy config), the remote must be too:

       git remote get-url origin                 # want git@github.com:<owner>/<name>.git
       git remote set-url origin git@github.com:<owner>/<name>.git
       gh config set -h github.com git_protocol ssh   # the per-host value is the one gh uses; check with gh auth status

4. **Apply the repository settings** below, and verify the first commit
   reports `verified: true`.

## Pull requests

| Step | Command |
|---|---|
| open, as a draft | `gh pr create --draft --title "#<ticket> <type>(<scope>): <summary>" --body-file <file>` |
| the body | from `.github/PULL_REQUEST_TEMPLATE.md`, written to a file, ending with `Closes #<ticket>` |
| update the description | `gh pr edit <n> --body-file <file>` |
| ready for review | `gh pr ready <n>`, then `gh pr edit <n> --add-reviewer <login>` |
| see it whole | `gh pr view <n> --json title,body,files,reviews,comments` |

The body always goes through a file; a multi-line `--body` on the command
line gets mangled. Merging is `gh pr merge --squash` — the author's action,
after approval and green checks, never an agent's.

## Repository settings — once, after the repository exists on GitHub

Two of the merge rules are repository settings, not habits:

    gh repo edit --delete-branch-on-merge --enable-squash-merge \
                 --enable-merge-commit=false --enable-rebase-merge=false

- **Squash is the only merge method.** One conventional commit per PR on the
  default branch, with the PR title as its message.
- **The source branch is deleted on merge.** Branches are scaffolding; the PR
  and the ticket are the record.

Apply this as part of repository initialization when a GitHub remote exists,
or the first time a pull request is opened. Verify:

    gh repo view --json deleteBranchOnMerge,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed
