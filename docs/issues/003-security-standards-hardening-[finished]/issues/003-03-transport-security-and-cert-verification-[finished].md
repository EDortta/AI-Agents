# Task: Never disable TLS certificate verification; encrypt channels carrying secrets/PII

## Metadata
- work_id: WK-20260707-sec-transport-tls
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §3 (Network and service exposure) to forbid disabling certificate verification
and to require TLS for any channel carrying secrets or personal data, including
machine-to-machine and deploy channels.

## In Scope
- §3 additions:
  - **Cert verification is never disabled:** no `rejectUnauthorized: false`,
    `CURLOPT_SSL_VERIFYPEER=0`, `verify=False`, `sslmode=disable` for a channel that
    carries secrets/PII or an agent token. A dev exception is a named, non-default opt-in.
  - **TLS required** for any transport of credentials/PII outside loopback (auth APIs,
    payment/financial APIs, agent WebSockets).
  - **SSH/SCP host-key verification** is mandatory in deploy scripts — no
    `StrictHostKeyChecking=no` / unverified host keys.
- Matching PR self-check line.

## Out of Scope
- Per-project remediation of the specific cleartext endpoints.

## ARO
- Acceptance: rule merged; any disabled-verification flag or cleartext secret/PII
  channel fails review unless a named dev opt-in is present.
- Risk: self-signed internal CAs need a documented trust store rather than disabling
  verification — accepted.
- Operations: `doctor`-automatable as advisory grep (`rejectUnauthorized:\s*false`,
  `VERIFYPEER`, `StrictHostKeyChecking=no`, `http://` for known secret paths).

## Test Plan
- N/A for standards text.

## Security
- Sources: SEC-0041 (`rejectUnauthorized:false` on agent WS carrying `AGENT_SECRET`),
  SEC-0119 (SSL verifypeer off), SEC-0132 (MySQL TLS off), SEC-0049/0083/0087/0094/
  0143/0146/0147/0149/0168/0292 (cleartext HTTP for prod/financial APIs), SEC-0238
  (deploy scp no host-key verification), SEC-0244 (`StrictHostKeyChecking no`).

## Privacy
- Personal data impact: yes (cleartext transport of PII/credentials).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §3 addition + self-check line drafted; cross-referenced to source SEC ids.
