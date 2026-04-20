# AGENTS.md

Universal operating contract for repository agents.
Primary objective: deliver secure, correct, maintainable changes with predictable execution.

Instruction precedence:
1. system/runtime instructions
2. this AGENTS.md
3. local user preferences

---

## 0. Workspace Overview

This repository is a universal source kit meant to be reused in other projects.

### Canonical local files

[MANDATORY] Software/product context is defined in:
- `docs/software-overview.md`

[MANDATORY] Agent operational boundaries (what agents can/cannot do) are defined in:
- `docs/limits.md`

[MANDATORY] Every issue/task/implementation must stay within `docs/limits.md` unless a human explicitly approves a boundary update first.

### Project profile dispatch rule

[MANDATORY] Before implementation, identify the target repository and apply:
- this universal contract (always), plus
- target-repo local `AGENTS.md` (if present), plus
- target-repo `docs/agents/*` contracts (if present and relevant)

If there is any conflict, follow instruction precedence.

---

## 1. Global Contract

### Priority order

[MANDATORY] Security over speed.
[MANDATORY] Correctness over convenience.
[MANDATORY] Maintainability over cleverness.
[DEFAULT] Prefer simple and explicit implementations.

### Core engineering principles

[MANDATORY] Solve root cause, not only symptoms.
[MANDATORY] Keep scope tight to issue requirements.
[MANDATORY] Keep work inside boundaries defined in `docs/limits.md`.
[MANDATORY] Preserve backward compatibility unless explicitly changed by issue.
[MANDATORY] Keep changes traceable to issue, code, and tests.
[PROHIBITED] Hidden behavior or undocumented side effects.

### Correctness contract

[MANDATORY] A delivery is correct only if all are true:
- it solves the issue problem at root-cause level, or explicitly documents why root-cause correction is not possible
- it does not introduce unjustified behavior outside issue scope
- it preserves existing contracts unless the issue explicitly changes them
- it does not introduce new lint, type, compile, or security failures in impacted modules
- it includes or updates tests when behavior changes, where applicable

### Scope discipline

Allowed:
- issue implementation
- necessary supporting refactor required for safe implementation/testing
- required tests
- official migrations when model/persistence changes

Not allowed:
- unrelated refactors
- opportunistic cleanup outside impacted area
- speculative improvements
- architecture changes not required by issue

[MANDATORY] If a supporting refactor is needed, declare it as `Necessary supporting refactor` with:
- reason
- files affected
- why it is required for safe implementation or testing

---

## 2. GitHub Issue/PR Content Guard

[MANDATORY] Never create GitHub Issue/PR with empty `title` or `body`.
[PROHIBITED] Run `gh issue create` without `--body`/`--body-file`.
[PROHIBITED] Run `gh pr create` without `--body`/`--body-file`.

### Minimum issue body

[MANDATORY] Every issue must include:
- Context
- Objective
- In scope
- Out of scope
- ARO (Acceptance, Risk, Operations)
- Test plan
- DoD

### Minimum PR body

[MANDATORY] Every PR must include:
- Summary
- Related issue (Jira/GitHub)
- What changed (files/areas)
- How to test
- Risks / Rollback
- Security impact
- Validation checklist (lint/test/typecheck)

### Pre-flight validation

[MANDATORY] Validate title and body have useful content (not only spaces).
[MANDATORY] If any field is empty, abort with explicit error.
[MANDATORY] Build body in a temp file and validate size:
- `test -s <body_file>`
- reject placeholder-only content (`TBD`, `TODO`, `.`, `-`, `N/A`)
- reject very small content (`wc -c <body_file> < 80`)

### Issue/PR automation tool preference

[MANDATORY] For Jira/GitHub issue and PR workflows, prefer `jkctl.py` when it exists in the target repository.
[MANDATORY] If `jkctl.py` exists, use it as the first option for create/link/start-solve/pull-request flows.
[DEFAULT] Use direct `gh`/Jira API commands only when `jkctl.py` is not available or does not support the required operation.

---

## 3. Quality and Testing

### Quality gates

For impacted modules only (unless shared contracts/tooling are changed):
- [MANDATORY] lint passes
- [MANDATORY] typecheck/compilation passes
- [MANDATORY] tests pass
- [MANDATORY] no exposed secrets

### Monorepo rule

[MANDATORY] Identify impacted package(s)/service(s) first.
[MANDATORY] Run checks for impacted modules and direct dependents when relevant.
[PROHIBITED] Run repository-wide checks by default unless shared tooling/contracts/root config changed.

### Public contract safety

[MANDATORY] When changing APIs/events/schemas/shared interfaces, declare:
- backward compatible: yes/no
- contract changed: yes/no
- migration required: yes/no
- downstream consumers affected: yes/no

### Test applicability

Tests are mandatory when changing:
- business logic
- API contracts
- authentication/authorization
- persistence/migrations
- shared interfaces
- regression-prone flows

Tests may be N/A only for:
- documentation-only
- comments-only
- metadata-only with no runtime effect

[MANDATORY] If N/A, provide explicit justification.

### Test evidence

For each command executed, report:
- command
- impacted module
- result
- behavior validated

For each added/updated test, report:
- file
- scenario
- fail-before/pass-after evidence, or objective reason if not executable

---

## 4. Security (Top Priority)

Security review is mandatory for runtime-impacting changes.

Evaluate at minimum:
- input validation
- injection risks
- authorization
- authentication
- data exposure
- logs and error handling
- business logic abuse
- privilege escalation
- tenant/isolation boundaries (if applicable)
- privacy/compliance impact when personal data is involved (GDPR/LGPD-style constraints)

### Security decision

[MANDATORY] Classify each delivery as one of:
- no security impact
- mitigated security impact
- known temporary risk requiring explicit human acceptance

If not `no security impact`, document:
- affected surface
- abuse path
- mitigation
- residual risk

### Security prohibitions

[PROHIBITED] Logging secrets/tokens/credentials/sensitive raw payloads.
[PROHIBITED] Weakening validation without explicit requirement.
[PROHIBITED] Broadening authorization silently.
[PROHIBITED] Hiding failures via broad catch-all handling without justification.
[PROHIBITED] Approving high-risk changes without mitigation and tests.

---

## 5. Observability and Operations

When runtime behavior changes, evaluate need for:
- clearer operational errors
- structured logs
- metrics
- tracing
- deploy notes
- rollback notes

[PROHIBITED] Noisy logs.
[PROHIBITED] Sensitive data leakage in logs/errors.

---

## 6. Repository Conventions

### Branch naming

- with Jira key: `feature/<JIRA-KEY>/<short-description>`
- without Jira key: `feature/gh-<issue-number>/<short-description>`
- undercover local tracker issue: `feature/uc-<NNN>/<short-description>`

### Branch and commit flow

[MANDATORY] Obtain explicit human permission before creating any new branch.
[MANDATORY] `create-issue` automation must not create/switch branch implicitly.
[MANDATORY] Branch creation only when user intent explicitly includes implementation start.
[MANDATORY] Create/switch branch before first code change.
[MANDATORY] Work only on that branch.
[MANDATORY] Default PR base branch is `development` unless explicitly required otherwise.
[MANDATORY] Run applicable checks/tests before commit.
[MANDATORY] Commit only after checks are green, unless objectively impossible and documented.
[MANDATORY] Commit message must be clear and PR-ready.
[MANDATORY] If Jira key exists, prefix commit with Jira key.
[MANDATORY] If a local work identifier exists, include it in commit message (recommended prefix: `[<work_id>]`).

[PROHIBITED] Start issue fix on `main`/`master`.
[PROHIBITED] Commit implementation before applicable checks without explicit justification.
[PROHIBITED] Create branch automatically right after issue creation without explicit permission.

### Work identifier and dated planning docs

[MANDATORY] Planning and development guide documents must include:
- `work_id` in format: `WK-YYYYMMDD-<short-slug>`
- `date` in format: `YYYY-MM-DD`

[MANDATORY] Use the same `work_id` across:
- issue planning docs
- handoff notes
- related commit messages

[DEFAULT] Commit subject format:
- `[WK-YYYYMMDD-<short-slug>] <summary>`

### Local artifacts and tracking

[MANDATORY] Keep operational runtime directories and generated local data untracked.
[PROHIBITED] Commit caches, backups, local runtime artifacts, or generated operational data.
[PROHIBITED] Commit or expose credentials/local secrets from `.credentials/`, `.env*`, tokens, or equivalent secret stores.

### Local issue documents (`docs/issues`)

[MANDATORY] Keep issue planning/execution in local epic folders with this structure:
- `docs/issues/NNN-<epic-slug>-[<status>]/README.md`
- `docs/issues/NNN-<epic-slug>-[<status>]/epic.md`
- `docs/issues/NNN-<epic-slug>-[<status>]/issues/NNN-<task-slug>-[<status>].md`

[MANDATORY] Epic folder must contain both `README.md` and `epic.md`.
[MANDATORY] Task issue files must be stored only under the epic `issues/` subfolder.
[MANDATORY] Epic and task docs must include `work_id` and `date`.
[DEFAULT] Bootstrap new epics/tasks from:
- `docs/issues/templates/README.template.md`
- `docs/issues/templates/epic.template.md`
- `docs/issues/templates/task.template.md`
[MANDATORY] Keep numbering stable, strictly increasing, and never reuse numbers.
[MANDATORY] Status transitions must be performed by folder/file rename.
[MANDATORY] Apply solved/finished status only with objective implementation evidence.
[PROHIBITED] Mark solved/finished status based only on planning/intention text.

### Undercover local issue documents (`docs/undercover-issues`)

[MANDATORY] Undercover mode is local-only (no Jira/GitHub issue API calls).
[MANDATORY] Use:
- `docs/undercover-issues/NNN-<epic-slug>-[<status>]/epic.md`
- `docs/undercover-issues/NNN-<epic-slug>-[<status>]/issues/NNN-<issue-slug>-[<status>].md`

[MANDATORY] Allowed status set:
- `[draft]`
- `[ready]`
- `[started]`
- `[blocked]`
- `[review]`
- `[finished]`
- `[cancelled]`

[MANDATORY] Perform status transitions by renaming files/folders.
[MANDATORY] Apply `[finished]` only with objective implementation evidence.
[PROHIBITED] Mark `[finished]` based only on planning/intention text.

### Session-close and handoff protocol

[MANDATORY] At the end of each implementation stage/session, run a session-close routine.
[MANDATORY] Update `handoff.md` with:
- current status
- next steps
- blockers/risks
- files changed
- checks/tests executed
- active `work_id` and date

[MANDATORY] Record concise lessons learned in `docs/napkin-lessons.md` (short bullet format).
[DEFAULT] If a project provides automated `session-close`/`dev-workflow` command, use it.
[MANDATORY] If automation is not available, perform manual updates before ending the session.

### Migrations

For model/persistence changes:
- [MANDATORY] use official stack migration tools/workflow
- [PROHIBITED] handcraft migrations when an official generator exists
- [PROHIBITED] manually edit generated migration artifacts without explicit technical justification
- [MANDATORY] ensure migration applies and rollback/downgrade is validated when supported

If no persistence change, declare: `No model/migration changes`.

---

## 7. Language Policy

- This file is American English.
- Issues/business/task content may be pt-BR.
- Preserve exact meaning when interpreting pt-BR content.

---

## 8. Role Contracts

[MANDATORY] Prefer externalized role contracts when available in target repo under `docs/agents/`:
- `docs/agents/programmer.md`
- `docs/agents/reviewer.md`
- `docs/agents/issue-automation.md`
- `docs/agents/security.md`
- `docs/agents/privacy-compliance.md` (when personal data is involved)

[MANDATORY] Any role-specific behavior change must be edited in those role files when they exist.
[MANDATORY] This universal `AGENTS.md` remains global baseline and precedence authority for workspace-level behavior.

---

## 9. Credentials and Authentication

Credential files are operational inputs and must never be committed.

Common paths:
- `./.credentials/programmer.token`
- `./.credentials/reviewer.token`
- `./.credentials/jira.json`

Credential handling rules:
- use standard credential files only
- do not request interactive login when non-interactive credentials are available
- do not expose token values in logs/responses
- validate credentials before GitHub/Jira operations in same shell session

---

## 10. Maintainability and Readability Guard

### DRY and reuse

[MANDATORY] Avoid relevant logic duplication; extract reusable units when repeated.
[PROHIBITED] Copy/paste blocks with minimal variations when a simple abstraction solves it.
[MANDATORY] Reuse existing project utilities/patterns before introducing new ones.

### Simplicity and clarity

[MANDATORY] Prefer small, explicit, predictable implementations.
[PROHIBITED] Clever code that harms readability/maintainability.
[MANDATORY] Function/variable names must communicate intent clearly.
[MANDATORY] Each function should have a single responsibility and limited scope.

### Complexity control

[MANDATORY] Break overly long functions into cohesive units when this improves readability/testability.
[PROHIBITED] Excessive conditional/loop nesting without need.
[MANDATORY] If refactor is needed to reduce complexity/duplication, declare it as `Necessary supporting refactor`.

### Review gate

[MANDATORY] Before finalizing, review diffs for:
- introduced duplication
- ambiguous naming
- overly long/cohesive-poor functions
- redundant/misleading comments

[MANDATORY] If accepting temporary duplication as trade-off, document reason and removal plan.

### Tests and contracts

[MANDATORY] New abstractions should include tests for reusable behavior.
[PROHIBITED] Refactor that changes public contract without explicit declaration in contract notes.

---

## 11. Optional Extensions

This kit is intentionally generic.

[DEFAULT] Keep `docs/agents/` focused on core reusable roles:
- `programmer.md`
- `reviewer.md`
- `issue-automation.md`
- `security.md`
- `privacy-compliance.md`
- shared references (`README.md`, `_shared.md`, optional `governance-precedence.md`)

[MANDATORY] If a project needs domain/stack-specific rules, add them as explicit project extensions and keep them separate from the generic core.
[MANDATORY] Any project-specific extension must declare scope and non-portable assumptions clearly.

---

## 12. Final Goal

Done means all are true:
- secure by design and validation
- correct relative to acceptance
- tested with objective evidence
- clear for fast review and safe maintenance
- operationally predictable (branching, commits, linkage, rollback awareness)
