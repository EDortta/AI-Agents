# IA-Agents Universal Kit

![Logo IA-Agents](./docs/icons/logo.png)

English version: [README.md](./README.md)  
Versão em português: [README-ptbr.md](./README-ptbr.md)

Si quieres entender cómo un agente de IA puede ayudar en tu camino de desarrollo, lee [ai-agents-in-vscodium-chat-es.md](./docs/articles/ai-agents-in-vscodium-chat-es.md).

## Propósito

Este repositorio es un kit reutilizable para gobernanza de agentes en proyectos de software.
Incluye:
- contrato global: `AGENTS.md`
- contratos por rol: `docs/agents/`
- flujo/plantillas de issues: `docs/issues/`
- dos archivos obligatorios de contexto para cada proyecto destino:
  - `docs/software-overview.md`
  - `docs/limits.md`

## Pensado Para Qué Agentes/Herramientas de IA

Este kit fue pensado para ser portable entre agentes y asistentes de código conocidos, especialmente:
- Agentes estilo Codex (usando `AGENTS.md`)
- Agentes basados en Claude (usando `CLAUDE.md`)
- GitHub Copilot (usando `.github/copilot-instructions.md`)
- Cursor (usando `.cursorrules`)
- Windsurf/Cascade (usando `.windsurfrules`)
- Asistentes basados en Gemini (usando `GEMINI.md`)

Regla central:
- `AGENTS.md` es el contrato global.
- Los archivos específicos por herramienta adaptan ese mismo contrato a cada ecosistema.

## Cómo usar en otro proyecto

1. Copia (o usa symlink) estos artefactos en el proyecto destino:
- `AGENTS.md`
- `docs/agents/`
- `docs/issues/`
- `docs/software-overview.md`
- `docs/limits.md`

2. Adapta solo lo específico del proyecto:
- Completa `docs/software-overview.md` con contexto del producto, arquitectura y objetivos.
- Completa `docs/limits.md` con límites estrictos (in/out-of-scope, acciones prohibidas, gates de aprobación).
- Estos dos archivos son obligatorios y deben ser editados por el programador para que el agents-kit reconozca correctamente qué hacer en el proyecto.

3. Mantén el núcleo genérico:
- Conserva estructura e intención de `AGENTS.md` y los archivos centrales de `docs/agents/`.
- Agrega extensiones específicas solo cuando sea necesario.

## Flujo del Programador (Obligatorio)

Antes de programar en el proyecto destino:
1. Leer `docs/software-overview.md` para entender qué se está desarrollando.
2. Leer `docs/limits.md` para entender qué está permitido/prohibido.
3. Planificar e implementar solo dentro de esos límites.
4. Si una solicitud entra en conflicto con `docs/limits.md`, detenerse y pedir aprobación humana explícita.

Durante el trabajo con issues:
1. Organizar el trabajo en carpetas de épica dentro de `docs/issues/`.
2. Usar las plantillas de `docs/issues/templates/`.
3. Incluir checklist de privacidad cuando haya datos personales:
- `docs/issues/templates/privacy-checklist.template.md`

## Setup mínimo recomendado del proyecto

Al adoptar este kit, actualiza primero:
- `docs/software-overview.md`: descripción del producto, arquitectura, módulos clave, dependencias.
- `docs/limits.md`: límites de alcance, límites de seguridad, reglas de branch/aprobación, operaciones prohibidas.

Luego ejecuta una issue piloto usando `docs/issues/templates/task.template.md` para validar el proceso.

## Estructura

- `AGENTS.md`: contrato universal de ejecución
- `docs/agents/`: contratos por rol (programmer, reviewer, issue automation, security, privacy)
- `docs/issues/`: estructura local de issues y plantillas

## Artículos

- EN: `docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `docs/articles/ai-agents-in-vscodium-chat-es.md`
