# Task: ligar council.md e as regras novas ao que já carrega

## Metadata
- work_id: WK-20260717-solid-council
- date: 2026-07-17
- owner: [OPERATOR_NAME]
- related_commit: 49e5daa

## Parent Epic
- 005-solid-council

## Objective

Regra que o commit `b706b4d` estabeleceu: **um arquivo que não está nas load rules
do `AGENTS.md` é um arquivo que ninguém carrega.** `council.md` e as regras O/L/I
não valem nada até alguém abri-las.

## In Scope
- `AGENTS.md` §2 — load rule
- `.docs/agents/README.md` — índice
- `.docs/agents/reviewer.md` — Blocker Criteria
- `scripts/run-checks.sh` — `required=`

## Out of Scope
- `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, `GEMINI.md`,
  `.github/copilot-instructions.md` — todos apontam para `AGENTS.md`, que já
  carrega. A linha do `harness run` neles é do épico 2.

## Implementado

| arquivo | mudança |
|---|---|
| `AGENTS.md` §2 | load rule para `council.md`, **com os triggers nomeados na própria linha** (varredura mecânica, contrato compartilhado, `not validated:` em runtime, release que muda gate) — quem lê a regra já sabe se ela é dele, sem abrir o arquivo |
| `.docs/agents/README.md` | `council.md` indexado ao lado de `governance-precedence.md`, cada um com a frase que os distingue. É onde a fronteira fica visível para quem escolhe qual abrir |
| `.docs/agents/reviewer.md` | 2 BLOCKERs novos: implementação que não passa na suíte da interface (§6); mecanismo geral com zero call sites convertidos (§7) — as duas MANDATORY novas que o reviewer consegue de fato verificar num diff |
| `scripts/run-checks.sh` | `required=` ganha `council.md` |

## Refactor de apoio — declarado, não contrabandeado

`required=` também ganhou **`design-standards.md`**, que estava faltando da lista
desde ontem (`b706b4d`) apesar de o `AGENTS.md` §2 já o carregar. O gate de release
não checava a presença de um arquivo que o contrato manda ler.

`design-standards.md` §7 exige: *"Supporting refactor is declared, not smuggled:
name it in the output, keep it in the same commit as the reason for it."* Ambos
feitos — declarado no corpo do commit `49e5daa` e no mesmo commit que a razão dele.

## Ordem que importou

`run-checks.sh` foi tocado **por último**, depois de `council.md` existir. O bloco 1
é o gate de release consumido por `new-tag.sh`: acrescentar ao `required=` um
arquivo que ainda não existe quebra a tag no meio do épico.

## Test Plan

- **`bash scripts/run-checks.sh`** — **executado, verde**: 9 required presentes
  (`design-standards.md` e `council.md` entre eles), sem marcador de conflito,
  `bash -n` em 5 scripts, nenhum arquivo de segredo rastreado, placeholders
  intactos.
- **shellcheck** — `[skip]`: **não instalado nesta máquina.** `not validated:` a
  análise estática do `run-checks.sh` modificado. A mudança é uma linha adicionada
  a um array literal; o `bash -n` passou.
- **Referências por número intactas** — grep cruzado; §1/§3/§7 continuam apontando
  para as seções certas. **Executado.**

## Security
- `no security impact`. O `run-checks.sh` ficou **mais** restritivo (dois arquivos
  a mais exigidos); nenhuma checagem foi afrouxada ou removida.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- [x] `AGENTS.md` §2 carrega `council.md`, com triggers na linha
- [x] `README.md` indexa council com a fronteira visível
- [x] `reviewer.md` com os 2 BLOCKERs derivados de §6 e §7
- [x] `run-checks.sh` exige `council.md` **e** `design-standards.md`
- [x] Refactor de apoio declarado no commit, no mesmo commit da razão
- [x] `run-checks.sh` verde
- [x] Adapters por ferramenta não tocados (apontam para `AGENTS.md`)
