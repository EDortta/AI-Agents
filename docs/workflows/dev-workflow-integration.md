# Dev-Workflow Integration (Session-Close Hook)

Use this pattern when your project has a `dev-workflow` command runner.

## Goal

Automatically trigger session-close at the end of each stage so context is never lost.

## Recommended behavior

At each stage end, run steps equivalent to:
1. update `handoff.md`
2. update `docs/napkin-lessons.md`
3. validate `work_id` linkage across planning docs and commit message

## Example command sequence

```bash
# Example only; adapt to your tooling
./dev-workflow stage-finish --work-id "WK-20260420-auth-reset"
./dev-workflow session-close --work-id "WK-20260420-auth-reset"
```

## Minimum acceptance for automation

- Fails if `handoff.md` has no new entry for the active `work_id`
- Fails if no lesson was added to `docs/napkin-lessons.md`
- Warns if commit message does not include active `work_id`
