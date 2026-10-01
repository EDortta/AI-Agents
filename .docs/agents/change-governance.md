# Change Governance — AI-Agents v2

This contract limits what an agent may change. It complements design standards.

## 1. Change contract

[MANDATORY] Every non-trivial behavioral, API, persistence, architecture, dependency, security, or UI change has a project-owned contract at:

`docs/ai-governance/changes/<work_id>.yaml`

Docs-only changes may declare `change_contract: n/a`.

Before editing, declare:
- `domains_read` and `domains_write`;
- `write_scope` and `forbidden_scope`;
- `must_preserve`: behavior/invariants that cannot regress;
- `acceptance`: observable proof of the change;
- `baseline`: pre-change checks/scenarios.

## 2. Write boundary

[MANDATORY] Read access is not write permission.

[MANDATORY] If implementation needs a path/domain outside the declared write scope, STOP. Amend the contract with explicit human approval or split the work.

[MANDATORY] Writing more than one domain is cross-domain work; every written domain must be declared before implementation.

[PROHIBITED] Incidental refactors, cleanup, dependency upgrades, renames, formatting sweeps, or architecture changes outside the contract.

## 3. Preservation and proof

[MANDATORY] Code existence is not completion. Acceptance behavior must be demonstrated and `must_preserve` must remain true.

[MANDATORY] A bug fix adds a regression test that fails without the fix.

[MANDATORY] Compare the final diff with `write_scope` and `forbidden_scope`. Any undeclared write rejects the change until resolved.

[MANDATORY] A baseline check that passed before and fails after blocks delivery unless the contract explicitly intended and approved that behavior change.

Runtime enforcement belongs to AI-GovernanceKit; this file defines policy.
