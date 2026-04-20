# Session-Close Workflow

Run this at the end of each implementation stage/session.

## Required steps

1. Confirm active `work_id` and date.
2. Update `handoff.md` with status, next steps, blockers, changed files, and checks/tests.
3. Add at least one short lesson to `docs/napkin-lessons.md`.
4. Ensure planning docs and commit plan use the same `work_id`.
5. If automation exists (for example `session-close` in dev-workflow), execute it.

## Optional automation

If your repository has a `dev-workflow` command layer, see:
- `docs/workflows/dev-workflow-integration.md`

## Output quality bar

- Handoff must be enough for another programmer to continue without chat history.
- Lessons must be specific, not generic motivation.
- Work identifier linkage must be explicit and traceable.
