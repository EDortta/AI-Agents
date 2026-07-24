# Task: Kit templates bind loopback with no trivial creds; localhost daemons guard Host header

## Metadata
- work_id: WK-20260707-sec-exposure-hosthdr
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §3 for two concrete gaps: kit-shipped templates that expose services on
`0.0.0.0` with default creds, and localhost daemons missing a Host-header guard.

## In Scope
- §3 additions:
  - **Kit compose/worktree templates bind `127.0.0.1` by default** and never ship
    trivial default datastore creds — generate a per-worktree/per-project random
    password. External exposure stays a named opt-in.
  - **No trivial default creds for any exposed datastore/admin port** (MQTT, ES/Kibana,
    haproxy stats, Chrome CDP/debug ports must not be exposed).
  - **Localhost-bound daemons validate the `Host` header** (allowlist localhost/expected
    names) to resist DNS-rebinding, in addition to a bearer token.
- Fix the kit's own offending template(s) in the follow-up (see sources).
- Matching PR self-check line.

## Out of Scope
- Per-project remediation of exposed ports (own SEC-* alerts).

## ARO
- Acceptance: §3 additions merged; the kit's `templates/docker-compose.worktree.yml`
  no longer binds `0.0.0.0`/`app:app`; a new localhost daemon without a Host guard fails
  review.
- Risk: per-worktree random passwords must propagate to the app config generation — note
  it in the template.
- Operations: partially `doctor`-automatable (grep templates for `0.0.0.0`, port maps
  without `127.0.0.1`, and `app`/trivial default creds).

## Test Plan
- N/A for standards text. Applied: `curl -H 'Host: evil' localhost:PORT` → 403;
  template binds loopback.

## Security
- Sources: SEC-0103 (kit worktree template publishes Postgres on 0.0.0.0 with `app/app/app`),
  SEC-0001 + AI-hub SECURITY-ALERT (Host-header guard added with token + fail-closed 503),
  SEC-0036/0069/0154/0155 (Chrome CDP debug port), SEC-0095/0014/0139 (MQTT), SEC-0067
  (ES/Kibana), SEC-0135 (haproxy stats no auth), SEC-0178 (world-writable data dirs).

## Privacy
- Personal data impact: indirect (exposed datastores hold personal data).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §3 additions + self-check line drafted; kit template fix scoped; cross-referenced to SEC ids.
