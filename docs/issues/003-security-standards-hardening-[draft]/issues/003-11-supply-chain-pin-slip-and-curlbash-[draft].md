# Task: Supply chain — pin immutable refs, slip-protect extraction, no mutable curl|bash

## Metadata
- work_id: WK-20260707-sec-supplychain
- date: 2026-07-07
- owner: [OPERATOR_NAME]
- related_commit: <planned>

## Parent Epic
- 003-security-standards-hardening

## Objective
Extend §7 (Supply chain and release) beyond "checksum-verify the installer" to cover
mutable-ref installs, archive extraction safety, remote-script execution, and CDN SRI.

## In Scope
- §7 additions:
  - **Installers pin an immutable tag/commit** and verify a published SHA-256 before
    running — never install from a mutable branch (`@main`).
  - **Archive extraction is slip-protected** (`tarfile.extractall(filter="data")` /
    validate members) — no `../` or absolute-path writes.
  - **Post-download script execution is opt-in**, not automatic.
  - **Docs never advertise `curl | bash` of a mutable ref;** pin + checksum in examples.
  - **Third-party deps are pinned;** CDN `<script>` uses SRI.
- Matching PR self-check line.

## Out of Scope
- Per-project dependency upgrades (own SEC-* alerts).
- Note: the kit installer already pins `DEFAULT_REF` + `KNOWN_TARBALL_SHA256` and uses
  `filter="data"`; this task codifies those as **standards** and closes the doc/`curl|bash`
  and release-gate residuals.

## ARO
- Acceptance: §7 additions merged; an install-from-`main`, an unfiltered `extractall`,
  an auto-run downloaded script, or an unpinned `curl|bash` doc example fails review.
- Risk: pinning increases upgrade friction — mitigated by the `upgrade-agents` flow (Frente #4).
- Operations: partially `doctor`-automatable (grep docs/scripts for `curl .* | bash`,
  `extractall(` without `filter=`, `@main`).

## Test Plan
- N/A for standards text.

## Security
- Sources: SEC-0105 (kit installed from mutable `main`, auto-runs `awt install`),
  SEC-0106 (tar-slip in extraction), SEC-0215 (promoted `curl|bash` of mutable ref),
  SEC-0109 (curl|bash no integrity), SEC-0256 (installer integrity — done), SEC-0231
  (CDN script without SRI), SEC-0225/0288/0239 (unpinned/vulnerable deps),
  SEC-0180/0233/0234 (outdated images/toolchain). Napkin: GovernanceKit
  WK-20260706-security-standards-distill (§7 release-gate `run-checks.sh` still a no-op
  in `new-tag.sh`).

## Privacy
- Personal data impact: no (integrity/RCE class).

## Session-Close
- Add/update handoff entry in `handoff.md`: yes
- Add napkin lesson in `docs/napkin-lessons.md`: yes

## DoD
- §7 additions + self-check line drafted; residual release-gate no-op noted; cross-referenced to SEC ids.
