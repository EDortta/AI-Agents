# Task: AI-Gateway serves under a sub-path via AIGW_ROOT_PATH

## Metadata
- work_id: WK-20260708-gw-root-path
- date: 2026-07-08
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 004-deploy-gateway-hub-proxmox

## Objective
Let the Gateway be mounted behind nginx at `/api-gateway/` by making its sub-path
configurable, so generated links/openapi and route matching are correct when a proxy
strips the prefix.

## In Scope
- New setting `root_path: str = ""` in `app/config.py` (`Settings`, `AIGW_` prefix →
  env `AIGW_ROOT_PATH`), documented alongside the existing `aihub_*` settings.
- Pass it to the app: `FastAPI(root_path=get_settings().root_path)` (and/or document the
  uvicorn `--root-path` equivalent for the systemd unit in 004-02).
- Empty default = current behavior (root mount); backward compatible.

## Out of Scope
- The nginx bundle itself (004-04) and the systemd unit (004-02).
- Any auth/CORS change (those are epic 003 / already-shipped SEC work).

## ARO
- Acceptance: with `AIGW_ROOT_PATH=/api-gateway`, `GET /api-gateway/health` behind a
  prefix-stripping proxy returns 200 and OpenAPI (`/api-gateway/docs`, `openapi.json`
  `servers`) reflects the prefix; with the var unset, all current routes work unchanged.
- Risk: root_path interacts with FastAPI's openapi `servers` and any absolute redirects —
  verify docs + one authenticated route under the prefix.
- Operations: pure code/config; no runtime data impact.

## Test Plan
- Local: `AIGW_ROOT_PATH=/api-gateway uvicorn app.main:app --root-path /api-gateway`,
  then `curl` a health route through an nginx `location /api-gateway/ { proxy_pass .../; }`.
- Regression: unset var → existing test suite green.

## Security
- No new surface. Confirms proxy-fronted deploy without weakening the existing API-key
  auth. Cross-ref: epic 003 network-exposure rules.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: no

## DoD
- Setting added + wired to `FastAPI(root_path=...)`; local verification under a prefix;
  backward-compatible default; changed files listed in the PR.
