# Handoff Log

Use this file to resume work after clearing sessions.
Most recent entry should be on top.

---

## [2026-05-07] WK-20260507-personal-touch-1.0.2 - done

- Status: ready-for-review
- Summary: 1.0.2 — USER.md as first-class personal touch mechanism; `.cursorrules` rewritten self-contained; AI-GovernanceKit relationship defined as companion; all tool adapters updated.
- Next steps:
  - Review diff.
  - Run `./new-tag.sh auto` to tag 1.0.2 if accepted.
- Blockers/Risks:
  - No blocker. Main risk: `.cursorrules` §3 session-close format may be too prescriptive; trim if it causes friction in Cursor.
- Files changed:
  - `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`
  - `docs/agents/_shared.md`, `docs/agents/communication.md` (new)
  - `README.md`, `handoff.md`, `docs/napkin-lessons.md`
  - `AI-GovernanceKit/README.md`
- Checks/Tests executed:
  - `bash -n scripts/install-agents-kit.sh` -> pending reviewer run
  - grep `~/.config/USER.md` across adapters -> pending reviewer run
- Related commits:
  - planned: `[WK-20260507-personal-touch-1.0.2] Add USER.md personal touch mechanism and rework Cursor adapter`
- Suggested restart prompt:
  - "Continue work_id WK-20260507-personal-touch-1.0.2. Read AGENTS.md, docs/software-overview.md, docs/limits.md and this handoff entry before coding."

---

## [2026-05-04] WK-20260504-low-token-contract-v2 - review

- Status: ready-for-review
- Summary: Root `AGENTS.md` was reduced into a low-token dispatcher while install gates and detailed safety/workflow rules were preserved in focused docs. Installer now has `--upgrade` for safe existing-target migration.
- Next steps:
  - Review the docs diff.
  - Commit with subject `[WK-20260504-low-token-contract-v2] Reduce root contract token load` if accepted.
- Blockers/Risks:
  - No blocker. Main review risk is whether the compact root contract removed any rule that should remain always-loaded.
- Files changed:
  - `AGENTS.md`
  - `docs/software-overview.md`
  - `docs/limits.md`
  - `docs/agents/_shared.md`
  - `docs/agents/programmer.md`
  - `docs/agents/security.md`
  - `docs/agents/privacy-compliance.md`
  - `docs/workflows/session-restore.md`
  - `docs/workflows/session-close.md`
  - `docs/issues/001-low-token-contract-v2-[review]/`
  - `scripts/install-agents-kit.sh`
  - `README.md`
  - `README-ptbr.md`
  - `README-es.md`
- Checks/Tests executed:
  - `rg -n "project_context_ready|limits_ready|..." .` -> readiness and stale-reference scan completed
  - `rg -n "## [0-9]+\\. (...old section names...)" docs AGENTS.md` -> no stale old section references
  - `wc -l AGENTS.md docs/agents/programmer.md docs/workflows/session-restore.md docs/workflows/session-close.md` -> root contract is 182 lines
  - `bash -n scripts/install-agents-kit.sh` -> passed
  - fresh install smoke test in temp target -> exited 30 and reset target readiness flags to `no`
  - upgrade smoke test in temp target -> preserved project-local state and deleted stale managed files
  - `git diff --check` -> passed
- Related commits:
  - planned: `[WK-20260504-low-token-contract-v2] Reduce root contract token load`
- Suggested restart prompt:
  - "Continue work_id WK-20260504-low-token-contract-v2. Read docs/issues/001-low-token-contract-v2-[review]/RESUME.md first."

## [YYYY-MM-DD] <work_id> - <stage>

- Status: <in-progress|blocked|ready-for-review|done>
- Summary: <short status summary>
- Next steps:
  - <step 1>
  - <step 2>
- Blockers/Risks:
  - <risk or none>
- Files changed:
  - <path>
- Checks/Tests executed:
  - <command> -> <result>
- Related commits:
  - <hash or planned commit message>
- Suggested restart prompt:
  - "Continue work_id <work_id>. Read AGENTS.md, docs/software-overview.md, docs/limits.md and this handoff entry before coding."
