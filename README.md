# AI-Agents Universal Kit

## Deterministic context budgets

The kit ships `.docs/context-manifest.yaml`, validated by JSON Schema, so compatible
runtimes load only the contracts required by a task and declared risks.
AI-GovernanceKit implements `governancekit context inspect` and
`governancekit context build`; see `.docs/context-optimization.md`.

<!-- AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .credentials/identity.json (untracked, per-programmer) -->

![AI-Agents Logo](./.docs/icons/logo.png)

Portuguese version: [README-ptbr.md](./README-ptbr.md)  
Spanish version: [README-es.md](./README-es.md)

If you want to understand how an AI agent can help in your development journey, take a look at [ai-agents-in-vscodium-chat.md](./.docs/articles/ai-agents-in-vscodium-chat.md).

## Purpose

This repository is a reusable starter kit for agent governance in software projects.
It provides:
- a global contract: `AGENTS.md`
- role contracts: `.docs/agents/`
- issue templates/workflow: `docs/issues/`
- two mandatory context files for each target project:
  - `.docs/software-overview.md`
  - `.docs/limits.md`

## Designed For Which AI Agents/Tools

This kit was designed to be portable across well-known coding agents and IDE assistants, especially:
- Codex-style agents (using `AGENTS.md`)
- Claude-based agents (using `CLAUDE.md`)
- GitHub Copilot (using `.github/copilot-instructions.md`)
- Cursor (using `.cursorrules`)
- Windsurf/Cascade (using `.windsurfrules`)
- Gemini-based assistants (using `GEMINI.md`)
- Amazon Q Developer (using `.amazonq/rules/ai-agents.md`)

Core rule:
- `AGENTS.md` is the global contract.
- Tool-specific files adapt that same contract to each ecosystem.
- Every adapter loads the same five-document baseline; the release gate checks this
  and upgrades restore kit-owned adapters so projects cannot silently weaken them.

## How to Use in Another Project

For every installer parameter, identity files, exit codes, migration paths, and
CI examples, see [Advanced usage details](https://edortta.github.io/AI-Agents/advanced-usage.html).

Preferred: clone and inspect before running, especially the first time:

```bash
git clone --branch v1.1.6 https://github.com/EDortta/AI-Agents.git
less AI-Agents/scripts/install-agents-kit.sh
./AI-Agents/scripts/install-agents-kit.sh --target /path/to/your-project
```

Shortcut, if you accept running a script straight from GitHub (pinned to a
release tag, not the mutable `main` branch):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EDortta/AI-Agents/v1.1.6/scripts/install-agents-kit.sh) \
  --target /path/to/your-project
```

Upgrade an existing installation without overwriting project-local context/state:

```bash
./scripts/install-agents-kit.sh --target /path/to/your-project --upgrade
```

If you just cloned a project that already has AI-Agents installed, run that
`--upgrade` before the first task in the clone. It refreshes kit-owned files and
prompts for any missing or newly introduced local operator values instead of letting
you inherit another programmer's identity or stale slot state.

Upgrade mode updates kit-owned files and preserves:
- `.docs/software-overview.md`
- `.docs/limits.md`
- `docs/project-rules.md`
- `handoff.md`
- `docs/napkin-lessons.md`
- project issue folders under `docs/issues/`
- `docs/undercover-issues/`
- `.credentials/`

### Where project-specific rules go

`AGENTS.md` is the first file every agent reads, which makes it the first place
people write project rules — and it is kit-owned, so `--upgrade` replaces it.
Write project rules in **`docs/project-rules.md`** instead. The installer seeds it
once and never touches it again; it is deliberately absent from the kit manifest,
and that absence is what guarantees it.

`AGENTS.md` is nonetheless **protected**: once its content differs from what the kit
installed, `--upgrade` keeps your version, writes the new one to `AGENTS.md.kit-new`
beside it, and tells you. Nothing is overwritten silently. When the manifest is
missing (an install predating `.gk/`, or no `python3`) the installer cannot prove the
file is untouched, so it fails closed and preserves it.

Every replaced root file is also copied to `.gk/pre-upgrade/` before being written.

Kit files also say so in their first lines: a short banner naming them kit-owned and
pointing at `docs/project-rules.md`. The release gate asserts the banner is present,
so an edit cannot quietly remove the one thing that tells the next agent where to write.

### Operator values: `{{…}}` slots and `.credentials/identity.json`

Kit files never contain the operator's real name or account — they carry `{{…}}` slots
(double braces around an UPPERCASE name), because personal data must not sit in tracked
kit source. The values live in **`.credentials/identity.json`**:

```json
{
  "values": { "OPERATOR_NAME": "…", "SMTP_ACCOUNT": "…" },
  "refs":   { "EMAIL_CREDENTIALS": "~/.config/email/credentials.conf" }
}
```

`values` holds literals; `refs` holds **paths** to credential files — never a secret
inline. The file is **never tracked**: `.credentials/.gitignore` keeps it out of git, so
each programmer on a project establishes their own identity rather than inheriting a
colleague's name from the repository. That is the point — the operator's name and
account are the personal data the slot scheme exists to keep out of the repo, and
sharing one file would only move the leak from `AGENTS.md` into a JSON.

On every install and `--upgrade`, the installer resolves these required values first.
In an interactive terminal it prompts for empty `OPERATOR_NAME` and `SMTP_ACCOUNT`
values; in a non-interactive run it fails before copying kit files and names what must
be configured. It stores the file with mode `0600`, then re-applies the values, so a
filled slot is not drift: the file on disk and the incoming kit version match byte for
byte, and the upgrade neither burns the value nor asks you to merge one.
`.credentials/` is the one directory no upgrade path touches.

Only *declared* tokens are substituted, so a GitHub Actions `${{ … }}` expression or a
mustache template you ship as an example is left alone. Braces are used rather than
brackets because `[MANDATORY]`, `[PROHIBITED]` and `[DEFAULT]` are content vocabulary
in these documents: a bracket token cannot be told from prose without a hand-maintained
allowlist, a `{{…}}` token always can.

`python3` is required to validate and apply identity. The installer fails early when it
is unavailable or when required values cannot be collected.

### Migrating an existing target: `--check` → `--migrate` → `--upgrade`

A project installed before all this usually has both problems at once: project rules
typed into `AGENTS.md`, and operator values typed over the placeholders. `--migrate`
separates them mechanically, once:

```bash
./scripts/install-agents-kit.sh --target /path/to/your-project --check     # what drifted
./scripts/install-agents-kit.sh --target /path/to/your-project --migrate   # separate it
./scripts/install-agents-kit.sh --target /path/to/your-project --upgrade   # now clean
```

`--migrate` reads operator values back out of the target — using the template's own
slots as the probe, so a value is only recorded when the surrounding line still matches
exactly — and writes them to `.credentials/identity.json`. A file whose only difference from the
kit is *inserted* lines is unambiguous, so those lines move to `docs/project-rules.md`
and the file returns to the kit version. Anything else — a kit line rewritten or
deleted — is reported and left untouched: the kit does not guess what an edit meant.
Legacy `[TOKEN]` spellings are rewritten to `{{…}}`; a slot that was never filled is
recognised as unfilled, not mistaken for a value. Shell scripts are reported, never
content-migrated.

It writes to the target, so it is gated: an interactive TTY plus a typed confirmation,
with no flag to skip it, and a copy of everything it can touch in `.gk/pre-migrate/`.

In CI, make an unmerged protected file fail the run (the upgrade still completes):

```bash
./scripts/install-agents-kit.sh --target /path/to/your-project --upgrade --strict
```

Important:
- the installer uses a readiness gate and exits with non-zero until:
  - `.docs/software-overview.md` has `project_context_ready: yes`
  - `.docs/limits.md` has `limits_ready: yes`

1. Copy (or symlink) these assets into the target project:
- `AGENTS.md`
- `.docs/agents/`
- `docs/issues/`
- `.docs/software-overview.md`
- `.docs/limits.md`

2. Adapt only what is project-specific:
- Fill `.docs/software-overview.md` with product context, architecture, and objectives.
- Fill `.docs/limits.md` with hard boundaries (in/out-of-scope, prohibited actions, approval gates).
- These two files are mandatory and must be edited by the programmer so the agents-kit can correctly recognize what to do in the project.

3. Keep core contracts generic:
- Preserve the structure and intent of `AGENTS.md` and core files in `.docs/agents/`.
- Add project extensions only when necessary.

## Programmer Workflow (Required)

Before coding in a target project:
1. Read `.docs/software-overview.md` to understand what is being built.
2. Read `.docs/limits.md` to understand what is allowed/prohibited.
3. Plan and implement only within those boundaries.
4. If a request conflicts with `.docs/limits.md`, stop and request explicit human approval.

During issue work:
1. Organize work under epic folders in `docs/issues/`.
2. Use templates in `.docs/issues/templates/`.
3. Include privacy checks when personal data is involved:
- `.docs/issues/templates/privacy-checklist.template.md`

Session close at each stage:
1. Update `handoff.md` with status, next steps, blockers, changed files, and checks.
2. Add short lessons learned to `docs/napkin-lessons.md`.
3. Follow `.docs/workflows/session-close.md`.

Work identifier convention:
- Use `work_id` format: `WK-YYYYMMDD-<short-slug>`.
- Keep same `work_id` in planning docs, handoff entries, and related commit messages.

## Suggested Minimal Project Setup

When adopting this kit, update first:
- `.docs/software-overview.md`: product description, architecture, key modules, dependencies.
- `.docs/limits.md`: scope boundaries, security boundaries, branch/approval rules, forbidden operations.

Then run a pilot issue using `.docs/issues/templates/task.template.md` to validate the process.

## Personal Touch via USER.md

Agents can adapt their communication style to your profile when a `USER.md` file is present at `~/.config/USER.md`.

This file is:
- **Global** — lives in your home config directory, not in any project repo
- **Optional** — the kit works without it; governance behavior is unchanged
- **User-specific** — generated from a profile assessment (DISC, Jung, Spranger, etc.) or written manually

When present, agents read it at session start to adapt tone, depth, decision framing, and language to the user.

Convention:
- Path: `~/.config/USER.md`
- Format: Markdown, free-form sections describing communication preferences, profile type, and pitfalls to avoid
- Never committed to any project repository

Tools like [ConhecerTe](https://conhecerte.com.br) can generate a ready-to-use `USER.md` from a structured profile assessment.

---

## Companion: AI-GovernanceKit

[AI-GovernanceKit](https://github.com/EDortta/AI-GovernanceKit) is the runtime enforcement layer for this policy pack.

- **AI-Agents** = policy pack — the "what and why" of governance (this repo)
- **AI-GovernanceKit** = runtime CLI — the "how" of enforcement (doctor, session automation, CI hooks)

They are designed to work together but have no formal dependency:
- Install AI-Agents by copying files into a target project
- Install AI-GovernanceKit as a Python package (`pip install ai-governancekit`)
- GovernanceKit's `doctor` command validates the AI-Agents file structure automatically

---

## Credentials Setup

Use:
- `.credentials/README.md`

Templates available:
- `.credentials/programmer.token.example`
- `.credentials/reviewer.token.example`
- `.credentials/jira.json.example`

## Structure

- `AGENTS.md`: universal execution contract
- `scripts/install-agents-kit.sh`: installer (local run or direct GitHub raw execution)
- `scripts/agent-worktree.sh` (`awt`): one git worktree per `work_id`, for parallel agents
- `scripts/git-bare-remote.sh` (`gbr`): self-hosted git remote on a server you own,
  with a secret gate over the committed history (`.docs/workflows/git-bare-remote.md`)
- `.docs/agents/`: role-level contracts (programmer, reviewer, issue automation, security, privacy)
- `.docs/agents/design-standards.md`: design rules that keep the next change from
  breaking the last one (distilled from real regressions)
- `.docs/agents/security-standards.md`: security rules the delivered code must satisfy
- `docs/issues/`: local issue structure and templates
- `handoff.md`: resumable handoff log between sessions
- `docs/project-rules.md`: project-specific rules; project-owned, never overwritten
- `docs/napkin-lessons.md`: concise lessons learned log
- `.docs/workflows/session-close.md`: end-of-stage/session close checklist
- `.docs/workflows/dev-workflow-integration.md`: optional automation hook for stage-end session close

## Articles

- EN: `.docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `.docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `.docs/articles/ai-agents-in-vscodium-chat-es.md`
- Author perspective on the programming path: [I used to turn off the internet for my developers](https://edortta71.medium.com/i-used-to-turn-off-the-internet-for-my-developers-f0d1747ee78f)
