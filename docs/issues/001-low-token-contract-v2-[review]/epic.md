# Epic: Low-Token Contract V2

## Metadata
- work_id: WK-20260504-low-token-contract-v2
- date: 2026-05-04
- owner: maintainer
- related_commit: planned

## Context
The source kit currently keeps many universal rules in the root `AGENTS.md`, causing agents to reload detailed instructions even when a task needs only a small subset.

## Problem Statement
The contract needs to remain safe and deterministic while reducing repeated token usage.

## Outcome
Root `AGENTS.md` acts as a compact dispatcher. Installation context and limits remain mandatory target-project gates. Detailed role and workflow behavior is loaded only when relevant. Existing installations can use `--upgrade` to update kit-owned files while preserving project-local context/state.

## Dependencies
- Human-approved branch: `feature/uc-20260504/low-token-contract-v2`
- Human-approved boundary update for this source kit.

## DoD
- Root contract is compact.
- `docs/software-overview.md` and `docs/limits.md` explain their install-time purpose.
- Role/workflow docs retain implementation, quality, security, and session requirements.
- Installer supports safe upgrade mode.
- Handoff, resume, and lesson are updated.

## Privacy Checklist
- Personal data impact: no.

## Session-Close Notes
- Handoff sync status: synced
- Last handoff update date: 2026-05-04
