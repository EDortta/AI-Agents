# 01 - Setup del Primer Día

## Historia feliz: Lia empezó bien
Lia es desarrolladora junior. Quiere velocidad con IA sin perder control. En su primer día no empieza programando: primero define contexto y límites para que el agente trabaje con claridad.

## Qué es tuyo (programador)
- Escribir contexto real en `docs/software-overview.md`.
- Definir límites duros en `docs/limits.md`.
- Decidir qué puede y qué no puede hacer el agente.
- Confirmar que los readiness flags estén en `yes`.

## Qué es del agente
- Leer esos archivos antes de planificar o editar.
- Respetar límites y alertar conflictos.
- Proponer plan alineado al contexto del proyecto.

## Paso a paso

**1. Copia el policy pack en tu proyecto.**

```bash
git clone https://github.com/EDortta/AI-Agents.git
cp -r AI-Agents/AGENTS.md AI-Agents/docs AI-Agents/handoff.md AI-Agents/CLAUDE.md ./
```

Como mínimo necesitas `AGENTS.md`, `docs/software-overview.md`, `docs/limits.md` y `handoff.md`.

**2. Instala GovernanceKit (la CLI companion).**

```bash
pip install git+https://github.com/EDortta/AI-GovernanceKit.git
```

Requiere Python 3.10+. Sin dependencias externas.

**3. Valida el setup.**

```bash
governancekit doctor
```

Verás una lista de verificaciones. La mayoría fallarán en una instalación nueva — eso es esperado. Corrige cada línea `[FAIL]` antes de continuar.

**4. Completa `docs/software-overview.md`** con el propósito del producto, stack tecnológico y módulos principales.

**5. Completa `docs/limits.md`** con lo que los agentes pueden y no pueden hacer en este proyecto.

**6. Marca los readiness flags.**

Abre ambos archivos y define:
```
project_context_ready: yes
limits_ready: yes
```

Ejecuta `governancekit doctor` de nuevo — debería pasar ahora.

**7. Genera el mapa de código.**

```bash
governancekit map
```

Esto crea `docs/codemap.md` — un índice Markdown de tus archivos y símbolos. Haz commit. Los agentes lo leen al inicio de la sesión en lugar de escanear archivo por archivo.

**8. Recién entonces pide implementación al agente.**

## Prompt de inicio
"Ejecuta `governancekit resume` primero, luego lee AGENTS.md, software-overview y limits. Confirma las restricciones y propón un plan corto antes de programar."

## Definición de listo
- `governancekit doctor` pasa todas las verificaciones.
- `docs/codemap.md` existe y está commiteado.
- El agente sabe qué hacer y qué evitar.
- Puedes reiniciar cualquier sesión sin perder contexto.
