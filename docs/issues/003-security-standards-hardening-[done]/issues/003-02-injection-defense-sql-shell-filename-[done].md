# Task: Injection defense — no request-derived data in SQL or shell

## Metadata
- work_id: WK-20260707-sec-injection-defense
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Add a new standards section mandating parameterized queries and shell-free command
execution, since request-derived data reaching a SQL string or a shell caused
data theft and unauthenticated RCE across the ecosystem.

## In Scope
- New standards section (proposed §10 "Injection"):
  - **SQL:** all queries use parameter binding / an ORM; never concatenate or
    f-string request input into SQL. Dynamic identifiers come from a fixed allowlist.
  - **Shell/command:** never pass request-derived data to a shell. Use argument-array
    APIs (`subprocess.run([...], shell=False)`), never `os.system`/`os.execute`/
    `shell=True` with interpolated input; where a value must appear, whitelist it
    (e.g. `^[A-Za-z0-9._-]+$`) and reject otherwise.
  - Applies equally to values derived from commit messages, filenames, and LLM output.
- Matching PR self-check line.

## Out of Scope
- Remediating the specific offending endpoints (own SEC-* alerts).

## ARO
- Acceptance: rule text merged; any string-built SQL or shell command from request/LLM
  input fails review.
- Risk: low; parameterization is standard practice.
- Operations: partially `doctor`-automatable (grep for `shell=True`, `os.system`,
  `os.execute`, f-string SQL) as an advisory check; review-gated otherwise.

## Test Plan
- N/A for standards text. Applied: injection payloads (`'; DROP`, `$(...)`, `; rm`)
  are neutralized/parameterized.

## Security
- Sources: SEC-0027 (OpenResty Lua `os.execute` on URL segment → unauthenticated RCE),
  SEC-0045/0061/0006 (SQL injection incl. arbitrary SQL via WS), SEC-0123 (shell
  injection via commit message), SEC-0138 (SMS `sed` param injection), SEC-0197
  (unquoted shell). Napkin: AI-Agents git-ref sanitization (branch name with embedded
  quotes corrupted tooling — validate `^[a-zA-Z0-9/_-]+$` before touching git).

## Privacy
- Personal data impact: indirect (injection enabled DB/data exfiltration).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Section text + self-check line drafted; cross-referenced to source SEC ids and the
  existing git-ref-sanitization napkin lesson.
