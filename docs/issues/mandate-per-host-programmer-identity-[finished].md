# Contrato deve exigir identidade individual do programador/host em projetos de branch compartilhada

- work_id: WK-20260702-per-host-identity-contract
- date: 2026-07-02
- solicitado por: [OPERATOR_NAME]
- lado do problema: **policy pack (AI-Agents)** — o "o quê e porquê"
- companheira: issue equivalente no **AI-GovernanceKit** (lado runtime/"como")

## Motivação

Os documentos deste kit (`AGENTS.md`, guias de papel, `RESUME.md`, `handoff.md`)
são **compartilhados por vários programadores/agentes** que trabalham no mesmo
projeto. Em casos como o simulador (jk-structure), **todos rodam sobre a mesma
branch** e sobre os mesmos arquivos de governança.

Sem informação que **individualize** cada programador/host/instância, surgem
falhas silenciosas:

- dois hosts editam/commitam sobre a mesma branch sem saber um do outro;
- colisão de portas e de artefatos de runtime locais;
- impossível auditar "quem/qual host fez o quê" a partir dos docs compartilhados;
- o prefixo do operador (`[OPERATOR_NAME]`) já resolve identidade *na conversa*,
  mas não há identidade **de host/instância** persistida e verificável.

O incidente do branch `"development"` (ver
`branch-names-ascii-only-[draft].md`) é um sintoma da mesma classe: falta de
regra explícita sobre o que é individual vs. compartilhado.

> Observação: o `AGENTS.md` do simulador jk-structure já tinha um conceito de
> `WORKSPACE.md` (identidade da instância, path do irmão, guarda de same-branch).
> Essa boa prática **não está generalizada** neste kit reutilizável. Esta issue
> pede exatamente isso.

## Objetivo

Definir no contrato do kit que **identidade individual é obrigatória** em
qualquer projeto governado, e declarar o schema mínimo dos campos que
individualizam o programador/host/instância.

## Escopo

Somente documentação/contrato (`AGENTS.md` e, se aplicável, um template de
identidade). Sem código de runtime — a coleta/validação executável é a issue
companheira no AI-GovernanceKit.

### Campos mínimos de identidade (proposta)

- `operator_name` — nome do operador humano (já usado como prefixo de mensagem)
- `host_id` — identificador da máquina/instância
- `instance_path` — caminho absoluto do checkout desta instância
- `sibling_path` — caminho da(s) instância(s) irmã(s), quando houver
- `assigned_ports` — portas reservadas por esta instância
- `branch_ownership` — política de quem opera qual branch em projetos de
  branch compartilhada (e a guarda de "same-branch" antes de criar/trocar branch)

### Regras a acrescentar ao contrato

- [MANDATORY] Antes de qualquer ação, o agente lê o arquivo de identidade da
  instância; se ausente → PARA e pede que seja criado.
- [MANDATORY] Em projeto de branch compartilhada, rodar a guarda de same-branch
  (não operar a mesma branch que a instância irmã sem alinhamento explícito).
- [MANDATORY] Distinguir claramente o que é **compartilhado** (contrato, docs)
  do que é **individual** (identidade, portas, artefatos de runtime locais).

## Comportamento esperado

- Antes: docs compartilhados não carregam nenhuma noção de host/instância;
  colisões passam despercebidas.
- Depois: o contrato obriga identidade individual verificável; agentes param
  quando ela falta.

## Plano de teste (aceitação)

- Contrato descreve o schema de identidade e as três regras acima.
- Um projeto sem arquivo de identidade é reconhecido como não-conforme (a
  verificação executável fica na issue do GovernanceKit).

## Impacto / Risco

- Mudança de contrato/documentação. Baixo risco.
- Habilita a aplicação executável no AI-GovernanceKit.

## Definition of Done

- Seção de identidade individual presente no `AGENTS.md` do kit.
- Schema mínimo e regras documentados.
- Referência cruzada para a issue companheira do AI-GovernanceKit.
- Status movido para `[review]` após aplicar.
