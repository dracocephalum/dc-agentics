# Optimizing dc-agentics itself

Applies when asked to optimize, compact or measure **this repository's**
documents. For a repository dc-agentics initialized, the shipped document is
the whole procedure.

**Start with the shipped document**,
[`payload/agentics/rules/optimize.md`](payload/agentics/rules/optimize.md). Three
adjustments, because this repository is where the documents every target
reads are written:

- **The payload is the product, and this is where it is compacted.** The
  shipped document sends a target here for the rule files, templates and
  shims. *Compact* applies to them in full, and its invariant matters more
  here than anywhere: a rule lost from the payload is lost from every
  repository at its next upgrade.
- **Defaults never touches the payload.** The payload is written for any
  agent, and trimming it against one model's habits would ship that coupling
  to every target. If it is tried at all it is tried on `machine/` and
  `repo/`, which are read by whatever agent the user runs here, so a mistake
  stays here. What it would take to re-test such a trim when the model moves
  is in [`PLAN.md`](../PLAN.md), *Re-testing a trim to a model's defaults*.
- **The always-loaded group is measured in lines as well as bytes**, below.

## Always-loaded documents stay within budget

`AGENTS.md` is read every session with no trigger to gate it, and so is each
shim's **name and description** — the shim body loads only when the skill is
invoked. Everything under `payload/agentics/rules/` is loaded on demand;
depth there is cheap until its trigger fires.

    wc -l AGENTS.md .claude/skills/*/SKILL.md | sort -n

`AGENTS.md` is the one to watch, since every row added to the task index is
paid for everywhere. Shims sit around 40 lines; one that has grown well past
that is usually carrying substance that belongs in the document it points at,
which is a clarity problem rather than a context one.

Report growth as a trend rather than a threshold: a shim that has doubled is a
finding, a shim at 44 lines is not.

The same applies to the template a target's `AGENTS.md` is made from,
`payload/agentics/templates/AGENTS.template.md`: a row added there is paid
for in every session of every target.
