# Task: VM provisioning runbook for 192.168.7.200 (GATED apply)

## Metadata
- work_id: WK-20260708-vm-runbook
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
A versioned, step-by-step runbook to stand up the dedicated Proxmox VM on 192.168.7.200
and install Gateway + Hub from the artifacts of 004-01..04 — **without applying it**. The
apply is a separate, explicitly operator-approved action.

## In Scope
- Runbook doc (e.g. `deploy/README-vm.md`): create the Proxmox **VM** (not LXC — the hub's
  persistent Chrome/Xvfb is more stable in a full VM), sized for both apps + Postgres.
- System deps: python 3.10+, nginx, Postgres 16, Google Chrome + Xvfb (`:99`) for the hub.
- Install: clone both repos; Gateway venv + `pip install -e .` + `alembic upgrade head` +
  `app.cli` bootstrap; install both systemd units (004-02, 004-03) with **out-of-repo**
  EnvironmentFiles; install the nginx bundle (004-04) + `nginx -t` + reload; `loginctl
  enable-linger` if user-scoped units.
- **One-time human steps** (schedule a window): ChatGPT login on the hub via VNC/X-forward
  (visible browser — cannot be headless-automated); provision the `AIHUB_DAEMON_TOKEN`
  (`openssl rand -hex 32`) into the shared out-of-repo env consumed by daemon + Gateway +
  guardian; provision provider keys + `AIGW_DATABASE_URL` for the Gateway.
- Guardian: install `ai-hub-guardian.sh` (Bearer-aware, SEC-0001) on the VM cron with the
  `XDG_RUNTIME_DIR`/`DBUS_SESSION_BUS_ADDRESS` exports.

## Out of Scope
- **Executing** any of it on 192.168.7.200 (gated).
- Touching host infra: nginx `:80`, `zeecred-sftp`/`/enviar-arquivo/` (:5055), reverse
  tunnel (:2203), OpenVPN, DHCP (vmbr2), wifi — all preserved; the VM is additive.
- wa-hub (out of this epic).

## ARO
- Acceptance: the runbook is complete and internally consistent (a reader could execute it);
  each destructive/remote step is clearly marked "requires operator approval"; the
  untouchable-infra list is restated as a pre-flight guard.
- Risk: interactive ChatGPT login and WhatsApp-style human steps must be planned, not
  automated; RAM/host contention is lower with a VM than the 3-LXC alternative but still
  noted. Any `ssh root@192.168.7.200` command is documentation only until approved.
- Operations: **APPLY GATED** — non-autonomous deploy policy; no `--yes`/`--force` flows.

## Test Plan
- Doc-level dry run: walk the steps against a scratch/local VM if available; verify each
  referenced artifact (unit, nginx bundle, env keys) exists from 004-01..04. No remote apply.

## Security
- All secrets provisioned on the VM only, never in repo/logs. Reasserts SEC-0001 token model
  and epic 003 exposure rules. Pre-flight check that host services remain bound/served.

## Privacy
- Personal data impact: no (infra provisioning; runtime data path unchanged).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Runbook committed; every remote/destructive step gated and labeled; untouchable-infra
  pre-flight included; references to 004-01..04 artifacts resolve. No apply performed.
