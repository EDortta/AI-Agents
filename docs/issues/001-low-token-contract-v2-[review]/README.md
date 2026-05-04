# Low-Token Contract V2

## Metadata
- work_id: WK-20260504-low-token-contract-v2
- date: 2026-05-04
- owner: maintainer
- related_commit: planned

## Objective
- Reduce always-loaded agent context while preserving installation gates, security, workflow, and traceability requirements.

## Scope
- In scope: root contract compaction, install-gate clarification, role/workflow dispatch, session memory guidance, safe installer upgrade mode.
- Out of scope: TypeScript runtime engine, vector retrieval, GitHub/Jira issue creation, application code changes.

## ARO
- Acceptance: `AGENTS.md` becomes a low-token dispatcher, detailed rules remain reachable in focused docs, and the installer can upgrade existing targets without overwriting project-local context/state.
- Risk: over-compression could remove enforceable safety rules.
- Operations: source kit remains copy/adapt friendly for target repositories.

## Privacy
- Personal data impact: no.

## Session-Close
- Handoff entry updated in `handoff.md`: yes
- Napkin lesson added in `docs/napkin-lessons.md`: yes

## Task Index
- `issues/001-low-token-root-contract-[review].md`
