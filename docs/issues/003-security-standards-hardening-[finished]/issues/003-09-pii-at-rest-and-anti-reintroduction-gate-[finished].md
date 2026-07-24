# Task: PII at rest, no PII in synced dirs, and operator-name anti-reintroduction gate

## Metadata
- work_id: WK-20260707-sec-pii-atrest-gate
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §2 for personal data at rest and add an automated gate that stops a real
operator name (or other PII) from being reintroduced into the public kit contract.

## In Scope
- §2 additions:
  - **PII is never committed nor stored plaintext in a synced dir** (`~/Sync`, cloud-
    synced folders). PII stores are encrypted at rest and have a written retention policy
    before production (reinforces the existing purpose/retention rule).
  - **No PII in filenames** either (rename PII-bearing files).
- Start Gate 1a / hook (automatable):
  - Extend the Start Gate check beyond unfilled `[PLACEHOLDER]` tokens to also grep the
    kit's distributed contract (`AGENTS.md` and shared docs) for a configured
    operator-name / PII regex, so a later commit cannot silently re-add a real name
    (LGPD Art. 46). Wire it as a CI/pre-commit hook, not only a manual gate.
- Matching PR self-check line.

## Out of Scope
- Per-project PII remediation (own SEC-* alerts).
- The hook/gate code lands where the Start Gate lives (AGENTS.md tooling / governancekit).

## ARO
- Acceptance: §2 additions merged; gate spec captured; reintroducing a real operator
  name into a tracked kit file is auto-detected; a plaintext PII store in `~/Sync` fails
  review.
- Risk: the operator-name regex must be configured per-instance and itself kept out of
  the public repo (it references a real name) — store it in the gitignored identity file.
- Operations: automatable (grep gate); at-rest encryption is review-gated.

## Test Plan
- N/A for standards text. Applied: gate fails a commit that adds the real name to
  `AGENTS.md`; passes when only `[OPERATOR_NAME]` is present.

## Security
- Sources: SEC-0102 (operator name reintroduced into public `AGENTS.md` after
  anonymization), SEC-0079/0206 (unencrypted PII dumps/backups), SEC-0066 (WhatsApp
  messages backup unencrypted), SEC-0074/0185/0186/0211 (PII versioned/localStorage),
  SEC-0115/0134/0137 (financial/forensic PII plaintext in synced dirs), SEC-0163/0247
  (undefined retention). Napkin: GovernanceKit per-host identity in gitignored file.

## Privacy
- Personal data impact: yes — this is the PII-specific task; attach
  `.docs/issues/templates/privacy-checklist.template.md` when applied.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §2 additions + gate spec + self-check line drafted; cross-referenced to source SEC ids.
