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
- `[YYYY-MM-DD] WK-YYYYMMDD-example - <lesson learned>`
- `Action next time: <what to do differently>`
