# 002 — Mover o kit para `.docs/` e libertar `docs/` para o projeto

## Metadata
- work_id: WK-20260701-dotdocs-kit-layout
- date: 2026-07-01
- owner: Esteban D.Dortta
- related_commit: <planned>

## Objective
- Reestruturar o conteúdo kit-owned da fonte de `docs/` para `.docs/`, deixando
  `docs/` como território exclusivo do projeto.

## Scope
- In scope: mover arquivos kit-owned da fonte para `.docs/`; atualizar
  `scripts/install-agents-kit.sh` (novo layout + migração legada); templates;
  AGENTS.md; CLAUDE.md; READMEs; docs de referência; `.gitignore`.
- Out of scope: o instalador Python (feito no repo AI-GovernanceKit, work_id gêmeo).

## ARO
- Acceptance: fresh install gera kit em `.docs/` e `docs/` livre; upgrade de projeto
  legado migra kit `docs/*`→`.docs/` e promove `docs/project/*`→`docs/` com backup.
- Risk: instalador e fonte em layouts divergentes se os merges não forem coordenados.
- Operations: sem deploy; mudança de repositório-fonte apenas.

## Privacy
- N/A — sem dados pessoais.

## Session-Close
- Handoff entry updated in `handoff.md`: no
- Napkin lesson added in `docs/napkin-lessons.md`: no

## Task Index
- 001-restructure-source-to-dotdocs-[draft].md
- 002-update-install-script-and-migration-[draft].md
- 003-update-references-and-docs-[draft].md
