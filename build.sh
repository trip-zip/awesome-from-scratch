#!/usr/bin/env bash
# Regenerate the 13 Awesome From Scratch checkpoint branches from main.
#
# Each chapter tree is assembled from:
#   1. exact slices of main            (chapters/<ch>/manifest: git pathspecs)
#   2. per-chapter file variants       (chapters/<ch>/overlay.map: lines of
#                                       "<dest-path>\t<file in variants/>")
#   3. a generated README stub         (README-template.md; ch 12 ships main's)
# and committed as exactly one commit on top of the previous chapter.
#
# Variants live once in variants/ and are shared by every chapter that maps
# them, so editing one file updates every checkpoint that carries it.
#
# Commit dates are pinned so an unchanged input tree produces identical SHAs
# (re-running is idempotent: no gratuitous force-pushes).
#
# Run from anywhere inside the repo, with the ladder-build branch checked out
# in the worktree that holds this script:
#   ./build.sh [source-ref]        # default source-ref: main

set -euo pipefail

src_ref=${1:-main}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
repo=${repo%/.git}

# Pinned base date; each chapter gets +1 minute so the chain is ordered.
base_epoch=$(date -d "2026-08-09 12:00:00 -0600" +%s)

wt=$(mktemp -d)
trap 'git -C "$repo" worktree remove --force "$wt" 2>/dev/null || true; rm -rf "$wt"' EXIT
git -C "$repo" worktree add --detach "$wt" "$src_ref" >/dev/null

mapfile -t rows < "$here/chapters.tsv"
total=$(( ${#rows[@]} ))

prev_commit=""
i=0
for row in "${rows[@]}"; do
  branch=${row%%$'\t'*}
  title=${row#*$'\t'}
  nn=${branch%%-*}
  chdir="$here/chapters/$branch"

  # Start from an empty tree
  find "$wt" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

  # 1. Slices of main
  if [ -s "$chdir/manifest" ]; then
    # shellcheck disable=SC2046
    git -C "$repo" archive "$src_ref" -- $(grep -v '^#' "$chdir/manifest") | tar -x -C "$wt"
  fi

  # 2. Variants
  if [ -s "$chdir/overlay.map" ]; then
    while IFS=$'\t' read -r dest src; do
      case "$dest" in \#*|"") continue ;; esac
      mkdir -p "$wt/$(dirname "$dest")"
      cp "$here/variants/$src" "$wt/$dest"
    done < "$chdir/overlay.map"
  fi

  # 3. README stub (unless the manifest/overlay already provided one)
  if [ ! -f "$wt/README.md" ]; then
    prev_branch=""
    next_branch=""
    [ "$i" -gt 0 ] && prev_branch=$(printf '%s' "${rows[$((i - 1))]}" | cut -f1)
    [ "$i" -lt $((total - 1)) ] && next_branch=$(printf '%s' "${rows[$((i + 1))]}" | cut -f1)

    nav=""
    [ -n "$prev_branch" ] && nav="Previous: [\`$prev_branch\`](../../tree/$prev_branch)  "
    if [ -n "$next_branch" ]; then
      nav="$nav
Next: [\`$next_branch\`](../../tree/$next_branch)"
    fi

    sed -e "s/{{BRANCH}}/$branch/g" \
        -e "s/{{NN}}/$((10#$nn))/g" \
        -e "s/{{TITLE}}/$(printf '%s' "${title#*: }" | sed 's/[&/\]/\\&/g')/g" \
        -e "s|{{NAV}}|$(printf '%s' "$nav" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')|" \
        "$here/README-template.md" > "$wt/README.md"
    # sed can't emit newlines portably from the substitution; fix the marker
    perl -0pi -e 's/\\n/\n/g' "$wt/README.md"
  fi

  # Commit
  git -C "$wt" add -A
  tree=$(git -C "$wt" write-tree)
  date_str="@$((base_epoch + i * 60)) -0600"
  if [ -z "$prev_commit" ]; then
    commit=$(GIT_AUTHOR_DATE="$date_str" GIT_COMMITTER_DATE="$date_str" \
      git -C "$wt" commit-tree "$tree" -m "$title")
  else
    commit=$(GIT_AUTHOR_DATE="$date_str" GIT_COMMITTER_DATE="$date_str" \
      git -C "$wt" commit-tree "$tree" -p "$prev_commit" -m "$title")
  fi
  git -C "$repo" branch -f "$branch" "$commit"
  echo "$branch -> $commit"

  prev_commit=$commit
  i=$((i + 1))
done

echo
echo "Done. Verify with ./verify.sh"
