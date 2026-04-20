# IA-Agents Universal Kit

Portuguese version: [README-ptbr.md](./README-ptbr.md)  
Spanish version: [README-es.md](./README-es.md)

If you want to understand how an AI agent can help in your development journey, take a look at [ai-agents-in-vscodium-chat.md](./docs/articles/ai-agents-in-vscodium-chat.md).

## Purpose

This repository is a reusable starter kit for agent governance in software projects.
It provides:
- a global contract: `AGENTS.md`
- role contracts: `docs/agents/`
- issue templates/workflow: `docs/issues/`
- two mandatory context files for each target project:
  - `docs/software-overview.md`
  - `docs/limits.md`

## Designed For Which AI Agents/Tools

This kit was designed to be portable across well-known coding agents and IDE assistants, especially:
- Codex-style agents (using `AGENTS.md`)
- Claude-based agents (using `CLAUDE.md`)
- GitHub Copilot (using `.github/copilot-instructions.md`)
- Cursor (using `.cursorrules`)
- Windsurf/Cascade (using `.windsurfrules`)
- Gemini-based assistants (using `GEMINI.md`)

Core rule:
- `AGENTS.md` is the global contract.
- Tool-specific files adapt that same contract to each ecosystem.

## How to Use in Another Project

1. Copy (or symlink) these assets into the target project:
- `AGENTS.md`
- `docs/agents/`
- `docs/issues/`
- `docs/software-overview.md`
- `docs/limits.md`

2. Adapt only what is project-specific:
- Fill `docs/software-overview.md` with product context, architecture, and objectives.
- Fill `docs/limits.md` with hard boundaries (in/out-of-scope, prohibited actions, approval gates).
- These two files are mandatory and must be edited by the programmer so the agents-kit can correctly recognize what to do in the project.

3. Keep core contracts generic:
- Preserve the structure and intent of `AGENTS.md` and core files in `docs/agents/`.
- Add project extensions only when necessary.

## Programmer Workflow (Required)

Before coding in a target project:
1. Read `docs/software-overview.md` to understand what is being built.
2. Read `docs/limits.md` to understand what is allowed/prohibited.
3. Plan and implement only within those boundaries.
4. If a request conflicts with `docs/limits.md`, stop and request explicit human approval.

During issue work:
1. Organize work under epic folders in `docs/issues/`.
2. Use templates in `docs/issues/templates/`.
3. Include privacy checks when personal data is involved:
- `docs/issues/templates/privacy-checklist.template.md`

## Suggested Minimal Project Setup

When adopting this kit, update first:
- `docs/software-overview.md`: product description, architecture, key modules, dependencies.
- `docs/limits.md`: scope boundaries, security boundaries, branch/approval rules, forbidden operations.

Then run a pilot issue using `docs/issues/templates/task.template.md` to validate the process.

## Structure

- `AGENTS.md`: universal execution contract
- `docs/agents/`: role-level contracts (programmer, reviewer, issue automation, security, privacy)
- `docs/issues/`: local issue structure and templates

## Articles

- EN: `docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `docs/articles/ai-agents-in-vscodium-chat-es.md`
