# Epic: Deploy AI-Gateway + AI-hub on a dedicated Proxmox VM (192.168.7.200)

## Metadata
- work_id: WK-20260708-deploy-gw-hub-vm
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Context
The AI-* ecosystem currently runs on `devel3` (Frente #1 restored it: SEC-0001
daemon-token rollout). The goal is to move **AI-Gateway + AI-hub** onto the always-on
box **192.168.7.200** so the browser-backed hub (real Chrome/ChatGPT) no longer depends
on `devel3`'s 07:00–18:00 power window. The box is a Proxmox 8.3 host that also runs
**live, untouchable infrastructure** (host nginx serving `/enviar-arquivo/` →
`zeecred-sftp:5055`, reverse SSH tunnel :2203, OpenVPN, DHCP on vmbr2, wifi). The chosen
topology (operator, 2026-07-08) is a **single dedicated VM** that is purely *additive* —
it does not wipe the box nor reopen the destructive cleanup gate that the companion
`adaptive-gliding-alpaca` plan is still blocked on.

## Problem Statement
Neither app is deployable behind a reverse proxy today:
- Neither serves a sub-path (no `root_path`); the Gateway compose starts **only Postgres**;
  the Gateway has **no app systemd unit**.
- The AI-hub daemon binds `127.0.0.1`, enforces a **hardcoded Host-allowlist**
  (`{127.0.0.1, localhost, ::1}` → any other Host returns 403), and is **fail-closed** on
  `AIHUB_DAEMON_TOKEN` (503 without it).
- ChatGPT login is interactive (visible browser) — a one-time human step on a new host.

## Outcome
Versioned, reproducible artifacts (code, systemd units, nginx bundle, runbook) such that a
fresh clone + the runbook stands up the VM; nginx inside the VM proxies
`/api-gateway/ → 127.0.0.1:8000` and `/api-hub/ → 127.0.0.1:9400`; and after the
**gated** apply the ecosystem answers on 192.168.7.200 without disturbing host infra.

## Dependencies
- SEC-0001 daemon-token model (`AI-hub/issues/DIAG-20260707-daemon-token-ausente-503-[resolved].md`)
  — the token must be provisioned on the VM for daemon, Gateway driver, and guardian.
- Security hardening rules live in epic `003-security-standards-hardening` (referenced,
  not re-implemented here).
- Operator approval for each step touching 192.168.7.200 (non-autonomous deploy policy).

## DoD
- 004-01..04 merged with local verification; 004-05 runbook complete and reviewed;
  004-06 e2e checklist defined. The host's untouchable services are demonstrably
  untouched by the design. Remote apply remains a separate, operator-approved action.

## Privacy Checklist
- No personal data in the epic/task docs. Secrets never committed. Owner = `[OPERATOR_NAME]`.
  Baseline: `.docs/issues/templates/privacy-checklist.template.md` — personal-data impact
  is **none** for the deploy artifacts themselves (the runtime data path is unchanged).

## Session-Close Notes
- Handoff sync status: pending
- Last handoff update date: 2026-07-08
