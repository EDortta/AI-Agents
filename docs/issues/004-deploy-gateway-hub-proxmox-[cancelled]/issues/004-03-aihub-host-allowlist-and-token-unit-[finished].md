# Task: AI-hub — env-configurable Host-allowlist + daemon token in the VM systemd unit

## Metadata
- work_id: WK-20260708-aihub-hosts-unit
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
Make the chrome-daemon proxy-friendly on the VM without weakening its DNS-rebinding
defense: allow the Host-allowlist to be extended via env, and ensure `AIHUB_DAEMON_TOKEN`
is loaded by the daemon's systemd unit on the VM.

## In Scope
- `chrome-daemon/main.py`: make `_ALLOWED_HOSTS` seed from env
  `AIHUB_ALLOWED_HOSTS` (comma-separated) merged with the current hardcoded
  `{127.0.0.1, localhost, ::1}` — default (unset) keeps today's behavior exactly.
  This is the **durable** fix so the deploy does not depend solely on nginx rewriting
  `Host: localhost` (that trick stays valid as the zero-code fallback, documented in 004-04).
- Optional `AI_HUB_ROOT_PATH` for symmetry if the hub is ever mounted on a sub-path
  (nginx currently strips the prefix, so this is optional — note the decision).
- VM systemd unit: reuse `chrome-daemon/install/chrome-daemon.service` as the base and
  document the token drop-in (`EnvironmentFile=%h/.config/ai-hub/daemon.env`, chmod 600,
  **out of repo**) — the same 3-point token model proven in SEC-0001 (daemon + Gateway
  driver + guardian all share one value).

## Out of Scope
- Changing the token/auth mechanism (SEC-0001 is settled); the nginx bundle (004-04);
  Gateway-side token wiring (004-06, already shipped in Frente #1).

## ARO
- Acceptance: with `AIHUB_ALLOWED_HOSTS` unset, `curl -H 'Host: 192.168.7.200' :9400/status`
  still 403 (unchanged); with `AIHUB_ALLOWED_HOSTS=192.168.7.200` it is accepted; the daemon
  boots on the VM with the token loaded (journal "Daemon auth enabled") and no token in any
  committed file.
- Risk: broadening the allowlist weakens DNS-rebinding protection — keep it opt-in and
  document that the nginx `Host: localhost` rewrite is the preferred no-broadening path.
  After editing the drop-in on the VM: `daemon-reload` **and** `restart` (reload alone does
  not refresh a live process's env — SEC-0001 lesson).
- Operations: token file lives only on the VM (`~/.config/ai-hub/daemon.env`).

## Test Plan
- Local: unset → `Host: evil`/`Host: 192.168.7.200` both 403; set → configured host 200
  (with valid Bearer); missing/empty token → 503; wrong token → 401.

## Security
- Sources: SEC-0001 (fail-closed token, Host-header guard), epic 003 task
  003-10 (localhost daemons validate Host header). Keeps fail-closed default; opt-in only.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Env-seeded allowlist merged (default unchanged); token drop-in documented for the VM
  unit; local matrix (403/200/503/401) verified; no secret committed.
