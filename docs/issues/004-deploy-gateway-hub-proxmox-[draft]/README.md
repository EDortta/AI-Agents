# Deploy AI-Gateway + AI-hub on a dedicated Proxmox VM (192.168.7.200)

## Metadata
- work_id: WK-20260708-deploy-gw-hub-vm
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Objective
- Make the AI-* ecosystem (AI-Gateway + AI-hub) runnable on the always-on box at
  **192.168.7.200** as a **single dedicated Proxmox VM**, served behind an
  **nginx internal to that VM** on sub-paths, without touching the host's live
  infrastructure. Produce the **versioned artifacts** (code, systemd units, nginx
  bundle, runbook) that make the deploy reproducible; the remote apply itself is a
  **separate, operator-gated step**.

## Scope
- In scope: sub-path support in the Gateway (`AIGW_ROOT_PATH`); an app **systemd
  unit** for the Gateway (none exists today); an env-configurable **Host-allowlist**
  and token wiring for the AI-hub daemon; a versioned **nginx bundle**; a
  **VM provisioning runbook**; integration/e2e verification incl. daemon-token
  propagation to the Gateway env.
- Out of scope: **wa-hub** deploy (separate front — the operator scoped this deploy
  to Gateway+Hub only); wiping/reprovisioning the box or the 3-LXC topology (see the
  companion `adaptive-gliding-alpaca` plan and its still-open cleanup gate); the
  generic security-standards hardening (that is epic `003`, referenced not duplicated);
  the actual remote apply on 192.168.7.200 (gated, non-autonomous).

## ARO
- Acceptance: each task ships versioned artifacts and a local verification; a fresh
  clone + the runbook reproduces the VM install; `curl` against the apps with a
  root-path returns 200 locally; after the **gated** apply,
  `curl http://192.168.7.200/api-gateway/health` → 200 and `/api-hub/status` with
  Bearer → 200.
- Risk: the AI-hub Host-allowlist (`{127.0.0.1, localhost, ::1}`) is hardcoded → a
  reverse proxy fronting it 403s unless nginx rewrites `Host: localhost` **or** the
  allowlist becomes env-configurable (task 03 does the durable fix). The apps have no
  `root_path` today, so nginx must strip the prefix. ChatGPT login is interactive
  (visible browser) → needs a one-time human window on the VM.
- Operations: **APPLY GATED** — every step that touches 192.168.7.200 requires explicit
  operator approval (non-autonomous deploy policy). Secrets (`AIHUB_DAEMON_TOKEN`,
  provider keys, PG creds) live outside any repo, provisioned on the VM.

## Untouchable host infrastructure (must survive; VM is additive)
- nginx on the host (`default_server` :80) + `zeecred-sftp` (`/enviar-arquivo/` →
  `127.0.0.1:5055`, used daily by Rodrigo), reverse SSH tunnel (:2203), OpenVPN,
  `isc-dhcp-server` (vmbr2), wifi `wlx` (15.200). The VM must **not** rebind :80 on
  the host or disturb these. (Source: companion plan `adaptive-gliding-alpaca.md`.)

## Privacy
- No personal data stored in these issues. The daemon token and provider keys are
  never written to issues, logs, or commits. Owner recorded as `[OPERATOR_NAME]`.

## Session-Close
- Handoff entry updated in `handoff.md`: pending
- Napkin lesson added in `docs/napkin-lessons.md`: pending

## Provenance
- Distilled from the AI-* epic plan (`este-chat-apenas-streamed-iverson.md`, Front #2),
  the companion `adaptive-gliding-alpaca.md` survey of 192.168.7.200, and the SEC-0001
  daemon-token rollout (`AI-hub/issues/DIAG-20260707-daemon-token-ausente-503-[resolved].md`,
  memory `ecosystem-services-supervision`). Topology chosen 2026-07-08 by the operator:
  **1 dedicated VM** (additive) over the 3-LXC + box-wipe alternative.

## Task Index
- 004-01-gateway-subpath-root-path-[draft].md — `AIGW_ROOT_PATH` → FastAPI/uvicorn root_path
- 004-02-gateway-systemd-unit-and-deploy-doc-[draft].md — app systemd unit (new) + deploy README + alembic/env
- 004-03-aihub-host-allowlist-and-token-unit-[draft].md — env-configurable `AIHUB_ALLOWED_HOSTS` + token in unit
- 004-04-nginx-subpath-bundle-[draft].md — versioned nginx server block (prefix rewrite + `Host: localhost`)
- 004-05-vm-provisioning-runbook-[draft].md — Proxmox VM runbook (deps, units, alembic, linger, ChatGPT login) — GATED
- 004-06-integration-token-propagation-and-e2e-[draft].md — daemon-token → Gateway env + e2e verification
