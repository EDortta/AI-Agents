# Task: Atualizar referências e documentação para `.docs/`

## Metadata
- work_id: WK-20260701-dotdocs-kit-layout
- date: 2026-07-01
- owner: Esteban D.Dortta
- related_commit: <planned>

## Parent Epic
- 002-dotdocs-kit-layout

## Objective
Atualizar todos os textos e templates que referenciam caminhos kit-owned em `docs/`
para o novo layout `.docs/`, e reescrever a regra de propriedade.

## In Scope
- `AGENTS.md`: seção "Mandatory Context"/"Documentation Ownership" — kit em `.docs/`,
  projeto em `docs/`; required-reading permanece em `docs/`.
- `CLAUDE.md`: caminhos de contexto obrigatório.
- `README.md`, `README-ptbr.md`, `README-es.md`: instruções e exemplos de layout.
- `docs/issues/templates/*`: referências a `docs/napkin-lessons.md`,
  `docs/issues/templates/...`, `docs/project/` → novo layout
  (napkin/required-reading ficam em `docs/`; templates em `.docs/issues/templates/`).
- `docs/workflows/session-close.md` e demais workflows: caminhos.
- `scripts/agent-worktree.sh`: comentário que aponta para
  `docs/workflows/parallel-worktrees.md` → `.docs/workflows/...`.

## Out of Scope
- Lógica de instalador (tasks 001/002).

## ARO
- Acceptance: `grep -rn "docs/"` só retorna referências project-owned legítimas
  (required-reading, napkin-lessons, codemap, issues ativas).
- Risk: esquecer um mirror de texto; usar grep abrangente ao final.
- Operations: sem deploy.

## Test Plan
- `grep -rn "docs/software-overview\|docs/limits\|docs/workflows\|docs/agents\|docs/project"`
  não deve retornar referências kit-owned remanescentes.

## Security
- Sem impacto.
