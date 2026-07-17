# Task: O, L e I entram nas seções que já os ancoram

## Metadata
- work_id: WK-20260717-solid-council
- date: 2026-07-17
- owner: [OPERATOR_NAME]
- related_commit: 8a71052

## Parent Epic
- 005-solid-council

## Objective

`design-standards.md` cobria **D** (§2, seams) e **S** (§5, uma razão para mudar).
Faltavam Open/Closed, Liskov e Interface Segregation — apesar de os três terem
incidente real já registrado na Provenance do arquivo, sem serem nomeados.

## In Scope
- `.docs/agents/design-standards.md` (único arquivo)

## Out of Scope
- Renumerar seções. `§1`, `§3` e `§7` são referenciados por número em `AGENTS.md`,
  `programmer.md` e `reviewer.md`.
- Inventar incidente para ancorar regra. A Provenance ancora **toda** regra num
  incidente real; onde a regra é preventiva, isso vai escrito.

## ARO
- Acceptance: as três letras presentes; zero renumeração; toda regra nova termina
  em algo executável; toda regra preventiva declarada como tal; checklist com uma
  linha por MANDATORY novo.
- Risk: baixo (markdown). O risco real é de **conteúdo**: uma regra preventiva
  vendida como derivada de incidente infla a evidência num arquivo cuja tese é
  honestidade.
- Operations: nenhuma.

## Decisão de estrutura

As letras entram **dentro** das seções que já as ancoram, não como §8/§9/§10:

1. **Provenance é por seção.** Se OCP virasse §8, o `chrome_op_guard()` morto teria
   que aparecer na Provenance de §7 *e* §8 — um incidente lendo como dois — ou §8
   nasceria sem provenance, que é a decoração que o §0 condena.
2. **O arquivo é organizado por modo de falha, não por letra.** §0: *"The goal is
   not to be SOLID. SOLID is a means"*.
3. **Precedente interno.** É assim que as duas letras já presentes aparecem: §2
   *"Seams — the real reason Dependency Inversion is in this file"*; §5 *"One reason
   to change (SRP, stated so it can be checked)"*.

## Implementado

| seção | letra | âncora | regras |
|---|---|---|---|
| §7 | OCP | **real**: `chrome_op_guard()` morto, 4 endpoints hand-rolling `try/finally` | 2 MANDATORY (o segundo call site é a prova; N+1 não edita N) + 1 PROHIBITED **preventivo** (flag-param) |
| §6 | Liskov | **real**: dataclass com default em todo campo aceitando `{"nonsense": true}` | 1 MANDATORY (não enfraquece o que os chamadores da base assumem; executável = a suíte da interface roda contra toda implementação) + 1 PROHIBITED (override que vira falha em sucesso silencioso) |
| §2 | ISP | **nenhuma** | 1 `[IMPROVEMENT]` (o fake implementa só o que o código chama; conte os stubs nunca chamados) |

**ISP é `[IMPROVEMENT]`, não MANDATORY.** A única âncora disponível (">3 mocks é o
design falando") não tem incidente registrado atrás. Um MANDATORY preventivo é
precisamente o que o §0 chama de decoração — e o §0 vale para este arquivo também.
Declarado na Provenance como candidato a remoção se nunca pegar nada.

## Test Plan

Markdown; não há runtime. O que foi verificado, e como:

- **Zero renumeração** — `grep -rn 'design-standards.*§[0-9]' AGENTS.md .docs/agents/ docs/`
  cruzado com `grep -n '^## [0-9]' design-standards.md`. Seções seguem 0–7; §1
  (tests), §3 (invariant) e §7 (delete) continuam sendo o que eram. **Executado.**
- **Uma linha de checklist por MANDATORY novo** — 4 MANDATORY adicionados, 4 linhas
  de checklist, zero para ISP. Contado no diff. **Executado.**
- **`bash scripts/run-checks.sh`** — verde. **Executado.**

`not validated:` o efeito das regras novas sobre uma revisão real. Nenhum PR foi
revisado sob elas ainda.

## Security
- `no security impact`. Contrato de design em markdown; sem superfície de runtime.
- Verificação inversa `AGENTS.md` §1a executada (valores reais do operador lidos de
  `~/.config/USER.md`/git config, grepados sem hardcode): sem vazamento.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- [x] O, L, I presentes, cada um na seção que o ancora
- [x] Zero renumeração, verificado por grep
- [x] Toda regra nova termina em algo executável
- [x] As três regras preventivas declaradas como preventivas na Provenance
- [x] Checklist: 4 linhas, uma por MANDATORY novo
- [x] Enforcement status diz qual letra é mecanizável (Liskov) e qual não é
- [x] `run-checks.sh` verde
