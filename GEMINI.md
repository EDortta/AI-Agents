# Gemini Agent Instructions

Use this repository contract as source of truth:
- AGENTS.md
- docs/software-overview.md
- docs/limits.md

Implementation policy:
- Keep scope strict and explicit.
- Prefer simple and maintainable solutions.
- Validate with focused tests/checks.
- Document security and privacy impacts when relevant.
- Use `work_id` format `WK-YYYYMMDD-<short-slug>` in planning docs and related commits.
- At each stage close, update `handoff.md` and `docs/napkin-lessons.md` using `docs/workflows/session-close.md`.

If a request is outside limits, stop and request explicit human approval.
