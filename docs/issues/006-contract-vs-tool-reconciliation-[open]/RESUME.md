# RESUME — Reconciliar contrato AI-Agents e ferramenta GovernanceKit

- work_id: WK-20260804-governancekit-contract-reassessment
- date: 2026-08-26 (reconciliado; original 2026-08-04)
- status: `[open]` — texto entregue na branch `feature/006-reconcile-batch` (PR para `development` pendente de revisão); **corte de tag pendente do operador**

Histórico (crítica de 2026-08-06, decisões C1/C2, refutação de B1, sessão de
2026-08-07): `git log -- "docs/issues/006-contract-vs-tool-reconciliation-[draft]"`.

## Placar verificado em 2026-08-26 (contra código/refs, não mensagens de commit)

Fechado "na fonte" ainda não é fechado no parque: nada abaixo de `40f925b` está em
tag alguma. O parque só recebe A2/A4–A10/C1 após o `tag-cut-checklist.md` desta pasta.

| Issue | Estado | Evidência |
|---|---|---|
| **A1** | fechada na cadeia 1–3 | fonte sem `.docs/` de readiness; `v1.1.8`/`v1.2.0`/`v1.2.1` no origin; GovernanceKit `DEFAULT_REF="v1.2.1"`+sha256 (main e development). Critério final (06/08): *num projeto governado, §1b nomeia os caminhos que o `doctor` verifica* — validar no elo 4, passo 9 do checklist |
| **A2** | fechada neste batch (fonte) | decisão do operador registrada como AC-30 (GovernanceKit `1f7daa7`, **só em `development` de lá — sem tag/main ainda**); `scripts/install-agents-kit.sh` removido daqui, docs instruem `governancekit install-agents`, guard 6b no `run-checks.sh`. Chega ao parque com o release coordenado (checklist, passos 7–8) |
| **A3** | fechada 07/08 | `79e16aa` (GovernanceKit) · `9a34b57` (AI-Agents) |
| **A4** | fechada (`40f925b`) | `AGENTS.md` §3c presente |
| **A5** | fechada neste batch | §1a/§8b/banners citam o que a ferramenta escreve (`.gk/operator.json`, `.governancekit-identity.json`); `.credentials/identity.json` vira legado/fallback |
| **A6** | fechada (`40f925b`) | §1b nomeia `doctor`; "either"→"any of them"; fallback documentado |
| **A7** | fechada no contrato | §8a e `~/CLAUDE.md` global concordam no XDG desde 06/08. Residual fora do repo: `~/Sync/agent-status.json` ainda recebe escrita (sessões `cursor` 16–17/08) — regra local alheia aponta ao caminho velho; aviso de monitor não-canônico no `doctor` é lado GovernanceKit |
| **A8** | metade contrato fechada (`40f925b`) | falta a metade `doctor` (estrutura, não só flag) — GovernanceKit |
| **A9** | fechada (`40f925b`) | instalar é ação do operador |
| **A10** | fechada (`40f925b`) | §1c manda rodar `concurrency`/`resume` na abertura |
| **B1** | fechada 07/08 | refutada; reduzida ao bullet de council da §7 |
| **B2** | aberta | inventário de regras determinísticas → hooks. Inclui a decisão de 06/08: proibir `git add -A` **por hook** — a prosa do git-delivery §7 é paliativo, não fechamento |
| **B3** | fechada 07/08 | `56ff8f0` (GovernanceKit) · `889eabe` (AI-Agents) |
| **C1** | metade contrato fechada (`40f925b`) | §1c terceira frente + §7 gates em prosa; enforcement segue em B2 |
| **C2** | aberta | lease de sessão em `<git-common-dir>` — GovernanceKit; inclui `_unmerged_count` fail-open |
| **D1** | fechada 06/08 | gate no commit de entrega |
| **G1–G5** | lado GovernanceKit | épica gêmea; G2 absorvida por G1 |

## Este batch (branch `feature/006-reconcile-batch`)

Épica `[draft]`→`[open]`; A2-retirada (fecha também R2-1 e #9/#10 da épica 008 do
GovernanceKit); A5; `tag-cut-checklist.md`. Council do batch: **2 rodadas, 3 lentes
independentes cada** — r1: 19 levantados / 16 sobreviveram / 2 viraram teste / 4
perguntas; r2: 18 levantados + 2 perguntas, classificados **6 introduzidos-pela-r1 ·
3 abertos-da-r1 · 9 pré-existentes** — todos fechados nesta branch ou registrados
acima como coordenação/aceitação. Detalhe nas entradas de 2026-08-26 de
`docs/napkin-lessons.md` e `handoff.md`, que entram no commit de session-close
desta mesma PR.

## Coordenação pendente (lado GovernanceKit — épica gêmea / Squad D)

1. **O bump de `DEFAULT_REF` para `v1.3.0`, o AC-30 e o conserto das páginas/testes
   de lá têm de entrar no MESMO release** (detalhe no checklist, passos 7–8):
   `scripts/refresh-kit-snapshot.py` aborta num tarball sem o instalador shell;
   `tests/test_advanced_usage_docs.py:96` exige a URL do script no `DEFAULT_REF`
   (com `v1.3.0`, um 404); `:115-123` amarra as 4 páginas ao mesmo `v1.x.y`. Um
   release intermediário (AC-30 sem o bump) apaga o script do alvo e reinstala o
   `AGENTS.md` de `v1.2.1` que manda rodá-lo. O range
   `>=0.2.2,<0.4.0` do contrato **não força** o upgrade do pacote — a
   reinstalação (`pip install --upgrade …@<tag>`) é passo explícito do checklist;
   a decisão de não estreitar o range (2026-08-11) segue de pé e registrada.
2. A landing do GovernanceKit (`docs/index.html:1279`) ainda instrui `curl | bash`
   do instalador aposentado (raw URL de `v1.2.1` segue servindo — tags são
   imutáveis). Só ela: `docs/melhorias.html` menciona o script apenas em prosa
   histórica de roadmap (`:439`), sem comando — corrigido nesta rodada, a r1
   listava as duas.
3. `--allow-unverified` recomendado pela mensagem de erro de `install_agents.py:600`
   não existe no parser do CLI (e está documentado como existente lá).
4. `README.md` fora de `_WITHDRAWN_PATHS` — README do kit vazado em alvos fica lá
   para sempre (o check 9 daqui foi removido junto com o instalador).
5. Injeção do bloco kit no `docs/required-reading.md` em upgrade (o back-fill do
   shell aposentou sem equivalente Python; hoje só o advisory do `doctor` cobre).
6. `tests/test_doctor_gitignore.py:207-232` (`ShellInstallerWritesTheSameBlockTests`)
   passa a `skipTest` silencioso quando o `.sh` some do checkout irmão — aposentar
   o teste de paridade deliberadamente, não deixá-lo verde sem testar nada.

## Next Step (DO THIS FIRST)

**Operador:** executar `tag-cut-checklist.md` desta pasta — cortar `v1.3.0` com o
batch mesclado e apontar `DEFAULT_REF`+checksum do GovernanceKit para ela. Só isso
leva A2/A4–A10/C1 ao parque. Depois: B2, C2 e G* na épica gêmea do GovernanceKit.
