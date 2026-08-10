# RESUME — §Sending Email canônica e universal (gh-5 / GK gh-7)

- work_id: WK-20260810-sending-email-canonico
- date: 2026-08-10
- status: `[review]` — lado AI-Agents entregue e gateado. Operador decidiu A e D em
  2026-08-10 (avisar, nunca reescrever) e mandou seguir para o GovernanceKit fechando
  a #7 e os achados do concílio juntos. Lado GovernanceKit não iniciado.

## Next Step (DO THIS FIRST)

**Etapa GovernanceKit, em `GovernanceKit-main-merge` (branch `development`):** seção
canônica no `AGENTS.md` dele, `SMTP_ACCOUNT` fora do `install_agents.py` e dos testes,
o seeding de `docs/required-reading.md` (que hoje refaz o defeito que o lado shell
corrigiu), o `templates/` que falta nos alvos instalados pelo Python, o parser de
tabela vazia do `doctor` e a distinção citação-vs-contra-exemplo do
`_check_local_sources_indexed`. Concílio de novo no commit de entrega.

## O que a issue pedia

`EDortta/AI-Agents#5`, espelhada em `EDortta/AI-GovernanceKit#7`. Quatro itens:

1. Substituir a seção nos `AGENTS.md` dos dois kits, mesmo texto, uma origem só.
2. Remover o placeholder `SMTP_ACCOUNT` do instalador.
3. Reconciliar a divergência de sintaxe de placeholder entre os dois kits.
4. Verificar se o `doctor` audita a seção e ajustar se necessário.

Origem: em 2026-08-07 um agente resolveu "manda para mim" pelo `userEmail` do harness —
a conta logada, não o operador — e o material foi para a pessoa errada. A lista correta
existia, em dois lugares, e nenhum documento de leitura obrigatória apontava para ela.

## Entregue (AI-Agents, branch `development`, nada empurrado)

| commit | o quê |
|---|---|
| `26fcf86` | seção canônica sem transporte + índice deste repo declara o transporte daqui |
| `07b6023` | slot `SMTP_ACCOUNT` aposentado em 15 arquivos; dois testes viram asserção da aposentadoria |
| `fb503aa` | achados da rodada 1 |
| `0c0b6be` | achados da rodada 2 do sweep skeptic |

Itens 1 e 2 fechados **deste lado**. Item 3 e 4 dependem do GovernanceKit.

## Council — rodada 1

Quatro membros: sweep skeptic, claim auditor, second caller e **the migrator** (lente
opcional do §3, selecionada pela pergunta de §5 sobre modelo de deploy — um projeto pode
atualizar o kit sem atualizar o GovernanceKit, em qualquer ordem).

**Levantados: 12. Sobreviveram ao §2: 5 neste repositório. Viraram teste: 5. Perguntas
deixadas em aberto: 14.**

| # | achado | fechamento |
|---|---|---|
| 1 | `AGENTS.md:350` ainda prescrevia `~/.config/email/` como `[MANDATORY]`, e o arquivo novo defere ao `/AGENTS.md` em conflito — a regra aposentada vencia a substituta em todo projeto instalado | teste §8b(a), verificado vermelho |
| 2 | o instalador semeava o índice **deste** repositório em alvo novo, exportando o transporte daqui como declaração de outro projeto | template neutro + testes §8b(b), §10c-bis |
| 3 | o passo 1 do contrato apontava para uma seção que o kit nunca provisionou e nenhum `--upgrade` podia criar | `ensure_local_sources_section` + testes |
| 4 | a nota pt-BR do advanced-usage ainda dizia "conta SMTP" (só o pt-BR) | corrigido; coberto pelo grep de aposentadoria |
| 5 | a proveniência citava os caminhos completos do transporte, e o `_check_local_sources_indexed` do doctor mandava todo projeto do parque indexar o transporte de outro operador | nomes nus sob o diretório; verificado contra o detector real |

Por que a varredura falhou no #1: o grep procurava "Sending Email" e o stub de roteamento
se chama "Enviar e-mail". É a forma exata da lente *sweep skeptic*.

## Council — rodada 2

Dois membros caíram em erro de API na primeira convocação e foram reconvocados; a
rodada só fechou com os três relatos.

**Levantados: 13. Sobreviveram ao §2: 13. Fechados nesta sessão: 3. Abertos: 10.**

Fechados (commit `0c0b6be`):

| # | achado | fechamento |
|---|---|---|
| 6 | o gate novo tinha o mesmo defeito de escopo que existia para pegar: 8b(a) varria só `AGENTS.md` e `.docs/*`; a regra reintroduzida no `CLAUDE.md` deixava tudo verde | pathspec cobre os seis espelhos, verificado vermelho |
| 7 | `ensure_local_sources_section` casava uma grafia exata enquanto o `doctor` aceita uma família e recomenda outra — num projeto que seguiu a dica do doctor, o upgrade acrescentava uma segunda seção, vazia, contradizendo a lista de CC real | casa a família; teste com fixture de grafia variante |
| 8 | o índice semeado saía com o bloco do kit acima da própria lede, porque o template não tinha os marcadores | marcadores no template; teste de ordem |

## Aberto — decisão do operador (council.md §4)

**A. RESOLVIDO — decisão do operador em 2026-08-10: avisar, nunca reescrever.**
O coorte de 3 dias não era alcançado, e é o que existe no parque. Um projeto
instalado depois de `889eabe` já tem a seção `Fontes locais`, com a linha antiga
`| ~/.config/email/send.py | opcional | transporte da §Sending Email |`. A guarda do
back-fill vê a seção e volta; a linha fica. Um agente ali lê a tabela, encontra um
transporte declarado para o projeto, e envia por ele — a corrupção exata da gh-5. O
`doctor` certifica: `[PASS] 4 local source(s) indexed and present`.
**Decidido (i):** o `--upgrade` nomeia a linha, cita o número dela e diz o que fazer;
não toca em `docs/`. A regra de propriedade fica de pé — foi ela que impediu o
`--upgrade` de invadir `docs/`, e a lição de 07/08 já tinha escolhido este mesmo
veículo. O casamento é com a redação que o próprio kit escreveu, então não pode
disparar sobre nada que o projeto tenha escrito.

**D. RESOLVIDO pela mesma decisão.** O coorte de `AGENTS.md` com deriva recebe o mesmo
tratamento: o `report_upgrade_effects` avisa que o arquivo mantido ainda prescreve o
transporte retirado e que ele vence por precedência até alguém adotar o `.kit-new`.
Dois testes novos, ambos verificados vermelhos sem a correção.

**B. Regressão no `doctor`, no caminho feliz da própria entrega.** O scaffold semeado
tem cabeçalho de tabela e nenhuma linha de dado, e o `_parse_local_sources` classifica
isso como "tem tabela mas nenhuma linha legível" — todo projeto novo nasce com um
`[HINT]` que acusa de malformada uma tabela escrita pelo próprio kit. Segundo hint na
mesma instalação: o template neutro largou a linha `~/.config/USER.md`, que o
`AGENTS.md` cita em três lugares. **Antes da entrega esses alvos estavam verdes.** A
correção mora nos dois lados (scaffold sem tabela vazia aqui; parser lá) e faz parte da
etapa GovernanceKit.

**C. O instalador Python refaz tudo.** `_PROJECT_SEED_PATHS` ainda semeia
`docs/required-reading.md` a partir do índice **do kit**; o template novo lhe é
desconhecido; não há back-fill. Pior: ele instala `scripts/install-agents-kit.sh` nos
alvos **sem** `templates/`, então o self-upgrade documentado sai por `return 0` na
primeira linha do `sync_reading_index` e o alvo fica **sem índice nenhum**, enquanto o
instalador imprime `preserved project-local: docs/required-reading.md`. Ordem
`python-fresh → shell-upgrade` deixa o alvo contaminado para sempre. **Isso torna a
etapa GovernanceKit pré-requisito, não follow-up.**

**D-restante (doctor).** Falta o outro meio do coorte com deriva: naquele estado a
única dica do `doctor` recomenda **indexar** o caminho retirado — isto é, terminar a
corrupção. Isso é da etapa GovernanceKit.

## Aceitações de risco escritas (delivery-loop §9)

- **Lag de release.** O `REF` do instalador shell é `v1.1.8` e o `DEFAULT_REF` do
  Python é `v1.1.7`; nenhuma tag carrega esta correção ainda. Até a tag, o
  `curl | bash` documentado não entrega nada disto. Aceito: é lag ordinário de trabalho
  não lançado, e a issue não fecha antes da tag.
- **Duas declarações da mesma regra.** O stub do `AGENTS.md` e o
  `.docs/workflows/sending-email.md` hoje dizem a mesma coisa, linha a linha. Nada
  impede que divirjam. Aceito por ora: o §8b(a) impede a volta do defeito conhecido
  (nomear transporte), não a divergência de fraseado.

## Contagem das asserções — correção do registro

Os commits `fb503aa` e `0c0b6be` erram a contagem. O auditado é: **nove asserções
novas** (sete em `fb503aa`, duas em `0c0b6be`). Contra a árvore pré-correção
(`07b6023`) **seis** ficam vermelhas, não "todas": a asserção
`the §Sending Email contract names no transport above its Provenance` guarda o trabalho
original e só fica vermelha contra `26fcf86^`. Nenhuma das nove é luz verde vazia; a
única fraca é `the section the contract points at is seeded and back-filled on upgrade`,
que é presença de string e fica verde se só a chamada for apagada — a asserção
comportamental do §10c-bis cobre o mesmo defeito.
