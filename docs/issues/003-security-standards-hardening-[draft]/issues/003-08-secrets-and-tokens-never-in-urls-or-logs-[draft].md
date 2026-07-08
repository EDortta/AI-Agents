# Task: Secrets and tokens never in URLs or logs; mandatory redaction

## Metadata
- work_id: WK-20260707-sec-urls-logs
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §2 (Logs and personal data) to forbid secrets/tokens in URLs/query strings and
to require redaction of secrets and PII before anything is logged.

## In Scope
- §2 additions:
  - **No secret/token in a URL or query string** — they leak to access logs, proxies,
    browser history, and referrers. Use headers or POST bodies. (Complements §3's
    "key in a header, never in the URL" for internal APIs, generalized to all traffic.)
  - **Never log a full request URL/body that can contain credentials.** Redact
    `Authorization`, tokens, passwords, and PII (CPF/phone/email) before logging.
  - **Peer-supplied text is not logged verbatim** unless known-safe (log injection): log
    structured fields (code, duration, id), not arbitrary payload strings.
- Matching PR self-check line.

## Out of Scope
- Per-project remediation (own SEC-* alerts).

## ARO
- Acceptance: rules merged; a token in a query string or an unredacted secret/PII log
  line fails review.
- Risk: low; requires a shared redaction helper — reference one in the standards.
- Operations: partially `doctor`-automatable (grep for `?...(token|key|senha|password)=`
  and logging of full request URLs).

## Test Plan
- N/A for standards text. Applied: log output for an auth request shows redacted
  `Authorization`/token and no query-string secret.

## Security
- Sources: SEC-0082 (SMS gateway password in query string logged in cleartext),
  SEC-0126/0148/0158 (API key in query string), SEC-0184/0242/0243 (token/JWT/SMS
  password in URL), SEC-0213 (tokens in URL → logs), SEC-0187 (consent token in logged
  URL), SEC-0086/0133/0201/0248/0284 (tokens/PII logged). Napkin: wa-hub "close reason
  is external input" (log known-safe reasons only).

## Privacy
- Personal data impact: yes (phone/CPF/message content in logs).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §2 additions + self-check line drafted; cross-referenced to source SEC ids.
