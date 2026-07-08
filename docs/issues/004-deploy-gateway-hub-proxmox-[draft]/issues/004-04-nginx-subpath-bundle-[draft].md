# Task: Versioned nginx bundle — sub-path proxy for Gateway + Hub (internal to the VM)

## Metadata
- work_id: WK-20260708-nginx-subpath
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
Provide a versioned nginx server block (running **inside the VM**, not on the host) that
fronts both loopback apps on sub-paths, stripping the prefix and, for the hub, presenting
`Host: localhost` so the daemon's Host-allowlist is satisfied with zero code changes.

## In Scope
- New bundle, e.g. `deploy/nginx/ai-ecosystem.conf` (in AI-Gateway, with the hub block
  documented cross-repo, or a small mirror in AI-hub `deploy/nginx/`):
  - `location /api-gateway/ { proxy_pass http://127.0.0.1:8000/; }` (trailing slash strips
    the prefix) with standard `proxy_set_header` (`X-Forwarded-*`, `Host $host`).
  - `location /api-hub/ { proxy_pass http://127.0.0.1:9400/; proxy_set_header Host localhost; }`
    — the `Host: localhost` override defeats the daemon's Host-allowlist 403 without
    broadening it (complements the opt-in env in 004-03).
  - `Authorization` header passthrough preserved for both (Gateway API key; hub Bearer).
- README note: this nginx runs **inside the VM** and must not collide with the **host**
  nginx that owns `:80` and serves `/enviar-arquivo/` — the VM has its own IP/port; the
  host config is untouched.

## Out of Scope
- Provisioning/installing nginx on the VM (that is the runbook, 004-05).
- TLS termination decision (internal network; note as a follow-up if exposed).

## ARO
- Acceptance: `nginx -t` passes on the bundle; locally, `location /api-gateway/` reaches a
  Gateway on `127.0.0.1:8000` (200 on `/api-gateway/health`) and `location /api-hub/` reaches
  the daemon with `Host: localhost` (200 on `/api-hub/status` with a valid Bearer, not 403).
- Risk: trailing-slash mismatch in `proxy_pass` breaks prefix stripping; missing
  `Host: localhost` re-introduces the 403; forgetting `Authorization` passthrough breaks auth.
- Operations: config is versioned; installed on the VM only, additively.

## Test Plan
- Local: run nginx with the bundle in front of stub/real upstreams; assert prefix strip,
  Host rewrite (hub 200 not 403), and Bearer/API-key passthrough end to end.

## Security
- Does not expose Chrome CDP or any datastore; only the two app ports via defined locations.
  Cross-ref epic 003 (network exposure, Host header). No secrets in the config.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Versioned nginx bundle; `nginx -t` clean; local proof of prefix strip + hub `Host: localhost`
  (200 not 403) + auth passthrough; explicit note that host nginx is untouched.
