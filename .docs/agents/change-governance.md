# Change Governance — AI-Agents v2

This contract limits what an agent may change. It complements design standards; it does not replace tests, review, or project limits.

## 1. Change contract

[MANDATORY] Every non-trivial behavioral, API, persistence, architecture, dependency, security, or UI change has a project-owned contract at:

`docs/ai-governance/changes/<work_id>.yaml`

Docs-only changes may declare `change_contract: n/a`.

Before editing code, the contract declares:
- `domains_read`: domains that may be inspected;
- `domains_write`: domains that may be modified;
- `write_scope`: allowed paths;
- `forbidden_scope`: paths that must not change;
- `must_preserve`: existing behavior/invariants that must remain true;
- `acceptance`: observable behavior that proves the change;
- `baseline`: checks/scenarios known before the change.

## 2. Write boundary

[MANDATORY] Read access is not write permission. An agent may inspect a dependency to understand its contract and still be forbidden to edit it.

[MANDATORY] If implementation requires a path or domain outside `domains_write` / `write_scope`, STOP. Amend the change contract with explicit human approval or split the work.

[MANDATORY] Writing more than one domain is a cross-domain change and every written domain must be declared before implementation.

[PROHIBITED] Incidental refactors, opportunistic cleanup, dependency upgrades, renames, formatting sweeps, or architecture changes outside the declared change.

## 3. Preservation and proof

[MANDATORY] A change is not complete because code exists. It is complete when the declared acceptance behavior is demonstrated and `must_preserve` remains true.

[MANDATORY] A bug fix adds a regression test that fails without the fix.

[MANDATORY] Compare the final diff to `write_scope` and `forbidden_scope`. Any undeclared write rejects the change until resolved.

[MANDATORY] If a baseline check passed before the work and fails after it, the delivery is blocked unless the change contract explicitly intended and approved that behavioral change.

Runtime enforcement belongs to AI-GovernanceKit. This file defines the policy.
