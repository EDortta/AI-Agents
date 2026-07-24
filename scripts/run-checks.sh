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
  ".docs/agents/design-standards.md"
  ".docs/agents/council.md"
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
# The kit ships with {{OPERATOR_NAME}}/{{SMTP_ACCOUNT}} slots. If they are absent from
# AGENTS.md the source was likely committed with real operator data.
#
# The delimiter is {{...}}, not [...], because [MANDATORY]/[PROHIBITED]/[DEFAULT] are
# content vocabulary in these documents: a bracket token cannot be told from prose
# without an allowlist, a mustache token always can.
if grep -q '{{OPERATOR_NAME}}' AGENTS.md; then
  ok "placeholder slots intact in AGENTS.md"
else
  err "AGENTS.md has no {{OPERATOR_NAME}} slot — real operator data may be committed"
fi

# The old spelling must not creep back into live kit files: an installer that renders
# {{...}} would silently leave a [...] token unfilled forever. docs/issues/ is history,
# not template, so it keeps whatever spelling it was written with.
legacy="$(git grep -lE '\[(OPERATOR_NAME|SMTP_ACCOUNT|PROJECT_SLUG|GITHUB_OWNER)\]' \
          -- 'AGENTS.md' '.docs/*' 'templates/*' 'scripts/*' || true)"
if [[ -n "$legacy" ]]; then
  echo "$legacy"
  err "legacy [TOKEN] placeholders in live kit files — the installer only renders {{TOKEN}}"
else
  ok "no legacy [TOKEN] placeholders in live kit files"
fi

# A slot written literally in PROSE (documenting the convention) is indistinguishable
# from a real slot: the installer substitutes it — putting the operator's real name into
# the very paragraph that forbids it — and the Start Gate grep then flags it forever.
# Documentation must spell the convention as {{…}}. This caught itself during testing.
meta="$(git grep -lE '\{\{(TOKEN|PLACEHOLDER|NAME|VALUE)\}\}' -- 'AGENTS.md' '.docs/*' || true)"
if [[ -n "$meta" ]]; then
  echo "$meta"
  err "a generic slot is written literally in prose — spell it {{…}} so it is not substituted"
else
  ok "no generic slot written literally in agent-facing docs"
fi

echo "== 6. Project-rules destination is reachable and stays project-owned =="
# Check 5 guards one direction (operator data leaking INTO the kit). This guards the
# other: project rules written into AGENTS.md and destroyed by the next --upgrade.
# The kit can only check its own repo — it has no target here — so it checks the two
# invariants that make the protection work at all.
if grep -q 'docs/project-rules\.md' AGENTS.md; then
  ok "AGENTS.md points at docs/project-rules.md"
else
  err "AGENTS.md does not point at docs/project-rules.md — agents will keep writing project rules into AGENTS.md"
fi

if [[ -f docs/project-rules.md ]]; then
  ok "docs/project-rules.md starter present"
else
  err "docs/project-rules.md is missing — the installer would seed a bare fallback"
fi

# The guarantee that no upgrade touches this file is an ABSENCE from KIT_OWNED_PATHS.
# Absences are easy to undo by accident, so assert it.
if grep -q 'project-rules' scripts/install-agents-kit.sh &&
   awk '/^KIT_OWNED_PATHS=\(/,/^\)/' scripts/install-agents-kit.sh | grep -q 'project-rules'; then
  err "docs/project-rules.md is listed in KIT_OWNED_PATHS — an upgrade would overwrite project rules"
else
  ok "docs/project-rules.md is not kit-owned"
fi

if grep -q 'PROTECTED_ROOT_FILES=' scripts/install-agents-kit.sh &&
   grep -A2 'PROTECTED_ROOT_FILES=' scripts/install-agents-kit.sh | grep -q 'AGENTS.md'; then
  ok "AGENTS.md is in PROTECTED_ROOT_FILES"
else
  err "AGENTS.md is not protected in install-agents-kit.sh — --upgrade would overwrite it blindly"
fi

echo "== 7. Operator identity stays project-owned and reachable =="
# Same shape as check 6, for the other half of the separation: {{TOKEN}} values live in
# .gk/identity.json so an upgrade re-applies them instead of burning them. The guarantee
# is again an ABSENCE from KIT_OWNED_PATHS, so assert it.
if awk '/^KIT_OWNED_PATHS=\(/,/^\)/' scripts/install-agents-kit.sh | grep -q 'identity'; then
  err ".gk/identity.json is listed in KIT_OWNED_PATHS — an upgrade would overwrite operator values"
else
  ok ".gk/identity.json is not kit-owned"
fi

if grep -q 'apply_identity' scripts/install-agents-kit.sh &&
   awk '/^upgrade_kit\(\)/,/^}/' scripts/install-agents-kit.sh | grep -q 'apply_identity'; then
  ok "--upgrade re-applies operator identity before copying"
else
  err "upgrade_kit does not call apply_identity — an upgrade would reinstall empty {{TOKEN}} slots"
fi

echo "== 8. Kit-owned files declare themselves kit-owned =="
# The read-only contract is what stops the next agent from writing project rules into a
# file the upgrade replaces. It only works if the banner is actually in every file, and
# a banner is trivially lost to an unrelated edit — so it is asserted, not trusted.
banner='AI-Agents kit-owned file. Do not edit'
missing=0
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  if head -n 12 "$f" | grep -qF "$banner"; then
    ok "$f"
  else
    err "no kit-owned banner in the first 12 lines: $f"
    missing=$((missing + 1))
  fi
done < <(awk '/^KIT_ROOT_FILES=\(/,/^\)/' scripts/install-agents-kit.sh |
         grep -oE '"[^"]+"' | tr -d '"')
if [[ "$missing" -eq 0 ]]; then
  ok "every KIT_ROOT_FILES entry carries the banner"
fi

echo "== 9. shellcheck (advisory, if installed) =="
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
