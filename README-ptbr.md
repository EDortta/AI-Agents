# AI-Agents Universal Kit

## Orçamento determinístico de contexto

O kit distribui `.docs/context-manifest.yaml`, validado por JSON Schema, para que
runtimes compatíveis carreguem apenas os contratos exigidos pela tarefa e pelos
riscos declarados. O AI-GovernanceKit implementa `governancekit context inspect` e
`governancekit context build`; consulte `.docs/context-optimization.md`.

<!-- AI-Agents kit-owned file. Do not edit: `governancekit install-agents --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .gk/operator.json (untracked; written by `governancekit install-agents`) -->

![Logo AI-Agents](./.docs/icons/logo.png)

English version: [README.md](./README.md)  
Versión en español: [README-es.md](./README-es.md)

Se você quer entender como um agente de IA pode ajudar na sua jornada de desenvolvimento, leia [ai-agents-in-vscodium-chat-ptbr.md](./.docs/articles/ai-agents-in-vscodium-chat-ptbr.md).

## Propósito

Este repositório é um kit reutilizável para governança de agentes em projetos de software.
Ele fornece:
- contrato global: `AGENTS.md`
- contratos por papel: `.docs/agents/`
- fluxo/templates de issues: `docs/issues/`
- dois arquivos obrigatórios de contexto para cada projeto alvo:
  - `docs/software-overview.md`
  - `docs/limits.md`

## Pensado Para Quais Agentes/Ferramentas de IA

Este kit foi pensado para ser portátil entre agentes e assistentes de código conhecidos, principalmente:
- Agentes estilo Codex (usando `AGENTS.md`)
- Agentes baseados em Claude (usando `CLAUDE.md`)
- GitHub Copilot (usando `.github/copilot-instructions.md`)
- Cursor (usando `.cursorrules`)
- Windsurf/Cascade (usando `.windsurfrules`)
- Assistentes baseados em Gemini (usando `GEMINI.md`)
- Amazon Q Developer (usando `.amazonq/rules/ai-agents.md`)

Regra central:
- `AGENTS.md` é o contrato global.
- Os arquivos específicos por ferramenta adaptam esse mesmo contrato para cada ecossistema.
- Todos os adaptadores carregam a mesma base de cinco documentos; o gate de release
  verifica isso e upgrades restauram adaptadores do kit para impedir enfraquecimento silencioso.

## Como usar em outro projeto

Para todos os parâmetros do instalador, arquivos de identidade, códigos de saída,
migrações e exemplos de CI, veja
[Detalhes avançados de uso](https://edortta.github.io/AI-Agents/advanced-usage-ptbr.html).

O kit é instalado e atualizado pelo **CLI do GovernanceKit**. O instalador shell
legado que este repositório distribuía em `scripts/` foi aposentado: dois
instaladores escrevendo os mesmos arquivos, sem fonte de verdade compartilhada,
eram a causa raiz de uma família de defeitos de deriva e perda de dados. A
aposentadoria chega com o próximo release dos dois kits — um GovernanceKit que a
carregue também remove cópias antigas do script dos projetos governados no
`--upgrade`; até o seu GovernanceKit instalado carregá-la, um install ainda
entrega o script da release que ele fixa.

```bash
pip install git+https://github.com/EDortta/AI-GovernanceKit.git

governancekit --root /caminho/do/seu-projeto install-agents
```

O CLI baixa este repositório na tag de release fixada no próprio CLI e verifica o
tarball contra um SHA-256 conhecido antes de escrever qualquer coisa.

Atualize uma instalação existente sem sobrescrever contexto/estado local do projeto:

```bash
governancekit --root /caminho/do/seu-projeto install-agents --upgrade
```

Se você acabou de clonar um projeto que já tem AI-Agents instalado, rode esse
`--upgrade` antes da primeira tarefa no clone. Ele atualiza os arquivos geridos pelo
kit e pergunta pelos valores locais ausentes ou novos, em vez de deixar você herdar
a identidade de outro programador ou um estado antigo dos slots.

O modo upgrade atualiza arquivos pertencentes ao kit e preserva:
- `docs/software-overview.md`
- `docs/limits.md`
- `docs/project-rules.md`
- `handoff.md`
- `docs/napkin-lessons.md`
- pastas de issues do projeto em `docs/issues/`
- `docs/undercover-issues/`
- `.credentials/`

### Onde ficam as regras específicas do projeto

O `AGENTS.md` é o primeiro arquivo que todo agente lê, o que faz dele o primeiro
lugar onde as pessoas escrevem regra de projeto — e ele pertence ao kit, então o
`--upgrade` o substitui. Escreva regra de projeto em **`docs/project-rules.md`**.
O instalador o cria uma vez e nunca mais o toca; ele está deliberadamente **fora**
do manifesto do kit, e é essa ausência que garante isso.

Ainda assim o `AGENTS.md` é **protegido**: quando seu conteúdo diverge do que o kit
instalou, o `--upgrade` mantém a sua versão, grava a nova em `AGENTS.md.kit-new` ao
lado e avisa. Nada é sobrescrito em silêncio. Sem manifesto (instalação anterior ao
`.gk/`, ou sem `python3`) o instalador não consegue provar que o arquivo está
intocado, então falha fechado e preserva.

Todo arquivo de raiz substituído também é copiado para `.gk/pre-upgrade/` antes.

Os arquivos do kit também se declaram: um banner curto nas primeiras linhas diz que
são kit-owned e aponta para `docs/project-rules.md`. O gate de release verifica que o
banner está lá, para que uma edição qualquer não apague justamente a única linha que
diz ao próximo agente onde escrever.

### Valores do operador: slots `{{…}}` e `.gk/operator.json`

Arquivos do kit nunca contêm o nome ou a conta real do operador — eles trazem slots
`{{…}}` (chaves duplas em volta de um nome em MAIÚSCULAS), porque dado pessoal não
pode ficar em fonte rastreada. As respostas vivem em **`.gk/operator.json`**, escrito
por `governancekit install-agents` e mantido fora do git, então cada programador do
projeto estabelece a própria identidade em vez de herdar o nome de um colega pelo
repositório. É esse o ponto — nome e conta do operador são justamente o dado pessoal
que o esquema de slots existe para manter fora do repo, e compartilhar um arquivo só
mudaria o vazamento do `AGENTS.md` para um JSON. (Um `.credentials/identity.json`
legado, do instalador shell aposentado, é lido pelo `governancekit configure` como
fonte legada do nome do operador; o `install-agents` em si não o lê.)

Em todo install e `--upgrade`, o instalador reaplica os valores guardados, então um
slot preenchido não é deriva: o arquivo em disco e a versão nova do kit batem, e o
upgrade não queima o valor nem pede merge. Num terminal interativo ele pergunta pelo
valor ausente de `OPERATOR_NAME`; numa execução não interativa, um valor ausente é
**reportado como aviso e o slot fica sem preencher** — leia a saída da execução (e
rode `governancekit doctor`) em vez de confiar no código de saída. `.credentials/` é
um diretório que nenhum caminho de upgrade substitui.

Só tokens *declarados* são substituídos, então uma expressão `${{ … }}` do GitHub
Actions ou um template mustache de exemplo passa intacto. Chaves em vez de colchetes
porque `[MANDATORY]`, `[PROHIBITED]` e `[DEFAULT]` são vocabulário de conteúdo nestes
documentos: token entre colchetes não se distingue da prosa sem uma allowlist mantida
à mão; `{{…}}` sempre se distingue.

### Migrar um alvo existente ou legado

Um projeto instalado antes disso tudo costuma ter os dois problemas juntos: regras de
projeto digitadas dentro do `AGENTS.md` e valores do operador digitados por cima dos
placeholders. O caminho de upgrade trata os dois sem adivinhar: um `AGENTS.md` editado
à mão é **preservado** e a versão nova fica ao lado como `AGENTS.md.kit-new` para merge
manual, e `--migrate-content` extrai contratos legados do projeto para
`docs/project-rules/`:

```bash
governancekit --root /caminho/do/seu-projeto install-agents --upgrade --migrate-content
```

Importante:
- o `governancekit doctor` é o readiness gate: ele reprova até que:
  - `docs/software-overview.md` tenha `project_context_ready: yes`
  - `docs/limits.md` tenha `limits_ready: yes`

1. Copie (ou use symlink) destes artefatos no projeto alvo:
- `AGENTS.md`
- `.docs/agents/`
- `docs/issues/`
- `docs/software-overview.md`
- `docs/limits.md`

2. Adapte apenas o que é específico do projeto:
- Preencha `docs/software-overview.md` com contexto do produto, arquitetura e objetivos.
- Preencha `docs/limits.md` com limites rígidos (in/out-of-scope, ações proibidas, gates de aprovação).
- Esses dois arquivos são obrigatórios e precisam ser editados pelo programador para que o agents-kit reconheça corretamente o que fazer no projeto.

3. Mantenha o núcleo genérico:
- Preserve estrutura e intenção de `AGENTS.md` e dos arquivos centrais em `.docs/agents/`.
- Adicione extensões específicas somente quando necessário.

## Fluxo do Programador (Obrigatório)

Antes de codar no projeto alvo:
1. Ler `docs/software-overview.md` para entender o que está sendo desenvolvido.
2. Ler `docs/limits.md` para entender o que é permitido/proibido.
3. Planejar e implementar somente dentro desses limites.
4. Se uma solicitação conflitar com `docs/limits.md`, parar e pedir aprovação humana explícita.

Durante trabalho com issues:
1. Organizar trabalho em pastas de épico em `docs/issues/`.
2. Usar templates em `.docs/issues/templates/`.
3. Incluir checagem de privacidade quando houver dados pessoais:
- `.docs/issues/templates/privacy-checklist.template.md`

Fechamento de sessão em cada etapa:
1. Atualizar `handoff.md` com status, próximos passos, bloqueios, arquivos alterados e checks.
2. Registrar lições aprendidas curtas em `docs/napkin-lessons.md`.
3. Seguir `.docs/workflows/session-close.md`.

Convenção de identificador de trabalho:
- Usar `work_id` no formato: `WK-YYYYMMDD-<short-slug>`.
- Manter o mesmo `work_id` nos docs de planejamento, handoff e mensagens de commit relacionadas.

## Setup mínimo recomendado no projeto

Ao adotar este kit, atualize primeiro:
- `docs/software-overview.md`: descrição do produto, arquitetura, módulos-chave, dependências.
- `docs/limits.md`: limites de escopo, limites de segurança, regras de branch/aprovação, operações proibidas.

Depois execute uma issue piloto usando `.docs/issues/templates/task.template.md` para validar o processo.

## Toque Pessoal via USER.md

Os agentes podem adaptar o estilo de comunicação ao seu perfil quando um arquivo `USER.md` estiver presente em `~/.config/USER.md`.

Este arquivo é:
- **Global** — fica no diretório de configuração do seu usuário, não em nenhum repositório de projeto
- **Opcional** — o kit funciona sem ele; o comportamento de governança não muda
- **Pessoal** — gerado a partir de uma avaliação de perfil (DISC, Jung, Spranger, etc.) ou escrito manualmente

Quando presente, os agentes o leem no início da sessão para adaptar tom, profundidade, enquadramento de decisões e linguagem ao usuário.

Convenção:
- Caminho: `~/.config/USER.md`
- Formato: Markdown, seções livres descrevendo preferências de comunicação, tipo de perfil e armadilhas a evitar
- Nunca deve ser commitado em nenhum repositório de projeto

Ferramentas como o [ConhecerTe](https://conhecerte.com.br) podem gerar um `USER.md` pronto a partir de uma avaliação de perfil estruturada.

---

## Complementar: AI-GovernanceKit

O [AI-GovernanceKit](https://github.com/EDortta/AI-GovernanceKit) é a camada de execução e validação para este policy pack.

- **AI-Agents** = policy pack — o "o quê e o porquê" da governança (este repositório)
- **AI-GovernanceKit** = CLI de runtime — o "como" da execução (doctor, automação de sessão, hooks de CI)

São projetados para trabalhar juntos, mas sem dependência formal:
- Instale o AI-Agents copiando os arquivos no projeto alvo
- Instale o AI-GovernanceKit como pacote Python (`pip install git+https://github.com/EDortta/AI-GovernanceKit.git`)
- O comando `doctor` do GovernanceKit valida a estrutura de arquivos do AI-Agents automaticamente

---

## Setup de Credenciais

Use:
- `.credentials/README-ptbr.md`

Modelos disponíveis:
- `.credentials/programmer.token.example`
- `.credentials/reviewer.token.example`
- `.credentials/jira.json.example`

## Estrutura

- `AGENTS.md`: contrato universal de execução
- `.docs/agents/`: contratos por papel (programmer, reviewer, issue automation, security, privacy)
- `docs/issues/`: estrutura local de issues e templates
- `handoff.md`: log de handoff para retomada entre sessões
- `docs/napkin-lessons.md`: log conciso de lições aprendidas
- `.docs/workflows/session-close.md`: checklist de fechamento de etapa/sessão
- `.docs/workflows/dev-workflow-integration.md`: integração opcional de automação no fim de etapa
- `.docs/workflows/unattended-run.md`: regras que uma rodada sem supervisão precisa satisfazer — quando ela para, o que nunca pode fazer e o que reporta de manhã

## Artigos

- EN: `.docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `.docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `.docs/articles/ai-agents-in-vscodium-chat-es.md`
- Perspectiva do autor sobre a jornada de programação: [I used to turn off the internet for my developers](https://edortta71.medium.com/i-used-to-turn-off-the-internet-for-my-developers-f0d1747ee78f)
