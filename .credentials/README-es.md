# Carpeta de Credenciales

English version: [README.md](./README.md)  
Versão em português: [README-ptbr.md](./README-ptbr.md)

Esta carpeta almacena credenciales locales usadas por agentes de IA y automatizaciones.

## Reglas de Seguridad

- Nunca hagas commit de credenciales reales.
- Mantén esta carpeta solo en entorno local de desarrollo.
- Usa los archivos `.example` como plantilla.

## Archivos

- `programmer.token`: token de GitHub usado por flujos del programmer-agent.
- `reviewer.token`: token de GitHub usado por flujos del reviewer-agent.
- `jira.json`: credenciales de API de Jira.

Plantillas incluidas:
- `programmer.token.example`
- `reviewer.token.example`
- `jira.json.example`

## Setup

1. Crea archivos reales desde las plantillas:
- `cp programmer.token.example programmer.token`
- `cp reviewer.token.example reviewer.token`
- `cp jira.json.example jira.json`

2. Completa cada archivo con valores reales.
3. Asegura permisos restringidos.

Ejemplo:

```bash
chmod 600 programmer.token reviewer.token jira.json
```

## Usado por

- reglas de credenciales en `AGENTS.md`
- pasos de automatización para operaciones GitHub/Jira
