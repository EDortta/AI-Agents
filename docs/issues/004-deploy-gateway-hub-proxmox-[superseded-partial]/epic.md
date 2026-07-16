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

## Status (2026-07-16) — WK-20260716-ai-issues-sweep — a realidade divergiu do plano

**Metade desta epic foi entregue por outra frente, com outra topologia.** Em 2026-07-15
(`WK-20260715-aihub-stage4`, repo AI-hub) o chrome-daemon **migrou para 192.168.7.200** —
o alvo desta epic — sem passar por 004-04/05. O `AI-hub/handoff.md` ("Topologia atual")
descreve o que existe hoje:

- daemon + Chrome (Xvfb `:99`) no stage4, usuário dedicado `ai-hub`, systemd user + linger;
- API em `127.0.0.1:9400`, exposta na LAN por **vhost nginx próprio**
  (`/etc/nginx/sites-available/ai-hub.conf`, `listen 9480`) — **não** por `/api-hub/`;
- Gateway continua no **devel3**, apontando para lá via `AIGW_AIHUB_BASE_URL`;
- devel3 preservado para rollback (service inactive+disabled, crons neutralizados).

O objetivo declarado no *Context* acima — "o hub com browser real não depende mais da
janela de energia 07:00–18:00 do devel3" — **está atingido**. Só que não da forma desenhada.

### Conflito de documentos que precisa da sua decisão

Os documentos **discordam sobre o que é 192.168.7.200**, e isso muda o que resta fazer:

| Fonte | Diz que 192.168.7.200 é | Plano |
|---|---|---|
| `epic.md` (aqui, 2026-07-08) | **host Proxmox 8.3** com infra intocável (nginx do host no `:80`, `/enviar-arquivo/`) | VM dedicada, **aditiva** |
| `Gateway/deploy/runbook.md` (004-05) | host **LXC-native** (`pct`; sem VMs KVM) | criar **um LXC** Debian 12 |
| `AI-hub/handoff.md` (2026-07-15) | "**VM Proxmox Debian 12**", acesso `root@192.168.7.200` | daemon instalado **direto**, vhost próprio `:9480` |

Se o `ai-hub.conf` mora em `/etc/nginx/sites-available/` **ao lado do `steward.conf`** (que
o handoff diz ter deixado intocado), então esse é o **nginx do host** — exatamente o que
esta epic declarou intocável. Foi tocado de forma **aditiva** (vhost novo, porta nova), não
destrutiva; o espírito da regra ("não perturbar a infra viva") foi respeitado. Mas a letra
do desenho ("nginx **dentro** da VM faz proxy de `/api-hub/`") não foi seguida.

**Não verifiquei remotamente** — acesso ao 192.168.7.200 é passo gateado e não o executei.
O que está acima é o que os documentos afirmam; o conflito é entre eles.

### Consequência para cada sub-issue

- **004-02** (unit systemd do Gateway) — **vale como está.** Independe da topologia do hub.
  Verificado localmente: `systemd-analyze verify` limpo (única queixa é
  `/opt/ai-gateway/.venv/bin/uvicorn` não existir *neste* host — existe só no alvo).
- **004-04** (bundle nginx sub-path) — **o bloco `/api-gateway/` vale; o `/api-hub/` está
  obsoleto.** Ele faz `proxy_pass http://127.0.0.1:9400/` com `Host: localhost`,
  pressupondo hub **no mesmo** LXC. Hoje o hub está no stage4 com vhost próprio: um Gateway
  novo alcança o hub por `http://192.168.7.200:9480` (que é o que o devel3 já faz), não por
  loopback. Verificado localmente: `nginx -t` **passa** (validado em container nginx:alpine).
  A config é válida; a **premissa** é que caducou.
- **004-05** (runbook) — a seção do hub descreve instalar algo **que já existe**. Precisa ser
  reescrita para "Gateway sobe e aponta para o hub já rodando no stage4", ou a epic assume
  que o hub será *re-instalado* dentro do LXC (o que jogaria fora a migração de 2026-07-15).
- **004-06** (propagação de token + e2e) — **na prática já aconteceu**, fora do escopo desta
  epic: o Gateway do devel3 já fala com o daemon do stage4 com o mesmo `AIHUB_DAEMON_TOKEN`.
  O que falta é a **decisão registrada** sobre `drivers.yaml` — e ela foi tomada em
  2026-07-16 (`Gateway/config/drivers.yaml`: `aihub.enabled: false → true`, com o porquê no
  arquivo; ver `Gateway/issues/002`, fase A). O checklist e2e continua válido, com os
  endereços corrigidos.

### A pergunta que sobra (operador decide)

O Gateway **precisa** mesmo sair do devel3? O motivo original da epic era a janela de
energia — mas ela machucava o **hub** (sessão de browser persistente), não o Gateway. O
Gateway é stateless na frente do Postgres; se ele cair fora do horário, ninguém perde
sessão de ChatGPT, só disponibilidade de API. Três saídas:

1. **Mover só o Gateway para o stage4** e fechar a epic com a topologia real (vhost próprio,
   como o hub — descartando o desenho de sub-path/LXC). Mais simples, coerente com o que já
   existe.
2. **Manter o desenho original** (LXC dedicado com nginx interno e sub-paths) e aceitar
   re-instalar o hub lá dentro, jogando fora a migração de 2026-07-15. Custo alto, ganho
   pequeno.
3. **Fechar a epic como parcialmente superada**: o hub — que era o motivo — está resolvido;
   o Gateway fica no devel3 até haver uma razão própria para movê-lo.

Recomendação: **(3) agora, (1) quando houver motivo.** A epic nasceu para tirar o browser da
janela de energia; isso está feito. Mover o Gateway hoje é trabalho de infra gateado sem
problema correspondente.

## Session-Close Notes
- Handoff sync status: pending
- Last handoff update date: 2026-07-16 (status acima; artefatos 004-02/04 verificados
  localmente — `systemd-analyze verify` e `nginx -t` limpos; nenhum apply remoto executado)

---

## Fechamento (2026-07-16) — [superseded-partial], decisão do operador

O operador aprovou a recomendação (3): **fechar como parcialmente superada**.

**O motivo da epic foi atendido.** O *Context* acima diz: mover Gateway+hub para a caixa
sempre-ligada "so the browser-backed hub (real Chrome/ChatGPT) no longer depends on devel3's
07:00–18:00 power window". O hub está no stage4 desde 2026-07-15 (`WK-20260715-aihub-stage4`),
com Chrome real, perfil persistente e sessão que sobrevive ao horário. **Feito** — por outro
caminho, sem LXC e sem sub-paths.

**O Gateway fica no devel3, deliberadamente.** A janela de energia machucava o hub (sessão de
browser persistente que não migra), não o Gateway — que é stateless na frente do Postgres. Se
ele cair fora do horário ninguém perde sessão, só disponibilidade de API. Mover é trabalho de
infra gateado sem problema correspondente; será uma issue nova quando houver razão própria.

**Verificado hoje, de ponta a ponta (read-only, nada implantado):**

- `AiHubDriver.health()` do devel3 → **`('UP', None)`** contra `http://192.168.7.200:9480`
  com o token compartilhado. A ponte Gateway→hub **funciona hoje**, sem LXC e sem nginx
  sub-path. É o critério central de 004-06, atendido fora do desenho desta epic.
- Token: o serviço vivo (`MainPID`) carrega `AIHUB_DAEMON_TOKEN` via drop-in
  `ai-gateway.service.d/aihub-token.conf` (SEC-0001). O `.env` do repo **não** o contém — e
  não deve conter.
- `drivers.yaml`: `aihub.enabled: true` (2026-07-16), decisão registrada no arquivo. O driver
  agora aparece no registry.
- `alembic upgrade head` → **rodado no banco real** (não de rascunho): `0002` → `0003`,
  downgrade e re-upgrade validados, 925 requests preservados. A "dívida vizinha" da issue 002
  do Gateway **já estava paga** — o banco tinha as tabelas, ao contrário do que aquela issue
  registrou em 2026-07-09.

**Estado final das sub-issues:** 004-01 `[done]`, 004-02 `[done]`, 004-03 `[done]`,
004-04 `[done]` (bloco `/api-gateway/` válido; `/api-hub/` documentado como premissa
caduca), 004-05 `[superseded]` (o runbook instala um hub que já existe), 004-06 `[done]`
(propagação de token provada UP; checklist e2e com os endereços reais).

Os artefatos **não** foram jogados fora: a unit systemd e o bloco `/api-gateway/` do nginx
ficam versionados e verificados, prontos para o dia em que o Gateway tiver motivo para mudar
de casa. O que caducou foi o *plano de aplicá-los agora*, não o trabalho.
