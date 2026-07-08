# Task: Atualizar `install-agents-kit.sh` para `.docs/` + migração legada

## Metadata
- work_id: WK-20260701-dotdocs-kit-layout
- date: 2026-07-01
- owner: Esteban D.Dortta
- related_commit: <planned>

## Parent Epic
- 002-dotdocs-kit-layout

## Objective
Alinhar o instalador bash (`scripts/install-agents-kit.sh`) ao novo layout `.docs/`,
espelhando o instalador Python, e adicionar migração de projetos legados.

## In Scope
- Trocar caminhos kit-owned de `docs/...` para `.docs/...`
  (linhas ~173-174, 189, 206-223, 249, 255-268).
- `replace_dir`/`copy_file_replace`: apontar para `.docs/`.
- Território do projeto passa a ser `docs/` (não mais `docs/project/`); deixar de
  criar `docs/project/` — em vez disso semear `docs/` com README do projeto se vazio.
- `_reset_readiness_flags` (SO_FILE/LIM_FILE) → `.docs/software-overview.md`,
  `.docs/limits.md`.
- **Migração legada**: se detectar layout antigo (kit em `docs/`, `docs/project/`),
  mover kit `docs/*`→`.docs/`, promover `docs/project/*`→`docs/`, backup em
  `.docs-migration-bak/`, relatório, idempotente.
- Ajustar mensagens "preserved project-local".

## Out of Scope
- Instalador Python (repo AI-GovernanceKit) — só manter paridade de comportamento.

## ARO
- Acceptance: fresh e upgrade produzem `.docs/` (kit) + `docs/` (projeto); migração
  legada funciona e é idempotente.
- Risk: divergência com o instalador Python — sincronizar constantes/comportamento.
- Operations: sem deploy.

## Test Plan
- Fresh install em dir temporário: kit em `.docs/`, `docs/` semeada.
- Projeto legado simulado: upgrade migra e cria backup; segunda execução sem efeito.

## Security
- Preservar `.credentials` e `handoff.md` fora do git como hoje.
