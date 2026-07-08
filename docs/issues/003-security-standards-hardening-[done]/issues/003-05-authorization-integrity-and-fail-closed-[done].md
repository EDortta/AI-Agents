# Task: Authorization integrity — webhook signatures, no mass-assignment, fail-closed

## Metadata
- work_id: WK-20260707-sec-authz-failclosed
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §4 (Authentication and authorization) with three concrete, recurring failure
modes not currently named: unsigned webhooks, self-mutable authorization fields, and
fail-open allowlists/config.

## In Scope
- §4 additions:
  - **Every state-mutating or data-reading route declares an auth guard.** "No auth
    annotation" fails review — absence is not a default-allow.
  - **Inbound webhooks that mutate state verify the provider signature/HMAC before any
    write;** unsigned → 401.
  - **No self-mutable authorization fields.** Self-update endpoints (`PATCH /users/me`)
    never accept `role`/`permissions`/`isAdmin` from the body (mass-assignment); use one
    canonical authorization field checked consistently across all guards.
  - **Fail closed on empty policy and config-load failure.** `if not allowlist or
    caller not in allowlist: deny`. A missing/failed config denies; it never falls back
    to an allow-all or a mock that accepts any credential. Mock/demo auth is gated to
    DEV builds and excluded from production bundles.
- Matching PR self-check lines.

## Out of Scope
- Per-project remediation (own SEC-* alerts).

## ARO
- Acceptance: rules merged; an unsigned mutating webhook, a body-settable role, an
  empty-allowlist-allows branch, or mock auth in a prod bundle each fail review.
- Risk: enumerating "every route has a guard" needs a per-framework convention — note it.
- Operations: partially `doctor`-automatable (grep for mock-auth flags in prod config,
  `origin: true`-style allow-all); signature/mass-assignment stay review-gated.

## Test Plan
- N/A for standards text. Applied: empty allowlist denies; unsigned webhook → 401;
  `PATCH /users/me {role:'ADMIN'}` ignored.

## Security
- Sources: SEC-0021 (payment webhooks without signature → anyone marks paid),
  SEC-0055 (self-service privilege escalation via `body.role`), SEC-0157 (`/aprovar`
  fails open on empty operator list), SEC-0290/0270/0174/0175 (mock/fallback auth
  accepts any password in prod), SEC-0085 (onboarding IDOR), SEC-0002 (BASELY IDOR).
  Napkin: GestaoContasFernanda central public-visibility function + regression test.

## Privacy
- Personal data impact: yes (authz failures exposed others' financial/personal data).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §4 additions + self-check lines drafted; cross-referenced to source SEC ids.
