# GitHub Copilot Instructions

Before suggesting or applying changes, align with:
- AGENTS.md
- docs/software-overview.md
- docs/limits.md

Project expectations:
- Root-cause fixes over patchy symptom fixes.
- No unrelated refactors.
- Backward compatibility by default.
- Security and privacy review for relevant changes.

Issue artifacts:
- Use docs/issues epic-folder structure and templates.
- Include privacy checklist when personal data is involved.
- Use `work_id` format `WK-YYYYMMDD-<short-slug>` in planning docs and related commits.

Session close:
- At each stage end, update `handoff.md` and `docs/napkin-lessons.md`.
- Follow `docs/workflows/session-close.md`.
