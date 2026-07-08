# Task: AI-Gateway app systemd unit + VM deploy doc (alembic, env, production guard)

## Metadata
- work_id: WK-20260708-gw-systemd-unit
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
Ship a versioned **systemd unit** for the Gateway app (none exists today — only the
Postgres compose runs) plus a deploy README describing the VM/systemd flow, so the app
starts on boot on the VM with the right env and DB.

## In Scope
- New unit under the repo (e.g. `deploy/systemd/ai-gateway.service`): runs
  `.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --root-path ${AIGW_ROOT_PATH}`,
  `EnvironmentFile=` pointing at an **out-of-repo** env file (provider keys, `AIGW_DATABASE_URL`,
  `AIGW_ENVIRONMENT=production`, `AIGW_ROOT_PATH`, `AIHUB_DAEMON_TOKEN`), `Restart=always`,
  `WorkingDirectory=` the repo. Decide user vs system unit and document `loginctl enable-linger`
  if user-scoped (mirrors the AI-hub daemon pattern).
- Deploy doc (README section or `deploy/README.md`): venv + `pip install -e .`, Postgres
  (native apt **or** the existing `docker compose up -d db`), `alembic upgrade head`
  (creates schema incl. `drivers_health`), `app.cli init-db/create-project/create-key`,
  where the `.env`/EnvironmentFile lives (never in repo), and that
  `AIGW_ENVIRONMENT=production` **requires** an explicit `AIGW_DATABASE_URL` (the
  SEC-0218 production guard in `get_settings()` refuses the default dev DB URL).

## Out of Scope
- The nginx bundle (004-04); the sub-path code (004-01); AI-hub unit (004-03).

## ARO
- Acceptance: `systemctl [--user] start ai-gateway` brings the app up bound to
  `127.0.0.1:8000` reading its env from the out-of-repo file; a fresh DB reaches head via
  `alembic upgrade head`; the doc reproduces the install from a clean clone.
- Risk: production guard aborts boot if `AIGW_DATABASE_URL` is unset under
  `AIGW_ENVIRONMENT=production` — the doc must make this explicit. Secrets must not land
  in the committed unit (use `EnvironmentFile`, not inline `Environment=`).
- Operations: unit is versioned; real env file is provisioned on the VM only.

## Test Plan
- Local dry-run: `systemd-analyze verify deploy/systemd/ai-gateway.service`; start with a
  local EnvironmentFile → `curl 127.0.0.1:8000/health` 200; `alembic upgrade head` on a
  scratch DB → `drivers_health` present.

## Security
- Secrets via `EnvironmentFile` outside the repo (never committed). Reuses the SEC-0218
  production DB-URL guard. Cross-ref epic 003 (secrets/defaults).

## Privacy
- Personal data impact: no (deploy scaffolding; runtime data path unchanged).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Versioned unit + deploy doc; `systemd-analyze verify` clean; alembic-to-head verified on
  a scratch DB; no secret in any committed file.
