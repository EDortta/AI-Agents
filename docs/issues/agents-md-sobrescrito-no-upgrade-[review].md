# `AGENTS.md` é substituído no `--upgrade` e leva junto as regras do projeto

- work_id: WK-20260723-agents-md-protegido
- date: 2026-07-23
- solicitado por: [OPERATOR_NAME]

## Motivação

`upgrade_kit()` em `scripts/install-agents-kit.sh` trata o `AGENTS.md` como
arquivo kit-owned e o **substitui inteiro**:

```bash
# Root kit files. These are safe to replace because project-specific context
# lives in .docs/software-overview.md, .docs/limits.md, handoff, issues, and lessons.
copy_file_replace "AGENTS.md"
```

O comentário declara a premissa: *"safe to replace because project-specific context
lives elsewhere"*. A premissa é razoável como design — mas **nada no kit a verifica ou
a impede de ser violada**, e na prática ela é violada.

Caso real (ZeeCred / `jk-structure`, 2026-07-23): o `AGENTS.md` do projeto tinha
**960 linhas**, das quais cerca de **300 eram específicas do projeto** — visão geral do
repositório, arquitetura, guarda de configuração do ESLint com lista nominal de
mantenedores autorizados, regras de acesso a servidor remoto, isolamento de servidores
standalone, integração wa-hub, envio de e-mail, e logins reais de revisor
(`EXPECTED_REVIEWER_LOGINS="..."`) no lugar dos placeholders.

Um `--upgrade` teria apagado tudo isso em silêncio. Não há aviso, não há diff, não há
backup: `copy_file_replace` sobrescreve e segue.

O caminho pelo qual isso acontece é previsível, e é o mesmo em qualquer projeto:

1. O `AGENTS.md` é o primeiro arquivo que todo agente lê — o kit manda ler ele primeiro.
2. Um agente (ou uma pessoa) precisa registrar uma regra do projeto.
3. Escreve no arquivo mais visível e mais autoritativo: o próprio `AGENTS.md`.
4. Ninguém percebe, porque o arquivo continua funcionando perfeitamente — até o upgrade.

Ou seja: **o kit não protege o arquivo, e o design do kit incentiva justamente a
edição que o upgrade destrói.** O `run-checks.sh` já checa que os placeholders
`[OPERATOR_NAME]` continuam intactos, o que mostra que a preocupação com deriva do
`AGENTS.md` já existe — só que a checagem cobre um caso (dados do operador vazados
para o kit) e não cobre o inverso (regras do projeto que serão perdidas).

## Mudança necessária

Três opções, em ordem de preferência. Não são mutuamente exclusivas.

### A. Detectar deriva e recusar (mínimo aceitável)

Antes de `copy_file_replace "AGENTS.md"`, comparar o arquivo do alvo com o
`AGENTS.md` da versão do kit que o instalou (hash gravado no manifesto). Se divergir:

- **parar o upgrade desse arquivo**, não o restante;
- salvar `AGENTS.md.kit-new` ao lado;
- imprimir o diff resumido e instruir a migração manual;
- sair com código distinto de 0 apenas se o operador pediu `--strict`.

Fail-closed: divergência não detectável (sem manifesto, sem python) → não substituir.

### B. Mecanismo de inclusão de regras do projeto (resolve a causa)

Dar ao projeto um lugar legítimo e visível **dentro do fluxo de leitura**, para que
ninguém precise editar o `AGENTS.md`:

- o kit passa a escrever, no final do `AGENTS.md`, um ponteiro fixo do tipo
  `Project-specific rules: .docs/agents/project-rules.md (read after this file)`;
- `install` cria `.docs/agents/project-rules.md` vazio se não existir, e **nunca**
  o sobrescreve no upgrade (não entra no manifesto como kit-owned).

Assim o instinto "escrever no lugar autoritativo" passa a ter um destino que sobrevive.

### C. Backup incondicional

`copy_file_replace` de qualquer arquivo kit-owned grava `<arquivo>.pre-upgrade.bak`
antes de sobrescrever. Barato, e transforma perda silenciosa em recuperação trivial.

## Escopo

- `scripts/install-agents-kit.sh` — detecção de deriva, backup, criação do arquivo de
  regras do projeto.
- `AGENTS.md` do kit — ponteiro para o arquivo de regras do projeto (opção B).
- `scripts/run-checks.sh` — checagem simétrica à de placeholders: avisar se o
  `AGENTS.md` do alvo contém seções que não existem no do kit.
- Sem mudança de runtime em projeto consumidor.

## Comportamento esperado

- **Antes:** `--upgrade` sobrescreve `AGENTS.md` e apaga regras do projeto sem aviso.
- **Depois:** o upgrade detecta a divergência, preserva o arquivo do projeto, deixa a
  versão nova ao lado e diz exatamente o que fazer; e existe um destino oficial para
  regra de projeto que o upgrade nunca toca.

## Plano de teste

1. Instalar o kit num diretório limpo; anotar o hash do `AGENTS.md`.
2. Acrescentar uma seção qualquer ao `AGENTS.md` do alvo.
3. Rodar `--upgrade` → a seção deve sobreviver; `AGENTS.md.kit-new` presente; aviso impresso.
4. Alvo sem modificação → `--upgrade` substitui normalmente, sem ruído.
5. Alvo sem manifesto (instalação antiga) → não substitui; instrui migração.
6. `run-checks.sh` num alvo com seção extra → aviso, não falha.

## Impacto / Risco

- Risco baixo: o caminho novo é mais conservador que o atual (deixa de sobrescrever).
- Risco de regressão: um alvo cujo `AGENTS.md` diverge por motivo legítimo (edição
  antiga já absorvida) passa a exigir uma ação manual uma vez. Aceitável — hoje a
  alternativa é perda silenciosa.

## Definition of Done

- `--upgrade` não sobrescreve `AGENTS.md` divergente; deixa `.kit-new` e avisa.
- Existe destino oficial para regras de projeto, criado no install e nunca sobrescrito.
- `run-checks.sh` avisa sobre seções extras no `AGENTS.md` do alvo.
- Comportamento documentado no README do kit.
- Status do arquivo movido para `[review]` após aplicar.

---

## Resolução (2026-07-23) — WK-20260723-agents-md-protegido

As três opções entregues, mais os avisos no `run-checks.sh`.

**A máquina já existia e não estava ligada nos arquivos de raiz.** `sync_dir` já fazia
exatamente a proteção pedida — carrega `.gk/manifest.json`, compara `file_sha256` contra
`KIT_HASHES`, e guarda a versão editada em `.gk/overwritten/`. Mas arquivos de raiz não
passam por `sync_dir`; passam por `copy_file_replace`, que era um `cp -a` seco. O conserto
foi estender `copy_file_replace` com o julgamento que o vizinho já fazia.

**A.** `copy_file_replace` agora decide por hash:

| Estado | Protegido (`AGENTS.md`) | Demais kit-owned de raiz |
|---|---|---|
| hash bate com o manifesto | substitui, silencioso | substitui, silencioso |
| hash diverge | **não substitui**; `AGENTS.md.kit-new`; entra em `DRIFTED` | stash em `.gk/overwritten/`, substitui |
| sem manifesto / sem `python3` | **fail-closed: não substitui** | substitui (comportamento antigo) |

O fail-closed sem manifesto é o que cobre o caso `jk-structure` — instalações anteriores
ao `.gk/` são justamente as mais propensas a ter regra escrita à mão.

`PROTECTED_ROOT_FILES=("AGENTS.md")` é lista nomeada: outro arquivo entra sem tocar na
lógica. Novo `--strict` (só com `--upgrade`) sai 6 quando algo foi preservado — o upgrade
mesmo assim se completa, o código de saída é só como um pipeline aprende que há merge
pendente. Novo `--check`: relatório de deriva read-only, escreve nada.

**B.** Destino oficial em **`docs/project-rules.md`**, não em `.docs/agents/project-rules.md`
como a issue propunha. Motivo: `.docs/` é território do kit (`sync_dir ".docs/agents"`);
`docs/` é a metade que o instalador promete nunca sobrescrever. A garantia é uma **ausência**:
o path está deliberadamente fora de `KIT_OWNED_PATHS`, e o `run-checks.sh` agora assere essa
ausência — ausências são fáceis de desfazer sem querer. Semeado no install **e** no upgrade
(um alvo existente não tem o arquivo e nunca ganharia um). Ponteiro no `AGENTS.md`,
`CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules` e `copilot-instructions.md`.

**C.** Backup de todo arquivo de raiz substituído, em `.gk/pre-upgrade/<rel>` e **não** em
`<arquivo>.pre-upgrade.bak` ao lado, como a issue pedia: são 14 arquivos de raiz, e 14 `.bak`
no topo do projeto a cada upgrade é lixo que acaba commitado. Sob `.gk/` já existe o
`.gitignore` gerado, e a recuperação continua sendo um `cp`. Limpo no início de cada upgrade
— "pre-upgrade" acumulado não significa nada em particular. O `.kit-new`, esse sim, fica ao
lado do arquivo: é um só, e é para ser visto.

**`run-checks.sh`:** a issue pedia "avisar se o `AGENTS.md` do alvo tem seções que o do kit
não tem". Não cabe ali — o `run-checks.sh` roda no repo do kit e nem é instalado no alvo;
não existe alvo para comparar. A comparação foi para onde os dois lados existem: o
`--check` do instalador. No `run-checks.sh` ficaram as quatro invariantes que ele **pode**
verificar, simétricas à checagem de placeholders (que guarda a direção oposta): o ponteiro
existe no `AGENTS.md`, o starter existe, o path **não** é kit-owned, e o `AGENTS.md` está
em `PROTECTED_ROOT_FILES`.

**Bug real pego durante a implementação, não pelo teste:** `write_manifest` grava o hash do
que está em disco. Para um `AGENTS.md` preservado, o que está em disco é a versão **do
projeto** — o manifesto passaria a dizer "conteúdo intocado do kit, pode substituir", e o
upgrade seguinte apagaria tudo. Exatamente a perda que a proteção existe para impedir, com
um turno de atraso. Agora `write_manifest` pula os paths em `DRIFTED`, deixando a entrada
anterior (ou nenhuma) no lugar: o arquivo continua divergente até um humano mesclar.
O teste 2b (dois `--upgrade` seguidos) existe por causa disso.

**Validado — executado de verdade:**

| Cenário | Resultado |
|---|---|
| install fresco | `docs/project-rules.md` criado; ponteiro presente; `AGENTS.md` no manifesto |
| alvo intocado → `--upgrade` | substitui, sem `.kit-new`, sem ruído; 14 backups em `.gk/pre-upgrade/` |
| `AGENTS.md` editado → `--upgrade` | regra sobrevive; `.kit-new` presente; manifesto **não** absorve o hash do projeto |
| dois `--upgrade` seguidos | regra ainda viva na segunda passada |
| `--upgrade --strict` | exit 6 |
| sem `.gk/` (instalação antiga) | não substitui; `.kit-new`; regra viva |
| `--check` com deriva | relata; nenhum byte escrito (md5 da árvore igual antes/depois) |
| `--check` sem manifesto | explica que preservaria tudo |
| `--check --upgrade` / `--strict` sozinho | exit 2 |
| `docs/project-rules.md` customizado → `--upgrade` | customização sobrevive; ausente do manifesto |
| regressão: path em `KIT_OWNED_PATHS` | `run-checks.sh` FALHA |
| regressão: `PROTECTED_ROOT_FILES` vazio | `run-checks.sh` FALHA |
| regressão: ponteiro removido do `AGENTS.md` | `run-checks.sh` FALHA |

`bash scripts/run-checks.sh` passa; `shellcheck -S error` limpo nos dois scripts.

**Não validado:** o caso `python3` ausente foi verificado por leitura de código
(`load_manifest` avisa e deixa `KIT_HASHES` vazio, caindo no mesmo caminho fail-closed já
testado sem manifesto), não por execução num host sem `python3`.

---

## Dry-run em 33 projetos reais (2026-07-23) — e o segundo bug

O operador pediu `--check` em todo projeto que usa o kit. 33 alvos identificados
(`AGENTS.md` + `.docs/limits.md` ou `docs/limits.md`).

**A primeira passada reportou "No drift" em 20 alvos, incluindo o `jk-structure` que
motivou esta issue.** Isso contradizia a issue, então fui olhar em vez de acreditar:
o `AGENTS.md` do `jk-structure` tem 607 linhas e **não está no `.gk/manifest.json`** —
o manifesto de lá tem 13 arquivos e `ref: "backfilled"` (veio do GovernanceKit, não
deste instalador).

O `check_drift` iterava as **chaves do manifesto**. Arquivo ausente do manifesto era
invisível para o relatório — mas o `copy_file_replace` trata ausência como fail-closed e
**preserva**. Relatório e comportamento discordavam, e o relatório era o otimista: dizia
"pode subir tranquilo" sobre 20 alvos onde o upgrade na verdade pararia. Causa: as listas
de arquivos de raiz estavam duplicadas em três lugares (`upgrade_kit`, `KIT_OWNED_PATHS`,
e implicitamente o `check_drift`), e uma delas divergiu.

Corrigido: `KIT_ROOT_FILES` é a lista única; `upgrade_kit` a percorre, `KIT_OWNED_PATHS`
a inclui, e `check_drift` julga exatamente ela com a mesma tabela de decisão — arquivo
ausente do manifesto agora aparece como `KEPT (not in manifest, provenance unknown)`.

**Resultado do dry-run, com o `--check` corrigido** (nenhum byte escrito em nenhum alvo —
verificado por varredura de `*.kit-new` e `pre-upgrade/` depois):

| Situação do `AGENTS.md` | Alvos | O que o `--upgrade` faz |
|---|---|---|
| Conteúdo próprio do projeto | **24** | preserva; grava `.kit-new` |
| Só placeholders substituídos | 3 | preserva; grava `.kit-new` |
| Idêntico a uma versão do kit | 5 | substitui normalmente |

Método: hash do `AGENTS.md` de cada alvo contra as 22 versões conhecidas do arquivo no
histórico deste repo (7 tags + 40 commits que o tocaram); depois a mesma comparação com
os placeholders revertidos, para separar customização de instalação de regra de projeto.

**Os 24 são a issue medida.** Os maiores:

| Linhas | vs `v1.1.1` | Projeto |
|---|---|---|
| 958 | +816 / −260 | `ZeeCred/jk-structure-web-canonical`, `ZeeCred2/jk-structure` |
| 607 | +482 / −277 | `ZeeCred/jk-structure` |
| 602 | +464 / −264 | `Lumina/lumina` (×3), `ZeeCred/jk-backoffice` |
| 544 | +406 / −264 | `inovacaoSistemasInstitucional` |

O `jk-structure` acrescentou guard de conteúdo de issue/PR do GitHub, guard de formatação
Jira, regra de monorepo, convenção de branch, gates de cobertura — centenas de linhas de
contrato de projeto que o `--upgrade` de ontem teria apagado.

**Consequência a decidir (não implementada):** os 3 alvos "só placeholders" passam a exigir
merge manual a cada upgrade, para sempre, por uma customização que o kit **espera** que
aconteça (`[OPERATOR_NAME]`/`[SMTP_ACCOUNT]` preenchidos após o install). Merge, adota o
`.kit-new`, substitui os placeholders de novo, diverge de novo. Duas saídas possíveis:
normalizar placeholders antes do hash no julgamento de deriva, ou o instalador passar a
substituir os placeholders ele mesmo (a partir de um arquivo de identidade) e gravar o
hash pós-substituição. Fica para o operador escolher — não dá para inventar por conta.

---

## Parte 3 (2026-07-24) — a decisão que faltava, e o resto da separação

O operador escolheu a **segunda** saída acima — o instalador substitui os placeholders
ele mesmo, a partir de um arquivo de identidade, e grava o hash pós-substituição — e
ampliou o escopo: separar, em cada arquivo que o kit controla, o conteúdo do kit do que
o projeto colou lá dentro; fazer os arquivos do kit se declararem read-only e apontarem
onde o projeto deve escrever; e isolar o conteúdo particular **antes** de rodar o
upgrade.

Antes de implementar, uma correção de pressuposto que vale registrar: a *perda* de
placeholder já estava evitada pela Parte 1 — só o `AGENTS.md` carrega slots reais e ele
é protegido. O problema real não era perder o valor, era o **re-merge manual eterno** e
a **poluição contínua** dos arquivos do kit.

### Sintaxe: `[TOKEN]` → `{{TOKEN}}`

Eu ia construir uma allowlist de nomes de token para distinguir `[OPERATOR_NAME]` de
`[MANDATORY]`/`[PROHIBITED]`/`[DEFAULT]`, que são vocabulário de conteúdo com a mesma
forma. O operador propôs trocar o delimitador. Verificado que `{{` e `${{` não ocorriam
em lugar nenhum do kit, a ambiguidade evaporou: `{{…}}` é sempre slot, `[...]` é sempre
conteúdo, e a detecção vira sintática, sem lista para manter.

**Armadilha encontrada no teste do cenário 1:** a própria prosa do Start Gate escrevia
`{{TOKEN}}` literal para explicar a convenção. Isso (a) seria substituído junto com os
slots de verdade — colocando o nome real do operador exatamente no parágrafo que manda
mantê-lo fora dos arquivos, o oposto do objetivo LGPD — e (b) faria o grep do gate
acusar o arquivo para sempre. A documentação agora grafa a convenção como `{{…}}`
(reticências Unicode, não casa com `[A-Z]`), e o `run-checks.sh` tem uma checagem que
proíbe `{{TOKEN}}`/`{{PLACEHOLDER}}`/`{{NAME}}`/`{{VALUE}}` literais em `AGENTS.md` e
`.docs/`.

### Mecanismo: `.gk/identity.json` + render-antes-de-comparar

`values` (literais) e `refs` (caminhos para arquivos de credencial — nunca segredo
inline; o arquivo é rastreado). `apply_identity()` renderiza a fonte que está entrando
para um diretório temporário e aponta `SRC_ROOT` para ele; daí todo o resto do script
funciona sem alteração. Só tokens **declarados** são substituídos, então `${{ … }}` do
GitHub Actions passa intacto (verificado ponta a ponta). Sem `python3` ou sem
`identity.json`, nada é substituído e o Start Gate trava — degradação graciosa, igual ao
resto do script. `identity.json` está fora de `KIT_OWNED_PATHS`, e o `run-checks.sh`
afirma essa ausência.

Efeito: um slot preenchido deixa de ser deriva. O arquivo em disco e a versão nova do
kit ficam byte a byte iguais, o manifesto grava o hash renderizado, e o `.kit-new` do
`AGENTS.md` passa a mostrar **só** a diferença de conteúdo genuína — sem o ruído
`{{OPERATOR_NAME}}`-vs-nome-real que hoje domina o diff.

### Uma regra que faltava no `copy_file_replace`

Descoberta ao testar o cenário 7: depois do `--migrate` o arquivo **é** a versão
renderizada do kit, mas o manifesto ainda guarda o hash pré-migração — e julgar só pelo
manifesto marcava como deriva um arquivo byte a byte idêntico ao que estava prestes a
ser escrito, pedindo merge do arquivo contra ele mesmo. Agora, `dst == src` é curto-
circuito: não há o que preservar nem o que reportar, manifesto ou não. A mesma regra
entrou no `check_drift`, senão relatório e upgrade voltariam a discordar — exatamente o
segundo bug desta issue.

### `--migrate`: extrai o inequívoco, reporta o resto

Modo novo, gateado (TTY + confirmação digitada, sem flag para pular; backup em
`.gk/pre-migrate/`). Lê os valores de volta do alvo usando os slots do próprio template
como sonda — só registra quando a linha em volta ainda casa exatamente, então uma linha
editada vira "ambíguo, decida à mão" em vez de um valor inventado. Grafia legada
`[TOKEN]` é reconhecida como **não preenchida**, não confundida com valor, e reescrita
para `{{…}}`. Depois, diff do alvo contra o template renderizado: só-inserção move para
`docs/project-rules.md` sob cabeçalho datado; linha do kit reescrita ou removida é
reportada e **não** tocada. Scripts shell são reportados, nunca migrados por conteúdo —
"linha inserida" num script é código, não regra de projeto. O relatório redige os
valores (tamanho e primeira letra), porque ele pode acabar colado numa issue.

### Contrato read-only

Banner nas primeiras linhas de todo `KIT_ROOT_FILES` ("kit-owned, não edite, suas regras
vão em `docs/project-rules.md`, valores em `.gk/identity.json`"), mais uma seção no topo
do `AGENTS.md` com a tabela de "isto vai em tal arquivo". O `run-checks.sh` afirma que o
banner está presente em todos os 13 — um banner é trivialmente perdido numa edição
qualquer, e ele é a única linha que diz ao próximo agente onde escrever.

### Verificação

Os 8 cenários do plano foram executados de verdade em alvos sintéticos (não só
`bash -n`): install sem/com identity, upgrade com seção acrescentada, upgrade com só
slot preenchido, `--migrate` completo, `--migrate` sem TTY (recusa, exit 3), `--upgrade`
depois do `--migrate` (limpo, sem `.kit-new`), e `${{ }}`/`{{UNDECLARED}}` intactos ponta
a ponta. `run-checks.sh` verde com as checagens novas; `shellcheck -S error` limpo.

**Não aplicado aos 33 alvos reais** — isso é trabalho cross-repo e continua gateado por
aprovação do operador.
