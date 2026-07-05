# AI-Agents Universal Kit

![Logo AI-Agents](./.docs/icons/logo.png)

English version: [README.md](./README.md)  
Versão em português: [README-ptbr.md](./README-ptbr.md)

Si quieres entender cómo un agente de IA puede ayudar en tu camino de desarrollo, lee [ai-agents-in-vscodium-chat-es.md](./.docs/articles/ai-agents-in-vscodium-chat-es.md).

## Propósito

Este repositorio es un kit reutilizable para gobernanza de agentes en proyectos de software.
Incluye:
- contrato global: `AGENTS.md`
- contratos por rol: `.docs/agents/`
- flujo/plantillas de issues: `docs/issues/`
- dos archivos obligatorios de contexto para cada proyecto destino:
  - `.docs/software-overview.md`
  - `.docs/limits.md`

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

Preferido: clona e inspecciona antes de ejecutar, sobre todo la primera vez:

```bash
git clone --branch v1.0.2 https://github.com/EDortta/AI-Agents.git
less AI-Agents/scripts/install-agents-kit.sh
./AI-Agents/scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto
```

Atajo, si aceptas ejecutar un script directo desde GitHub (fijado a una tag
de release, no a la rama mutable `main`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EDortta/AI-Agents/v1.0.2/scripts/install-agents-kit.sh) \
  --target /ruta/de/tu-proyecto
```

Actualiza una instalación existente sin sobrescribir contexto/estado local del proyecto:

```bash
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --upgrade
```

El modo upgrade actualiza archivos propios del kit y preserva:
- `.docs/software-overview.md`
- `.docs/limits.md`
- `handoff.md`
- `docs/napkin-lessons.md`
- carpetas de issues del proyecto en `docs/issues/`
- `docs/undercover-issues/`
- `.credentials/`

Importante:
- el instalador usa un readiness gate y termina con código distinto de cero hasta que:
  - `.docs/software-overview.md` tenga `project_context_ready: yes`
  - `.docs/limits.md` tenga `limits_ready: yes`

1. Copia (o usa symlink) estos artefactos en el proyecto destino:
- `AGENTS.md`
- `.docs/agents/`
- `docs/issues/`
- `.docs/software-overview.md`
- `.docs/limits.md`

2. Adapta solo lo específico del proyecto:
- Completa `.docs/software-overview.md` con contexto del producto, arquitectura y objetivos.
- Completa `.docs/limits.md` con límites estrictos (in/out-of-scope, acciones prohibidas, gates de aprobación).
- Estos dos archivos son obligatorios y deben ser editados por el programador para que el agents-kit reconozca correctamente qué hacer en el proyecto.

3. Mantén el núcleo genérico:
- Conserva estructura e intención de `AGENTS.md` y los archivos centrales de `.docs/agents/`.
- Agrega extensiones específicas solo cuando sea necesario.

## Flujo del Programador (Obligatorio)

Antes de programar en el proyecto destino:
1. Leer `.docs/software-overview.md` para entender qué se está desarrollando.
2. Leer `.docs/limits.md` para entender qué está permitido/prohibido.
3. Planificar e implementar solo dentro de esos límites.
4. Si una solicitud entra en conflicto con `.docs/limits.md`, detenerse y pedir aprobación humana explícita.

Durante el trabajo con issues:
1. Organizar el trabajo en carpetas de épica dentro de `docs/issues/`.
2. Usar las plantillas de `.docs/issues/templates/`.
3. Incluir checklist de privacidad cuando haya datos personales:
- `.docs/issues/templates/privacy-checklist.template.md`

Cierre de sesión en cada etapa:
1. Actualizar `handoff.md` con estado, próximos pasos, bloqueos, archivos cambiados y checks.
2. Registrar lecciones aprendidas cortas en `docs/napkin-lessons.md`.
3. Seguir `.docs/workflows/session-close.md`.

Convención de identificador de trabajo:
- Usar `work_id` con formato: `WK-YYYYMMDD-<short-slug>`.
- Mantener el mismo `work_id` en docs de planificación, handoff y mensajes de commit relacionados.

## Setup mínimo recomendado del proyecto

Al adoptar este kit, actualiza primero:
- `.docs/software-overview.md`: descripción del producto, arquitectura, módulos clave, dependencias.
- `.docs/limits.md`: límites de alcance, límites de seguridad, reglas de branch/aprobación, operaciones prohibidas.

Luego ejecuta una issue piloto usando `.docs/issues/templates/task.template.md` para validar el proceso.

## Toque Personal via USER.md

Los agentes pueden adaptar su estilo de comunicación a tu perfil cuando existe un archivo `USER.md` en `~/.config/USER.md`.

Este archivo es:
- **Global** — vive en el directorio de configuración de tu usuario, no en ningún repositorio de proyecto
- **Opcional** — el kit funciona sin él; el comportamiento de gobernanza no cambia
- **Personal** — generado a partir de una evaluación de perfil (DISC, Jung, Spranger, etc.) o escrito manualmente

Cuando está presente, los agentes lo leen al inicio de la sesión para adaptar tono, profundidad, encuadre de decisiones e idioma al usuario.

Convención:
- Ruta: `~/.config/USER.md`
- Formato: Markdown, secciones libres que describen preferencias de comunicación, tipo de perfil y trampas a evitar
- Nunca debe commitearse en ningún repositorio de proyecto

Herramientas como [ConhecerTe](https://conhecerte.com.br) pueden generar un `USER.md` listo a partir de una evaluación de perfil estructurada.

---

## Complementario: AI-GovernanceKit

El [AI-GovernanceKit](https://github.com/EDortta/AI-GovernanceKit) es la capa de ejecución y validación para este policy pack.

- **AI-Agents** = policy pack — el "qué y por qué" de la gobernanza (este repositorio)
- **AI-GovernanceKit** = CLI de runtime — el "cómo" de la ejecución (doctor, automatización de sesión, hooks de CI)

Están diseñados para funcionar juntos, pero sin dependencia formal:
- Instala AI-Agents copiando los archivos en el proyecto destino
- Instala AI-GovernanceKit como paquete Python (`pip install ai-governancekit`)
- El comando `doctor` del GovernanceKit valida la estructura de archivos del AI-Agents automáticamente

---

## Setup de Credenciales

Usa:
- `.credentials/README-es.md`

Plantillas disponibles:
- `.credentials/programmer.token.example`
- `.credentials/reviewer.token.example`
- `.credentials/jira.json.example`

## Estructura

- `AGENTS.md`: contrato universal de ejecución
- `scripts/install-agents-kit.sh`: instalador (ejecución local o directa vía raw de GitHub)
- `.docs/agents/`: contratos por rol (programmer, reviewer, issue automation, security, privacy)
- `docs/issues/`: estructura local de issues y plantillas
- `handoff.md`: log de handoff para retomar trabajo entre sesiones
- `docs/napkin-lessons.md`: log conciso de lecciones aprendidas
- `.docs/workflows/session-close.md`: checklist de cierre de etapa/sesión
- `.docs/workflows/dev-workflow-integration.md`: integración opcional de automatización al cierre de etapa

## Artículos

- EN: `.docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `.docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `.docs/articles/ai-agents-in-vscodium-chat-es.md`
- Perspectiva del autor sobre el camino de programación: [I used to turn off the internet for my developers](https://edortta71.medium.com/i-used-to-turn-off-the-internet-for-my-developers-f0d1747ee78f)
