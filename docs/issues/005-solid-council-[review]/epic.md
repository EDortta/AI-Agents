# Epic: SOLID completo + Concílio de Agentes

## Metadata
- work_id: WK-20260717-solid-council
- date: 2026-07-17
- owner: [OPERATOR_NAME]
- related_commit: 8a71052, 80d0921, 49e5daa

## Context

O operador pediu três coisas na mesma frase: reforçar SOLID, acrescentar
harnesses, e permitir um concílio de agentes com as perguntas pertinentes vindas
do GovernanceKit.

A exploração mostrou que são **duas entregas de natureza diferente**:

- **SOLID + concílio são política** — markdown neste repo, sem dependência do
  runtime, entregam valor sozinhos;
- **arnês é runtime** — exige detecção de stack, geração, hooks por ferramenta, e
  refactors pesados no GovernanceKit. Depende de uma **tag** deste repo para o GK
  pinar o `KNOWN_TARBALL_SHA256`.

Tratá-las como um épico só produziria ~18 tarefas atravessando dois repos com uma
tag no meio. Decisão do operador: **fatiar**. Este épico é a fatia de política.

**Autorização de fronteira:** `.docs/limits.md` § Scope Authority exige aprovação
humana explícita para editar os gates/templates do kit-fonte, como *boundary
update*; `AGENTS.md` §1b tem a exceção correspondente ("Source-kit exception"). O
pedido do operador na sessão de 2026-07-17 é essa aprovação.

## Problem Statement

Três lacunas, de naturezas diferentes:

1. **`design-standards.md` cobria D e S, não O/L/I.** §2 nomeia Dependency
   Inversion, §5 nomeia SRP. Open/Closed, Liskov e Interface Segregation estavam
   ausentes — apesar de os três terem incidente real registrado na própria
   Provenance do arquivo, sem serem nomeados como tal.

2. **O concílio não existia como contrato.** Existia **uma** vez, ad-hoc: os "3
   adversarial skeptics" de `WK-20260701-dotdocs-kit-layout` → 6 findings, todos
   corrigidos e retestados. O instrumento funcionou e sumiu — virou nota de
   rodapé em `handoff.md` e `RESUME.md`, citado como evidência retroativa de que o
   trabalho era sólido. Nenhum workflow, spec ou contrato o descrevia.

3. **`governance-precedence.md` cobre o caso oposto.** Ele resolve papéis que
   **discordam**, com precedência + escalação humana, sem voto. Não cobre — e não
   deve cobrir — o caso em que **ninguém discorda** e o artefato está errado
   assim mesmo. Um concílio mal desenhado colidiria com ele, arbitrando por
   maioria e roteando em volta da escalação humana que o §Round 2 exige.

## Outcome

- **SOLID completo, sem inflar evidência.** As três letras entram *dentro* das
  seções que já as ancoram, não como §8/§9/§10: Provenance é por seção, e um
  incidente citado sob dois números lê como dois incidentes. Segue o precedente
  interno (§2 nomeia DI, §5 nomeia SRP). Zero renumeração — §1/§3/§7 são
  referenciados por número em `AGENTS.md`, `programmer.md` e `reviewer.md`.
  - §7 ← OCP (âncora: `chrome_op_guard()` morto, 4 endpoints hand-rolling `try/finally`)
  - §6 ← Liskov (âncora: dataclass com default em todo campo aceitando `{"nonsense": true}`)
  - §2 ← ISP como `[IMPROVEMENT]`, **não** MANDATORY: a única âncora (>3 mocks) não tem
    incidente atrás, e §0 diz que regra de nível 3 sem nível 1 é decoração. A regra vale
    para este arquivo também.

- **`council.md` com a fronteira explícita.** O concílio **produz findings, nunca
  decisões** — é isso que o impede de colidir com `governance-precedence.md`. Se
  dois membros discordam entre si, isso *vira* conflito de papéis e sai por uma
  porta de uma via. **Votar é PROHIBITED**: contar concordância é proxy de
  evidência; 3 de 3 sem reprodução vale zero, 1 com teste falhando vale tudo.

- **Ligado ao que carrega.** Load rule no `AGENTS.md` §2, índice no README com a
  frase que distingue council de precedence, 2 BLOCKERs novos no reviewer,
  `required=` no gate de release.

## Dependencies

- Nenhuma para esta fatia. Só markdown; não depende do AI-GovernanceKit.
- **Depende deste épico:** `WK-20260717-harness-generation` (épico 2) — o
  `council.md` §5 declara que a coleta executável das perguntas é o "como" do
  GovernanceKit, e o `design-standards.md` § Enforcement status declara Liskov
  como a primeira template do arnês.

## DoD

- [x] O, L e I presentes, cada um na seção que o ancora, sem renumeração
- [x] Toda regra nova termina em algo executável (não em adjetivo)
- [x] Toda regra preventiva declarada como preventiva na Provenance (flag-param §7,
      subclasse-clássica §6, ISP inteiro §2)
- [x] Checklist com exatamente uma linha por MANDATORY novo (4), zero para ISP
- [x] `council.md` segue o molde: preâmbulo com fronteira + precedência → seções
      numeradas → checklist → Provenance ancorada em incidente real → Enforcement
      status honesto
- [x] Fronteira council × governance-precedence explícita e em tabela
- [x] Ligado: `AGENTS.md` §2, `.docs/agents/README.md`, `reviewer.md`, `run-checks.sh`
- [x] `bash scripts/run-checks.sh` verde
- [x] Verificação inversa `AGENTS.md` §1a executada, sem vazamento
- [x] Session-close: `handoff.md` + `docs/napkin-lessons.md`
- [ ] Merge para `main` — **requer "sim" explícito do operador** (`AGENTS.md` §7)

## Privacy Checklist

Não aplicável: nenhum dado pessoal tratado, armazenado ou transmitido. O épico
altera contratos de governança em markdown. A única superfície de dado pessoal do
kit são os placeholders `[OPERATOR_NAME]`/`[SMTP_ACCOUNT]`, cuja integridade foi
verificada (`run-checks.sh` bloco 5 + verificação inversa do §1a).

## Épico 2 — Arnês + GovernanceKit (fatiado, NÃO executado aqui)

`work_id` proposto: `WK-20260717-harness-generation`, **coordenado nos dois
repos** (precedente: a epic 002 rodou o mesmo work_id nos gêmeos porque *"layouts
must not diverge"*).

Decisões do operador já tomadas, a preservar:

- Templates moram em `.docs/harness/` **no AI-Agents**, baixados pelo GK via
  tarball → uma só fonte de conteúdo, herda `DEFAULT_REF` + `KNOWN_TARBALL_SHA256`.
  Acrescentar `docs/harness` a `_KIT_DOC_PATHS` — os templates **não** precisam de
  categoria de ownership nova; são material de referência.
- Primeiro corte: Python + TypeScript/JS.
- Gate `project_context_ready`+`limits_ready` bloqueia **só** `harness`/`council`.
  `install-agents` fica intocado — ele **semeia** esses arquivos; gatear ele seria
  deadlock de bootstrap.
- Hooks: **merge por sentinela, opt-in** em `.claude/settings.json` e
  `.cursor/hooks.json`. JSON ilegível → aborta sem escrever. Escrita atômica.
- **`~/.codex/config.toml` o GK não escreve** — é global e escrever o
  `trusted_hash` seria fabricar consentimento que o modelo de confiança do Codex
  existe para colher do humano. Sai como fragmento + instruções.
- Templates testados pelo GK, com a **janela de lag declarada no contrato**.

A regra central que o épico 2 deve carregar:

> Nenhuma regra tem o hook como única enforcement. Uma regra enforced só por
> `PreToolUse` existe só na ferramenta que tem hooks → nas outras ela
> silenciosamente não existe. É o §3 na forma exata: *"a safety check placed at one
> caller, so the next caller silently lacks it"*. **As ferramentas são os call
> sites.**

Desenho completo, riscos e ordem de execução: ver o plano da sessão de
2026-07-17 e o `handoff.md` desta data.

## Session-Close Notes
- Handoff sync status: synced
- Last handoff update date: 2026-07-17
