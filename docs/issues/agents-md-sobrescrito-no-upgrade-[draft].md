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
