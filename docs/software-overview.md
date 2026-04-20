# Software Overview

This repository provides a universal, reusable agent-governance bundle for software projects.

## Purpose
- Provide a high-quality base `AGENTS.md`.
- Provide role-specific contracts under `docs/agents/`.
- Provide deterministic issue-management structure under `docs/issues/`.

## Components
- `AGENTS.md`: global operating contract and precedence rules.
- `docs/agents/`: role and specialized contracts (programmer, reviewer, issue automation, security, and optional domain add-ons).
- `docs/issues/`: local issue artifacts grouped by epic folders, with templates.
- `agents-sources/`: imported source variants used to maintain and improve this universal bundle.

## Intended Use
- Copy/adapt this bundle into other repositories.
- Keep only relevant specialized contracts for the target project domain.
- Keep global sections stable across projects for predictable agent behavior.
