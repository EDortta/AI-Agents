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
  ".docs/workflows/unattended-run.md"
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

echo "== 6b. The shell installer stays retired (GovernanceKit AC-30) =="
# Two installers writing the same manifest and the same managed .gitignore block, with
# no shared source of truth, produced drift and data-loss defects (manifest keys
# dropped, gitignore suffixes lost, a project's own templates/ deleted on the second
# upgrade). The operator's decision was retirement, not reconciliation: the Python
# installer is the only writer, and GovernanceKit (from AC-30 on) withdraws stale
# copies from targets. Of the invariants the deleted checks asserted: the neutral
# reading-index seed and identity-untracked/0600 have equivalents in GovernanceKit's
# tests (over .gk/operator.json, the file the surviving installer writes); the
# identity preflight (fail-before-copy) and the reading-index back-fill retired WITH
# the shell installer as deliberate contract changes (the CLI warns and exits 0);
# the two-upgrade templates/ scenario migrated (GovernanceKit's
# test_templates_is_never_a_managed_path_at_the_project_root and its behavioral
# pair); README withdrawal is the one with no owner yet — needs-coordination,
# 006 epic RESUME item 4. This is a mapping, not a blanket claim: anything not
# named above died with the shell installer.
if [[ -e "scripts/install-agents-kit.sh" ]]; then
  err "scripts/install-agents-kit.sh is back — the shell installer was retired; do not reintroduce a second writer"
else
  ok "scripts/install-agents-kit.sh is absent"
fi
# No live kit file may name it, or an operator following the docs resurrects the split.
# History keeps its record (docs/issues/, handoff.md, napkin-lessons) and this file has
# to write the pattern it greps for, so both are excluded — same shape as check 8b's
# mention-versus-use exclusions.
resurrect="$(git grep -l 'install-agents-kit' -- . \
  ':!docs/issues/*' ':!handoff.md' ':!docs/napkin-lessons.md' ':!scripts/run-checks.sh' \
  ':!.gk/council/*' || true)"
if [[ -n "$resurrect" ]]; then
  echo "$resurrect"
  err "a live kit file still references the retired shell installer"
else
  ok "no live kit file references the retired shell installer"
fi

echo "== 7. Operator identity stays per-programmer, untracked and reachable =="
# The other half of the separation guarded by check 6: operator {{TOKEN}} values are
# per-programmer and never tracked. The current installer stores answers in
# .gk/operator.json (GovernanceKit's suite asserts that side); this repository still
# ships the legacy .credentials/identity.json contract, so its invariants are asserted
# here.

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
  ok ".credentials/identity.json.example ships as the legacy/mailbox example"
else
  err ".credentials/identity.json.example is missing — the documented legacy/mailbox contract has no example"
fi

# The file the CURRENT installer writes gets the same two gates. The docs now point
# operators at .gk/operator.json, so an exposure there is the same leak one rename
# away — guarding only the legacy path would protect the file nobody writes to.
if git check-ignore -q .gk/operator.json; then
  ok ".gk/operator.json is gitignored"
else
  err ".gk/operator.json is NOT gitignored — operator personal data would be committed"
fi
if git ls-files --error-unmatch .gk/operator.json >/dev/null 2>&1; then
  err ".gk/operator.json is TRACKED — remove it from the index"
else
  ok ".gk/operator.json is not tracked"
fi


echo "== 8. Single reading index is intact and in sync =="
# docs/required-reading.md is the one place an agent looks to know what to read. It is
# project-owned, but the kit's half lives in a managed block kept in lockstep, BY HAND,
# with templates/required-reading.kit-block.md — since the shell installer retired,
# nothing regenerates the block in targets (fresh targets are seeded from
# templates/required-reading.template.md, whose block starts empty; upgrade-time
# injection is pending coordination with GovernanceKit). If the two drift here, the
# template ships a stale index and nobody notices — the failure mode is a document
# silently not being read.
block="templates/required-reading.kit-block.md"
index="docs/required-reading.md"
if [[ -f "$block" ]]; then ok "$block ships"; else err "missing $block — the kit list has no source of truth"; fi
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
# (c) The contract sends the agent to a section the kit has to provision: the template
#     must ship the scaffold, or docs/required-reading.md in a fresh target points at
#     nothing. (The shell installer's upgrade-time back-fill retired with it — a
#     deliberate drop; GovernanceKit's doctor advisory on the reading index is the
#     delivery mechanism for existing targets now.)
if grep -qF '## Fontes locais' "$reading_template"; then
  ok "the template ships the Fontes locais scaffold the contract points at"
else
  err "$reading_template has no Fontes locais scaffold — the contract points at nothing"
fi

echo "== 9. (retired) =="
# Check 9 asserted, against the shell installer's own source, that the kit README was
# never shipped into targets. The prevention half lives in GovernanceKit
# (_FRESH_PATHS/_UPGRADE_PATHS never listed README.md); the cure half — withdrawing a
# README a past upgrade leaked — has no owner: needs-coordination, 006 epic RESUME
# item 4 (README.md is not in _WITHDRAWN_PATHS there).
echo "  [skip] retired with the shell installer — see 006 epic RESUME, Coordenação pendente #4"

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
done < <(printf '%s\n' \
  "AGENTS.md" ".cursorrules" "CLAUDE.md" ".windsurfrules" "GEMINI.md" \
  ".github/copilot-instructions.md" ".amazonq/rules/ai-agents.md" \
  "new-tag.sh" "scripts/agent-worktree.sh" \
  "scripts/git-bare-remote.sh")
# The list above is maintained by hand: the first nine mirror what GovernanceKit's
# installer ships to targets (_FRESH_PATHS/_UPGRADE_PATHS — keep in sync when that
# set changes); git-bare-remote.sh is not shipped but is kit-owned in this repo and
# carries the banner for the same reason.
if [[ "$missing" -eq 0 ]]; then
  ok "every kit root file carries the banner"
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

echo "== 10c. Declared release stays coherent =="
# The integration contract carries its own `ref`, is copied into every target on
# upgrade, and is what `governancekit --version` reports as the project's kit
# version. It must be the current release or the one being prepared: any version at
# or ahead of the latest tag answers "is it stale?". This used to accept only the
# next PATCH, which made a minor or major release impossible to prepare — the gate
# refused the bump before the tag existed, and the tag could not be cut without the
# bump. Caught while cutting v1.2.0.
integration=".docs/governancekit-integration.json"
integration_ref="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ai_agents"]["ref"])' "$integration" 2>/dev/null || true)"
latest_tag="$(git tag --sort=-version:refname | head -n1)"
ref_ok="$(
  python3 - "$integration_ref" "$latest_tag" <<'REFPY'
import re
import sys


def parse(tag):
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", tag)
    return tuple(map(int, match.groups())) if match else None


ref, latest = parse(sys.argv[1]), parse(sys.argv[2])
print("yes" if ref and latest and ref >= latest else "no")
REFPY
)"
if [[ "$ref_ok" == "yes" ]]; then
  ok "governancekit-integration.json ref is the current release or ahead of it ($integration_ref)"
else
  err "governancekit-integration.json ref '${integration_ref:-unreadable}' is stale or unparsable; latest tag is $latest_tag"
fi

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
for key in products features install advanced unattended compatibility concepts support star; do
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
  if ! grep -qF -- 'governancekit --root "$PWD" install-agents' "$guide" ||
     ! grep -qF -- 'governancekit --root "$PWD" install-agents --upgrade' "$guide"; then
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
# The unattended-run guide is the only page that documents an operating mode rather
# than an install step, and it is the one a reader reaches with a cost question. Both
# halves are asserted: that the three languages stay in sync with their distributed
# copies (same failure the advanced guide already had), and that each one still names
# the contract it summarises — a summary that outlives its contract is worse than none.
unattended_run="docs/unattended-run.html"
unattended_run_ptbr="docs/unattended-run-ptbr.html"
unattended_run_es="docs/unattended-run-es.html"
unattended_ok=1
for guide in "$unattended_run" "$unattended_run_ptbr" "$unattended_run_es"; do
  distributed=".docs/${guide#docs/}"
  if [[ ! -f "$guide" || ! -f "$distributed" ]] || ! cmp -s "$guide" "$distributed"; then
    err "unattended-run language copy is missing or unsynchronized: $guide"
    unattended_ok=0
  fi
  if ! grep -qF '.docs/workflows/unattended-run.md' "$guide"; then
    err "unattended-run page does not name the contract it summarises: $guide"
    unattended_ok=0
  fi
  # Named because the operator arrives believing tokens are cheaper overnight. They
  # are not: the discount that exists is the Batch API's, and it is about how the
  # work is sent, not when. A page that drops this answers the wrong question.
  if ! grep -qF 'Batch API' "$guide"; then
    err "unattended-run page dropped the Batch API cost answer: $guide"
    unattended_ok=0
  fi
done
# The delivery that introduced these pages got this figure wrong once in seven places,
# fixed it in five, and left it wrong in the two that outlive the pages — the napkin
# lessons and the handoff, which is where the next council reads from. So the guard is
# repository-wide, not page-wide: anything citing the incident's input envelope has to
# say the tokens were cache reads. Read as plain input, 7.1M prices the call at ~7x what
# it actually cost, inside the sentence arguing that caching is the lever.
#
# Two things this check learned the hard way. The qualifier must sit right after the
# figure: a first cut searched the whole line, and the word "caching" elsewhere in the
# same sentence satisfied it while the figure stayed unqualified. And the scan is over
# the whole file, not line by line, because markdown wraps prose and the qualifier
# legitimately lands on the next line.
if python3 - <<'ENVPY'
import re, sys
from pathlib import Path

FIGURE = re.compile(r"7[.,]1M(.{0,60})", re.S)
CACHE = re.compile(r"cach", re.I)

bad = []
for path in sorted(Path(".").rglob("*")):
    if path.suffix not in {".md", ".html"} or not path.is_file():
        continue
    if ".git/" in str(path):
        continue
    text = path.read_text(encoding="utf-8", errors="replace")
    for m in FIGURE.finditer(text):
        if not CACHE.search(m.group(1)):
            bad.append(f"{path}:{text.count(chr(10), 0, m.start()) + 1}")
if bad:
    print("; ".join(bad[:3]))
    sys.exit(1)
ENVPY
then
  ok "the 7.1M input envelope is named as cache reads everywhere it is cited"
else
  err "the 7.1M envelope is cited as plain input (it was cache reads) — paths printed above"
fi

# Rates move between model generations, and the same delivery once paired a current
# Opus rate with the previous generation's Sonnet rate — a precise, checkable, wrong
# number where a vague one had been. Naming the generation is what makes the figure
# falsifiable by a reader; the figure alone is not.
rates_named_ok=1
for guide in "$unattended_run" "$unattended_run_ptbr" "$unattended_run_es"; do
  if grep -qF 'MTok' "$guide" && ! { grep -qF 'Opus 5' "$guide" && grep -qF 'Sonnet 5' "$guide"; }; then
    err "unattended-run page quotes per-token rates without naming the model generation: $guide"
    rates_named_ok=0
  fi
done
[[ "$rates_named_ok" == "1" ]] && ok "per-token rates on the unattended-run pages name the model generation"

if [[ "$unattended_ok" == "1" ]] &&
   grep -qF 'unattended-run-ptbr.html' "$landing" &&
   grep -qF 'unattended-run-es.html' "$landing" &&
   grep -qF './unattended-run.html' "$landing"; then
  ok "unattended-run guide is available, routed, and synchronized in EN, PT-BR, and ES"
else
  err "landing does not route all three unattended-run languages"
fi
if grep -qF 'data-install-tab="upgrade"' "$landing" &&
   grep -qF "tab.addEventListener('click'" "$landing" &&
   grep -qF 'data-install-panel="upgrade"' "$landing"; then
  ok "fresh/upgrade installation tabs have interactive behavior"
else
  err "installation tabs are present without a working upgrade interaction"
fi
concepts_public="docs/concepts.html"
concepts_copy=".docs/concepts.html"
if [[ -f "$concepts_public" && -f "$concepts_copy" ]] && cmp -s "$concepts_public" "$concepts_copy"; then
  ok "concepts page is published and synchronized with its distributed copy"
else
  err "$concepts_public is missing or differs from $concepts_copy — the landing nav links it, and Pages publishes docs/ only"
fi
if [[ -f "$advanced_usage" && -f "$advanced_usage_copy" ]] &&
   cmp -s "$advanced_usage" "$advanced_usage_copy" &&
   grep -qF './advanced-usage.html' "$landing"; then
  ok "advanced usage guide is linked and its distributed copy is synchronized"
else
  err "advanced usage guide is missing, unlinked, or differs from its distributed copy"
fi
if grep -qF '.governancekit-identity.json' "$advanced_usage" &&
   grep -qF '.gk/operator.json' "$advanced_usage" &&
   grep -qF '.credentials/identity.json' "$advanced_usage" &&
   grep -qF 'WORKSPACE.md' "$advanced_usage" &&
   ! grep -q 'e.g.[[:space:]]*`WORKSPACE.md`' AGENTS.md; then
  ok "identity documentation names the canonical and legacy files and rejects WORKSPACE.md ambiguity"
else
  err "identity documentation is incomplete or still makes WORKSPACE.md look mandatory"
fi
installer_options=(
  --root --repo --ref --upgrade --force --docs-only --migrate-content
  --track --install-awt --non-interactive --help
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
# Version-pinned installer URLs left the landing with the shell installer's
# retirement: the CLI pins the release (and its checksum) itself, and 10c asserts
# the declared ref. What the landing must still show is the CLI path.
if grep -qF 'governancekit --root /path/to/your-project install-agents' "$landing"; then
  ok "landing shows the governancekit install command"
else
  err "landing does not show the governancekit install command"
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
