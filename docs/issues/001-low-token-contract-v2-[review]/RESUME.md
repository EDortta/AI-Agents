# Resume: WK-20260504-low-token-contract-v2

- date: 2026-05-04
- branch: `feature/uc-20260504/low-token-contract-v2`
- status: review
- focus: low-token source-kit contract v2

## Current State
- Root `AGENTS.md` converted to compact dispatcher.
- Install gate intent added to `docs/software-overview.md` and `docs/limits.md`.
- Programmer/session workflow docs updated with detailed rules.

## Changed Files
- `AGENTS.md`
- `docs/software-overview.md`
- `docs/limits.md`
- `docs/agents/programmer.md`
- `docs/agents/_shared.md`
- `docs/workflows/session-restore.md`
- `docs/workflows/session-close.md`
- `docs/issues/001-low-token-contract-v2-[review]/`
- `docs/agents/security.md`
- `docs/agents/privacy-compliance.md`
- `scripts/install-agents-kit.sh`
- `README.md`
- `README-ptbr.md`
- `README-es.md`

## Checks
- `rg -n "project_context_ready|limits_ready|..." .` -> readiness and stale-reference scan completed; stale role references fixed.
- `rg -n "## [0-9]+\\. (...old section names...)" docs AGENTS.md` -> no old numbered section references found.
- `wc -l AGENTS.md docs/agents/programmer.md docs/workflows/session-restore.md docs/workflows/session-close.md` -> root contract is 182 lines.
- `bash -n scripts/install-agents-kit.sh` -> passed.
- fresh install smoke test in temp target -> exited 30 and reset target readiness flags to `no`.
- upgrade smoke test in temp target -> preserved overview/limits/handoff/lessons/issues/credentials and deleted stale managed `docs/agents/obsolete.md`.
- `git diff --check` -> passed.

## Next Step (DO THIS FIRST)
Review the docs diff, then commit with subject `[WK-20260504-low-token-contract-v2] Reduce root contract token load` if accepted.
