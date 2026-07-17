# SOLID completo + Concílio de Agentes

## Metadata
- work_id: WK-20260717-solid-council
- date: 2026-07-17
- owner: [OPERATOR_NAME]
- related_commit: 8a71052, 80d0921, 49e5daa

## Objective
- Completar SOLID em `.docs/agents/design-standards.md`: O, L e I entram nas seções que já os ancoram (D e S já estavam).
- Criar `.docs/agents/council.md`: contrato de revisão adversarial de trabalho **já aprovado**, formalizando o precedente não-documentado dos "3 adversarial skeptics" da epic 002.
- Ligar os dois ao que já carrega (AGENTS.md §2, README, reviewer, run-checks) — arquivo fora das load rules é arquivo que ninguém lê.

## Scope
- In scope: `.docs/agents/design-standards.md`, `.docs/agents/council.md`, `AGENTS.md` §2, `.docs/agents/README.md`, `.docs/agents/reviewer.md`, `scripts/run-checks.sh`.
- Out of scope: o **arnês** (harness) e as mudanças no AI-GovernanceKit — fatiados para o épico 2, `WK-20260717-harness-generation`. Ver `epic.md` § Épico 2.

## ARO
- Acceptance:
  - as três letras faltantes presentes, cada uma na seção que a ancora, sem renumeração;
  - toda regra nova termina em algo executável; toda regra preventiva declarada como preventiva na Provenance;
  - checklist com exatamente uma linha por MANDATORY novo;
  - `council.md` com fronteira explícita contra `governance-precedence.md`;
  - `bash scripts/run-checks.sh` verde.
- Risk:
  - **Baixo para o repo** (só markdown, sem runtime).
  - **Real para o uso**: um concílio que nada convoca é decoração pelo próprio §0. Aceito conscientemente nesta fatia; mitigado por triggers declarados provisórios + registro de rodada MANDATORY.
  - ISP pode nunca pegar nada — declarado candidato a remoção na própria Provenance.
- Operations: nenhuma. Kit de documentação; sem deploy, sem migração, sem serviço.

## Privacy
- Personal data impact: **no**. Nenhum dado pessoal tocado. Verificação inversa do `AGENTS.md` §1a executada (valores reais do operador lidos de `~/.config/USER.md`/git config e grepados contra os arquivos kit-owned, sem hardcode no grep): nenhum vazamento. Placeholders intactos (`run-checks.sh` bloco 5).
- `.docs/issues/templates/privacy-checklist.template.md` não se aplica: sem tratamento de dado pessoal.

## Session-Close
- Handoff entry updated in `handoff.md`: yes
- Napkin lesson added in `docs/napkin-lessons.md`: yes

## Task Index
- 001-solid-design-standards-[finished].md
- 002-council-contract-[finished].md
- 003-wire-load-rules-[finished].md
