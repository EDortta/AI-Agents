# AGENTS.md

Low-token universal operating contract for repository agents.
Primary objective: secure, correct, maintainable changes with predictable execution.

Instruction precedence:
1. system/runtime instructions
2. this `AGENTS.md`
3. target-repository role/workflow docs loaded by this file
4. local user preferences (`~/.config/USER.md` if present)

---

## 1. Start Gate

Before implementation, identify the target repository.

Required target-project files:
- `docs/software-overview.md`
- `docs/limits.md`

Required readiness flags:
- `project_context_ready: yes`
- `limits_ready: yes`

If either file is missing or not ready:
1. Stop implementation.
2. Do not inspect, refactor, edit, branch, or run project checks.
3. Tell the programmer to configure the missing file(s).
4. Briefly explain:
   - `docs/software-overview.md`: product, stack, users, modules, key behavior.
   - `docs/limits.md`: allowed/prohibited agent actions, security boundaries, workflow constraints.

Every task must stay within `docs/limits.md` unless a human explicitly approves a boundary update.

Source-kit exception: when maintaining this reusable kit itself, a human may approve edits to these gates/templates before implementation starts.

Optional user profile:
- If `~/.config/USER.md` exists, read it to adapt communication style (tone, depth, decision framing) to the user's profile.
- This satisfies precedence level 4 (local user preferences).
- Only communication is adapted; governance behavior and quality gates are unchanged.

---

## 2. Load Only What Is Needed

Always read first:
- this file
- `docs/software-overview.md`
- `docs/limits.md`

Then load only relevant contracts:
- coding or issue solving: `docs/agents/programmer.md`
- code/PR review: `docs/agents/reviewer.md`
- issue or PR automation: `docs/agents/issue-automation.md`
- runtime-impacting change: `docs/agents/security.md`
- personal data handling: `docs/agents/privacy-compliance.md`
- session restore: `docs/workflows/session-restore.md`
- session close: `docs/workflows/session-close.md`

Do not load historical issue docs, handoff notes, or lessons unless resuming active work or they are directly relevant.

---

## 3. Hard Rules

- Security over speed.
- Correctness over convenience.
- Maintainability over cleverness.
- Prefer simple, explicit implementations.
- Solve root cause, not only symptoms.
- Keep scope tight to the issue/request.
- Preserve existing contracts unless the issue explicitly changes them.
- Do not introduce hidden behavior or undocumented side effects.
- Do not expose secrets, tokens, credentials, or sensitive raw payloads.

---

## 4. Execution Loop

For implementation work:
1. Restore active work context if one exists.
2. State issue understanding, scope, risks, impacted files, and contract notes.
3. Create/switch branch only after explicit human permission.
4. Implement the smallest durable safe fix.
5. Run impacted lint/typecheck/tests.
6. Review diff for scope, duplication, clarity, contracts, and secrets.
7. Close the session with handoff/resume updates.

Never start implementation on `main` or `master`.

---

## 5. Quality Gates

For impacted modules only, unless shared tooling/contracts changed:
- lint passes
- typecheck/compilation passes
- tests pass
- no exposed secrets

Tests are required for behavior, API, auth, persistence, shared-interface, or regression-prone changes.
Tests may be N/A only for docs/comments/metadata with no runtime effect; justify N/A explicitly.

When changing public contracts, report:
- backward compatible: yes/no
- contract changed: yes/no
- migration required: yes/no
- downstream consumers affected: yes/no

If no persistence change, report: `No model/migration changes`.

---

## 6. GitHub/Jira Guard

Prefer `jkctl.py` for issue/PR workflows when present.

Never create an issue or PR with empty or placeholder-only title/body.
Never run:
- `gh issue create` without `--body` or `--body-file`
- `gh pr create` without `--body` or `--body-file`

Issue bodies must include context, objective, scope, ARO, test plan, and DoD.
PR bodies must include summary, related issue, changed areas, tests, risks/rollback, security impact, and validation checklist.

---

## 7. Branch, Commit, Artifacts

Branch naming:
- Jira: `feature/<JIRA-KEY>/<short-description>`
- GitHub: `feature/gh-<issue-number>/<short-description>`
- undercover/local: `feature/uc-<NNN>/<short-description>`

Rules:
- Obtain explicit human permission before creating a branch.
- Create/switch branch before first code change.
- Work only on that branch.
- Default PR base is `development` unless explicitly required otherwise.
- Commit only after applicable checks are green, unless impossible and documented.
- Do not commit caches, local runtime data, backups, credentials, `.env*`, or token files.

---

## 8. Session Memory

Use session memory only for active work:
- `docs/issues/<epic>/RESUME.md`
- `handoff.md`
- current issue/task file
- `docs/napkin-lessons.md`

`RESUME.md` is the source of truth for the immediate next action and must contain exactly one clear `Next Step (DO THIS FIRST)`.

At session close, update:
- `handoff.md`
- active `RESUME.md`
- `docs/napkin-lessons.md`

Planning/development docs must include:
- `work_id: WK-YYYYMMDD-<short-slug>`
- `date: YYYY-MM-DD`

---

## 9. Security Decision

For every delivery, classify security impact as:
- `no security impact`
- `mitigated security impact`
- `known temporary risk requiring explicit human acceptance`

If not `no security impact`, document affected surface, abuse path, mitigation, and residual risk.

---

## 10. Done

Done means:
- scope respected
- root cause handled or limitation documented
- contracts preserved or declared changed
- impacted checks/tests executed or justified
- security impact classified
- session handoff/resume updated
- review-ready summary produced
