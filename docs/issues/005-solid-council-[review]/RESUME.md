# RESUME — 005 SOLID completo + Concílio

- work_id: WK-20260717-solid-council
- date: 2026-07-17
- branch: `feature/uc-005/solid-council`
- status: [review] — implementado e validado; aguarda decisão de merge do operador

## Next Step (DO THIS FIRST)

Perguntar ao operador se `feature/uc-005/solid-council` (3 commits: 8a71052,
80d0921, 49e5daa) merge para `main`. `AGENTS.md` §7 exige "sim" explícito e o
default é **não**. Este repo não tem `development` — se o operador quiser
corrigir essa divergência (o §7 diz que development é a branch de trabalho), isso
é decisão de topologia própria, fora deste épico.

## Estado

Implementado, com `bash scripts/run-checks.sh` verde:

| commit | o quê |
|---|---|
| `8a71052` | O/L/I em `design-standards.md`, dentro das seções que já os ancoram |
| `80d0921` | `.docs/agents/council.md` |
| `49e5daa` | load rules (`AGENTS.md` §2), README, 2 BLOCKERs no reviewer, `required=` |

## Decisões que não devem ser re-litigadas

- **As letras entram dentro das seções, não como §8/§9/§10.** Provenance é por
  seção; um incidente sob dois números lê como dois incidentes. Zero renumeração
  (§1/§3/§7 são citados por número em 3 arquivos).
- **ISP é `[IMPROVEMENT]`, não MANDATORY.** Sem incidente atrás. §0 aplica-se a
  este arquivo: nível 3 sem nível 1 é decoração. Declarado candidato a remoção se
  nunca pegar nada.
- **O concílio não decide.** É o que o mantém sem colidir com
  `governance-precedence.md`. Votar é PROHIBITED.
- **O concílio é decoração até que algo o convoque** — declarado no próprio
  Enforcement status. Escolha consciente do operador nesta fatia.

## Aberto

- **Épico 2** (`WK-20260717-harness-generation`): arnês + GovernanceKit, fatiado
  desta sessão. Desenho completo em `epic.md` § Épico 2 e no `handoff.md` de
  2026-07-17. A ordem é forçada por um handoff duro: AI-Agents taggeia → só então
  o GK calcula o sha256 e bumpa `DEFAULT_REF`.
- **not validated:** o efeito do `council.md` numa rodada real. Zero rodadas sob
  ele. Só o registro das primeiras N (MANDATORY no §4) dirá se os triggers e o
  número 3 prestam.
