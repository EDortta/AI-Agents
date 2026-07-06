#!/bin/bash
# Release gate for the AI-Agents kit (security-standards.md §7: a release/tag is
# gated by checks; a broken suite does not tag and does not publish).
#
# This is a docs/contract kit, not a compiled project, so the "tests" are
# structural integrity checks. Any failure exits non-zero so new-tag.sh aborts.
#
# Run from the repo root: bash scripts/run-checks.sh
set -u

fail=0
err() { echo "  [FAIL] $1"; fail=1; }
ok()  { echo "  [ ok ] $1"; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || { echo "cannot cd to repo root"; exit 2; }

echo "== 1. Required kit files present =="
required=(
  "AGENTS.md"
  "README.md"
  ".docs/software-overview.md"
  ".docs/limits.md"
  ".docs/agents/security.md"
  ".docs/agents/security-standards.md"
  ".docs/agents/privacy-compliance.md"
)
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then ok "$f"; else err "missing required file: $f"; fi
done

echo "== 2. No unresolved merge-conflict markers =="
# Match at line start to avoid flagging prose that mentions the markers.
if git grep -nE '^(<<<<<<< |=======$|>>>>>>> )' -- '*.md' '*.sh' >/dev/null 2>&1; then
  git grep -nE '^(<<<<<<< |=======$|>>>>>>> )' -- '*.md' '*.sh'
  err "merge-conflict markers found"
else
  ok "none"
fi

echo "== 3. Shell scripts parse ('bash -n') =="
while IFS= read -r script; do
  if bash -n "$script" 2>/dev/null; then ok "$script"; else err "syntax error: $script"; fi
done < <(git ls-files '*.sh')

echo "== 4. No secret files tracked (security-standards.md §1) =="
# Only .example templates are allowed under .credentials/; a real secret file or
# any tracked .env is a release blocker.
offenders="$(git ls-files | grep -E '(^\.env|/\.env|(^|/)\.credentials$)' || true)"
offenders+="$(git ls-files '.credentials/*' | grep -vE '\.example$|(^|/)(README|\.gitignore)' || true)"
if [[ -n "${offenders//[$'\n\t ']/}" ]]; then
  echo "$offenders"
  err "secret-bearing files are tracked"
else
  ok "none tracked"
fi

echo "== 5. Operator placeholders not filled with real data in kit source =="
# The kit ships with [OPERATOR_NAME]/[SMTP_ACCOUNT] placeholders. If they are
# absent from AGENTS.md the source was likely committed with real operator data.
if grep -q '\[OPERATOR_NAME\]' AGENTS.md; then
  ok "placeholders intact in AGENTS.md"
else
  err "AGENTS.md has no [OPERATOR_NAME] placeholder — real operator data may be committed"
fi

echo "== 6. shellcheck (advisory, if installed) =="
if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r script; do
    shellcheck -S error "$script" && ok "$script" || err "shellcheck errors: $script"
  done < <(git ls-files '*.sh')
else
  echo "  [skip] shellcheck not installed"
fi

echo
if [[ $fail -ne 0 ]]; then
  echo "run-checks: FAILED — release gate blocks tagging."
  exit 1
fi
echo "run-checks: all checks passed."
exit 0
