# RESUME — WK-20260701-dotdocs-kit-layout

## Next Step (DO THIS FIRST)
Coordinate the merge with the twin Python installer in `AI-GovernanceKit`
(same work_id: `WK-20260701-dotdocs-kit-layout`) so source and installer land the
`.docs/` layout together. Then merge this branch and mark the epic `[finished]`.

## Status
- Source-side restructure implemented and self-verified (3 tasks). Branch:
  `feature/WK-20260701-dotdocs-kit-layout`. Ready for review.

## Changed Files
- `scripts/install-agents-kit.sh` (new `.docs/` layout + `migrate_legacy_layout()`)
- `AGENTS.md` (Documentation ownership rewritten), `CLAUDE.md`, `GEMINI.md`
- `README.md`, `README-ptbr.md`, `README-es.md`, `.cursorrules`, `.windsurfrules`
- `.github/copilot-instructions.md`, `.gitignore`, `docs/required-reading.md`
- Moved kit-owned tree `docs/*` → `.docs/*` (agents, workflows, articles, icons,
  software-overview.md, limits.md, index.html, concepts.html, issues/templates,
  issues/README.md)

## Checks
- `bash -n scripts/install-agents-kit.sh` -> passed
- fresh install (temp) -> kit in `.docs/`, `docs/` seeded, readiness reset, exit 30
- legacy migration (temp) -> moved kit to `.docs/`, promoted `docs/project/*`, backup made
- conflict + idempotency (temp) -> honest reporting, no re-migration, backup not clobbered
- residual kit-owned `docs/` scan -> 0
- 3 adversarial skeptics -> 6 findings, all fixed and retested

## Divergence
- Twin installer in `AI-GovernanceKit` must be aligned (issue opened there).
