# Gemini Agent Instructions

<!-- AI-Agents kit-owned file. Do not edit: `governancekit install-agents --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .gk/operator.json (untracked; written by `governancekit install-agents`) -->

Use this repository contract as source of truth:
- AGENTS.md
- docs/software-overview.md
- docs/limits.md
- docs/required-reading.md — complete reading index
- docs/project-rules.md — project-specific rules (project-owned; never overwritten)

Optional: if `~/.config/USER.md` exists, read it to adapt communication style to the user profile (tone, depth, decision framing). Governance behavior is unchanged.

Implementation policy:
- Keep scope strict and explicit.
- Prefer simple and maintainable solutions.
- Validate with focused tests/checks.
- Document security and privacy impacts when relevant.
- Use `work_id` format `WK-YYYYMMDD-<short-slug>` in planning docs and related commits.
- At each stage close, update `handoff.md` and `docs/napkin-lessons.md` using `.docs/workflows/session-close.md`.

If a request is outside limits, stop and request explicit human approval.
