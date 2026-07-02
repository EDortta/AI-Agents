# AGENTS.md


## Prefixo obrigatório nas mensagens ao operador

Toda mensagem de texto enviada diretamente ao operador (`[OPERATOR_NAME]`) **deve começar
com "`[OPERATOR_NAME]`, "** — incluindo a vírgula e o espaço.

Aplica-se a: respostas no chat, resumos de sessão, perguntas de clarificação.
Não se aplica a: tool calls, conteúdo de arquivos, corpos de issue/PR.


Low-token universal operating contract for repository agents.
Primary objective: secure, correct, maintainable changes with predictable execution.

Instruction precedence:
1. system/runtime instructions
2. this `AGENTS.md`
3. target-repository role/workflow docs loaded by this file
4. local user preferences (`~/.config/USER.md` if present)

---

## 1. Start Gate

### 1a. Placeholders do operador preenchidos (pré-condição absoluta)

Este kit é instalado via `governancekit install-agents`, que preenche
interativamente os tokens `[PLACEHOLDER]` nos arquivos instalados.

Antes de qualquer outra ação, verifique se ainda existem tokens não preenchidos
neste arquivo ou em `.docs/agents/*.md`:

```
grep -r '\[OPERATOR_NAME\]\|\[SMTP_ACCOUNT\]\|\[PROJECT_SLUG\]\|\[GITHUB_OWNER\]' \
     AGENTS.md .docs/agents/
```

Se qualquer token `[PLACEHOLDER]` for encontrado:

1. **Pare imediatamente.** Não execute nenhuma ação — nem leitura de código,
   nem inspeção, nem branch, nem commit.
2. Informe ao operador:
   > "Este kit contém placeholders não preenchidos: `[TOKEN]`. Execute
   > `governancekit install-agents` (ou preencha manualmente) e reinicie."
3. Não prossiga até que o operador confirme que os tokens foram substituídos.

Este gate existe por conformidade com a LGPD (Art. 46) e para garantir que
dados pessoais do operador nunca sejam embutidos literalmente em arquivos
rastreados. Não há exceção a esta regra.

---

### 1b. Projeto alvo configurado

Before implementation, identify the target repository.

Required target-project files:
- `.docs/software-overview.md`
- `.docs/limits.md`
- `docs/required-reading.md` — and every project-specific document it lists

Required readiness flags:
- `project_context_ready: yes`
- `limits_ready: yes`
- `docs/required-reading.md` lists the project docs to read (or `- (none)`)

If either file is missing or not ready:
1. Stop implementation.
2. Do not inspect, refactor, edit, branch, or run project checks.
3. Tell the programmer to configure the missing file(s).
4. Briefly explain:
   - `.docs/software-overview.md`: product, stack, users, modules, key behavior.
   - `.docs/limits.md`: allowed/prohibited agent actions, security boundaries, workflow constraints.

Every task must stay within `.docs/limits.md` unless a human explicitly approves a boundary update.

Source-kit exception: when maintaining this reusable kit itself, a human may approve edits to these gates/templates before implementation starts.

Optional user profile:
- If `~/.config/USER.md` exists, read it to adapt communication style (tone, depth, decision framing) to the user's profile.
- This satisfies precedence level 4 (local user preferences).
- Only communication is adapted; governance behavior and quality gates are unchanged.

---

## 2. Load Only What Is Needed

Always read first:
- this file
- `.docs/software-overview.md`
- `.docs/limits.md`
- `docs/required-reading.md` (and every document it lists)

Documentation ownership:
- `docs/` is 100% project territory — record project-specific docs there. The
  installer never overwrites it (`docs/required-reading.md`, `docs/napkin-lessons.md`,
  issue folders, and any project docs live here).
- `.docs/` plus `AGENTS.md` and per-tool rule files are kit-owned and overwritten
  by `install-agents --upgrade`. Never hand-edit kit-owned files in a target
  project; put project knowledge under `docs/`. Exception: `.docs/software-overview.md`
  and `.docs/limits.md` are seeded by the kit but filled and preserved per project.

Then load only relevant contracts:
- coding or issue solving: `.docs/agents/programmer.md`
- code/PR review: `.docs/agents/reviewer.md`
- issue or PR automation: `.docs/agents/issue-automation.md`
- runtime-impacting change: `.docs/agents/security.md`
- personal data handling: `.docs/agents/privacy-compliance.md`
- session restore: `.docs/workflows/session-restore.md`
- session close: `.docs/workflows/session-close.md`

Do not load historical issue docs, handoff notes, or lessons unless resuming active work or they are directly relevant.

---

## 3. Hard Rules

- Security over speed.
- Correctness over convenience.
- Maintainability over cleverness.
- Prefer simple, explicit implementations.
- Solve root cause, not only symptoms.
- Keep scope tight to the issue/request.
- Preserve existing contracts unless the issue explicitly changes them.
- Do not introduce hidden behavior or undocumented side effects.
- Do not expose secrets, tokens, credentials, or sensitive raw payloads.

---

## 4. Execution Loop

For implementation work:
1. Restore active work context if one exists.
2. State issue understanding, scope, risks, impacted files, and contract notes.
3. Create/switch branch only after explicit human permission.
4. Implement the smallest durable safe fix.
5. Run impacted lint/typecheck/tests.
6. Review diff for scope, duplication, clarity, contracts, and secrets.
7. Close the session with handoff/resume updates.

Never start implementation on `main` or `master`.

---

## 5. Quality Gates

For impacted modules only, unless shared tooling/contracts changed:
- lint passes
- typecheck/compilation passes
- tests pass
- no exposed secrets

Tests are required for behavior, API, auth, persistence, shared-interface, or regression-prone changes.
Tests may be N/A only for docs/comments/metadata with no runtime effect; justify N/A explicitly.

When changing public contracts, report:
- backward compatible: yes/no
- contract changed: yes/no
- migration required: yes/no
- downstream consumers affected: yes/no

If no persistence change, report: `No model/migration changes`.

---

## 6. GitHub/Jira Guard

Prefer `jkctl.py` for issue/PR workflows when present.

Never create an issue or PR with empty or placeholder-only title/body.
Never run:
- `gh issue create` without `--body` or `--body-file`
- `gh pr create` without `--body` or `--body-file`

Issue bodies must include context, objective, scope, ARO, test plan, and DoD.
PR bodies must include summary, related issue, changed areas, tests, risks/rollback, security impact, and validation checklist.

---

## 7. Branch, Commit, Artifacts

Branch naming:
- Jira: `feature/<JIRA-KEY>/<short-description>`
- GitHub: `feature/gh-<issue-number>/<short-description>`
- undercover/local: `feature/uc-<NNN>/<short-description>`

#### Allowed characters (MANDATORY)

Branch names must use only plain ASCII in the class `[a-z0-9/_-]`
(uppercase permitted solely inside an issue/Jira key, e.g. `UBR-1027`).
The final name must match `^[a-zA-Z0-9/_-]+$`.

[PROHIBITED] in a branch name — they silently break tooling, prompts, and refs:
- quotes of any kind (`"` `'` `` ` ``), even from a shell-escaping mistake;
- whitespace (spaces, tabs);
- shell/glob metacharacters: `$ & * ? ! ; | < > ( ) { } [ ] \ ^ ~ : @ = + , #`
  and a leading `-`;
- accented or non-ASCII letters and any Unicode symbol, homoglyph, or
  invisible character;
- `..`, a trailing `/`, a trailing `.lock`, or a trailing `.` (invalid git refs).

[MANDATORY] When deriving a branch slug from an issue title/slug: transliterate
to ASCII, lowercase, replace every disallowed character with `-`, collapse
repeats, strip leading/trailing `-`. Verify the final name matches
`^[a-zA-Z0-9/_-]+$` **before** `git checkout -b` (or `git worktree add -b`).
Never pass an issue title verbatim to git branch/checkout. An invalid name →
stop and report; do not create the branch.

Rules:
- Obtain explicit human permission before creating a branch.
- Create/switch branch before first code change.
- Work only on that branch.
- Default PR base is `development` unless explicitly required otherwise.
- Commit only after applicable checks are green, unless impossible and documented.
- Do not commit caches, local runtime data, backups, credentials, `.env*`, or token files.

---

## 8. Session Memory

Use session memory only for active work:
- `docs/issues/<epic>/RESUME.md`
- `handoff.md`
- current issue/task file
- `docs/napkin-lessons.md`

`RESUME.md` is the source of truth for the immediate next action and must contain exactly one clear `Next Step (DO THIS FIRST)`.

At session close, update:
- `handoff.md`
- active `RESUME.md`
- `docs/napkin-lessons.md`

Planning/development docs must include:
- `work_id: WK-YYYYMMDD-<short-slug>`
- `date: YYYY-MM-DD`

---

## 8b. Individual identity (MANDATORY)

Kit docs (`AGENTS.md`, role guides, `RESUME.md`, `handoff.md`) are **shared** by
several programmers/agents/hosts. On shared-branch projects (e.g. the jk-structure
simulator) multiple hosts may run on the same branch and the same governance
files. Without data that **individualizes** each host/instance, silent failures
appear: two hosts commit on the same branch unaware of each other, ports and
local runtime artifacts collide, and it becomes impossible to audit "which host
did what" from the shared docs.

Every governed project must carry a per-instance identity file (e.g.
`WORKSPACE.md`) with at least this minimum schema:

- `operator_name` — human operator (also used as the message prefix)
- `host_id` — machine/instance identifier
- `instance_path` — absolute path of this instance's checkout
- `sibling_path` — path(s) of sibling instance(s), when any
- `assigned_ports` — ports reserved by this instance
- `branch_ownership` — who operates which branch on shared-branch projects
  (includes the same-branch guard before creating/switching a branch)

Mandatory rules:

- [MANDATORY] Before any action, read/establish this instance's identity file.
  If it is absent → **STOP** and ask the operator to create it. Do not inspect,
  branch, edit, or commit until identity is established.
- [MANDATORY] Same-branch guard — on a shared-branch project, before creating or
  switching a branch, check whether another host owns the current branch
  (`branch_ownership`/sibling identity). If so, **warn** and do not operate that
  same branch without explicit alignment.
- [MANDATORY] Distinguish **shared** artifacts (contract, docs) from
  **individual** ones (identity file, assigned ports, local runtime artifacts).
  Never treat individual state as shared, or vice versa.

The executable collection/enforcement of this identity is the companion runtime
issue `collect-and-enforce-per-host-identity` in **AI-GovernanceKit** (the
"how"); this contract owns the "what and why".

---

## 9. Security Decision

For every delivery, classify security impact as:
- `no security impact`
- `mitigated security impact`
- `known temporary risk requiring explicit human acceptance`

If not `no security impact`, document affected surface, abuse path, mitigation, and residual risk.

---

## 10. Done

Done means:
- scope respected
- root cause handled or limitation documented
- contracts preserved or declared changed
- impacted checks/tests executed or justified
- security impact classified
- session handoff/resume updated
- review-ready summary produced


---

## Sending Email

When a task requires sending email, credentials and mechanism live in `~/.config/email/` — **local-only, never tracked in any repo**.

| File | Purpose |
|------|---------|
| `~/.config/email/credentials.conf` | SMTP account (`[SMTP_ACCOUNT]`) + app password |
| `~/.config/email/send.py` | CLI/script helper — reads credentials automatically |

```bash
# Plain text
python3 ~/.config/email/send.py --to dest@example.com --subject "Assunto" --body "Corpo"

# HTML body
python3 ~/.config/email/send.py --to dest@example.com --subject "Assunto" --body "<b>ok</b>" --html

# Multiple recipients
python3 ~/.config/email/send.py --to a@x.com --to b@x.com --subject "Assunto" --body "Corpo"

# Body from stdin
echo "Corpo" | python3 ~/.config/email/send.py --to dest@example.com --subject "Assunto"
```

Never hardcode or commit credentials. Always read from `~/.config/email/credentials.conf`.

