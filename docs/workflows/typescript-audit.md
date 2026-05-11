# TypeScript Audit Workflow

Activation: on-demand only. Do not run as part of routine PR review.
Trigger: human requests a TypeScript quality audit for a project.

## Prerequisites

- Project uses TypeScript (`.ts`/`.tsx` files present).
- `docs/software-overview.md` and `docs/limits.md` are ready.
- Human has explicitly requested this audit.

## Scope

Whole-codebase analysis. Not scoped to a diff or branch.
Report findings; do not apply fixes unless the human explicitly authorizes.

---

## Audit Checklist

### 1. Excessive `any` Usage

- Grep for `: any`, `as any`, `<any>`, `Promise<any>`.
- For each occurrence: file, line, context.
- Suggest: `unknown` + narrowing, union type, or generic.

### 2. React Component Props Without Types

- Find components (function or class) that accept props without an explicit `interface` or `type`.
- List component name, file, and suggested interface shape.

### 3. `interface` vs `type` Consistency

- Identify whether the project mixes both without a stated convention.
- Recommend one pattern and list files that diverge.
- Guidance: prefer `interface` for object shapes that may be extended; prefer `type` for unions, intersections, and aliases.

### 4. Overly Permissive Types

- Find `string | number | boolean | object | any[]` where a union of literals, enum, or discriminated union would be more precise.
- Flag function parameters that accept wide types but only use a narrow subset.

### 5. Functions Without Explicit Types

- Find exported functions with missing parameter types or inferred-`any` return types.
- Find callbacks passed to `Array.map`/`filter`/`reduce` with untyped parameters.

### 6. Unsafe `as` Assertions

- Find `as SomeType` on paths that receive external/untrusted input (API responses, user input, `JSON.parse`).
- Classify: unsafe (BLOCKER candidate), internal-only (IMPROVEMENT), or justified (OK with comment).

### 7. Duplicated Types

- Identify identical or near-identical `interface`/`type` declarations across files.
- Suggest canonical location (e.g., `src/types/`, `src/shared/types.ts`).

### 8. Shared Type Extraction

- List types used in 3+ files that are not yet in a shared location.
- Suggest `src/types/` structure if the project lacks one.

### 9. `tsconfig.json` Evaluation

Recommended flags to verify or enable:

| Flag | Why |
|---|---|
| `"strict": true` | Enables all strict checks in one flag |
| `"noImplicitAny": true` | Catches untyped parameters |
| `"strictNullChecks": true` | Prevents null/undefined runtime errors |
| `"noUncheckedIndexedAccess": true` | Safer array/object access |
| `"exactOptionalPropertyTypes": true` | Prevents `undefined` from leaking into optional props |
| `"noImplicitReturns": true` | All code paths must return a value |
| `"noFallthroughCasesInSwitch": true` | Prevents accidental fallthrough |
| `"forceConsistentCasingInFileNames": true` | Cross-platform safety |

Report current state (enabled/disabled) and flag any that are disabled but would catch real issues in the current codebase.

### 10. Maintainability, Readability, and Type Safety Gains

- Estimate effort vs. benefit for each category above.
- Identify which findings, if fixed, would eliminate the most runtime risk.

---

## Required Output Format

### Executive Summary

2–4 sentences: overall TypeScript maturity, top risk, and top quick win.

### Findings by Category

For each category (1–10):
- Category name
- Severity: High / Medium / Low
- Occurrences count
- Representative examples (file:line + snippet)
- Recommendation

### Before / After Examples

For each High finding, provide one concrete before/after code snippet.

### Prioritized Recommendations

| Priority | Finding | Effort | Impact |
|---|---|---|---|
| High | ... | ... | ... |
| Medium | ... | ... | ... |
| Low | ... | ... | ... |

### Quick Wins

List up to 5 changes achievable in under 30 minutes each with no functional risk.

### TypeScript Maturity Score

Score: X / 10

| Dimension | Score |
|---|---|
| Strict config | /2 |
| Explicit types | /2 |
| No unsafe assertions | /2 |
| Type reuse and organization | /2 |
| React prop types | /2 |

Scoring guide:
- 8–10: Production-ready, minimal risk
- 5–7: Functional but brittle; targeted improvements recommended
- 3–4: High implicit-`any` surface; type safety largely nominal
- 0–2: TypeScript used as a linter only; consider strict migration plan

---

## What This Workflow Does NOT Do

- Does not apply fixes automatically.
- Does not create branches or PRs.
- Does not flag findings from unmodified legacy code as BLOCKERs — those are IMPROVEMENT.
- Does not replace per-PR TypeScript checks in `reviewer.md`.
