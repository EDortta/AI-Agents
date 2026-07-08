# Task: Enforce commit-only with a deterministic deny-hook; forbid autonomous credential transmission

## Metadata
- work_id: WK-20260707-sec-commitonly-hook
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Strengthen §8 (Rules specific to AI agents): make the commit-only rule enforceable by a
deterministic hook (not prompt goodwill) and forbid autonomous credential transmission.

## In Scope
- §8 additions:
  - **The commit-only rule is backed by a versioned deny-hook.** The kit ships a
    `PreToolUse` deny-hook that exits non-zero for `docker compose up`, service restart,
    `deploy.sh`, `git push`, and `--yes`/`--force`/`--skip-confirm` on production paths.
    It must run even under `--dangerously-skip-permissions`. Rationale: a prompt
    *prevents*, a deterministic gate *catches what escapes*.
  - **No autonomous credential transmission.** Any code that transmits credentials /
    rotates keys / deploys is opt-in, **default off**, and requires explicit human
    confirmation. Private-key bytes are never transmitted — use fingerprints/references
    plus an audit log of exactly what is sent.
- Matching PR self-check line.

## Out of Scope
- Per-project remediation (e.g. disabling the specific offending agent).
- The hook implementation ships with the kit's hook tooling; this task specifies the rule
  and the hook contract.

## ARO
- Acceptance: §8 additions merged; deny-hook contract specified; a default-on credential-
  transmitting agent or a raw private-key send fails review.
- Risk: the deny-hook must not block legitimate local dev (scope to production markers) —
  define the trigger patterns carefully.
- Operations: the hook is the automation; rule text is review-gated. Aligns with the
  global operator rule (autonomous deploy prohibited).

## Test Plan
- N/A for standards text. Applied: hook exits 2 on `deploy.sh --yes` and `git push`
  to a production branch even under skip-permissions.

## Security
- Sources: SEC-0096 (`CredentialsSyncAgent` base64-ships SSH private keys + `.credentials/`
  to `wss://jkx.app`, `enabled` default `True`), all 11 SOURCE A alerts (code fixed but
  rotation/deploy deliberately deferred to operator). Napkin: wa-hub "Nexo deploy gate"
  (prompt instruction relies on model goodwill; the real barrier is a versioned PreToolUse
  deny-hook). Precedent: global CLAUDE.md autonomous-deploy prohibition (2026-06-25 incident).

## Privacy
- Personal data impact: yes (credential/key exfiltration).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §8 additions + deny-hook contract + self-check line drafted; cross-referenced to source SEC ids.
