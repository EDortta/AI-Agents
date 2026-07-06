#!/bin/bash

if [[ -z "$1" || "$1" == "--force" || "$1" == "-f" ]]; then
  git tag | sort -V | tail -n 5
  exit 0
fi

if [[ "$1" == "auto" ]]; then
  LAST_TAG=$(git tag | sort -V | tail -n 1)
  IFS='.' read -r a b c <<< "$LAST_TAG"
  NEXT_TAG="$a.$b.$((c+1))"
else
  NEXT_TAG="v$1"
fi

force=false
[[ "$2" == "--force" || "$2" == "-f" ]] && force=true

# Release gate (security-standards.md §7): tagging is gated by scripts/run-checks.sh.
# Fail-closed: a missing gate aborts instead of tagging silently. --force skips the
# gate but says so loudly and is never the default.
if $force; then
  echo "WARNING: --force given — skipping release gate (scripts/run-checks.sh). Not recommended."
elif [[ ! -f "scripts/run-checks.sh" ]]; then
  echo "Release gate missing: scripts/run-checks.sh not found. Aborting (use --force to override)."
  exit 1
else
  bash scripts/run-checks.sh
  r=$?
  if [ $r -ne 0 ]; then
    echo "Checks failed. Aborting."
    exit 1
  fi
fi

git tag -a "$NEXT_TAG" -m "Version $NEXT_TAG"

current_branch=$(git rev-parse --abbrev-ref HEAD)
remotes=$(git remote)
for remote in $remotes; do
  git pull "$remote" main
  echo "--------------------------------------------"
  echo "Pushing $current_branch + tags to remote: $remote"
  git push "$remote" "$current_branch" --follow-tags
done

