# Claude Project Instructions

## Mandatory Context
Read and follow:
- AGENTS.md
- docs/software-overview.md
- docs/limits.md

## Behavior Contract
- Solve root cause, not only symptoms.
- Preserve backward compatibility unless explicitly changed.
- Keep changes scoped and explain trade-offs.
- Do not perform out-of-scope architecture expansion.

## Safety and Compliance
- Never leak credentials/secrets in code, logs, or docs.
- Apply security review for runtime-impacting changes.
- Apply privacy-compliance review for personal-data changes.

## Delivery Expectations
- Provide implementation summary, changed files, tests, and residual risks.
- Report what was validated and what was not validated.
- Use `work_id` format `WK-YYYYMMDD-<short-slug>` in planning docs and related commits.
- At each stage end, run session-close: update `handoff.md` and `docs/napkin-lessons.md` (`docs/workflows/session-close.md`).
