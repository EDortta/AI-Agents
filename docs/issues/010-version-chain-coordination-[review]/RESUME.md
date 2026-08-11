# RESUME — Cadeia de versões AI-Agents ↔ GovernanceKit

- work_id: WK-20260811-version-chain-coordination
- date: 2026-08-11
- status: `[review]` — lado AI-Agents entregue; lado GovernanceKit em andamento.

## Regra que originou o trabalho

Decisão do operador em 2026-08-11: **quando a tag de um dos dois kits avança, a versão
do outro acompanha o avanço** — não necessariamente com o mesmo número. O
GovernanceKit estava em `0.2.3` com 45 commits de mudança de comportamento parados sob
`[Unreleased]`, enquanto o AI-Agents já tinha publicado `v1.2.0`.

## Por que a versão do GovernanceKit não podia subir sozinha

`.docs/governancekit-integration.json` declara o range de GovernanceKit aceito, e
`integration.py:140` compara `__version__` contra ele. Subir o GovernanceKit para
`0.3.0` sem republicar o contrato faz todo projeto governado reportar `incompatible`.

## Council — rodada 1 (single-threaded; o operador proibiu spawn de subagentes)

**Levantados: 4. Sobreviveram ao §2: 2. Viraram teste: 0. Perguntas em aberto: 1.**

| # | lente | achado | fechamento |
|---|---|---|---|
| 1 | migrator | `incompatible` é `[FAIL]` não-advisory para projeto `existing` (`doctor.py:239`); 4 projetos do parque parariam, incluindo `jk-structure` | **foi ao operador** (§4: achado que contraria regra estabelecida sai do concílio). Decidiu range permissivo |
| 2 | sweep skeptic | a varredura de `v1.2.0` com `--include` perdeu 8 landing pages; quem pegou foi o §10d do `run-checks.sh` | corrigido; a lição está no napkin |
| 3 | claim auditor | `v1.2.1` declararia depender de um GovernanceKit `0.3.0` que ainda não existe no instante da tag | dissolvido pelo range permissivo |
| 4 | second caller | `ai_agents.ref` auto-referencia `v1.2.1` | não é achado — coerente |

**Pergunta em aberto:** nada verifica que os dois lados concordam. É o `R2-18` do épico
011 do GovernanceKit ("sem gate de deriva entre os dois kits"), e este trabalho é a
segunda vez que a ausência dele custa uma rodada. Continua aberto.

## Decisão do operador — range permissivo

`>=0.2.2,<0.4.0` em vez de `>=0.3.0,<0.4.0`. GovernanceKit `0.3.0` passa a ser
compatível com o contrato antigo e com o novo; nenhum dos 4 projetos `existing` acusa
`FAIL`; a migração deles deixa de ser urgente. O custo aceito: o gate não força o
upgrade — o que já era verdade na prática, já que os 4 estão em `v1.1.6`.

## Entregue (AI-Agents, branch `development`)

- `.docs/governancekit-integration.json`: `ref` `v1.2.0` → `v1.2.1`, range
  `>=0.2.2,<0.3.0` → `>=0.2.2,<0.4.0`
- `scripts/install-agents-kit.sh`: `REF` e as três referências que o §10c cobre
- `README.md`, `README-ptbr.md`, `README-es.md`
- 8 landing pages — `docs/` e a cópia distribuída em `.docs/`

`scripts/run-checks.sh`: verde.

## Next Step (DO THIS FIRST)

Lado GovernanceKit: `DEFAULT_REF` → `v1.2.1` com sha256 pinado, `0.2.3` → `0.3.0` em
`pyproject.toml` e `__init__.py`, os fixtures de teste que declaram o range antigo,
`CHANGELOG [Unreleased]` → `[0.3.0]`. Depois reinstalar a cópia local, que hoje está
congelada em 2026-08-06 e não tem `council.py`.

## Não validado

`not validated:` o comportamento do `doctor` num projeto `existing` real depois de o
GovernanceKit virar `0.3.0`. A previsão é `[PASS]`, porque o range permissivo admite
`0.3.0`, mas isso só se confirma rodando no `jk-structure` ou no `ledgerlab`.
