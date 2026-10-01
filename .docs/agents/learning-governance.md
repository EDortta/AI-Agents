# Learning Governance — AI-Agents v2

Projects may teach the framework, but project knowledge must never leak into another project.

## 1. Three levels

Every lesson is classified as exactly one of:

- `LOCAL`: business, customer, architecture, infrastructure, or workflow knowledge that belongs only to the project.
- `PATTERN`: a potentially reusable engineering observation that still needs abstraction or more evidence.
- `CORE-CANDIDATE`: a generic engineering rule proposed for AI-Agents.

A project lesson starts LOCAL or PATTERN. No lesson becomes CORE automatically.

## 2. Local record

Project lessons live only in:

`docs/ai-governance/lessons/<date>-<slug>.md`

They may contain project-specific evidence because they remain inside that project.

## 3. Promotion boundary

Promotion to AI-Agents is a deliberate review step. A candidate must be rewritten so it contains only the generalized failure mode and rule.

[PROHIBITED] A promoted candidate must not contain:
- project, customer, product, person, host, repository, branch, URL, or infrastructure names;
- business entity names or domain-specific workflows;
- secrets, credentials, personal data, production identifiers, or raw payloads;
- a rule whose correctness depends on one project's architecture.

The source project may be referenced locally by an incident ID, but the promoted framework text must stand on its own without that context.

## 4. Promotion flow

`LOCAL -> PATTERN -> CORE-CANDIDATE -> human review -> CORE`

The agent may propose a promotion. It may not modify AI-Agents automatically as a consequence of a project incident.

Before promotion, answer:
1. Would this rule still make sense in an unrelated project?
2. Is it already covered by an existing AI-Agents rule?
3. Can it be enforced or checked?
4. Is the rule narrower than the failure it is trying to prevent?
5. Has all project-specific content been removed?

If any answer is unsatisfactory, keep it LOCAL/PATTERN.

## 5. Technology profiles

A reusable lesson that is not universal belongs to a technology/ecosystem profile, not CORE. Examples: Flutter-specific, Go-specific, PostgreSQL-specific.

AI-Agents therefore separates:
- CORE: universal engineering governance;
- PROFILE: technology/ecosystem rules;
- PROJECT: business and concrete architecture.

Runtime tooling may assist classification and sanitization, but promotion requires explicit human approval.
