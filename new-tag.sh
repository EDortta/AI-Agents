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

# There is no test suite wired into this repo yet (no run-checks.sh). Until
# one exists, --force is a no-op and tagging always proceeds — it used to
# look like a test gate but never actually ran anything (r=$? was reading
# the exit status of the `if ! $force` check itself, always 0).
if [[ -f "scripts/run-checks.sh" ]]; then
  if ! $force; then
    bash scripts/run-checks.sh
    r=$?
    if [ $r -ne 0 ]; then
      echo "Tests failed. Aborting"
      exit 1
    fi
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

