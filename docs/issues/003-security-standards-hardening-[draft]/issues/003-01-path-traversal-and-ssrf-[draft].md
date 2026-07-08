# Task: Forbid unvalidated caller-supplied file paths and URLs (path traversal & SSRF)

## Metadata
- work_id: WK-20260707-sec-pathtraversal-ssrf
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Add a new section to `security-standards.md` requiring that any filesystem path or
URL taken from a caller be validated against a server-fixed allowlist before use.

## In Scope
- New standards section (proposed §9 "Path and URL inputs"):
  - **Filesystem paths:** never expose a raw path as a free client field. Resolve the
    input and require `resolved.is_relative_to(base)` against a server-fixed base;
    reject absolute paths, `..`, and symlinks that escape the base. Filenames derive
    from a strict pattern (e.g. `^[A-Za-z0-9._-]+$`) or a server-generated UUID —
    never client string concatenated into a path.
  - **Outbound fetch (SSRF):** any server-side or browser fetch of a caller-supplied
    URL requires auth **and** a domain allowlist, and must reject private, loopback,
    and link-local targets (and validate after DNS resolution, not just the scheme).
- Matching PR self-check line.

## Out of Scope
- Fixing the individual offending endpoints (tracked in their own SEC-* alerts).

## ARO
- Acceptance: rule text merged into `security-standards.md`; a caller-supplied path or
  URL reaching file I/O or an outbound request without allowlist validation fails review.
- Risk: legitimate path/URL features need an explicit, named allowlist — accepted cost.
- Operations: partially `doctor`-automatable (grep for user-supplied path/URL params
  reaching `open()/Path()/requests.get()`), but primary enforcement is review-gated.

## Test Plan
- N/A for the standards text. When applied, reference-implementation tests: reject
  `../`, absolute path, and a `127.0.0.1`/`169.254.169.254` URL.

## Security
- Sources: SEC-0033 (AI-Gateway client-controlled image `output_dir`/`reference_image_path`
  → arbitrary write + credential exfil), SEC-0035 (AI-hub `/browse?url=` authenticated
  SSRF/exfil), SEC-0141 (Nuomed compare-face raw uuid → arbitrary write), SEC-0108
  (AI-hub arbitrary local file upload), SEC-0282 (jk-monitor set-source SSRF, protocol-only
  check), SEC-0152/0196/0285 (path base escapes). Kit's own components are offenders.

## Privacy
- Personal data impact: indirect (path traversal enabled credential/PII exfiltration).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- Section text + self-check line drafted and cross-referenced to the source SEC ids.
