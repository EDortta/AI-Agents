# Pasta de Credenciais

English version: [README.md](./README.md)  
Versión en español: [README-es.md](./README-es.md)

Esta pasta armazena credenciais locais usadas por agentes de IA e automações.

## Regras de Segurança

- Nunca comite credenciais reais.
- Mantenha esta pasta apenas no ambiente local de desenvolvimento.
- Use os arquivos `.example` como modelo.

## Arquivos

- `programmer.token`: token GitHub usado pelos fluxos do programmer-agent.
- `reviewer.token`: token GitHub usado pelos fluxos do reviewer-agent.
- `jira.json`: credenciais de API do Jira.

Modelos fornecidos:
- `programmer.token.example`
- `reviewer.token.example`
- `jira.json.example`

## Setup

1. Crie os arquivos reais a partir dos modelos:
- `cp programmer.token.example programmer.token`
- `cp reviewer.token.example reviewer.token`
- `cp jira.json.example jira.json`

2. Preencha cada arquivo com valores reais.
3. Garanta permissões restritas nos arquivos.

Exemplo:

```bash
chmod 600 programmer.token reviewer.token jira.json
```

## Usado por

- regras de credenciais do `AGENTS.md`
- etapas de automação para operações GitHub/Jira
