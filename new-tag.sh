#!/bin/bash
# AI-Agents kit-owned file. Do not edit: `governancekit install-agents --upgrade` replaces it.
# Project-specific rules  -> docs/project-rules.md (never overwritten)
# Operator values ({{…}}) -> .gk/operator.json (untracked; written by `governancekit install-agents`)
# Fail-closed. Without this the script used to sail past a failed `git tag` and still
# push main, exiting 0 — so a release could report success while the tag either did not
# exist or pointed at an older commit than the one just pushed.
set -euo pipefail

if [[ -z "${1:-}" || "$1" == "--force" || "$1" == "-f" ]]; then
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
# Written as an if, not `[[ ... ]] && force=true`: under `set -e` that form aborts the
# script whenever the test is false, which is the common case.
if [[ "${2:-}" == "--force" || "${2:-}" == "-f" ]]; then
  force=true
fi

# Refuse to re-release an existing tag. Moving a published tag would silently change
# what a pinned installer downloads; cutting the next patch version is the safe move.
if git rev-parse -q --verify "refs/tags/$NEXT_TAG" >/dev/null; then
  echo "ERROR: tag $NEXT_TAG already exists (points at $(git log -1 --format=%h "$NEXT_TAG"))." >&2
  echo "       Releases are immutable — cut the next version instead of moving it." >&2
  exit 3
fi

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

