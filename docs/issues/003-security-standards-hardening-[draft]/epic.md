# Epic: Security Standards Hardening from Ecosystem Lessons

## Metadata
- work_id: WK-20260707-sec-standards-hardening
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Context
The kit's `.docs/agents/security-standards.md` was distilled from ~280 production
vulnerabilities into 8 sections + a PR self-check. Since then, a running catalogue
of ~296 vulnerabilities (`security-issues/`), per-project `SECURITY-ALERT-*` files,
and `docs/napkin-lessons.md` entries across the kit-installed projects have surfaced
recurring failure modes that the current 8 sections either do not name or only cover
in principle. Because the kit is shared, a rule added here travels to every project
that installs it — the highest-leverage place to fix a class of bug once.

## Problem Statement
Several high-frequency, high-severity classes are **not explicitly required** by the
current standards, so they slip through review project after project:
- path traversal / SSRF from caller-supplied paths and URLs (incl. the kit's own
  AI-Gateway/AI-hub: SEC-0033/0035/0108/0141);
- SQL / shell / command injection, up to unauthenticated RCE (SEC-0027);
- disabled TLS certificate verification and cleartext transport of secrets/PII;
- weak password hashing, non-CSPRNG secrets, non-expiring/non-revocable tokens;
- fail-open authorization (empty allowlist allows; mock auth shipped to prod;
  unsigned state-mutating webhooks; self-mutable role fields);
- secrets/tokens/PII in URLs, logs, and synced dirs; operator-name reintroduced
  into the public contract (SEC-0102);
- kit templates binding `0.0.0.0` with trivial creds; localhost daemons without a
  Host-header guard;
- supply-chain gaps beyond checksum (mutable-ref install, tar-slip, `curl|bash`);
- the commit-only rule enforced only by prompt goodwill, not a deterministic hook;
  autonomous credential transmission (SEC-0096);
- prompt-injection via untrusted content interpolated into action-generating prompts.

## Outcome
A reviewed set of standards additions/extensions (one task per class), each with
concrete rule text and a note on `doctor`-automatability, ready to be merged into
`security-standards.md` (and the PR self-check) in approved follow-ups.

## Dependencies
- `.docs/agents/security-standards.md` (baseline being extended).
- `governancekit doctor` (`AI-GovernanceKit/governancekit/doctor.py`) for the
  automatable subset (SEC-0221 matcher gaps, tracked-secret detection).
- The central `security-issues/` catalogue and per-project alerts as evidence.

## DoD
- 13 task files present under `issues/`, each citing sources, the section it extends,
  proposed rule text, and automatability; README task index matches; `governancekit
  doctor` PASS on AI-Agents; no real PII in any file (uses `[OPERATOR_NAME]`).

## Privacy Checklist
- No personal data collected or stored by this epic. Task 09 carries the PII-specific
  checklist items; see `.docs/issues/templates/privacy-checklist.template.md`.

## Session-Close Notes
- Handoff sync status: pending
- Last handoff update date: 2026-07-07
