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
  "docs/software-overview.md"
  "docs/limits.md"
  ".docs/agents/security.md"
  ".docs/agents/security-standards.md"
  ".docs/agents/design-standards.md"
  ".docs/agents/council.md"
  ".docs/agents/privacy-compliance.md"
  # Sliced out of AGENTS.md: §4/§5/§9/§10, §6/§7/§7b, §8/§8a, e-mail. AGENTS.md now
  # only points at them, so a missing file is a missing MANDATORY rule with nothing
  # left behind to notice it.
  ".docs/workflows/delivery-loop.md"
  ".docs/workflows/git-delivery.md"
  ".docs/workflows/session-memory.md"
  ".docs/workflows/sending-email.md"
  ".docs/context-manifest.yaml"
  ".docs/schemas/context-manifest.schema.json"
  ".docs/schemas/context-state.schema.json"
)
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then ok "$f"; else err "missing required file: $f"; fi
done

echo "== 1b. Context contract is structurally valid =="
if python3 - "$repo_root" <<'PY'
import json
import sys
from pathlib import Path
import yaml
from jsonschema import Draft202012Validator

root = Path(sys.argv[1])
manifest_path = root / ".docs/context-manifest.yaml"
manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
schema_path = manifest_path.parent / manifest["$schema"]
schema = json.loads(schema_path.read_text(encoding="utf-8"))
Draft202012Validator(schema).validate(manifest)
assert manifest["budgets"]["total_input_tokens"] > 0
assert manifest["budgets"]["categories"]["base_contracts"] > 0
PY
then
  ok "context manifest validates against its declared schema"
else
  err "context manifest/schema validation failed"
fi

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
# The kit ships a {{OPERATOR_NAME}} slot. If it is absent from AGENTS.md the source was
# likely committed with real operator data. (SMTP_ACCOUNT — braces omitted on purpose,
# a legacy identity.json that still declares it would substitute them — was the slot until
# 2026-08-10; it is retired — the canonical contract no longer names a transport.)
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

echo "== 7. Operator identity stays per-programmer, untracked and reachable =="
# Same shape as check 6, for the other half of the separation: {{TOKEN}} values live in
# .credentials/identity.json so an upgrade re-applies them instead of burning them. The
# guarantee is again an ABSENCE from KIT_OWNED_PATHS, so assert it.
if awk '/^KIT_OWNED_PATHS=\(/,/^\)/' scripts/install-agents-kit.sh | grep -q 'identity'; then
  err ".credentials/identity.json is listed in KIT_OWNED_PATHS — an upgrade would overwrite operator values"
else
  ok ".credentials/identity.json is not kit-owned"
fi

# The file holds the operator's real name and account. A tracked identity.json is the
# exact leak the {{...}} scheme exists to prevent, only harder to notice.
if git check-ignore -q .credentials/identity.json; then
  ok ".credentials/identity.json is gitignored"
else
  err ".credentials/identity.json is NOT gitignored — operator personal data would be committed"
fi
if git ls-files --error-unmatch .credentials/identity.json >/dev/null 2>&1; then
  err ".credentials/identity.json is TRACKED — remove it from the index"
else
  ok ".credentials/identity.json is not tracked"
fi
if [[ -f .credentials/identity.json.example ]]; then
  ok ".credentials/identity.json.example ships as the starter"
else
  err ".credentials/identity.json.example is missing — a fresh install has no starter"
fi

if grep -q 'apply_identity' scripts/install-agents-kit.sh &&
   awk '/^upgrade_kit\(\)/,/^}/' scripts/install-agents-kit.sh | grep -q 'apply_identity'; then
  ok "--upgrade re-applies operator identity before copying"
else
  err "upgrade_kit does not call apply_identity — an upgrade would reinstall empty {{TOKEN}} slots"
fi

echo "== 8. Single reading index is intact and in sync =="
# docs/required-reading.md is the one place an agent looks to know what to read. It is
# project-owned, but the kit's half lives in a managed block that install/upgrade
# regenerates from templates/. If the two drift, targets get a stale index and nobody
# notices — the failure mode is a document silently not being read.
block="templates/required-reading.kit-block.md"
index="docs/required-reading.md"
if [[ -f "$block" ]]; then ok "$block ships"; else err "missing $block — the installer has nothing to inject"; fi
if grep -q 'AI-AGENTS:BEGIN kit reading list' "$index" && grep -q 'AI-AGENTS:END' "$index"; then
  ok "$index has the managed-block markers"
else
  err "$index lost its AI-AGENTS markers — an upgrade would re-insert the block and duplicate it"
fi
if [[ -f "$block" ]] &&
   diff -q <(awk '/AI-AGENTS:BEGIN/{f=1;next} /AI-AGENTS:END/{f=0} f' "$index") \
           <(cat "$block") >/dev/null 2>&1; then
  ok "kit block in $index matches $block"
else
  err "kit block in $index differs from $block — regenerate it (install --upgrade) before tagging"
fi
if grep -q 'required-reading\.md' AGENTS.md; then
  ok "AGENTS.md points at the single index"
else
  err "AGENTS.md no longer points at docs/required-reading.md"
fi

echo "== 8b. The canonical contract names no email transport =="
# Council round 1 of the 2026-08-10 delivery (gh-5) found the retirement half-done in
# three distinct ways. Each assertion below fails if one of them comes back.
#
# (a) The rewrite emptied the leaf file .docs/workflows/sending-email.md and left the
#     ROOT contract still prescribing the transport as [MANDATORY] — and the leaf file
#     defers to AGENTS.md on conflict, so the retired rule outranked its replacement in
#     every installed project. Grep for the path, not for prose: a path is decidable.
#
#     Scope, twice — the first cut of this assertion passed against the un-fixed tree
#     and would have cleared the very finding it was written for. It required a
#     character after `email/`, and the offending line spelled the directory bare
#     (`~/.config/email/` closed by a backtick). Now: the path anywhere, no lookahead.
#     And sending-email.md is excluded rather than pattern-matched, because its
#     Provenance section is *about* the retirement — the mention-versus-use distinction
#     that has cost this kit four detectors is decided here by file, not by heuristic.
#
#     Round 2 widened the pathspec: it was `AGENTS.md .docs/*`, and appending the
#     retired rule to CLAUDE.md left the whole gate green. The six adapter mirrors are
#     kit-owned, installed everywhere, and are exactly what doctor scans as contracts.
#     Three files are excluded by name, not by pattern: sending-email.md documents the
#     retirement, docs/required-reading.md is where the rule SAYS a project must declare
#     its own transport (flagging it would forbid compliance), and napkin-lessons.md is
#     history — it records what happened, quoting the path, and this very check flagged
#     the lesson written about it. Same exclusion, same reason, as doctor's
#     `_CONTRACT_SCAN_SKIP`: "History, not instructions."
transport_cite="$(git grep -nE '~/\.config/email' -- \
                  'AGENTS.md' '.docs/*' 'docs/*.md' \
                  'CLAUDE.md' 'GEMINI.md' '.cursorrules' '.windsurfrules' \
                  '.github/copilot-instructions.md' '.amazonq/rules/*.md' \
                  ':!.docs/workflows/sending-email.md' \
                  ':!docs/required-reading.md' \
                  ':!docs/napkin-lessons.md' \
                  ':!docs/issues/*' || true)"
if [[ -n "$transport_cite" ]]; then
  echo "$transport_cite"
  err "a kit-owned contract cites one operator's email transport — it is installed in every project"
else
  ok "no kit-owned contract names an email transport"
fi

#     The excluded file still has to obey the rule in its normative half: everything
#     above ## Provenance is the contract, and the contract names no transport.
contract_half="$(awk '/^## Provenance/{exit} {print}' .docs/workflows/sending-email.md)"
if grep -qE '~/\.config/email|send\.py' <<<"$contract_half"; then
  err "the §Sending Email contract itself names a transport again — only its Provenance may"
else
  ok "the §Sending Email contract names no transport above its Provenance"
fi

# (b) A fresh install seeded docs/required-reading.md from THIS repository's own index,
#     so the kit's transport and the kit's "no recipient list" arrived in an unrelated
#     project as that project's own declaration. The starter must be a neutral template.
reading_template="templates/required-reading.template.md"
if [[ -f "$reading_template" ]] &&
   ! grep -qE '~/\.config|send\.py|agent-status\.json' "$reading_template"; then
  ok "$reading_template ships and declares no local source of its own"
else
  err "$reading_template is missing or carries this repository's own local sources"
fi
if grep -q 'READING_INDEX_TEMPLATE_REL' scripts/install-agents-kit.sh &&
   ! awk '/^sync_reading_index\(\)/,/^}/' scripts/install-agents-kit.sh |
       grep -q 'SRC_ROOT/\$READING_INDEX_REL'; then
  ok "the installer seeds a new index from the template, never from ours"
else
  err "sync_reading_index copies this repository's own index into fresh targets"
fi

# (c) The contract sends the agent to a section the kit never provisioned: it lives
#     outside the managed markers, so no upgrade could create it and no already
#     installed project would ever have one.
if grep -qF '## Fontes locais' "$reading_template" &&
   grep -q 'ensure_local_sources_section' scripts/install-agents-kit.sh; then
  ok "the section the contract points at is seeded and back-filled on upgrade"
else
  err "docs/required-reading.md has no Fontes locais scaffold — the contract points at nothing"
fi

echo "== 9. The kit does not ship its own README into consuming projects =="
# README.md is the kit's front page, not a file a consumer should receive. Shipping it
# meant --upgrade replaced the project's README with the kit's — which really happened
# (a target's README.md now opens with "# IA-Agents Universal Kit").
if awk '/^KIT_ROOT_FILES=\(/,/^\)/' scripts/install-agents-kit.sh | grep -q '"README'; then
  err "README*.md is back in KIT_ROOT_FILES — an upgrade would overwrite project READMEs"
elif grep -qE '^\s*copy_path "README' scripts/install-agents-kit.sh; then
  err "install still copy_path's README*.md into targets"
else
  ok "README*.md is neither installed nor upgraded into targets"
fi
if awk '/^upgrade_kit\(\)/,/^}/' scripts/install-agents-kit.sh | grep -q 'retire_root_file' &&
   awk '/^upgrade_kit\(\)/,/^}/' scripts/install-agents-kit.sh | grep -q '"README.md"'; then
  ok "--upgrade retires a kit README left in a target"
else
  err "no retirement path for READMEs the kit installed before this change"
fi

echo "== 10. Kit-owned files declare themselves kit-owned =="
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

echo "== 10b. Every agent adapter loads the same mandatory context =="
adapters=(
  "CLAUDE.md"
  "GEMINI.md"
  ".cursorrules"
  ".windsurfrules"
  ".github/copilot-instructions.md"
  ".amazonq/rules/ai-agents.md"
)
mandatory=(
  "AGENTS.md"
  "docs/software-overview.md"
  "docs/limits.md"
  "docs/required-reading.md"
  "docs/project-rules.md"
)
for adapter in "${adapters[@]}"; do
  if [[ ! -f "$adapter" ]]; then
    err "missing agent adapter: $adapter"
    continue
  fi
  adapter_ok=1
  for contract in "${mandatory[@]}"; do
    if ! grep -qF "$contract" "$adapter"; then
      err "$adapter does not load mandatory contract: $contract"
      adapter_ok=0
    fi
  done
  [[ "$adapter_ok" == "1" ]] && ok "$adapter loads all mandatory contracts"
done

echo "== 10c. Installer release and identity preflight stay coherent =="
installer="scripts/install-agents-kit.sh"
installer_ref="$(awk -F'"' '$1 == "REF=" { print $2; exit }' "$installer")"
latest_tag="$(git tag --sort=-version:refname | head -n1)"
next_tag="$(
  python3 - "$latest_tag" <<'PY'
import re
import sys

match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", sys.argv[1])
if match:
    major, minor, patch = map(int, match.groups())
    print(f"v{major}.{minor}.{patch + 1}")
PY
)"
if [[ "$installer_ref" == "$latest_tag" || "$installer_ref" == "$next_tag" ]]; then
  ok "installer REF is the current release or the next patch ($installer_ref)"
else
  err "installer REF $installer_ref is stale; expected $latest_tag or $next_tag"
fi
if grep -qF "/$installer_ref/scripts/install-agents-kit.sh" "$installer" &&
   grep -qF -- "--branch $installer_ref" "$installer" &&
   grep -qF "default: $installer_ref" "$installer"; then
  ok "installer examples and --ref help match REF=$installer_ref"
else
  err "installer release references disagree with REF=$installer_ref"
fi

identity_test_root="$(mktemp -d)"
trap 'rm -rf -- "$identity_test_root"' EXIT
noninteractive_target="$identity_test_root/noninteractive"
mkdir -p "$noninteractive_target"
set +e
bash "$repo_root/$installer" --target "$noninteractive_target" --upgrade \
  >"$identity_test_root/noninteractive.log" 2>&1
noninteractive_rc=$?
set -e
if [[ "$noninteractive_rc" == "8" ]] &&
   grep -q 'OPERATOR_NAME' "$identity_test_root/noninteractive.log" &&
   ! grep -q 'SMTP_ACCOUNT' "$identity_test_root/noninteractive.log" &&
   [[ ! -e "$noninteractive_target/AGENTS.md" ]]; then
  ok "non-interactive upgrade fails before copying files when identity is empty"
else
  err "non-interactive upgrade did not fail early naming OPERATOR_NAME and only it"
fi

interactive_target="$identity_test_root/interactive"
mkdir -p "$interactive_target"
set +e
printf 'Test Operator\n' |
  script -qec "bash '$repo_root/$installer' --target '$interactive_target' --upgrade" /dev/null \
    >"$identity_test_root/interactive.log" 2>&1
interactive_rc=$?
set -e
if [[ "$interactive_rc" == "30" ]] &&
   grep -q 'Test Operator' "$interactive_target/AGENTS.md" &&
   ! grep -q '{{OPERATOR_NAME}}' "$interactive_target/AGENTS.md" &&
   [[ "$(stat -c '%a' "$interactive_target/.credentials/identity.json")" == "600" ]]; then
  ok "interactive upgrade collects, protects, and applies required identity first"
else
  err "interactive upgrade did not collect and apply the required identity field"
fi
rm -rf -- "$identity_test_root"
trap - EXIT

echo "== 10c-bis. A fresh target's reading index is the target's, not ours =="
# The assertions in 8b are structural; these two run the installer, because the defect
# council round 1 reproduced was in what lands on disk, not in what the script says.
reading_test_root="$(mktemp -d)"
trap 'rm -rf -- "$reading_test_root"' EXIT

fresh_target="$reading_test_root/fresh"
mkdir -p "$fresh_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$fresh_target/.credentials/identity.json"
chmod 600 "$fresh_target/.credentials/identity.json"
bash "$repo_root/$installer" --target "$fresh_target" --upgrade \
  >"$reading_test_root/fresh.log" 2>&1 || true
fresh_index="$fresh_target/docs/required-reading.md"
if [[ -f "$fresh_index" ]] &&
   grep -qF '## Fontes locais' "$fresh_index" &&
   grep -q 'AI-AGENTS:BEGIN kit reading list' "$fresh_index" &&
   ! grep -qE '~/\.config/email|agent-status\.json' "$fresh_index"; then
  ok "fresh install seeds a neutral index with the Fontes locais section"
else
  err "fresh install produced no index, no Fontes locais section, or inherited our local sources"
fi

# An index written before the section existed — the state of essentially every install.
legacy_target="$reading_test_root/legacy"
mkdir -p "$legacy_target/docs" "$legacy_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$legacy_target/.credentials/identity.json"
chmod 600 "$legacy_target/.credentials/identity.json"
printf '# Required Reading\n\n## Deste projeto\n\n- `docs/arquitetura.md`\n' \
  > "$legacy_target/docs/required-reading.md"
bash "$repo_root/$installer" --target "$legacy_target" --upgrade \
  >"$reading_test_root/legacy.log" 2>&1 || true
legacy_index="$legacy_target/docs/required-reading.md"
if grep -qF '## Fontes locais' "$legacy_index" &&
   grep -qF 'docs/arquitetura.md' "$legacy_index" &&
   grep -q 'AI-AGENTS:BEGIN kit reading list' "$legacy_index"; then
  ok "upgrade back-fills Fontes locais without touching the project's own list"
else
  err "upgrade left an existing index without the section the email contract points at"
fi

# The seeded starter must read as a document: its lede explains what the file is and
# who owns which half, and an exact-marker miss would bury it under the kit's tables.
if [[ "$(grep -n 'índice único' "$fresh_index" | cut -d: -f1)" -lt \
      "$(grep -n 'AI-AGENTS:BEGIN' "$fresh_index" | cut -d: -f1)" ]]; then
  ok "the seeded index keeps its lede above the managed block"
else
  err "the seeded index has the kit block above its own lede — the template lost its markers"
fi

# Council round 2: the back-fill matched ONE spelling of the heading while doctor
# accepts a family and recommends another, so a project that had already written its
# own section got a second, empty, contradicting one appended.
variant_target="$reading_test_root/variant"
mkdir -p "$variant_target/docs" "$variant_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$variant_target/.credentials/identity.json"
chmod 600 "$variant_target/.credentials/identity.json"
printf '# Required Reading\n\n## Local sources\n\n| Caminho | Obrigatório | O que é |\n|---|---|---|\n| `~/x/mailer.py` | opcional | transporte deste projeto |\n\n### Lista de destinatários\n\n- ops@example.invalid (sempre em CC)\n' \
  > "$variant_target/docs/required-reading.md"
bash "$repo_root/$installer" --target "$variant_target" --upgrade \
  >"$reading_test_root/variant.log" 2>&1 || true
variant_index="$variant_target/docs/required-reading.md"
if [[ "$(grep -ciE '^#{2,4} .*(fontes locais|local sources)' "$variant_index")" == "1" ]] &&
   [[ "$(grep -cF 'Lista de destinatários' "$variant_index")" == "1" ]] &&
   grep -qF 'ops@example.invalid' "$variant_index"; then
  ok "back-fill recognises the heading family and never duplicates the section"
else
  err "upgrade duplicated the local-sources section — the project's recipient list now has a contradicting twin"
fi
# The cohort installed between 2026-08-07 and 2026-08-10: the section is already there,
# carrying the row the kit itself wrote and has since retired. Ownership forbids
# rewriting it, so the upgrade must NAME it — and must leave it exactly as it was.
stale_target="$reading_test_root/stale"
mkdir -p "$stale_target/docs" "$stale_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$stale_target/.credentials/identity.json"
chmod 600 "$stale_target/.credentials/identity.json"
printf '# Required Reading\n\n## Fontes locais — fora do checkout\n\n| Caminho | Obrigatório | O que é |\n|---|---|---|\n| `~/.config/email/send.py` | opcional | transporte da §Sending Email |\n' \
  > "$stale_target/docs/required-reading.md"
bash "$repo_root/$installer" --target "$stale_target" --upgrade \
  >"$reading_test_root/stale.log" 2>&1 || true
if grep -q 'has since retired' "$reading_test_root/stale.log" &&
   grep -q 'transporte da §Sending Email' "$reading_test_root/stale.log" &&
   [[ "$(grep -cF 'transporte da §Sending Email' "$stale_target/docs/required-reading.md")" == "1" ]]; then
  ok "upgrade names the retired transport row and leaves the project's half untouched"
else
  err "upgrade stayed silent about a retired row, or rewrote the project's own index"
fi
# The other cohort ownership puts out of reach: a drifted AGENTS.md is preserved, so the
# project keeps a BINDING contract carrying a WITHDRAWN rule while the corrected one
# waits, unread, in .kit-new. Same instrument, same decision: name it, never overwrite.
drift_target="$reading_test_root/drift"
mkdir -p "$drift_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$drift_target/.credentials/identity.json"
chmod 600 "$drift_target/.credentials/identity.json"
bash "$repo_root/$installer" --target "$drift_target" --upgrade >/dev/null 2>&1 || true
printf '# AGENTS.md\n\n[MANDATORY] Credenciais e transporte moram em `~/.config/email/`.\n' \
  > "$drift_target/AGENTS.md"
bash "$repo_root/$installer" --target "$drift_target" --upgrade \
  >"$reading_test_root/drift.log" 2>&1 || true
if grep -q 'kept: AGENTS.md' "$reading_test_root/drift.log" &&
   grep -q 'WITHDRAWN' "$reading_test_root/drift.log" &&
   grep -qF '~/.config/email' "$drift_target/AGENTS.md"; then
  ok "upgrade names a kept contract that still carries the withdrawn rule"
else
  err "a preserved AGENTS.md kept the withdrawn transport rule with no warning"
fi
# A source tree without templates/ must say what it failed to do. The silent `return 0`
# left the target with a refreshed AGENTS.md pointing at an index that was never made,
# and the run's only line about that file claimed it had been preserved.
partial_src="$reading_test_root/partial-src"
mkdir -p "$partial_src"
cp -a "$repo_root/AGENTS.md" "$repo_root/scripts" "$partial_src/"
rm -rf "$partial_src/templates"
partial_target="$reading_test_root/partial-target"
mkdir -p "$partial_target/.credentials"
printf '{"state_version":1,"values":{"OPERATOR_NAME":"Test Operator"},"refs":{}}\n' \
  > "$partial_target/.credentials/identity.json"
chmod 600 "$partial_target/.credentials/identity.json"
bash "$partial_src/scripts/$(basename "$installer")" --target "$partial_target" --upgrade \
  >"$reading_test_root/partial.log" 2>&1 || true
if grep -q 'was NOT created' "$reading_test_root/partial.log" &&
   [[ ! -f "$partial_target/docs/required-reading.md" ]]; then
  ok "a source tree without templates/ says the index was not created"
else
  err "the installer stayed silent about failing to create the reading index"
fi
rm -rf -- "$reading_test_root"
trap - EXIT

echo "== 10d. Landing page is publishable and release-safe =="
landing="docs/index.html"
landing_copy=".docs/index.html"
advanced_usage="docs/advanced-usage.html"
advanced_usage_copy=".docs/advanced-usage.html"
advanced_usage_ptbr="docs/advanced-usage-ptbr.html"
advanced_usage_es="docs/advanced-usage-es.html"
pages_workflow=".github/workflows/pages.yml"
if [[ -f "$landing" && -f "$landing_copy" ]] && cmp -s "$landing" "$landing_copy"; then
  ok "public landing and distributed landing are byte-identical"
else
  err "$landing and $landing_copy differ or one is missing"
fi
translated_nav_ok=1
for key in products features install advanced compatibility concepts support star; do
  if [[ "$(grep -c "'nav\\.${key}':" "$landing")" != "3" ]] ||
     ! grep -qF "data-i18n=\"nav.${key}\"" "$landing"; then
    err "landing navigation key is not complete in EN, PT-BR, and ES: nav.${key}"
    translated_nav_ok=0
  fi
done
if [[ "$translated_nav_ok" == "1" ]]; then
  ok "landing navigation is fully translated in EN, PT-BR, and ES"
fi
multilingual_guides_ok=1
for guide in "$advanced_usage" "$advanced_usage_ptbr" "$advanced_usage_es"; do
  distributed=".docs/${guide#docs/}"
  if [[ ! -f "$guide" || ! -f "$distributed" ]] || ! cmp -s "$guide" "$distributed"; then
    err "advanced usage language copy is missing or unsynchronized: $guide"
    multilingual_guides_ok=0
  fi
  if [[ "$(grep -c 'install-agents-kit.sh)' "$guide")" -lt 2 ]] ||
     ! grep -qF -- '--target "$PWD"' "$guide" ||
     ! grep -qF -- '--target "$PWD" --upgrade' "$guide"; then
    err "advanced usage does not show separate fresh-install and upgrade commands: $guide"
    multilingual_guides_ok=0
  fi
done
if [[ "$multilingual_guides_ok" == "1" ]] &&
   grep -qF 'advanced-usage-ptbr.html' "$landing" &&
   grep -qF 'advanced-usage-es.html' "$landing"; then
  ok "advanced usage is available and routed in EN, PT-BR, and ES"
else
  err "landing does not route all three advanced usage languages"
fi
if grep -qF 'data-install-tab="upgrade"' "$landing" &&
   grep -qF "tab.addEventListener('click'" "$landing" &&
   grep -qF 'data-install-panel="upgrade"' "$landing"; then
  ok "fresh/upgrade installation tabs have interactive behavior"
else
  err "installation tabs are present without a working upgrade interaction"
fi
if [[ -f "$advanced_usage" && -f "$advanced_usage_copy" ]] &&
   cmp -s "$advanced_usage" "$advanced_usage_copy" &&
   grep -qF './advanced-usage.html' "$landing"; then
  ok "advanced usage guide is linked and its distributed copy is synchronized"
else
  err "advanced usage guide is missing, unlinked, or differs from its distributed copy"
fi
if grep -qF '.governancekit-identity.json' "$advanced_usage" &&
   grep -qF '.credentials/identity.json' "$advanced_usage" &&
   grep -qF 'WORKSPACE.md' "$advanced_usage" &&
   ! grep -q 'e.g.[[:space:]]*`WORKSPACE.md`' AGENTS.md; then
  ok "identity documentation names both canonical files and rejects WORKSPACE.md ambiguity"
else
  err "identity documentation is incomplete or still makes WORKSPACE.md look mandatory"
fi
installer_options=(
  --target --repo --ref --checksum --force --upgrade --strict --check
  --migrate --dry-run --help
)
advanced_options_ok=1
for option in "${installer_options[@]}"; do
  if ! grep -qF -- "$option" "$advanced_usage"; then
    err "advanced usage guide does not document installer parameter: $option"
    advanced_options_ok=0
  fi
done
[[ "$advanced_options_ok" == "1" ]] && ok "advanced usage guide documents every installer parameter"
if grep -qF 'github.com/EDortta/AI-Agents' "$landing" &&
   grep -qF 'github.com/EDortta/AI-GovernanceKit' "$landing" &&
   ! grep -q 'GITHUB_OWNER' "$landing"; then
  ok "landing repository links use EDortta and contain no owner placeholder"
else
  err "landing repository links are missing, wrong, or contain GITHUB_OWNER"
fi
if grep -qF 'ko-fi.com/edortta' "$landing" &&
   grep -q 'PIX' "$landing" &&
   grep -q 'ETH' "$landing"; then
  ok "landing retains PIX, ETH, and Ko-fi support information"
else
  err "landing lost PIX, ETH, or Ko-fi support information"
fi
landing_refs="$(grep -oE 'AI-Agents/v[0-9]+\.[0-9]+\.[0-9]+/scripts/install-agents-kit\.sh' "$landing" |
  sed -E 's#AI-Agents/(v[0-9]+\.[0-9]+\.[0-9]+)/.*#\1#' | sort -u)"
if [[ "$landing_refs" == "$installer_ref" ]]; then
  ok "every landing installer URL matches REF=$installer_ref"
else
  err "landing installer URLs use '${landing_refs:-none}', expected $installer_ref"
fi
if [[ -f "$pages_workflow" ]] &&
   grep -qF 'path: docs' "$pages_workflow" &&
   grep -qF 'actions/configure-pages@v5' "$pages_workflow" &&
   grep -qF 'actions/upload-pages-artifact@v4' "$pages_workflow" &&
   grep -qF 'actions/deploy-pages@v4' "$pages_workflow"; then
  ok "GitHub Pages workflow deploys only docs/ with current official actions"
else
  err "GitHub Pages workflow is missing or does not deploy docs/ correctly"
fi

echo "== 10e. Every § reference resolves to a real section =="
# AGENTS.md carried `§commit-only` for months — a reference to a section that has never
# existed. Nothing dereferences §N, so a dangle costs nothing at runtime and everything
# to the reader who goes looking. Now that the contract is split across files, a dangle
# is also how a rule quietly becomes unreachable: the pointer survives the move, the
# target does not.
if python3 - <<'PY'
import re, sys
from pathlib import Path

# Section numbers are small integers and they collide across the corpus: `## 9` exists
# in security-standards.md and in three audit workflows. A check that pools every
# heading into one namespace therefore answers "does §9 exist anywhere?", which is
# always yes — it would have passed while `delivery-loop.md §9` pointed at nothing.
# So a reference resolves against the file it names, and only a bare one falls back
# to the file it was written in.
SCAN = [Path("AGENTS.md"), *sorted(Path(".docs").rglob("*.md")), *sorted(Path("scripts").glob("*.sh"))]
# This file is skipped: it is the only place in the tree that has to *write* the
# patterns it looks for, and a detector that reads its own source finds itself. Same
# shape as the four detection defects this kit has already paid for — here the scope
# is narrowed on purpose rather than discovered in production.
SCAN = [p for p in SCAN if p.name != "run-checks.sh"]
sources = {p: p.read_text(encoding="utf-8", errors="replace") for p in SCAN if p.is_file()}

HEADING = re.compile(r"^#{1,6}\s+(?:§\s*)?([0-9]+[a-z]?)\b")
headings = {
    path: {m.group(1) for line in text.splitlines() if (m := HEADING.match(line))}
    for path, text in sources.items()
}

# A single uppercase letter after § is a metavariable in prose ("`design-standards.md`
# §N"), not a citation. Everything else must resolve — including a word-shaped one:
# sections are numbered, so `§commit-only` was never anything but a dangle.
METAVARIABLE = re.compile(r"^[A-Z]$")
FILENAME = re.compile(r"[`'\"]?([\w./-]+\.md)[`'\"]?")
BARE = re.compile(r"§\s*([A-Za-z0-9][A-Za-z0-9-]*)")
HEADING_LINE = re.compile(r"^#{1,6}\s")


def resolve(named: str, home: Path) -> Path | None:
    """Which scanned file a citation's filename refers to, or None if unknown."""
    for candidate in ((home.parent / named).resolve(), Path(named.lstrip("/")).resolve()):
        for path in sources:
            if path.resolve() == candidate:
                return path
    return None


dangling = []
for path, text in sources.items():
    # A pointer stub names its target in the heading and lists the sections below it,
    # so a filename stays in force until the next heading. Without that, every stub
    # this slice created would read as citing itself.
    section_file = None
    for n, line in enumerate(text.splitlines(), 1):
        if HEADING_LINE.match(line):
            found = FILENAME.search(line)
            section_file = found.group(1) if found else None
        for match in BARE.finditer(line):
            ref = match.group(1)
            if METAVARIABLE.match(ref):
                continue
            # A filename qualifies a § only when it sits immediately before it:
            # "`design-standards.md` §1". Taking any filename on the line was wrong
            # four times out of six against council.md, where a sentence names a
            # sibling file and then cites its OWN §1 further along.
            before = line[max(0, match.start() - 30):match.start()]
            adjacent = re.search(r"[`'\"]?([\w./-]+\.md)[`'\"]?[\s(,]*$", before)
            if adjacent:
                named = adjacent.group(1)
            elif ref in headings[path]:
                # The own file wins over the enclosing heading's target. A heading may
                # name a sibling for other reasons ("## 1. The boundary with
                # governance-precedence.md") and its body still cite its own sections.
                named = None
            else:
                named = section_file
            target = resolve(named, path) if named else path
            if target is None:
                # Names a file this scan does not cover; only assert the number exists.
                if any(ref in found for found in headings.values()):
                    continue
                dangling.append(f"{path}:{n}: §{ref} (in {named}, not scanned)")
                continue
            if ref not in headings[target]:
                where = named or path.name
                dangling.append(f"{path}:{n}: §{ref} — no such section in {where}")
if dangling:
    print("  dangling § references:")
    for item in dangling:
        print(f"    {item}")
    raise SystemExit(1)
PY
then
  ok "every § reference resolves to a heading in AGENTS.md or .docs/"
else
  err "dangling § reference"
fi

echo "== 11. shellcheck (advisory, if installed) =="
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
