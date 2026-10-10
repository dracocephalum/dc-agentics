#!/bin/sh
# Sync a target repository to this toolkit: replace what the toolkit owns, regenerate
# the guidelines block in AGENTS.md, record the commit, verify, and report the rest.
# repo/upgrade.md, operation 2, is the procedure; this is its mechanism. POSIX sh and
# awk only, so it runs wherever git does. It never commits.
#
#   sh repo/sync.sh --plan <target>    report what changed and what would be done; nothing is touched
#   sh repo/sync.sh --apply <target>   apply, then verify
#   sh repo/sync.sh                    this help

set -eu

usage() { sed -n 's/^#   \(sh repo\/sync.sh.*\)$/  \1/p' "$0" >&2; exit 2; }
case "${1-}" in
  --plan) plan=1 ;;
  --apply) plan=0 ;;
  *) usage ;;
esac
[ $# -eq 2 ] || usage
shift
refuse() { echo "sync: $*" >&2; exit 1; }
target=$(cd "$1" 2> /dev/null && pwd) || refuse "$1 is not a directory"
toolkit=$(cd "$(dirname "$0")/.." && pwd)
payload=$toolkit/repo/payload
open='<!-- agentics:guidelines -->'
close='<!-- /agentics:guidelines -->'

say() { echo "$*"; }
# The line ending a file already uses, as an awk ORS value - a rewrite keeps it. Counted
# with tr, as the scrub does: grep on Windows drops the CR before matching and never sees it.
endings() { if [ "$(tr -dc '\r' < "$1" | wc -c | tr -d ' ')" -gt 0 ]; then printf '\\r\\n'; else printf '\\n'; fi; }
# Rewrite $1 in place through the awk program $2, keeping its line endings.
rewrite() {
  f=$1; prog=$2; shift 2
  awk -v ORS="$(endings "$f")" "$@" "{ sub(/\r\$/, \"\") } $prog" "$f" > "$f.sync~" && mv "$f.sync~" "$f"
}
# Items of the list rules.<$2> in the settings file $1, one per line; block or inline form.
# A settings file from before the block existed falls back to the payload's defaults.
yaml_list() {
  grep -q '^rules:' "$1" || set -- "$payload/.agentics.yaml" "$2"
  awk -v key="$2" '
    { sub(/\r$/, "") }
    /^[A-Za-z]/ { intop = ($0 ~ /^rules:/); insub = 0 }
    intop && $0 ~ "^  " key ":" {
      insub = 1; rest = $0; sub(/^[^:]*:[ \t]*/, "", rest); sub(/[ \t]*#.*$/, "", rest)
      if (rest ~ /^\[/) { gsub(/[][ "]/, "", rest); n = split(rest, a, ","); for (i = 1; i <= n; i++) if (a[i] != "") print a[i]; insub = 0 }
      next
    }
    intop && insub && /^    - / { v = $0; sub(/^    - */, "", v); sub(/[ \t]*#.*$/, "", v); gsub(/"/, "", v); if (v != "") print v; next }
    intop && /^  [A-Za-z]/ { insub = 0 }
  ' "$1"
}

# --- refuse early, with the one reason ------------------------------------------------
[ "$target" != "$toolkit" ] || refuse "the target is this toolkit checkout; a sync runs against a repository the toolkit initialized"
[ ! -d "$target/repo/payload" ] || refuse "$target is a toolkit checkout, not a target"
git -C "$target" rev-parse --git-dir > /dev/null 2>&1 || refuse "$target is not a git repository"
[ -f "$target/.agentics.yaml" ] || refuse "no .agentics.yaml at $target: not an initialized repository"
[ -z "$(git -C "$target" status --porcelain)" ] || refuse "the target tree is not clean; commit or stash first - the diff must be the sync alone"
grep -q "^$open" "$target/AGENTS.md" 2> /dev/null && grep -q "^$close" "$target/AGENTS.md" \
  || refuse "AGENTS.md has no guidelines block; adopt it once by hand - repo/upgrade.md, 'Adopting the block'"
template=$payload/agentics/templates/AGENTS.template.md
if awk -v o="$open" -v c="$close" '{ sub(/\r$/, "") } $0 == o { f = 1; next } $0 == c { f = 0 } f' "$template" | grep -q '{{'; then
  refuse "the template's guidelines block carries a placeholder; the toolkit is at fault, not the target"
fi

recorded=$(awk '{ sub(/\r$/, "") } /^  commit:/ { gsub(/"/, ""); print $2; exit }' "$target/.agentics.yaml")
base=${recorded%-dirty}
head=$(git -C "$toolkit" rev-parse --short=12 HEAD)
[ -z "$(git -C "$toolkit" status --porcelain)" ] || head="$head-dirty"
say "== sync $target: $recorded -> $head"
[ "$head" = "${head%-dirty}" ] || say "the toolkit checkout is not clean; the recorded commit will say so"

# --- what changed, for the pull request ------------------------------------------------
if git -C "$toolkit" cat-file -e "$base" 2> /dev/null; then
  say "== toolkit changes since $recorded"
  git -C "$toolkit" log --oneline "$base..HEAD" -- repo/payload .claude/skills
  say "== payload files outside agentics/ that changed - yours to apply by intent (repo/upgrade.md, 'The rest of the payload')"
  git -C "$toolkit" diff --name-status "$base..HEAD" -- repo/payload | grep -v 'repo/payload/agentics/' | sed 's|repo/payload/||' || true
  old_skills=$(git -C "$toolkit" ls-tree --name-only "$base:.claude/skills" 2> /dev/null || true)
else
  say "== the recorded commit $recorded does not resolve in this checkout (a squashed branch, or shallow); no change list"
  say "   shims the toolkit has since renamed or dropped stay in the target - compare .claude/skills by hand"
  old_skills=
fi
new_skills=$(ls "$toolkit/.claude/skills")

# --- replace what the toolkit owns -----------------------------------------------------
excluded=$(yaml_list "$target/.agentics.yaml" excluded)
local_dirs=$(yaml_list "$target/.agentics.yaml" local)
if [ $plan = 1 ]; then
  say "== plan: replace agentics/ and the toolkit's shims ($(echo $new_skills | tr ' ' ','))"
  [ -z "$excluded" ] || say "== plan: exclude $(echo $excluded | tr ' ' ',')"
  say "== plan: regenerate the guidelines block from the template and the indexes in: ${local_dirs:-none}"
else
  rm -rf "$target/agentics"
  cp -R "$payload/agentics" "$target/agentics"
  mkdir -p "$target/.claude/skills"
  for s in $old_skills $new_skills; do rm -rf "$target/.claude/skills/$s"; done
  cp -R "$toolkit/.claude/skills/." "$target/.claude/skills/"
  say "== replaced agentics/ and the toolkit's shims"
  for p in $excluded; do
    if [ -f "$target/agentics/rules/$p" ]; then rm -f "$target/agentics/rules/$p"; say "excluded: agentics/rules/$p"
    else say "rules.excluded names a path the payload does not have: $p - remove it from the list"; fi
  done
fi

# --- the guidelines block --------------------------------------------------------------
block=$target/.sync-block~
awk -v o="$open" -v c="$close" '{ sub(/\r$/, "") } $0 == o { f = 1; next } $0 == c { f = 0 } f' "$template" > "$block"
for p in $excluded; do
  grep -v -F "(agentics/rules/$p)" "$block" > "$block.x" && mv "$block.x" "$block" || true
done
rows=$target/.sync-rows~
: > "$rows"
for d in $local_dirs; do
  if [ -f "$target/$d/AGENTS.md" ]; then
    awk '{ sub(/\r$/, "") } /^\|[ ]*-+/ { f = 1; next } f && /^\| / { print }' "$target/$d/AGENTS.md" >> "$rows"
  else
    say "no local rules: $d/AGENTS.md does not exist (the first one starts from agentics/templates/rules-AGENTS.md)"
  fi
done
# Local rows go after the last table row of the block, before its closing paragraphs.
awk -v rows="$rows" '
  { lines[NR] = $0; if ($0 ~ /^\| /) last = NR }
  END {
    for (i = 1; i <= NR; i++) {
      print lines[i]
      if (i == last) while ((getline l < rows) > 0) print l
    }
  }' "$block" > "$block.x" && mv "$block.x" "$block"
# Two rows with one trigger compete, and nothing decides between them: exclude and replace instead.
awk -F'|' '/^\| / { t = $2; gsub(/^ +| +$/, "", t); print t }' "$block" | sort | uniq -d | while read -r t; do
  say "trigger stated twice: '$t' - a local row competes with a toolkit row; exclude the toolkit rule and replace it, or change the trigger"
done
if [ $plan = 1 ]; then
  say "== plan: the block would hold $(grep -c '^| ' "$block") rows, $(wc -l < "$rows" | tr -d ' ') of them local"
else
  rewrite "$target/AGENTS.md" '
    $0 == o { print; while ((getline l < blk) > 0) { sub(/\r$/, "", l); print l } close(blk); skip = 1; next }
    $0 == c { skip = 0 }
    !skip { print }' -v o="$open" -v c="$close" -v blk="$block"
  say "== regenerated the guidelines block: $(grep -c '^| ' "$block") rows, $(wc -l < "$rows" | tr -d ' ') of them local"
fi
rm -f "$block" "$rows"

# --- settings ---------------------------------------------------------------------------
settings=$target/.agentics.yaml
if [ $plan = 1 ]; then
  say "== plan: toolkit.commit -> $head"
else
  rewrite "$settings" '/^  commit:/ { sub(/"[^"]*"/, "\"" c "\"") } { print }' -v c="$head"
  say "== toolkit.commit -> $head"
fi
payload_keys=$(awk '{ sub(/\r$/, "") } /^[a-z][a-z-]*:/ { sub(/:.*/, ""); print }' "$payload/.agentics.yaml")
target_keys=$(awk '{ sub(/\r$/, "") } /^[a-z][a-z-]*:/ { sub(/:.*/, ""); print }' "$settings")
for k in $payload_keys; do
  echo "$target_keys" | grep -qx "$k" && continue
  if [ $plan = 1 ]; then say "== plan: append the settings block '$k:' with its defaults"; continue; fi
  # One blank line before the block; the block's own trailing blank lines dropped, or the file ends with two.
  { printf '%s' "$(printf "$(endings "$settings")")"
    awk -v k="$k" -v ORS="$(endings "$settings")" '
      { sub(/\r$/, "") }
      /^[a-z]/ { f = ($0 ~ "^" k ":") }
      f { n++; lines[n] = $0 }
      END { while (n > 0 && lines[n] == "") n--; for (i = 1; i <= n; i++) print lines[i] }' "$payload/.agentics.yaml"
  } >> "$settings"
  say "== appended the settings block '$k:' with its defaults - review the values"
done
for k in $target_keys; do
  echo "$payload_keys" | grep -qx "$k" || say "settings: the payload no longer defines '$k:' - nothing reads it; remove the block"
done
[ $plan = 0 ] || { say "== plan only; nothing was changed"; exit 0; }

# --- verify -------------------------------------------------------------------------------
say "== verify"
if command -v npx > /dev/null 2>&1; then
  (cd "$target" && npx --yes markdownlint-cli2@0.23.2 "**/*.md" "#node_modules" "#**/bin/**" "#**/obj/**" 2>&1 | grep -E '^(Linting|Summary):' || true)
else
  say "markdownlint skipped: npx is not on PATH"
fi
# The scrub's link check; a local index links relative to the root, where its rows land.
unresolved=$(cd "$target" && find . -name '*.md' -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/bin/*' -not -path '*/obj/*' -not -path './agentics/templates/*' | while read -r f; do
  from=$(dirname "$f")
  for d in $local_dirs; do [ "$f" = "./$d/AGENTS.md" ] && from=.; done
  sed -e 's/^    .*$//' -e 's/`[^`]*`//g' "$f" | grep -oE '\]\([^)#][^)]*\)' | sed 's/^](//;s/)$//' | while read -r l; do
    case "$l" in http*|mailto*) continue ;; esac
    [ -e "$from/${l%%#*}" ] || echo "$f -> $l"
  done
done)
if [ -n "$unresolved" ]; then say "unresolved links:"; echo "$unresolved"; else say "links: all resolve"; fi
say "== done: review 'git -C $target status' and the diff, then commit under the target's source-control.mode"
