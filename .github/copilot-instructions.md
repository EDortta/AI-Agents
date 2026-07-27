# GitHub Copilot Instructions

<!-- AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .credentials/identity.json (untracked, per-programmer) -->

Before suggesting or applying changes, align with:
- AGENTS.md
- .docs/software-overview.md
- .docs/limits.md
- docs/required-reading.md — complete reading index
- docs/project-rules.md — project-specific rules (project-owned; never overwritten)

Optional: if `~/.config/USER.md` exists, read it to adapt communication style to the user profile (tone, depth, decision framing). Governance behavior is unchanged.

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
- Follow `.docs/workflows/session-close.md`.
