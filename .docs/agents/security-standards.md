# Security Standards

Concrete, verifiable security rules for any code created or changed in a project
that uses this kit — agents and humans alike. This is the **minimum** bar, not a
project-specific checklist.

`./security.md` covers *how to review* (categories, classification, output).
This file covers *what must be true* in the delivered code. When a rule conflicts
with "make it work fast in dev", the rule wins. Every rule below was distilled
from real vulnerabilities found in production; see **Provenance** at the end.

If this file conflicts with `/AGENTS.md`, follow `/AGENTS.md`.

## 1. Secrets and credentials

- No secret (password, API key, token, private key) in code, docs, design docs,
  examples or git history. Secrets live **only** in `.credentials/` or `.env`,
  both gitignored from the first commit.
- **Fail-fast:** a service refuses to start without its required secrets
  (`JWT_SECRET`, cipher keys, allowed origins…). No embedded default "to run in
  dev" — dev also sets env.
- No default user password. Provisioning generates a random per-user password
  with forced change on first access.
- Persisted credentials are encrypted at rest and **masked** in any screen, log
  or dump.
- Secret leaked into the repo: immediate containment (`git rm --cached` +
  `.gitignore`) and **rotation as an explicit operator task**. History rewrite
  only with human approval.

## 2. Logs and personal data (privacy)

- Never log a token, password, national ID, e-mail, phone or auth payload. Log
  opaque identifiers (user id, request id) — the log records *what* happened,
  not *who* the person is.
- 500 errors never expose a stack trace or internal detail outside dev.
- Every personal-data field collected has a written purpose and retention policy
  before production. See `./privacy-compliance.md`.

## 3. Network and service exposure

- Services bind to **loopback by default**. External exposure is explicit and
  named opt-in (e.g. `allow_nonlocal_host`) — never `0.0.0.0` for convenience.
- Flags that disable protections (e.g. `--no-sandbox`) are never the default;
  always explicit opt-in with a name that announces the risk.
- Before reusing an existing port/endpoint/process, **validate the owner**
  (protocol handshake + PID/cmdline). Do not assume the port is yours.
- Internal APIs and WebSockets: always authenticate (key in a **header**, never
  in the URL) and refuse unencrypted transport outside localhost.

## 4. Authentication and authorization

- Every command interface (bot, C&C, admin panel, webhook) requires
  **authorization per action**, not just authentication of the caller.
- Approval flows are **fail-closed**: without explicit, verifiable operator
  confirmation, the answer is NO.
- Sensitive operations (financial data, payment keys, profile changes) are
  validated and authorized **on the backend**; the client is never the last line.
- Login has rate limiting and progressive lockout, with state shared across
  instances (e.g. Redis) — not local memory.
- Captcha/Turnstile on public forms. Disabling "temporarily" requires an open
  issue with a deadline — otherwise it is a regression.

## 5. Web hardening

- **CORS fail-closed:** allowed origins come from env; env absent → deny all, do
  not allow all.
- Required headers at the proxy/server: restrictive CSP,
  `X-Content-Type-Options: nosniff`, `frame-ancestors`, HSTS.
- No preview/dev-backdoor endpoint in code that reaches production. Admin seed
  and bootstrap routes gated by explicit env.
- Passwords and invite tokens never echoed in a response, URL or query string.

## 6. Runtime and filesystem

- Lockfiles and service state live **outside `/tmp`** (predictable, shared); use
  the service's own directory with restrictive permissions.
- A file with sensitive data is created with a restrictive `chmod` — not fixed
  afterwards.

## 7. Supply chain and release

- Every downloaded installer/artifact is **checksum-verified** before it runs.
- The release/tag script is **gated by tests**: a broken suite does not tag and
  does not publish.

## 8. Rules specific to AI agents

- User input is **untrusted by definition**: flows feeding an LLM have
  prompt-injection defense (delimitation, command allowlist, human confirmation
  for destructive actions).
- An autonomous agent is **commit-only**: `git push`, deploy, remote-host
  restart and key rotation are always human-operator tasks. No exception, even
  if "the issue asks for it".
- What the agent cannot resolve alone (rotations, firewall, production env)
  becomes an explicit `needs_operator` item in the report — never silently
  omitted.
- The agent reports faithfully: a failed test, a skipped step and residual risk
  appear in the delivery summary.

---

## PR self-check

Before opening or approving a PR that touches runtime, confirm — or mark `n/a`:

- [ ] No secret added to code, docs, examples or history (`.credentials/`/`.env` only)
- [ ] Service still fail-fast on missing required env (no new dev default)
- [ ] No token/password/personal ID/auth payload written to a log
- [ ] New service/port binds loopback unless external exposure is explicit opt-in
- [ ] CORS/allowed origins stay fail-closed (env absent → deny)
- [ ] Sensitive action authorized on the backend, per-action, fail-closed
- [ ] Downloaded artifact checksum-verified; release path still test-gated
- [ ] LLM-fed input treated as untrusted; destructive actions need human confirm
- [ ] `needs_operator` items (rotation, deploy, firewall) listed, not omitted

---

## Provenance

Distilled from ~280 real vulnerabilities remediated across production
repositories (secrets in code and design docs, mass-provisioned default
passwords, tokens and personal IDs logged at login, a debug service exposed off
loopback, CORS opened when env was absent, an unauthorized autonomous deploy →
the commit-only rule). Client and repo identifiers are intentionally omitted:
this kit is shared, so the *rule* travels, not the incident.

**Enforcement status:** §1 (tracked-secret paths) and §7 (installer checksum)
are already enforced by `governancekit doctor` and the installer. The remaining
sections are review-gated here and in `./security.md`; turning more of them into
automated checks is future work.
