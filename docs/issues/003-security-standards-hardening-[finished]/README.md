# Security Standards Hardening from Ecosystem Lessons

## Metadata
- work_id: WK-20260707-sec-standards-hardening
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Objective
- Turn the concrete security lessons harvested across the projects that use this
  kit into **generalizable additions/extensions** to `.docs/agents/security-standards.md`
  (and, where cheap, to `governancekit doctor` checks) — so every project that
  installs the kit inherits the hardening, not just the project where the bug was found.

## Scope
- In scope: proposing new/extended **rules** in the kit's security standards and
  matching PR self-check items; flagging which are automatable in `doctor`.
  One task per theme. Discussion artifacts only — for the operator to review.
- Out of scope: editing `security-standards.md` / `AGENTS.md` / `doctor.py` in this
  epic (each rule is applied in its own follow-up once approved); fixing the
  individual project bugs (those live in each project's own SEC-* alerts and the
  central `security-issues/` catalog).

## ARO
- Acceptance: each task names (a) the source lessons (SEC-* ids / napkin entries),
  (b) which existing standards section it extends or that it is a new section,
  (c) concrete rule text to add, (d) whether it is `doctor`-automatable. `governancekit doctor`
  stays PASS on AI-Agents; every file follows the kit issue template and `[draft]` naming.
- Risk: over-broad rules create false-positive review friction; each task keeps the
  rule falsifiable and scoped. No rule is auto-enforced until approved.
- Operations: status advances by **rename** (`[draft]`→`[ready]`→…). PII-free: kit
  files use `[OPERATOR_NAME]`, never a real name (this epic itself codifies that gate).

## Privacy
- No personal data stored in these issues. Task 09 specifically addresses PII handling
  and the operator-name anti-reintroduction gate (LGPD Art. 46 / Start Gate 1a).

## Session-Close
- Handoff entry updated in `handoff.md`: pending
- Napkin lesson added in `docs/napkin-lessons.md`: pending

## Provenance
- Distilled from ~296 catalogued vulnerabilities (`security-issues/`), 11 per-project
  `SECURITY-ALERT-*` files, and security/privacy entries in `docs/napkin-lessons.md`
  across ~15 kit-installed projects. Several sources are the kit's OWN components
  (AI-Gateway, AI-hub, GovernanceKit, AI-Agents) — those are the highest-leverage,
  since the kit propagates to every client.

## Task Index
- 003-01-path-traversal-and-ssrf-[draft].md — NEW §: validate caller-supplied paths & URLs
- 003-02-injection-defense-sql-shell-filename-[draft].md — NEW §: no request data into SQL/shell
- 003-03-transport-security-and-cert-verification-[draft].md — extends §3: no disabled TLS verify
- 003-04-cryptography-and-token-lifecycle-[draft].md — NEW §: hashing, CSPRNG, token expiry/revocation
- 003-05-authorization-integrity-and-fail-closed-[draft].md — extends §4: webhooks, mass-assign, fail-closed
- 003-06-auth-rate-limiting-enumeration-password-policy-[draft].md — extends §4
- 003-07-secrets-defaults-keymaterial-and-doctor-gaps-[draft].md — extends §1 + doctor
- 003-08-secrets-and-tokens-never-in-urls-or-logs-[draft].md — extends §2
- 003-09-pii-at-rest-and-anti-reintroduction-gate-[draft].md — extends §2 + Start Gate 1a
- 003-10-network-exposure-templates-and-host-header-[draft].md — extends §3 + kit artifacts
- 003-11-supply-chain-pin-slip-and-curlbash-[draft].md — extends §7
- 003-12-agent-commit-only-deny-hook-and-credential-transmission-[draft].md — extends §8
- 003-13-prompt-injection-delimiting-schema-and-autoaction-[draft].md — extends §8
