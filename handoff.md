# Handoff

## [2026-07-27] WK-20260727-context-hardening - finished

- Manifest/schema now separate task and risk contracts, enforce a real reserve, and
  use honest `max_sections` / `max_section_tokens` names.
- GovernanceKit runtime hardening and `--version` implemented on the companion branch.
- Validation: AI-Agents `scripts/run-checks.sh` PASS; GovernanceKit 136 tests PASS.
- Added Amazon Q Developer adapter and release enforcement that all adapters load the
  same five-document baseline. Both landing pages document the expanded compatibility.
- Version, merge, push, and tag authorized by the operator.

## [2026-07-27] WK-20260727-context-optimization - finished

- Branch: `feature/uc-006/context-optimization` in AI-Agents and AI-GovernanceKit.
- AI-Agents owns the canonical manifest, manifest/state schemas, baseline budgets,
  reading/telemetry contract, installer propagation, and epic state.
- AI-GovernanceKit owns inspect/build, token-counter seam, deterministic selection,
  budgets, provenance, duplicate reporting, JSON output, and local telemetry.
- Real implementation + runtime selection: 19,692 / 22,000 exact tokens. Mandatory
  rules remain full; savings come from excluding unrelated roles and history.
- Validation: `bash scripts/run-checks.sh` PASS; GovernanceKit pytest 125 PASS;
  real human and JSON CLI paths exercised.
- Not validated: install from a published ref; third-party agent integrations.
- Commit, merge into `main`, and push authorized by the operator.
- Tag, release, and deploy remain unperformed and separately gated.

## [2026-07-24] WK-20260723-agents-md-protegido - Parte 3 IMPLEMENTADA (ready-for-review)

- Status: ready-for-review. Itens A–F do plano
  (`~/.claude/plans/analisa-as-issues-abertas-proud-meadow.md`) implementados e
  verificados. **Nada commitado, taggeado ou empurrado** — Partes 1+2+3 estão na árvore
  de trabalho.
- **A. Sintaxe `{{…}}`** — `AGENTS.md` (3 slots reais), Start Gate reescrito para
  `grep -rnE '\{\{[A-Z][A-Z0-9_]*\}\}'`, `.docs/agents/security-standards.md`,
  `run-checks.sh` check 5. Ocorrências em `docs/issues/**` não mudam (registro histórico).
- **B. Contrato read-only** — banner nas primeiras linhas dos 13 `KIT_ROOT_FILES` +
  seção "Este arquivo é do kit" no topo do `AGENTS.md` com tabela "isto vai em tal
  arquivo". `run-checks.sh` check 8 afirma o banner em todos os 13.
- **C. `.credentials/identity.json` + `apply_identity()`** — renderiza a fonte que entra num
  tempdir e reaponta `SRC_ROOT`; só tokens declarados; sem python3/sem identity → nada
  substituído e o Start Gate trava. `seed_identity()` no install e no upgrade. Manifesto
  grava hash pós-substituição. `run-checks.sh` check 7 afirma que está fora de
  `KIT_OWNED_PATHS` e que `upgrade_kit` chama `apply_identity`.
- **D. `--migrate`** — gateado (TTY + "yes" digitado, sem flag para pular; backup em
  `.gk/pre-migrate/`). Extrai valores usando os slots do template como sonda; grafia
  legada `[TOKEN]` reconhecida como não-preenchida e reescrita para `{{…}}`; só-inserção
  vai para `docs/project-rules.md`; linha do kit reescrita/removida é reportada e não
  tocada; scripts `.sh` nunca migrados por conteúdo; relatório redige os valores.
- **E/F.** `run-checks.sh` (checks 5 ampliado, 7, 8; shellcheck agora é 9); os três
  READMEs documentam `{{…}}`, `identity.json` e o fluxo `--check → --migrate → --upgrade`.
- **Dois defeitos encontrados pelo próprio teste, ambos corrigidos:**
  1. A prosa do Start Gate escrevia `{{TOKEN}}` literal — seria substituída junto com os
     slots reais (colocando o nome do operador no parágrafo que manda mantê-lo fora) e o
     grep do gate acusaria o arquivo para sempre. Prosa agora usa `{{…}}`; novo check no
     `run-checks.sh` proíbe slot genérico literal em `AGENTS.md`/`.docs/`.
  2. `copy_file_replace`/`check_drift` julgavam só pelo manifesto, então depois do
     `--migrate` um arquivo byte a byte idêntico ao que ia ser escrito era marcado como
     deriva, pedindo merge contra si mesmo. Agora `dst == src` é curto-circuito nos dois
     — a mesma regra nos dois, senão relatório e upgrade voltam a discordar.
- Checks: 8 cenários executados de verdade em alvos sintéticos (20 asserções, todas
  PASS); `bash scripts/run-checks.sh` verde; `shellcheck -S error` limpo; sweep de status
  de `docs/issues/` vazio. Script de regressão em
  `<scratchpad>/regression-part3.sh` (não commitado — decisão do operador se vira teste
  do repo).
- Não validado: nenhum alvo real foi tocado; `--migrate` num `AGENTS.md` de kit ANTIGO
  (os 24 alvos) vai cair em MANUAL na maioria, porque o template mudou muito — é o
  comportamento correto, mas o volume de trabalho manual só se mede rodando.
- Next: operador revisa e decide o commit. Depois, gateados e separados: (a) aplicar
  `--check`/`--migrate` aos 33 alvos reais; (b) nova tag + bump dos pins.

---

## [2026-07-23] WK-20260723-agents-md-protegido - ready-for-review

- Status: ready-for-review
- Summary: Varredura das issues abertas (6 soltas + 5 épicos): só uma tinha trabalho
  técnico pendente. Implementada a proteção do `AGENTS.md` no `--upgrade` (opções A+B+C
  do DoD) e feito o sweep de deriva de status em `docs/issues/`.
  **A.** `copy_file_replace` agora julga pelo `.gk/manifest.json` antes de sobrescrever —
  reusando o que `sync_dir` já fazia e que arquivos de raiz nunca receberam. `AGENTS.md`
  entra em `PROTECTED_ROOT_FILES`: divergiu, não é substituído; a versão nova vai para
  `AGENTS.md.kit-new`. Sem manifesto (instalação pré-`.gk/`) → fail-closed. Novas flags
  `--strict` (exit 6 em CI) e `--check` (relatório read-only).
  **B.** Destino oficial para regra de projeto em `docs/project-rules.md` — em `docs/`
  (território do projeto), não em `.docs/` como a issue propunha, porque `.docs/` é
  sincronizado pelo kit. Fora de `KIT_OWNED_PATHS` de propósito; ponteiro nos 6 arquivos
  de regra por ferramenta.
  **C.** Backup de todo arquivo de raiz substituído em `.gk/pre-upgrade/`.
  Sweep: 30 arquivos/pastas renomeados por `git mv` para os status permitidos por
  `.docs/issues/README.md` (`[done]`/`[solved]`/`[superseded*]` não constavam da lista).
- Dry-run: `--check` rodado em 33 alvos reais (read-only, nada escrito — verificado).
  Primeira passada reportou "No drift" em 20 alvos, incluindo o `jk-structure` da issue.
  Era bug do `check_drift`: iterava as chaves do manifesto, então arquivo AUSENTE do
  manifesto ficava invisível — enquanto o `copy_file_replace` trata ausência como
  fail-closed e preserva. Relatório e comportamento discordavam, e o relatório era o
  otimista. Causa: lista de arquivos de raiz duplicada em três lugares. Unificada em
  `KIT_ROOT_FILES`. Resultado real: **24 alvos com conteúdo de projeto no `AGENTS.md`**
  (o maior, `jk-structure-web-canonical`, com +816 linhas sobre a v1.1.1), 3 só com
  placeholders substituídos, 5 idênticos a uma versão do kit.
- Next steps:
  - Operador revisa e aprova; `agents-md-sobrescrito-no-upgrade-[review]` → `[finished]`.
  - Decidir o caso "só placeholders" (3 alvos): hoje eles pedem merge manual a cada
    upgrade, para sempre, por uma customização que o kit espera. Duas saídas na issue.
  - Migrar as regras de projeto dos 24 alvos para `docs/project-rules.md`. Passo do
    operador, um repo de cada vez.
  - Nova tag (`new-tag.sh`) e bump dos pins de instalação — passo separado, gated.
- Blockers/Risks:
  - Risco de regressão aceito e documentado: um alvo cujo `AGENTS.md` diverge por motivo
    legítimo passa a exigir um merge manual uma vez. Hoje a alternativa é perda silenciosa.
  - Caso `python3` ausente verificado por leitura de código (cai no mesmo caminho
    fail-closed já testado sem manifesto), não por execução num host sem `python3`.
- Files changed:
  - `scripts/install-agents-kit.sh` (`copy_file_replace`, `PROTECTED_ROOT_FILES`,
    `check_drift`, `seed_project_rules`, `write_manifest`, `--strict`, `--check`)
  - `scripts/run-checks.sh` (checagem 6, quatro invariantes; shellcheck vira 7)
  - `docs/project-rules.md` (novo starter)
  - `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`,
    `.github/copilot-instructions.md` (ponteiro)
  - `README.md`, `README-ptbr.md`, `README-es.md` (seção nova sobre o `--upgrade`)
  - `docs/issues/` — renomeações + `Resolução` na issue + nota de nomenclatura no épico 004
  - `.docs/agents/council.md`, `docs/issues/001-*/README.md`, `001-*/RESUME.md` (refs)
- Checks/Tests executed:
  - install fresco em alvo limpo -> `docs/project-rules.md` criado, ponteiro presente,
    `AGENTS.md` gravado no manifesto
  - `--upgrade` com alvo intocado -> substitui em silêncio, 14 backups em `.gk/pre-upgrade/`
  - `--upgrade` com `AGENTS.md` editado -> regra sobrevive, `.kit-new` presente, e o
    manifesto **não** absorve o hash do projeto (bug encontrado e corrigido)
  - dois `--upgrade` seguidos -> regra ainda viva na segunda passada
  - `--upgrade --strict` -> exit 6 | `--check --upgrade` e `--strict` sozinho -> exit 2
  - `--upgrade` sem `.gk/` -> fail-closed, não substitui
  - `--check` -> md5 da árvore idêntico antes/depois (escreve nada)
  - 3 testes de regressão negativos -> `run-checks.sh` FALHA em cada um
  - `bash scripts/run-checks.sh` -> all checks passed
  - `shellcheck -S error scripts/install-agents-kit.sh scripts/run-checks.sh` -> limpo
  - `find docs/issues -name '*.md' | grep -vE '\[(draft|ready|started|blocked|review|finished|cancelled)\]'` -> vazio
- Related commits:
  - planned: `fix(install): AGENTS.md protegido no --upgrade + docs/project-rules.md [WK-20260723-agents-md-protegido]`
- Suggested restart prompt:
  - "Continue work_id WK-20260723-agents-md-protegido. Read AGENTS.md, .docs/software-overview.md, .docs/limits.md, docs/project-rules.md e `docs/issues/agents-md-sobrescrito-no-upgrade-[review].md` (seção Resolução) antes de mexer."

---

## Sessão 2026-07-17 (WK-20260717-solid-council)

Branch: `feature/uc-005/solid-council` — 4 commits, **não mergeada**.
Epic `005-solid-council-[review]`.

### Entregue

- **`design-standards.md` completa SOLID** (`8a71052`). Cobria D (§2) e S (§5).
  As três faltantes entram **dentro** das seções que já as ancoram, não como
  §8/§9/§10: Provenance é por seção, e um incidente citado sob dois números lê
  como dois incidentes. Segue o precedente interno (§2 nomeia DI, §5 nomeia SRP).
  **Zero renumeração** — §1/§3/§7 são citados por número em 3 arquivos.
  - §7 ← **OCP** (âncora real: `chrome_op_guard()` morto)
  - §6 ← **Liskov** (âncora real: dataclass com default em todo campo)
  - §2 ← **ISP como `[IMPROVEMENT]`**, não MANDATORY — sem incidente atrás, e §0
    diz que nível 3 sem nível 1 é decoração. Declarado candidato a remoção.
- **`.docs/agents/council.md`** (`80d0921`) — formaliza os "3 adversarial skeptics"
  da epic 002 (6 findings, todos corrigidos e retestados), que rodaram uma vez e
  sumiram. Fronteira contra `governance-precedence.md`: **precedência decide;
  concílio não decide nada**, produz findings. Discordância entre membros vira
  conflito de papéis e sai por porta de uma via. **Votar é PROHIBITED** — contar
  concordância é proxy de evidência.
- **Ligado** (`49e5daa`) — `AGENTS.md` §2 (load rule com os triggers na linha),
  `.docs/agents/README.md`, 2 BLOCKERs no `reviewer.md`, `required=` no
  `run-checks.sh`. Refactor de apoio declarado: `design-standards.md` também
  entrou no `required=` — faltava desde ontem.
- **Artefatos** (`c7b3b4c`) — epic `[review]`, 3 tasks `[finished]`.

### Próximo passo (DO THIS FIRST)

**Decidir o merge de `feature/uc-005/solid-council` para `main`.** `AGENTS.md` §7
exige "sim" explícito; default é não. Nota: este repo **não tem `development`**,
apesar de o §7 dizer que ela é a branch de trabalho — divergência real do kit
contra a própria regra, decisão de topologia própria, fora deste épico.

### Aberto / consciente

- **O `council.md` §4 pede um concílio sobre este próprio épico** — "mudança em
  contrato kit-owned que propaga para outros repos" é trigger MANDATORY, e é
  exatamente o que este trabalho é. Dogfooding óbvio e ainda não feito. Ressalva:
  o §4 manda rodar **depois** do reviewer devolver não-BLOCKER, e nenhum reviewer
  passou por aqui.
- **Risco aceito e registrado**: pelo §0, **um concílio que nada convoca é
  decoração** — e nada o convoca. Escolha deliberada do operador nesta fatia.
  Mitigação: triggers declarados provisórios (n=1) + registro de rodada MANDATORY,
  que é o que gera os dados para corrigi-los. Está escrito no Enforcement status
  do próprio arquivo, não escondido.
- **`not validated:`** o efeito do `council.md` numa rodada real, e o efeito das
  regras O/L/I numa revisão real. Zero rodadas, zero PRs sob elas.
- **Épico 2 fatiado desta sessão**: `WK-20260717-harness-generation` (arnês +
  GovernanceKit). Desenho completo em `docs/issues/005-solid-council-[review]/epic.md`
  § Épico 2. Ordem forçada por handoff duro: **AI-Agents taggeia → só então o GK
  calcula o sha256 e bumpa `DEFAULT_REF`**. `_do_upgrade` pula src path inexistente
  **em silêncio** — GK precisa de checagem explícita, senão renderiza de templates
  que nunca chegaram (§3: a proteção não cobre o que diz cobrir).
- **Achado fora de escopo, não corrigido**: os 11 projetos do operador com hooks
  Claude delegam a um `hook-handler.cjs` com fallback para
  `$HOME/.claude/helpers/hook-handler.cjs`, **que não existe**. Guard que lê como
  guard e não é (§3 puro). Só falham em silêncio se `CLAUDE_PROJECT_DIR` não
  resolver. Relevante para o épico 2 — o kit não deve reproduzir esse padrão.

---

## Sessão 2026-07-16 (WK-20260716-ai-issues-sweep + WK-20260716-git-remote-bare-self-hosted)

### Entregue
- **`.docs/agents/design-standards.md`** (novo) — regras de desenho destiladas de regressões
  reais achadas hoje no Gateway/hub. Tese: o objetivo não é ser SOLID, é não regredir; SOLID
  é meio. Ligado a `AGENTS.md` (§2 load, §3 hard rules), `programmer.md`, `reviewer.md`
  (claim de teste sem arquivo / guard no chamador / escopo pela metade viram **BLOCKER**),
  `README.md` e `.docs/agents/README.md`.
- **`scripts/git-bare-remote.sh` (`gbr`)** + `.docs/workflows/git-bare-remote.md` — issue
  `git-remote-bare-self-hosted` → `[review]`. Gate de segredos varre o **histórico**;
  autonomia imposta pelo script (sem `--yes`, recusa sem tty).
- **Epic 004** — artefatos [review] verificados de verdade (`systemd-analyze verify` limpo,
  `nginx -t` passa em container) e **divergência de topologia registrada** no `epic.md`.

### Próximo passo (DO THIS FIRST)
Ler o bloco **"Status (2026-07-16) — a realidade divergiu do plano"** em
`docs/issues/004-deploy-gateway-hub-proxmox-[draft]/epic.md` e decidir entre as 3 saídas.
Recomendação registrada lá: **fechar a epic como parcialmente superada** (o hub, que era o
motivo, já está no stage4 desde 2026-07-15) e mover o Gateway só quando houver razão própria.

### Aberto / consciente
- `design-standards.md` é **review-gated**: "uma razão para mudar" não tem regex. As duas
  regras mecânicas (claim de teste sem arquivo de teste; repo com fonte e sem alvo de teste)
  valem virar gate no `governancekit doctor` — está escrito na seção Enforcement status.


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
