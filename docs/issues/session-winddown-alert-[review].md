# Limitador forte de encerramento de sessão (session wind-down alert)

- work_id: WK-20260702-session-winddown-alert
- date: 2026-07-02
- status: [review]

## Problema

O operador trabalha muitos projetos em paralelo. Encerrar as sessões de forma
limpa (handoff + RESUME + napkin em cada projeto ativo) leva ~1 hora. Sem um
aviso no horário certo, o fim do dia chega com sessões sujas e trabalho perdido.

## Definition of Done

Adicionar à documentação centralizada (kit `AGENTS.md`) um **limitador forte**
que, ao atingir uma hora configurável (default `17:00`), obriga os agentes a
avisar que é hora de começar a encerrar as sessões, reservando ~1h de runway até
o hard stop (default `18:00`).

Regras MANDATORY: aviso disparado por ação (checar `date +%H:%M` no início de cada
resposta); reemitir no topo de cada resposta seguinte até o operador reconhecer;
priorizar session-close sobre trabalho novo a partir da hora; no hard stop, só
conduzir o encerramento.

## Implementação (2026-07-02)

Seção `## 8c. Session wind-down alert (MANDATORY, strong limiter)` adicionada ao
`AGENTS.md`, com config `session_winddown_hour` (default 17:00) e
`session_close_budget` (default 60min). Cross-reference para enforcement runtime
em AI-GovernanceKit (`resume`/`doctor` podem exibir a hora e o runway).

## Fora de escopo

Enforcement executável (hook de relógio contínuo / runtime que dispara o aviso
sem depender do agente checar) — fica como issue companheira no AI-GovernanceKit.
