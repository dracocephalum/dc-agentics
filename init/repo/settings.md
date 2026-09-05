# Host settings, licence, and the settings file

Stage 4 of [`README.md`](README.md): the choices that live outside the build
— merge behaviour on the host, the licence, and the settings file that
records every choice made so far. Fill the settings file last.

## 1. Merge settings — when the repository is on GitHub

If a GitHub remote exists (or once it does), apply the merge behaviour the
pull-request rules assume — squash only, delete the branch on merge — and,
after the first push, the default-branch ruleset:

    gh repo edit --delete-branch-on-merge --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
    gh api -X PATCH repos/<owner>/<name> -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY
    gh api repos/<owner>/<name>/rulesets --input .github/rulesets/protect-main.json

The ruleset is refused on a private repository under GitHub Free; that is the
user's choice to make (Pro, public, or none), not a step to skip silently —
it goes under *Decisions pending* in the target's `TODO.md` with the three
options and the command to run once one is taken.

Details and the verification query are in
[`payload/docs/rules/source-control/github.md`](payload/docs/rules/source-control/github.md).
If there is no remote yet, skip, say so, and add an *Initialization* entry to
`TODO.md` naming the three commands; `/source-control setup` runs them later.

## 2. Licence — default `none`, never assumed

A repository with no `LICENSE` file is all rights reserved, which is the
normal state of a private company repository; a repository meant to be shared
gets one. Unless the request names a licence, apply `none`: record it in
`.dc-agentics.yaml`, add *Choose a licence* under *Decisions pending* in the
target's `TODO.md` with the two options below, and flag it in the closing
summary. When the user has chosen, two things are needed:

1. **Which licence.** `Apache-2.0` (patent grant, trademark clause,
   contribution terms — the default for anything shared) or `MIT` (shorter;
   attribution only). Anything else is the user's own choice, fetched the
   same way.
2. **The copyright holder** — the legal owner of the work: the person's name,
   or the company when the work is made for it. A GitHub handle is acceptable
   for a personal project; a legal name is what a notice is for. Never guess,
   and never take it from the git identity.

Then, at the target root:

    gh api licenses/apache-2.0 --jq .body > LICENSE      # verbatim text; or licenses/mit

MIT carries `[year]` and `[fullname]` placeholders — fill both. The Apache
text names nobody; put `Copyright <year> <holder>` in a `NOTICE` file beside
it. Fill the *Licence* section of the generated `README.md`, or delete it when
the answer was `none`. Nothing from the toolkit needs a notice in the target:
the payload is offered under 0BSD.

Verify: `gh repo view --json licenseInfo` reports the chosen licence once the
file is on the default branch — GitHub detects it from the verbatim text, so
an edited Apache text shows as *Other*.

## 3. Settings file and TODO

`.dc-agentics.yaml` and `TODO.md` arrive with the payload copy. The settings
file is what agents read before any source-control action and what a future
update of the repository diffs from; every choice made above is recorded in
it, so fill it last, when the choices are final.

Fill every quoted double-brace placeholder in `.dc-agentics.yaml`; the
unquoted values are defaults, already correct unless a step above changed
them (`stylecop`, `central-package-management`, `source-control.mode`). Three
values are the agent's own and must not be guessed: the tool it runs in
(`Claude Code`), the model identifier (`claude-fable-5-1` form), and the
toolkit commit — `git -C <toolkit> rev-parse --short=12 HEAD`, with `-dirty`
appended when `git -C <toolkit> status --porcelain` prints anything. `initialized`
is today, `yyyy-mm-dd`.

`source-control.mode` is `local` unless the user asked for another; the
three modes are defined in
[`source-control.md`](payload/docs/rules/source-control/source-control.md),
*For an agent*.

`change-tracking` stays at its defaults — GitHub Issues, no board — unless the
user asked for a board; a board needs the extra scopes in the tracker file,
and the choice is recorded here, not asked. The initialization itself has no
ticket: the tracker exists only once the repository does, and
[`change-tracking.md`](payload/docs/rules/change-tracking/change-tracking.md)
states that as the one exception.

Then `TODO.md`: by now the earlier stages have added their entries — a skipped
Serena config, a refused or not-yet-applicable ruleset, the licence decision.
Anything else that was not finished, could not be verified, or was left for
a person goes in the same way, each entry with what would close it. Remove
an empty section; keep the file even when both are empty, because it is
where every later agent puts what it leaves open.

Verify:

    grep -n "{{" <repo>/.dc-agentics.yaml                 # must return nothing
