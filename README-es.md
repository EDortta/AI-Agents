# AI-Agents Universal Kit

## Presupuesto determinista de contexto

El kit distribuye `.docs/context-manifest.yaml`, validado con JSON Schema, para que
los runtimes compatibles carguen solamente los contratos requeridos por la tarea y
los riesgos declarados. AI-GovernanceKit implementa `governancekit context inspect`
y `governancekit context build`; consulte `.docs/context-optimization.md`.

<!-- AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .credentials/identity.json (untracked, per-programmer) -->

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
- Amazon Q Developer (usando `.amazonq/rules/ai-agents.md`)

Regla central:
- `AGENTS.md` es el contrato global.
- Los archivos específicos por herramienta adaptan ese mismo contrato a cada ecosistema.
- Todos los adaptadores cargan la misma base de cinco documentos; el gate de release
  lo verifica y los upgrades restauran adaptadores del kit para impedir debilitamientos silenciosos.

## Cómo usar en otro proyecto

Para todos los parámetros del instalador, archivos de identidad, códigos de salida,
migraciones y ejemplos de CI, consulta los
[Detalles avanzados de uso](https://edortta.github.io/AI-Agents/advanced-usage-es.html).

Preferido: clona e inspecciona antes de ejecutar, sobre todo la primera vez:

```bash
git clone --branch v1.1.8 https://github.com/EDortta/AI-Agents.git
less AI-Agents/scripts/install-agents-kit.sh
./AI-Agents/scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto
```

Atajo, si aceptas ejecutar un script directo desde GitHub (fijado a una tag
de release, no a la rama mutable `main`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EDortta/AI-Agents/v1.1.8/scripts/install-agents-kit.sh) \
  --target /ruta/de/tu-proyecto
```

Actualiza una instalación existente sin sobrescribir contexto/estado local del proyecto:

```bash
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --upgrade
```

Si acabas de clonar un proyecto que ya tiene AI-Agents instalado, ejecuta ese
`--upgrade` antes de la primera tarea en el clon. Actualiza los archivos gestionados
por el kit y pregunta por los valores locales faltantes o nuevos, en lugar de dejarte
heredar la identidad de otro programador o un estado antiguo de los slots.

El modo upgrade actualiza archivos propios del kit y preserva:
- `docs/software-overview.md`
- `docs/limits.md`
- `docs/project-rules.md`
- `handoff.md`
- `docs/napkin-lessons.md`
- carpetas de issues del proyecto en `docs/issues/`
- `docs/undercover-issues/`
- `.credentials/`

### Dónde van las reglas específicas del proyecto

`AGENTS.md` es el primer archivo que lee todo agente, lo que lo convierte en el
primer lugar donde la gente escribe una regla del proyecto — y pertenece al kit,
así que `--upgrade` lo reemplaza. Escribe las reglas del proyecto en
**`docs/project-rules.md`**. El instalador lo crea una vez y nunca vuelve a
tocarlo; está deliberadamente **fuera** del manifiesto del kit, y esa ausencia es
la garantía.

Aun así `AGENTS.md` está **protegido**: cuando su contenido difiere de lo que el kit
instaló, `--upgrade` conserva tu versión, escribe la nueva en `AGENTS.md.kit-new` al
lado y lo informa. Nada se sobrescribe en silencio. Sin manifiesto (instalación
anterior a `.gk/`, o sin `python3`) el instalador no puede probar que el archivo está
intacto, así que falla cerrado y lo preserva.

Cada archivo raíz reemplazado también se copia a `.gk/pre-upgrade/` antes.

Los archivos del kit además se declaran: un banner corto en sus primeras líneas dice
que son kit-owned y apunta a `docs/project-rules.md`. El gate de release verifica que
el banner esté presente, para que una edición cualquiera no borre justamente la única
línea que le dice al siguiente agente dónde escribir.

### Valores del operador: slots `{{…}}` y `.credentials/identity.json`

Los archivos del kit nunca contienen el nombre ni la cuenta real del operador — llevan
slots `{{…}}` (llaves dobles alrededor de un nombre en MAYÚSCULAS), porque un dato
personal no puede quedar en fuente versionada. Los valores viven en
**`.credentials/identity.json`**:

```json
{
  "values": { "OPERATOR_NAME": "…" },
  "refs":   { "EMAIL_CREDENTIALS": "~/.config/email/credentials.conf" }
}
```

`values` guarda literales; `refs` guarda **rutas** a archivos de credenciales — nunca
un secreto inline. El archivo **nunca se versiona**: `.credentials/.gitignore` lo
mantiene fuera de git, así que cada programador del proyecto establece su propia
identidad en vez de heredar el nombre de un colega desde el repositorio. Ese es el
punto — el nombre y la cuenta del operador son justamente el dato personal que el
esquema de slots existe para mantener fuera del repo, y compartir un archivo solo
movería la fuga de `AGENTS.md` a un JSON.

En cada install y `--upgrade`, el instalador resuelve primero estos valores obligatorios.
En una terminal interactiva pregunta por el valor vacío de `OPERATOR_NAME`;
en una ejecución no interactiva, falla antes de copiar archivos del kit
e informa qué debe configurarse. Mantiene el archivo con modo `0600` y reaplica los
valores, así que un slot completado no es deriva: el archivo en disco y la versión nueva
del kit quedan byte a byte iguales, y el upgrade ni quema el valor ni pide una fusión.
`.credentials/` es el único directorio que ningún camino de upgrade toca.

Solo se sustituyen los tokens *declarados*, así que una expresión `${{ … }}` de GitHub
Actions o una plantilla mustache de ejemplo queda intacta. Llaves en vez de corchetes
porque `[MANDATORY]`, `[PROHIBITED]` y `[DEFAULT]` son vocabulario de contenido en
estos documentos: un token entre corchetes no se distingue de la prosa sin una
allowlist mantenida a mano; `{{…}}` siempre se distingue.

`python3` es obligatorio para validar y aplicar la identidad. El instalador falla
pronto si no está disponible o si no puede obtener los valores obligatorios.

### Migrar un target existente: `--check` → `--migrate` → `--upgrade`

Un proyecto instalado antes de todo esto suele tener los dos problemas a la vez: reglas
de proyecto escritas dentro de `AGENTS.md`, y valores del operador escritos encima de
los placeholders. `--migrate` los separa mecánicamente, una vez:

```bash
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --check     # qué derivó
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --migrate   # separar
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --upgrade   # ya limpio
```

`--migrate` lee los valores del operador de vuelta desde el target — usando los propios
slots de la plantilla como sonda, de modo que un valor solo se registra cuando la línea
que lo rodea aún coincide exactamente — y los escribe en `.credentials/identity.json`. Un archivo
cuya única diferencia con el kit son líneas *insertadas* es inequívoco: esas líneas pasan
a `docs/project-rules.md` y el archivo vuelve a la versión del kit. Cualquier otra cosa
— una línea del kit reescrita o borrada — se reporta y se deja intacta: el kit no
adivina qué quiso decir una edición. Las grafías heredadas `[TOKEN]` se reescriben a
`{{…}}`; un slot que nunca se completó se reconoce como vacío, no se confunde con un
valor. Los scripts shell se reportan, nunca se migran por contenido.

Escribe en el target, así que está gateado: TTY interactivo más una confirmación
tecleada, sin flag para saltarla, y una copia de todo lo que puede tocar en
`.gk/pre-migrate/`.

En CI, hacer que un archivo protegido sin fusionar falle la ejecución (el upgrade
igualmente se completa):

```bash
./scripts/install-agents-kit.sh --target /ruta/de/tu-proyecto --upgrade --strict
```

Importante:
- el instalador usa un readiness gate y termina con código distinto de cero hasta que:
  - `docs/software-overview.md` tenga `project_context_ready: yes`
  - `docs/limits.md` tenga `limits_ready: yes`

1. Copia (o usa symlink) estos artefactos en el proyecto destino:
- `AGENTS.md`
- `.docs/agents/`
- `docs/issues/`
- `docs/software-overview.md`
- `docs/limits.md`

2. Adapta solo lo específico del proyecto:
- Completa `docs/software-overview.md` con contexto del producto, arquitectura y objetivos.
- Completa `docs/limits.md` con límites estrictos (in/out-of-scope, acciones prohibidas, gates de aprobación).
- Estos dos archivos son obligatorios y deben ser editados por el programador para que el agents-kit reconozca correctamente qué hacer en el proyecto.

3. Mantén el núcleo genérico:
- Conserva estructura e intención de `AGENTS.md` y los archivos centrales de `.docs/agents/`.
- Agrega extensiones específicas solo cuando sea necesario.

## Flujo del Programador (Obligatorio)

Antes de programar en el proyecto destino:
1. Leer `docs/software-overview.md` para entender qué se está desarrollando.
2. Leer `docs/limits.md` para entender qué está permitido/prohibido.
3. Planificar e implementar solo dentro de esos límites.
4. Si una solicitud entra en conflicto con `docs/limits.md`, detenerse y pedir aprobación humana explícita.

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
- `docs/software-overview.md`: descripción del producto, arquitectura, módulos clave, dependencias.
- `docs/limits.md`: límites de alcance, límites de seguridad, reglas de branch/aprobación, operaciones prohibidas.

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
