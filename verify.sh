#!/usr/bin/env bash
# Structural checks for the regenerated checkpoint ladder.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
repo=${repo%/.git}
cd "$repo"

fail=0
err() { echo "FAIL: $*"; fail=1; }

mapfile -t rows < "$here/chapters.tsv"
branches=()
for row in "${rows[@]}"; do branches+=("${row%%$'\t'*}"); done

# 1. Orphan root, strict parent chain, commit counts
[ -z "$(git rev-parse --verify --quiet "${branches[0]}^" 2>/dev/null)" ] \
  || err "${branches[0]} is not an orphan root"

prev=${branches[0]}
i=1
for ch in "${branches[@]:1}"; do
  [ "$(git rev-parse "$ch^")" = "$(git rev-parse "$prev")" ] \
    || err "$ch's parent is not $prev"
  count=$(git rev-list --count "$ch")
  [ "$count" = "$((i + 1))" ] || err "$ch has $count commits, expected $((i + 1))"
  prev=$ch
  i=$((i + 1))
done

# 2. The last checkpoint's tree is main's tree
[ "$(git rev-parse 'main^{tree}')" = "$(git rev-parse "${branches[12]}^{tree}")" ] \
  || err "${branches[12]} tree differs from main"

# 3. Every non-variant, non-generated file is byte-identical to main
for row in "${rows[@]}"; do
  ch=${row%%$'\t'*}
  chdir="$here/chapters/$ch"
  [ -s "$chdir/manifest" ] || continue
  variant_dests=""
  [ -s "$chdir/overlay.map" ] && variant_dests=$(cut -f1 "$chdir/overlay.map")
  while IFS= read -r spec; do
    case "$spec" in \#*|"") continue ;; esac
    for f in $(git ls-tree -r --name-only "$ch" -- "$spec"); do
      if printf '%s\n' "$variant_dests" | grep -qxF "$f"; then
        continue # variant files are allowed to differ
      fi
      if ! git diff --quiet "$ch" main -- "$f"; then
        err "$ch: $f differs from main but is not a variant"
      fi
    done
  done < "$chdir/manifest"
done

# 4. Grep gates on every chapter (source hygiene)
for ch in "${branches[@]}"; do
  git grep -qE 'JetBrainsMono' "$ch" -- '*.lua' ':!theme/theme.lua' 2>/dev/null \
    && err "$ch: hardcoded font outside theme.lua"
  git grep -qE ' or "#[0-9a-fA-F]' "$ch" -- '*.lua' 2>/dev/null \
    && err "$ch: hex color fallback"
  git grep -qE 'naughty\.notify\(|io\.popen|swaylock|hyprlock|i3lock|c3po|/home/jimmy' "$ch" -- '*.lua' 2>/dev/null \
    && err "$ch: forbidden pattern"
done

if [ "$fail" = 0 ]; then
  echo "All structural checks passed."
else
  exit 1
fi
