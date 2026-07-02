# Nomes de branch devem ser ASCII simples, sem símbolos, aspas ou espaços

- work_id: WK-20260702-branch-names-ascii
- date: 2026-07-02
- solicitado por: [OPERATOR_NAME]

## Motivação

Um agente criou (via escape de shell malfeito) um branch git com o nome
literal `"development"` — **com as aspas fazendo parte do nome do ref**
(`refs/heads/"development"`). O defeito passou despercebido porque:

- o prompt do shell (`.bashrc`, função `git_branch_name`) apenas ecoa o que o
  git devolve, então exibia `"development"` sem sinalizar erro;
- ferramentas que interpolam o nome do branch (geração de
  `docker-compose.override.yml`, comandos `gh`/`git`, status lines) quebram ou
  se comportam de forma imprevisível com caracteres especiais no nome.

A recuperação exigiu deletar o branch defeituoso e refazer o checkout a partir
do `origin` limpo. O nome nunca deveria ter sido aceito.

Causa-raiz: nenhum contrato de agente proíbe explicitamente caracteres perigosos
em nomes de branch, e títulos de issue eram passados quase crus para
`git checkout -b`.

## Mudança necessária

Adicionar ao `AGENTS.md` deste kit (seção de convenções de branch), uma
subseção de caracteres permitidos:

```
#### Allowed characters (MANDATORY)

Branch names must use only plain ASCII in the class [a-z0-9/_-]
(uppercase permitted solely inside an issue/Jira key, e.g. UBR-1027).

[PROHIBITED] in a branch name — they silently break tooling, prompts, and refs:
- quotes of any kind (" ' `), even from a shell-escaping mistake;
- whitespace (spaces, tabs);
- shell/glob metacharacters: $ & * ? ! ; | < > ( ) { } [ ] \ ^ ~ : @ = + , #
  and a leading '-';
- accented or non-ASCII letters and any Unicode symbol, homoglyph, or
  invisible character;
- '..', a trailing '/', a trailing '.lock', or a trailing '.' (invalid git refs).

[MANDATORY] When deriving a branch slug from an issue title: transliterate to
ASCII, replace every disallowed character with '-', collapse repeats, strip
leading/trailing '-'. Verify the final name matches ^[a-zA-Z0-9/_-]+$ before
'git checkout -b'. Never pass an issue title verbatim to git branch/checkout -b.
```

## Escopo

- Somente `AGENTS.md` do kit (contrato de agente). Sem código de runtime.
- Se este kit expõe um helper que cria branches (scripts/automação de issue),
  aplicar a mesma sanitização/validação nele, no mesmo PR.

## Comportamento esperado

- Antes: `git checkout -b '"development"'` é aceito silenciosamente.
- Depois: agente sanitiza para `development` e valida contra
  `^[a-zA-Z0-9/_-]+$` antes de criar; nome inválido → para e reporta.

## Plano de teste

- Título de issue com acentos/espaços/símbolos → slug resultante casa
  `^[a-zA-Z0-9/_-]+$`.
- Tentativa de criar branch com aspas/espaço → rejeitada antes do `git`.

## Impacto / Risco

- Mudança de documentação/contrato (mais validação opcional em helper).
- Baixo risco. Previne recorrência de refs git corrompidos.

## Definition of Done

- Subseção presente no `AGENTS.md` do kit.
- Helpers de criação de branch (se existirem) validam o nome.
- Status do arquivo movido para `[review]` após aplicar.
