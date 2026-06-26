# Agentes devem iniciar mensagens ao operador com "[OPERATOR_NAME], "

- work_id: WK-20260625-prefixo-operador
- date: 2026-06-25
- solicitado por: [OPERATOR_NAME]

## Motivação

O operador deste ambiente usa o prefixo `"[OPERATOR_NAME], "` como sinal
de coerência: toda mensagem de texto que um agente Claude envia diretamente ao
usuário deve começar com esse prefixo. Se ele sumir, o operador sabe que algo
está errado (alucinação, contexto corrompido, agente incorreto).

A mesma convenção já estava ativa em outro projeto do operador antes deste kit.

## Mudança necessária

Adicionar a seguinte seção no `AGENTS.md` deste projeto (ou no equivalente de
contrato de agente), **antes** de qualquer outra regra de comunicação:

```
## Prefixo obrigatório nas mensagens ao operador

Toda mensagem de texto enviada diretamente ao operador (`[OPERATOR_NAME]`) **deve começar
com "`[OPERATOR_NAME]`, "** — incluindo a vírgula e o espaço.

Aplica-se a: respostas no chat, resumos de sessão, perguntas de clarificação.
Não aplica-se a: tool calls, conteúdo de arquivos, corpos de issue/PR.
```

> **Configurar:** substitua `[OPERATOR_NAME]` pelo nome real do operador antes de ativar este kit.

## Comportamento esperado

- Antes: `"Encontrei o problema no módulo X."`
- Depois: `"[OPERATOR_NAME], encontrei o problema no módulo X."`

## Impacto

- Sem impacto em runtime ou código.
- Mudança de documentação / contrato de agente apenas.
- Baixo risco, sem efeitos colaterais.
