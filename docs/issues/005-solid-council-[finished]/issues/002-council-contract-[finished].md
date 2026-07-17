# Task: council.md — contrato de revisão adversarial de trabalho aprovado

## Metadata
- work_id: WK-20260717-solid-council
- date: 2026-07-17
- owner: [OPERATOR_NAME]
- related_commit: 80d0921

## Parent Epic
- 005-solid-council

## Objective

Formalizar o instrumento que rodou **uma vez** e sumiu: os "3 adversarial
skeptics" de `WK-20260701-dotdocs-kit-layout` → 6 findings, todos corrigidos e
retestados. Nunca teve workflow, spec ou contrato; foi citado só como evidência
retroativa em `handoff.md` e no `RESUME.md` da epic 002.

## In Scope
- `.docs/agents/council.md` (novo)

## Out of Scope
- **Orquestração.** Decisão do operador: spec markdown + config; quem executa é o
  agente lendo o doc. Zero código.
- **As perguntas executáveis.** Este arquivo owna o *quê/porquê* (§5); a coleta é o
  *como* do AI-GovernanceKit (épico 2).
- **Dar dentes.** Um gate de release que falhe sem registro de concílio é decisão
  futura, informada pelos registros que o §4 passa a exigir.

## O problema que justifica um arquivo novo

Um reviewer pergunta "esta mudança está correta?". Todos respondem sim. A mudança
sobe e está errada assim mesmo.

Isso não é falha de review — é a **falha de consenso**: reviewer e programmer
compartilham o mesmo modelo mental, e um erro *dentro* do modelo é invisível aos
dois, não por descuido, mas porque olham pela mesma lente. Um segundo reviewer com
a mesma lente acha o que o primeiro achou.

## A fronteira com governance-precedence.md (o ponto crítico)

|  | `governance-precedence.md` | `council.md` |
|---|---|---|
| entrada | duas recomendações que **conflitam** | um artefato que **todos aprovaram** |
| problema | os papéis discordam | **ninguém discorda** — esse é o problema |
| saída | uma **direção** + trade-off | **findings** — nunca uma direção |
| mecanismo | precedência + escalação humana | evidência |

**Não colidem porque o concílio não decide nada.** Se dois membros discordam entre
si, o concílio não resolve: ou o finding não sobrevive ao §2, ou **virou** conflito
de papéis e sai por uma porta de uma via para `governance-precedence.md`.

**Votar é `[PROHIBITED]`** — contar concordância é proxy de evidência. 3 de 3 sem
reprodução vale zero; 1 com teste falhando vale tudo. É o §0 do design-standards
aplicado a este arquivo. E a razão de fundo: um instrumento que arbitrasse por
maioria rotearia em volta da escalação humana que o §Round 2 do
governance-precedence exige.

## Implementado

- **§0** — a falha de consenso, e as três consequências que atravessam o arquivo.
- **§1** — a fronteira, em tabela, com a porta de uma via nomeada.
- **§2** — finding sobrevive **sse** nomeia os quatro: gatilho concreto, resultado
  errado observável, onde (`file:line` ou regra violada), e evidência (teste
  falhando / reprodução / `not reproduced:` honesto). Sem o quarto **não é finding,
  é pergunta** — e perguntas não bloqueiam, mas são escritas.
  Inclui `[PROHIBITED]`: reportar finding cuja evidência é que o modelo o achou
  convincente. **A confiança de um agente não é evidência**, e este é o último
  arquivo que deveria esquecer isso.
- **§3** — 3 membros default, lentes obrigatoriamente distintas, cada uma ancorada
  numa regressão real deste ecossistema.
- **§4** — triggers **declarados provisórios** + registro de rodada `[MANDATORY]`.
- **§5** — as perguntas, derivadas linha a linha do Target Project Checklist que o
  `software-overview.md` já tem. Não é questionário novo.

## As lentes e suas âncoras (nenhuma inventada)

| lente | âncora real |
|---|---|
| cético da varredura | `[2026-07-01]` sweep por prefixo perdeu args nus (`cp -r AI-Agents/docs`) e links `./`; os céticos pegaram 3 stragglers |
| auditor de claims | `[2026-07-16]` issue alegou "tested by unit"; o repositório não tinha teste nenhum |
| segundo chamador | `[2026-07-16]` o installer tem **dois** caminhos de cópia; script novo só no primeiro deixou a instalação limpa sem ele |

## Test Plan

Markdown; não há runtime. Verificado:

- **Molde respeitado** — gêmeo estrutural de `security-standards.md`/`design-standards.md`:
  preâmbulo com fronteira + precedência → seções numeradas com
  `[MANDATORY]/[PROHIBITED]/[IMPROVEMENT]` → checklist → Provenance ancorada →
  Enforcement status. **Conferido por leitura.**
- **Verificação inversa §1a** — sem dado real do operador. **Executado.**
- **`bash scripts/run-checks.sh`** — verde. **Executado.**

`not validated:` **o efeito deste contrato numa rodada real de concílio. Zero
rodadas foram feitas sob ele.** Declarado no próprio Enforcement status do arquivo.

## Security
- `no security impact`.

## Privacy
- Personal data impact: no.

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## Risco aceito, registrado

Pelo §0 do design-standards, **um concílio que nada convoca é decoração** — e nada
neste arquivo o convoca. Os triggers do §4 dependem de alguém lembrar de lê-los,
que é exatamente o modo de falha que o §0 nomeia.

Escolha deliberada do operador para esta fatia, mitigada por:
- triggers declarados **provisórios** em vez de fantasiados como assentados;
- registro de toda rodada `[MANDATORY]` — é o que gera os dados que dirão se vale
  mecanizar.

Está escrito no Enforcement status do próprio arquivo, não escondido aqui.

## DoD
- [x] `council.md` criado no molde dos standards
- [x] Fronteira contra `governance-precedence.md` explícita e em tabela
- [x] Concílio produz findings, nunca decisões; porta de uma via nomeada
- [x] Votar é PROHIBITED, com a razão escrita
- [x] Critério de finding sobrevivente com os quatro itens
- [x] 3 lentes, cada uma ancorada em regressão real citada por data
- [x] Provenance honesta sobre n=1
- [x] Enforcement status admite a decoração e diz o que a corrigiria
- [x] `run-checks.sh` verde
