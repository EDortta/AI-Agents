# Task: Reestruturar o conteúdo kit-owned da fonte para `.docs/`

## Metadata
- work_id: WK-20260701-dotdocs-kit-layout
- date: 2026-07-01
- owner: Esteban D.Dortta
- related_commit: <planned>

## Parent Epic
- 002-dotdocs-kit-layout

## Objective
Mover o conteúdo kit-owned de `docs/` para `.docs/` na fonte, deixando `docs/`
reservado ao projeto que adota o kit.

## In Scope
- Criar `.docs/` e mover para lá os kit-owned:
  `agents/`, `workflows/`, `articles/`, `icons/`, `issues/templates/`,
  `issues/README.md`, `software-overview.md`, `limits.md`, `concepts.html`,
  `index.html`.
- Manter em `docs/` os project-owned: `required-reading.md`, `napkin-lessons.md`,
  `project/` (a ser promovido — ver task de instalador), issues ativas
  (ex.: `001-low-token-contract-v2-[review]/`, esta 002), `undercover-issues/`.
- `.gitignore`: ajustar entradas de `docs/` para o novo layout (`.docs/`).

## Out of Scope
- Alterar o instalador Python (repo AI-GovernanceKit).

## ARO
- Acceptance: `.docs/` contém todo o kit-owned; `docs/` só project-owned; git limpo.
- Risk: mover HTML/artefatos referenciados por links relativos — revisar links.
- Operations: sem deploy.

## Test Plan
- Conferir que nenhum arquivo project-owned foi movido para `.docs/`.
- Abrir `index.html`/`concepts.html` e checar caminhos relativos de `icons/`/`articles/`.

## Security
- Nenhum segredo movido; `.credentials` fora do escopo desta task.
