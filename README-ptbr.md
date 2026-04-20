# IA-Agents Universal Kit

English version: [README.md](./README.md)  
Versión en español: [README-es.md](./README-es.md)

## Propósito

Este repositório é um kit reutilizável para governança de agentes em projetos de software.
Ele fornece:
- contrato global: `AGENTS.md`
- contratos por papel: `docs/agents/`
- fluxo/templates de issues: `docs/issues/`
- dois arquivos obrigatórios de contexto para cada projeto alvo:
  - `docs/software-overview.md`
  - `docs/limits.md`

## Como usar em outro projeto

1. Copie (ou use symlink) destes artefatos no projeto alvo:
- `AGENTS.md`
- `docs/agents/`
- `docs/issues/`
- `docs/software-overview.md`
- `docs/limits.md`

2. Adapte apenas o que é específico do projeto:
- Preencha `docs/software-overview.md` com contexto do produto, arquitetura e objetivos.
- Preencha `docs/limits.md` com limites rígidos (in/out-of-scope, ações proibidas, gates de aprovação).

3. Mantenha o núcleo genérico:
- Preserve estrutura e intenção de `AGENTS.md` e dos arquivos centrais em `docs/agents/`.
- Adicione extensões específicas somente quando necessário.

## Fluxo do Programador (Obrigatório)

Antes de codar no projeto alvo:
1. Ler `docs/software-overview.md` para entender o que está sendo desenvolvido.
2. Ler `docs/limits.md` para entender o que é permitido/proibido.
3. Planejar e implementar somente dentro desses limites.
4. Se uma solicitação conflitar com `docs/limits.md`, parar e pedir aprovação humana explícita.

Durante trabalho com issues:
1. Organizar trabalho em pastas de épico em `docs/issues/`.
2. Usar templates em `docs/issues/templates/`.
3. Incluir checagem de privacidade quando houver dados pessoais:
- `docs/issues/templates/privacy-checklist.template.md`

## Setup mínimo recomendado no projeto

Ao adotar este kit, atualize primeiro:
- `docs/software-overview.md`: descrição do produto, arquitetura, módulos-chave, dependências.
- `docs/limits.md`: limites de escopo, limites de segurança, regras de branch/aprovação, operações proibidas.

Depois execute uma issue piloto usando `docs/issues/templates/task.template.md` para validar o processo.

## Estrutura

- `AGENTS.md`: contrato universal de execução
- `docs/agents/`: contratos por papel (programmer, reviewer, issue automation, security, privacy)
- `docs/issues/`: estrutura local de issues e templates

## Artigos

- EN: `docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `docs/articles/ai-agents-in-vscodium-chat-es.md`
