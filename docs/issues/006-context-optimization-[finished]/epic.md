# WK-20260727-context-optimization

## What and why

Agents currently load broad Markdown contracts without an explicit budget or a
machine-readable explanation of why each source was selected. This epic adds a
canonical selection policy while preserving every mandatory rule.

## Scope

- AI-Agents owns `.docs/context-manifest.yaml` and the schemas.
- AI-GovernanceKit owns parsing, deterministic selection, token counting,
  duplication reporting, CLI output, and local metadata-only telemetry.
- `full`, `sections`, and lexical `retrieve` modes are supported.
- Existing `RESUME.md` and `handoff.md` remain compatible.

## Out of scope

Embeddings, vector databases, remote RAG, LLM summaries, external telemetry,
provider routing, historical deletion, and automatic removal of similar rules.

## ARO

- Acceptance: manifest validates; inspect/build are deterministic; mandatory
  overflow fails; optional overflow warns; provenance and duplicates are visible.
- Risk: reducing context must never silently truncate or omit a mandatory rule.
- Operations: metadata-only JSONL is local, keyed by work ID, retained for 30 days.

## Test plan and DoD

Exercise task/risk selection, exclusions, all reading modes, exact duplicate and
overlap reporting, category/total budgets, stable JSON, counter injection,
provenance, telemetry privacy, and the base-context ceiling. Run both repositories'
full impacted test gates. No commit, release, or deploy in this delivery.

## Contract notes

- backward compatible: yes
- contract changed: yes (additive manifest and CLI commands)
- migration required: no
- downstream consumers affected: AI-Agents installers must ship the new `.docs/` files
