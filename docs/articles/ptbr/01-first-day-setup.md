# 01 - Setup do Primeiro Dia

## História feliz: Lia começou certo
Lia é programadora júnior. Ela quer usar agentes sem perder controle do projeto. No primeiro dia, ela não começa codando. Primeiro, prepara o terreno: contexto, limites e regras. O agente passa a trabalhar a favor dela, não no escuro.

## O que é seu (programador)
- Escrever o contexto real em `docs/software-overview.md`.
- Definir limites reais em `docs/limits.md`.
- Decidir o que pode e o que não pode ser feito.
- Validar se os readiness flags viraram `yes`.

## O que é do agente
- Ler esses arquivos antes de planejar/editar.
- Respeitar limites e avisar quando houver conflito.
- Propor plano coerente com o contexto.

## Passo a passo
1. Rode o instalador do kit.
2. Preencha `docs/software-overview.md` com produto, arquitetura e objetivo.
3. Preencha `docs/limits.md` com fronteiras e proibições.
4. Marque:
- `project_context_ready: yes`
- `limits_ready: yes`
5. Só depois peça implementação ao agente.

## Prompt sugerido
"Leia AGENTS.md, docs/software-overview.md e docs/limits.md. Confirme entendimento e proponha um plano curto antes de codar."

## Definição de pronto
- O projeto tem contexto claro.
- O agente sabe o que fazer e o que evitar.
- Você evita retrabalho na primeira tarefa.
