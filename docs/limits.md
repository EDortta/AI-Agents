# Agent Operational Limits

## Metadata
- work_id: WK-YYYYMMDD-<project-slug>
- date: YYYY-MM-DD
- owner: <maintainer>
- limits_ready: no

This file defines hard boundaries for agent execution.

## Allowed
- Implement work explicitly requested by the user.
- Perform necessary supporting refactors required for safe implementation/testing.
- Update tests, docs, and issue artifacts directly related to requested work.
- Use official migration workflows when persistence models change.

## Not Allowed
- Unrelated refactors or speculative improvements.
- Architecture expansion not required by the requested outcome.
- Silent contract changes (API/schema/interface) without explicit declaration.
- Creating empty or low-content Jira/GitHub Issue/PR artifacts.
- Marking issues as solved/finished without objective implementation evidence.

## Branch and Workflow Constraints
- Never start implementation on `main`/`master`.
- Create/switch branch only with explicit user permission.
- Prefer `jkctl.py` for issue/PR automation when available.
- At each stage end, run session-close workflow (`docs/workflows/session-close.md`), update `handoff.md`, and record lessons in `docs/napkin-lessons.md`.

## Security and Secrets
- Never expose secrets/tokens/credentials in logs, code, or issue bodies.
- Never commit `.credentials`, `.env*`, token files, or equivalent secrets.

## Scope Authority
- Any request outside these boundaries must be explicitly flagged.
- Execution outside these boundaries requires explicit human approval first.
