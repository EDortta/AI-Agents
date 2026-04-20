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

if ! $force; then  
  r=$?
  if [ $r -ne 0 ]; then
    echo "Tests failed. Aborting"
    exit 1
  fi
fi

git tag -a "$NEXT_TAG" -m "Version $NEXT_TAG"

remotes=$(git remote)
for remote in $remotes; do
  git pull $remote main
  echo "--------------------------------------------"
  echo "Pushing tags to remote: $remote"
  git push $remote --follow-tags --all
done

