# Napkin Lessons Learned

Short, practical lessons captured at session close.
Keep each lesson concise and actionable.

## Entry format
- `[YYYY-MM-DD] <work_id> - <lesson>`
- `Action next time: <specific behavior to repeat/avoid>`

## Entries
- `[2026-05-07] WK-20260507-personal-touch-1.0.2 - Cursor ignores chain-loaded files; tool adapters must be self-contained to be effective.`
- `Action next time: Write .cursorrules to cover start gate, hard rules, session-close format, quality gates, and branch rules — no chain-loading assumption.`
- `[2026-05-07] WK-20260507-personal-touch-1.0.2 - USER.md is a global user-level file (~/.config/USER.md); never put it in the project repo or the install script.`
- `Action next time: Document the convention in README and all adapter files; keep it optional so the kit works without it.`
- `[2026-05-04] WK-20260504-low-token-contract-v2 - Keep root contracts as dispatchers and move detailed behavior to role/workflow docs to reduce repeated context.`
- `Action next time: Preserve hard gates in AGENTS.md, but push task-specific detail behind explicit load rules.`
- `[2026-05-04] WK-20260504-low-token-contract-v2 - Upgrade paths must preserve target-local context while replacing managed directories so removed kit files disappear.`
- `Action next time: Test fresh install and upgrade separately before declaring installer behavior safe.`
- `[2026-05-11] WK-20260511-php-delphi-audit-capability - When adding language support to the kit, mirror the exact output format of the existing reference (typescript-audit.md) — teams can then compare maturity scores across languages on the same scale.`
- `Action next time: Always produce the new audit workflow file first, then update programmer.md and reviewer.md; the workflow file is the source of truth that informs what rules belong in the contracts.`
- `[2026-05-11] WK-20260511-php-delphi-audit-capability - A real audit run (YeAPF2, 86 files, PHP 5.5/10) revealed that tooling baseline (PHPStan, CS-Fixer) is the single highest-leverage item: installing it costs 1 hr and gates all other type-safety improvements.`
- `Action next time: Lead audit recommendations with tooling setup, not code changes — without PHPStan, devs have no feedback loop to sustain improvements.`
- `[2026-07-01] WK-20260701-dotdocs-kit-layout - A path sweep by prefix (docs/agents etc.) misses bare directory args in shell examples (cp -r AI-Agents/docs) and links prefixed with ./ that a negative-lookbehind guard skips; adversarial skeptics caught 3 such stragglers in tutorials.`
- `Action next time: After a mechanical rename sweep, run a second grep for the bare token (word 'docs' as a path arg, './docs', 'AI-Agents/docs') — not just the prefixed forms — and verify with an independent reviewer.`
- `[2026-07-01] WK-20260701-dotdocs-kit-layout - A migration that auto-promotes files must never claim 'complete' when conflicts strand items, and must never rm -rf an existing backup.`
- `Action next time: Track a conflict counter, print an honest finished-with-N-conflicts message, and pick a free backup name (bak, bak-1, ...) instead of clobbering.`
- `[2026-07-02] WK-20260702-branch-ascii-and-identity - A branch named "development" (quotes part of the ref) corrupted tooling because issue titles were passed near-raw to git; contracts had no character allow-list.`
- `Action next time: Whenever a helper can create a ref, validate against ^[a-zA-Z0-9/_-]+$ before touching git, and document the same rule in AGENTS.md so agents sanitize slugs before checkout -b.`
- `[2026-07-02] WK-20260702-branch-ascii-and-identity - Shared governance docs on a shared branch hide host-level collisions (two hosts commit on the same branch, ports clash) because nothing individualizes the instance.`
- `Action next time: Mandate a per-instance identity file (operator/host/paths/ports/branch_ownership) read before acting, with a same-branch guard, and split shared vs individual artifacts explicitly.`
- `[2026-07-07] WK-20260707-sec-standards-hardening - ~296 catalogued vulns + 11 per-project SECURITY-ALERTs + napkin lessons across kit projects surfaced ~13 recurring classes the 8-section security-standards did not explicitly name (path-traversal/SSRF, SQL/shell injection, disabled TLS verify, weak crypto/token lifecycle, fail-open authz, secrets/PII in URLs/logs/synced dirs, mutable-ref supply chain, commit-only enforced by prompt goodwill only, prompt-injection auto-actions).`
- `Action next time: Harvest ecosystem SEC-* + napkin lessons, classify against the current standards sections, and open ONE epic (docs/issues) with a task per gap that proposes concrete rule text + notes doctor-automatability — do not edit the standard directly; let the operator approve each rule. Kit files must use [OPERATOR_NAME], never a real name (the SEC-0102 anti-reintroduction gate this epic itself codifies).`
- `[2026-07-08] WK-20260708-deploy-gw-hub-vm - Dois planos do mesmo alvo (192.168.7.200) divergiam em topologia (1 VM vs 3 LXCs) E um deles se auto-contradizia: a intro dizia "caixa ociosa, operador aprovou wipe" mas a própria seção de descobertas listava infra VIVA (nginx :80 servindo /enviar-arquivo/, túnel :2203, OpenVPN, DHCP) com gate de limpeza ainda aberto.`
- `Action next time: Antes de gerar issues de deploy, ler os planos companheiros por inteiro e cruzar a intro com as seções de descobertas — a premissa do topo pode estar desatualizada. Escolher a topologia ADITIVA (VM isolada) quando ela evita reabrir um gate destrutivo, e escrever a lista de infra-intocável como pré-flight explícito na issue de runbook, não só na cabeça.`
- `[YYYY-MM-DD] WK-YYYYMMDD-example - <lesson learned>`
- `Action next time: <what to do differently>`
