# Task: No secret/PII defaults in tracked files; key-material hygiene; close doctor gaps

## Metadata
- work_id: WK-20260707-sec-secrets-doctor
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §1 (Secrets and credentials) and the automated `governancekit doctor` check to
close the concrete gaps that let secrets and personal defaults reach tracked files.

## In Scope
- §1 additions:
  - **No personal identifier or secret as a default in a tracked file** (script default,
    env example, sample). Values source from env / `~/.config` and **fail when unset**
    (the `WA_HUB_KEY` pattern), never a baked-in default.
  - **No fallback secret** (e.g. `JWT_SECRET = os.getenv(...) or "dev"`); missing → fail-fast.
  - **Key material never in a repo or synced dir:** `*.pem *.key *.ppk *.pfx *.ovpn
    id_rsa id_ed25519 *.env* .credentials` are gitignored from the first commit and
    stored `chmod 600` (dirs `700`).
- `governancekit doctor` (automatable, ties into Frente #4):
  - Extend the tracked-secret matcher (SEC-0221) to also flag `.credentials` (file),
    `.env*` (all variants), and key-material extensions above — kept in sync with the
    kit `.gitignore`.
  - Add an advisory scan for operator-PII / secret-looking literals used as defaults.
- Matching PR self-check line.

## Out of Scope
- Rotation/purge of already-leaked secrets (operator task, per §1 and §8).
- The `doctor.py` code change itself lands in AI-GovernanceKit under Frente #4.

## ARO
- Acceptance: §1 additions merged; doctor matcher gap (SEC-0221) captured as a concrete
  check spec; a secret/PII default or committed key-material file fails review/doctor.
- Risk: broadening doctor's matcher may flag intentional example files — allow an
  explicit, reviewed ignore annotation.
- Operations: largely `doctor`-automatable; this task is the highest-leverage automation.

## Test Plan
- N/A for standards text. Applied: `doctor` flags a tracked `.env.override`, a
  `.credentials` file, and an `id_rsa`; passes a clean repo.

## Security
- Sources: SEC-0034 (operator phone as default in kit `notify-nexo.sh`), SEC-0221
  (doctor matcher gaps), SEC-0073/0077/0209 (fallback secrets), SEC-0043/0048/0060/0261
  (SSH/VPN keys in repo/sync), SEC-0051 (pfx `1234`), plus the large hardcoded-secret
  roll-up. Napkin: wa-hub credential-symlink rotation; GovernanceKit SEC-0256/gitignore
  preventive doctor check.

## Privacy
- Personal data impact: yes (operator PII as script default; LGPD).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §1 additions + doctor check spec + self-check line drafted; cross-referenced to SEC ids.
