# Task: Low-Token Root Contract

## Metadata
- work_id: WK-20260504-low-token-contract-v2
- date: 2026-05-04
- owner: maintainer
- related_commit: planned

## Parent Epic
- 001-low-token-contract-v2

## Objective
Convert the source kit to a lower-token contract model without removing safety, readiness, or workflow guarantees.

## In Scope
- Compact `AGENTS.md`.
- Clarify `software-overview.md` and `limits.md` as install gates.
- Add targeted session-restore workflow.
- Move detailed programmer obligations out of root and into `docs/agents/programmer.md`.
- Add installer `--upgrade` mode for existing installations.

## Out of Scope
- Runtime prompt orchestration engine.
- Automated retrieval implementation.
- Remote issue/PR creation.

## ARO
- Acceptance: agents can read less by default and load focused docs only when needed.
- Risk: root contract may become too brief unless role docs preserve required details.
- Operations: docs-only change with no runtime deployment.

## Test Plan
- Review markdown for required gates and role dispatch.
- Run repository text checks for readiness flags and stale references.
- Run installer syntax check.
- Run fresh install and upgrade smoke tests in temporary targets.
- Inspect git diff.

## Security
- No runtime security surface. Contract continues to require security classification for deliveries.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Docs updated.
- Installer upgrade path preserves project-local context/state and deletes stale files from managed directories.
- Validation commands executed or N/A justified.
- Session-close artifacts updated.
