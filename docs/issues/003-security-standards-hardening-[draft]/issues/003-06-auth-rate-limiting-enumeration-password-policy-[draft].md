# Task: Rate-limiting, anti-enumeration, and password policy on auth endpoints

## Metadata
- work_id: WK-20260707-sec-ratelimit-enum
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §4's existing login rate-limit rule to cover the full auth surface
(forgot/reset-password), resist user-enumeration, and set a minimum password policy.

## In Scope
- §4 additions (building on the existing "login has rate limiting and progressive
  lockout, shared across instances" rule):
  - **All auth-sensitive endpoints** — login, forgot-password, reset-password, token
    verification — have rate limiting + temporary lockout, with shared state.
  - **No user-enumeration:** login and password-reset return uniform responses/timing
    regardless of whether the account exists.
  - **Minimum password policy:** enforce a documented minimum length/complexity; no
    trivial minimums (e.g. 6 chars) for accounts protecting personal/financial data.
- Matching PR self-check line.

## Out of Scope
- Per-project remediation (own SEC-* alerts).

## ARO
- Acceptance: rules merged; a reset endpoint without rate limiting, an enumerable
  login/reset response, or a trivial password minimum fails review.
- Risk: shared rate-limit state needs Redis/equivalent — operational note (already
  implied by the existing §4 shared-state rule).
- Operations: review-gated; hard to fully automate in `doctor`.

## Test Plan
- N/A for standards text. Applied: brute-force is throttled/locked; existing vs
  non-existing account responses are indistinguishable.

## Security
- Sources: SEC-0289 (password-reset user-enumeration + no rate limit + weak 6-char
  policy), SEC-0160 (login without rate limit), SEC-0236/0191 (weak password policy).

## Privacy
- Personal data impact: yes (enumeration reveals account existence; brute-force targets
  personal accounts).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §4 additions + self-check line drafted; cross-referenced to source SEC ids.
