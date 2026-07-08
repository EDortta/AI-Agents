# Handoff Log

Use this file to resume work after clearing sessions.
Most recent entry should be on top.

---

## [2026-07-07] WK-20260707-sec-standards-hardening - draft (issues opened)

- Status: draft — issues opened for review; no standards/code edited
- Summary: Frente #3 of the AI-* epic. Harvested security/privacy lessons from ~15 kit-installed projects (`docs/napkin-lessons.md`), 11 per-project `SECURITY-ALERT-*.md`, and the central `security-issues/` catalogue (~296 SEC-*). Classified each against the 8-section `.docs/agents/security-standards.md`. Opened epic `003-security-standards-hardening-[draft]` with 13 themed task files, each citing source SEC ids, the standards section it extends (or that it is a new section), concrete proposed rule text, and doctor-automatability. Nothing in `security-standards.md` / `AGENTS.md` / `doctor.py` was changed — these are discussion artifacts for operator approval.
- Next steps:
  - Operator reviews the 13 tasks; approve/adjust which become standards additions.
  - For each approved task, apply the rule to `.docs/agents/security-standards.md` + PR self-check in its own follow-up (rename `[draft]`→`[ready]`→…).
  - Automatable subset (tasks 01,02,03,04,05,07,08,09,10,11) → `doctor` checks land in AI-GovernanceKit (ties to epic Frente #4).
- Blockers/Risks:
  - Some tasks classify long-tail SEC ids by their descriptive slug (not each read verbatim); verify representatives before writing final rule text.
  - `governancekit doctor` on AI-Agents is FAIL for pre-existing structural reasons (unfilled kit placeholders, tracked `.credentials/*.example`, missing host identity) — not introduced by this work.
- Files changed:
  - `docs/issues/003-security-standards-hardening-[draft]/` — new epic: `README.md`, `epic.md`, `issues/003-01..13` (13 task files).
- Checks/Tests executed:
  - `git status`: only the new epic folder is added; no tracked file modified by the harvest.
  - `git check-ignore`: epic path is tracked (not gitignored) in the AI-Agents repo.
  - `governancekit doctor`: FAIL pre-existing (see Blockers); no new failure references the epic files.
- Related commits:
  - `<planned>` WK-20260707-sec-standards-hardening

---

## [2026-05-11] WK-20260511-php-delphi-audit-capability - done

- Status: done
- Summary: Added PHP 8.x and Delphi 11/12 audit capability to the kit. Created `docs/workflows/php-audit.md` (18 categories) and `docs/workflows/delphi-audit.md` (18 categories), both following the same structure as `typescript-audit.md`. Updated `programmer.md` with PHP 8.x Rules and Delphi 11/12 Rules sections (auto-activated by file extension). Updated `reviewer.md` with BLOCKER/IMPROVEMENT items for both languages. Ran first live PHP audit on YeAPF2 (`~/Sync/Y2/`) — score 5.5/10. Top findings: 23/69 files missing `declare(strict_types=1)`, 19 unvalidated `json_decode()` calls, zero tooling baseline (no PHPStan, PHP-CS-Fixer, phpunit configured).
- Next steps:
  - Install PHPStan level 5 + PHP-CS-Fixer in YeAPF2 and confirm audit findings programmatically.
  - Apply Quick Wins to YeAPF2: add `declare(strict_types=1)` to 10 core files, wrap 5 `json_decode()` calls, add `default` to 3 critical `switch` blocks.
  - Run Delphi audit on a real `.pas` project from the group to calibrate `delphi-audit.md`.
  - Commit WK-20260511 changes once validated.
- Blockers/Risks:
  - YeAPF2 audit findings not yet confirmed by PHPStan — severity classification based on static grep analysis only.
  - Delphi audit not yet validated against real Delphi code.
- Files changed:
  - `docs/workflows/php-audit.md` — new, 218 lines, 18 categories for PHP 8.x
  - `docs/workflows/delphi-audit.md` — new, 239 lines, 18 categories for Delphi 11/12
  - `docs/agents/programmer.md` — added PHP 8.x Rules and Delphi 11/12 Rules sections
  - `docs/agents/reviewer.md` — added PHP Checks and Delphi Checks sections
- Checks/Tests executed:
  - PHP audit executed manually on `~/Sync/Y2/src/` (86 files) via grep/read analysis.
  - File structure verified: all 4 files present and insertion points confirmed via grep.
  - PHPStan not yet run — pending next session.
- Related commits:
  - adada66: Expand TypeScript audit capability with 2025 best practices (prior session)
  - WK-20260511 changes not yet committed — pending PHPStan validation.
- Suggested restart prompt:
  - "Continue work_id WK-20260511-php-delphi-audit-capability. Read AGENTS.md, docs/software-overview.md, docs/limits.md and this handoff entry. Next: install PHPStan in ~/Sync/Y2/ and confirm the audit findings, then commit the 4 changed files in AI-Agents."

---

## [2026-05-08] WK-20260508-docs-resume-newbie - done

- Status: done
- Summary: Added `governancekit resume` to all documentation surfaces in both repos. Rewrote articles 01 (first-day setup) and 09 (senior workflow) in EN/PT-BR/ES with actual install commands and step-by-step guidance for newbies. Added resume CLI section (§05) to GovernanceKit landing page. Added resume glossary entries to concepts.html (AI-Agents) and intro.html (GovernanceKit) in all 3 languages. Also committed previously untracked GovernanceKit package files (__init__.py, __main__.py, pyproject.toml).
- Next steps:
  - Continue improvement plan: A2 `governancekit init`, B3 end-to-end CLI tests, C1 PyPI prep, D1-D3 policy depth.
- Blockers/Risks:
  - None.
- Files changed:
  - `docs/agents/programmer.md` — resume step added to context loading section
  - `docs/concepts.html` — resume glossary in EN/PT-BR/ES
  - `docs/articles/en/01-first-day-setup.md` — rewritten with install steps
  - `docs/articles/en/09-senior-workflow-and-automation.md` — full CLI daily loop guide
  - `docs/articles/ptbr/01-first-day-setup.md`, `ptbr/09-senior-workflow-and-automation.md`
  - `docs/articles/es/01-first-day-setup.md`, `es/09-senior-workflow-and-automation.md`
  - AI-GovernanceKit: `README.md`, `docs/index.html`, `docs/intro.html`, `docs/software-overview.md`
- Checks/Tests executed:
  - Both repos pushed to GitHub successfully.
- Related commits:
  - AI-Agents 50dd705: Add resume command to docs, rewrite articles 01 and 09 for newbie clarity
  - AI-GovernanceKit 275784f: Add resume command docs, resume section to landing page, and trilingual glossary entries
- Suggested restart prompt:
  - "Run `governancekit resume`. Then read AGENTS.md, docs/software-overview.md, and docs/limits.md. Check the improvement roadmap plan and continue with the next pending item."

---

## [2026-05-07] WK-20260507-personal-touch-1.0.2 - done

- Status: ready-for-review
- Summary: 1.0.2 — USER.md as first-class personal touch mechanism; `.cursorrules` rewritten self-contained; AI-GovernanceKit relationship defined as companion; all tool adapters updated.
- Next steps:
  - Review diff.
  - Run `./new-tag.sh auto` to tag 1.0.2 if accepted.
- Blockers/Risks:
  - No blocker. Main risk: `.cursorrules` §3 session-close format may be too prescriptive; trim if it causes friction in Cursor.
- Files changed:
  - `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`
  - `docs/agents/_shared.md`, `docs/agents/communication.md` (new)
  - `README.md`, `handoff.md`, `docs/napkin-lessons.md`
  - `AI-GovernanceKit/README.md`
- Checks/Tests executed:
  - `bash -n scripts/install-agents-kit.sh` -> pending reviewer run
  - grep `~/.config/USER.md` across adapters -> pending reviewer run
- Related commits:
  - planned: `[WK-20260507-personal-touch-1.0.2] Add USER.md personal touch mechanism and rework Cursor adapter`
- Suggested restart prompt:
  - "Continue work_id WK-20260507-personal-touch-1.0.2. Read AGENTS.md, docs/software-overview.md, docs/limits.md and this handoff entry before coding."

---

## [2026-05-04] WK-20260504-low-token-contract-v2 - review

- Status: ready-for-review
- Summary: Root `AGENTS.md` was reduced into a low-token dispatcher while install gates and detailed safety/workflow rules were preserved in focused docs. Installer now has `--upgrade` for safe existing-target migration.
- Next steps:
  - Review the docs diff.
  - Commit with subject `[WK-20260504-low-token-contract-v2] Reduce root contract token load` if accepted.
- Blockers/Risks:
  - No blocker. Main review risk is whether the compact root contract removed any rule that should remain always-loaded.
- Files changed:
  - `AGENTS.md`
  - `docs/software-overview.md`
  - `docs/limits.md`
  - `docs/agents/_shared.md`
  - `docs/agents/programmer.md`
  - `docs/agents/security.md`
  - `docs/agents/privacy-compliance.md`
  - `docs/workflows/session-restore.md`
  - `docs/workflows/session-close.md`
  - `docs/issues/001-low-token-contract-v2-[review]/`
  - `scripts/install-agents-kit.sh`
  - `README.md`
  - `README-ptbr.md`
  - `README-es.md`
- Checks/Tests executed:
  - `rg -n "project_context_ready|limits_ready|..." .` -> readiness and stale-reference scan completed
  - `rg -n "## [0-9]+\\. (...old section names...)" docs AGENTS.md` -> no stale old section references
  - `wc -l AGENTS.md docs/agents/programmer.md docs/workflows/session-restore.md docs/workflows/session-close.md` -> root contract is 182 lines
  - `bash -n scripts/install-agents-kit.sh` -> passed
  - fresh install smoke test in temp target -> exited 30 and reset target readiness flags to `no`
  - upgrade smoke test in temp target -> preserved project-local state and deleted stale managed files
  - `git diff --check` -> passed
- Related commits:
  - planned: `[WK-20260504-low-token-contract-v2] Reduce root contract token load`
- Suggested restart prompt:
  - "Continue work_id WK-20260504-low-token-contract-v2. Read docs/issues/001-low-token-contract-v2-[review]/RESUME.md first."

## [2026-07-01] WK-20260701-dotdocs-kit-layout - source-side restructure

- Status: ready-for-review
- Summary: Moved all kit-owned docs from `docs/` to `.docs/`; `docs/` is now 100% project territory. Installer aligned to `.docs/` with fresh-install seeding of `docs/`, upgrade preserving `docs/` + readiness files, and a new idempotent `migrate_legacy_layout()` (backs up, promotes `docs/project/*`→`docs/`, reports conflicts honestly). All references swept; ownership rule rewritten in AGENTS.md.
- Next steps:
  - Coordinate merge with the twin Python installer in `AI-GovernanceKit` (same work_id) before merging — layouts must not diverge.
  - Human review of tutorial prose in `.docs/articles/` for remaining contextual "docs/" mentions.
- Blockers/Risks:
  - Twin repo `AI-GovernanceKit` not yet aligned (divergence issue opened there).
- Files changed:
  - `scripts/install-agents-kit.sh`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README*.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.gitignore`, `docs/required-reading.md`, and the moved `.docs/` tree (agents, workflows, articles, icons, software-overview.md, limits.md, index.html, concepts.html, issues/templates, issues/README.md).
- Checks/Tests executed:
  - `bash -n scripts/install-agents-kit.sh` -> passed
  - fresh install in temp target -> kit under `.docs/`, `docs/` seeded, readiness reset to `no`, exit 30
  - legacy-migration upgrade in temp target -> kit moved to `.docs/`, `docs/project/*` promoted, backup created
  - conflict scenario -> clean items promoted, colliding item kept + reported, honest completion message
  - 2nd upgrade run -> no re-migration (idempotent); backup not clobbered
  - residual kit-owned `docs/` reference scan -> 0
  - 3 adversarial skeptics (workflow) -> 6 findings, all fixed and retested
- Related commits:
  - planned: `[WK-20260701-dotdocs-kit-layout] Move kit to .docs/, free docs/ for the project`
- Suggested restart prompt:
  - "Continue work_id WK-20260701-dotdocs-kit-layout. Read docs/issues/002-dotdocs-kit-layout-[review]/RESUME.md and coordinate with the AI-GovernanceKit twin before merging."

## [2026-07-02] WK-20260702-branch-ascii-and-identity - ready-for-review

- Status: ready-for-review
- Summary: Implemented two governance-policy issues in the kit AGENTS.md.
  (1) Added "Allowed characters (MANDATORY)" subsection to branch naming:
  restricts branches to `^[a-zA-Z0-9/_-]+$`, prohibits quotes/spaces/shell
  metacharacters, mandates ASCII transliteration+validation before checkout,
  and hardened the `awt` worktree helper with the same regex guard (exit 6).
  (2) Added "8b. Individual identity (MANDATORY)" section defining the minimum
  identity schema (operator_name, host_id, instance_path, sibling_path,
  assigned_ports, branch_ownership) plus the 3 mandatory rules, cross-linked to
  the companion GovernanceKit runtime issue `collect-and-enforce-per-host-identity`.
- Next steps:
  - Operator review of both AGENTS.md blocks and the awt guard.
  - Land companion runtime issue in AI-GovernanceKit.
- Blockers/Risks:
  - Doc/contract change + one defensive validation in a helper. Low risk.
- Files changed:
  - AGENTS.md (branch section + section 8b)
  - scripts/agent-worktree.sh (branch-name regex guard)
  - docs/issues/branch-names-ascii-only-[review].md (renamed from [draft])
  - docs/issues/mandate-per-host-programmer-identity-[review].md (renamed from [draft])
- Checks/Tests executed:
  - `bash -n scripts/agent-worktree.sh` -> passed
  - manual regex check: `'"development"'` rejected, `development` accepted
- Related commits:
  - none (left in working tree per instruction)
- Suggested restart prompt:
  - "Continue work_id WK-20260702-branch-ascii-and-identity. Both issue files are [review]; land the AI-GovernanceKit companion."

## [2026-07-08] WK-20260708-deploy-gw-hub-vm - epic-drafted

- Status: ready-for-review
- Summary: Criado o épico `004-deploy-gateway-hub-proxmox-[draft]` (docs/issues) para
  deploy de AI-Gateway + AI-hub numa **VM Proxmox dedicada** em 192.168.7.200, atrás de
  nginx interno, em sub-paths. Topologia escolhida pelo operador (1 VM aditiva) sobre a
  alternativa de 3 LXCs + wipe da caixa (companion `adaptive-gliding-alpaca`, cujo gate de
  limpeza segue aberto). 6 tasks: root_path do gateway, unit systemd do app (inexistente
  hoje), Host-allowlist env-configurável do hub + token no unit, bundle nginx, runbook da
  VM (GATED) e propagação de token + e2e.
- Next steps:
  - Operador revisa as 6 issues; avançar `[draft]`→`[ready]` por rename.
  - Implementar 004-01..04 (código/artefatos versionados) antes de qualquer apply.
  - Apply em 192.168.7.200 permanece passo separado, gated (política não-autônoma).
- Blockers/Risks:
  - Host-allowlist do hub é hardcoded → 403 atrás de proxy (durável em 004-03; fallback
    nginx `Host: localhost` em 004-04). Login ChatGPT é interativo (janela humana única).
  - Infra intocável do host (nginx :80, `/enviar-arquivo/`→:5055, túnel :2203, OpenVPN,
    DHCP vmbr2, wifi) deve sobreviver — VM é aditiva.
- Files changed:
  - docs/issues/004-deploy-gateway-hub-proxmox-[draft]/README.md
  - docs/issues/004-deploy-gateway-hub-proxmox-[draft]/epic.md
  - docs/issues/004-deploy-gateway-hub-proxmox-[draft]/issues/004-01..06-*.md (6 tasks)
- Checks/Tests executed:
  - Estrutura conferida contra `.docs/issues/README.md` + templates + épico 003 real -> ok
  - `find` da árvore do épico -> 8 arquivos, naming `[draft]` consistente
- Related commits:
  - none (arquivos em working tree; sem commit por ora)
- Suggested restart prompt:
  - "Continue work_id WK-20260708-deploy-gw-hub-vm. Read AGENTS.md, docs/software-overview.md, docs/limits.md e o épico 004 (docs/issues) antes de implementar. Apply em 192.168.7.200 é gated."

## [YYYY-MM-DD] <work_id> - <stage>

- Status: <in-progress|blocked|ready-for-review|done>
- Summary: <short status summary>
- Next steps:
  - <step 1>
  - <step 2>
- Blockers/Risks:
  - <risk or none>
- Files changed:
  - <path>
- Checks/Tests executed:
  - <command> -> <result>
- Related commits:
  - <hash or planned commit message>
- Suggested restart prompt:
  - "Continue work_id <work_id>. Read AGENTS.md, docs/software-overview.md, docs/limits.md and this handoff entry before coding."
