# Task: Daemon-token propagation to the Gateway env + e2e verification on the VM

## Metadata
- work_id: WK-20260708-e2e-token-prop
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
Close the loop between Gateway and Hub on the VM: ensure the Gateway's aihub driver carries
the daemon Bearer token, decide whether the `aihub` driver is enabled there, and define the
end-to-end verification that proves the ecosystem works behind nginx.

## In Scope
- Confirm the Gateway driver already sends `Authorization: Bearer` from
  `settings.aihub_daemon_token` (shipped in Frente #1, `app/drivers/aihub_driver.py:_client`,
  `config.py` `aihub_daemon_token` via `validation_alias="AIHUB_DAEMON_TOKEN"`). This task
  is **provisioning + verification**, not new auth code.
- Ensure the VM Gateway EnvironmentFile provides `AIHUB_DAEMON_TOKEN` (same value as the
  daemon) and `AIGW_AIHUB_BASE_URL=http://127.0.0.1:9400` (loopback within the VM).
- Decide + document whether `drivers.yaml` enables the `aihub` driver on the VM (default
  today: `enabled: false`) — record as a deliberate choice, not an accident.
- Define the **e2e checklist** (run after the gated apply):
  - `curl http://192.168.7.200/api-gateway/health` → 200.
  - `curl -H 'Authorization: Bearer <token>' http://192.168.7.200/api-hub/status` → 200.
  - Gateway → hub bridge: `AiHubDriver.health()` → `("UP", None)` from the VM.
  - Reboot the VM → both services return on their own (systemd/linger + guardian cron).

## Out of Scope
- Building the token/auth mechanism (SEC-0001, done); the nginx bundle (004-04); the runbook
  steps themselves (004-05, which references this checklist).

## ARO
- Acceptance: the driver demonstrably authenticates to the daemon on the VM (health UP);
  the e2e checklist is documented and, post-apply, passes; the `aihub` enabled/disabled
  decision is recorded.
- Risk: token mismatch across the 3 points (daemon/driver/guardian) → 401 loop or guardian
  killing a healthy daemon (SEC-0001 trap) — the checklist asserts all three share one value.
- Operations: verification only; remote runs happen after the gated apply.

## Test Plan
- Local: point a local Gateway at a local daemon with a shared token → `AiHubDriver.health()`
  UP; wrong/empty token → DOWN with 401/503. Post-apply: run the e2e checklist on the VM.

## Security
- Reasserts SEC-0001 fail-closed token across daemon + driver + guardian. Token never in
  logs/issues/commits. Cross-ref epic 003 (secrets never in URLs/logs).

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Token propagation confirmed to the Gateway env; `aihub` enable decision recorded; e2e
  checklist committed; local UP/DOWN matrix verified. Remote e2e deferred to the gated apply.
