# Epic: Mover o kit para `.docs/` e libertar `docs/` para o projeto

## Metadata
- work_id: WK-20260701-dotdocs-kit-layout
- date: 2026-07-01
- owner: Esteban D.Dortta
- related_commit: <planned>

## Context

Hoje o kit AI-Agents ocupa a pasta `docs/` inteira e apenas recorta `docs/project/`
como território do projeto. Isso invade projetos legados que já usavam `docs/` como
pasta própria, mistura propriedade (a pasta do projeto fica *dentro* da pasta do kit)
e trata a publicação dos docs do kit no GitHub como decisão fixa.

Esta epic é o lado **fonte-de-verdade** (repo `EDortta/AI-Agents`) de uma mudança
coordenada. O lado instalador (Python) vive em `AI-GovernanceKit`
(work_id gêmeo lá). Vamos mexer nos dois em paralelo.

## Problem Statement

- `docs/` é do kit, forçando o projeto a um subdiretório `docs/project/`.
- `--upgrade` sobrescreve `docs/*`, arriscando docs particulares de projetos legados.
- Versionar (ou não) os docs do kit no git é uma escolha rígida.

## Outcome

- Conteúdo kit-owned da fonte migra para `.docs/` (oculto, gerenciado).
- `docs/` passa a ser 100% território do projeto (nunca sobrescrito).
- Layout da fonte casa com o destino esperado pelo instalador (mapeamento
  SOURCE→DEST no lado Python torna a transição não-bloqueante, mas alinhamos a fonte).
- Convenção documentada em AGENTS.md/CLAUDE.md e nos READMEs.

## Dependencies

- Gêmeo em AI-GovernanceKit: `WK-20260701-dotdocs-kit-layout` (instalador Python:
  mapeamento SOURCE→DEST, migração de layout legado, prompt de versionamento).
- Coordenar o merge para não deixar instalador e fonte em layouts divergentes.

## DoD

- Conteúdo kit-owned reestruturado sob `.docs/` na fonte.
- `scripts/install-agents-kit.sh` atualizado para o novo layout + migração legada.
- Templates, AGENTS.md, CLAUDE.md, READMEs e docs de referência com caminhos `.docs/`.
- `docs/` reservado ao projeto; `.gitignore` ajustado.
- Verificação: fresh install e upgrade de projeto legado produzem o layout correto.

## Privacy Checklist
- Sem dados pessoais envolvidos. Baseline em `docs/issues/templates/privacy-checklist.template.md` — N/A.

## Session-Close Notes
- Handoff sync status: pending
- Last handoff update date: 2026-07-01
