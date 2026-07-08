# Task: Cryptography baseline — password hashing, CSPRNG, token expiry/revocation

## Metadata
- work_id: WK-20260707-sec-crypto-tokens
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Add a new standards section setting the minimum bar for password hashing, random
secret generation, and token lifecycle, all of which were repeatedly weak.

## In Scope
- New standards section (proposed §11 "Cryptography and tokens"):
  - **Password hashing:** use a vetted, slow, salted KDF (argon2id / scrypt / bcrypt).
    No fast/plain hashing (md5/sha1/sha256-of-password), no home-grown KDF.
  - **Randomness:** secrets/tokens/IDs come from a CSPRNG (`secrets`, `crypto.randomBytes`),
    never `Math.random()`/`rand()`.
  - **Token lifecycle:** access tokens expire and are revocable; store server-side
    revocation/rotation state. No non-expiring or non-revocable JWTs. No weak/guessable
    signing secret and no fallback secret (see also task 07).
- Matching PR self-check line.

## Out of Scope
- Per-project migration of existing weak hashes/tokens.

## ARO
- Acceptance: rule merged; a fast/plain password hash, `Math.random()` for a secret,
  or a non-expiring token fails review.
- Risk: migrating stored hashes requires a rehash-on-login path — note as operational.
- Operations: partially `doctor`-automatable (grep for `Math.random`, `md5(`, `sha1(`
  near password, `algorithm: 'none'`).

## Test Plan
- N/A for standards text.

## Security
- Sources: SEC-0093 (weak password hashing), SEC-0203 (weak Fernet KDF), SEC-0202/0263
  (non-expiring / non-revocable JWT), SEC-0264 (`Math.random` for secrets),
  SEC-0073/0077/0209 (JWT secret fallback), SEC-0025 (hardcoded JWT), SEC-0051 (pfx
  password `1234`). BASELY SEC-0002 fix (scrypt) is the positive reference.

## Privacy
- Personal data impact: yes (weak hashing of credentials protecting personal accounts).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Section text + self-check line drafted; cross-referenced to source SEC ids.
