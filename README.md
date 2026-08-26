# AI-Agents Universal Kit

## Deterministic context budgets

The kit ships `.docs/context-manifest.yaml`, validated by JSON Schema, so compatible
runtimes load only the contracts required by a task and declared risks.
AI-GovernanceKit implements `governancekit context inspect` and
`governancekit context build`; see `.docs/context-optimization.md`.

<!-- AI-Agents kit-owned file. Do not edit: `governancekit install-agents --upgrade` replaces it.
     Project-specific rules  -> docs/project-rules.md (never overwritten)
     Operator values ({{…}}) -> .gk/operator.json (untracked; written by `governancekit install-agents`) -->

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
  - `docs/software-overview.md`
  - `docs/limits.md`

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

The kit is installed and updated by the **GovernanceKit CLI**. The legacy shell
installer this repository used to ship in `scripts/` is retired: two installers
writing the same files with no shared source of truth was the root cause of a
family of drift and data-loss defects. The retirement rolls out with the next
release of both kits — a GovernanceKit that carries it also removes stale copies
of the script from governed projects on `--upgrade`; until your installed
GovernanceKit does, an install still delivers the script — and the older contract
text that references it — from the release it pins; both leave together with the
coordinated release.

```bash
pip install "git+https://github.com/EDortta/AI-GovernanceKit.git@<release-tag>"

governancekit --root /path/to/your-project install-agents
```

Pin the CLI itself to a release tag or an inspected commit — never the mutable
default branch (that is this kit's own rule, `security-standards.md` §7). List the
tags with `git ls-remote --tags https://github.com/EDortta/AI-GovernanceKit.git`.
The CLI then downloads this repository at the release tag pinned inside the CLI and
verifies the tarball against a known SHA-256 before writing anything.

Upgrade an existing installation without overwriting project-local context/state:

```bash
governancekit --root /path/to/your-project install-agents --upgrade
```

If you just cloned a project that already has AI-Agents installed, run that
`--upgrade` before the first task in the clone. It refreshes kit-owned files and
prompts for any missing or newly introduced local operator values instead of letting
you inherit another programmer's identity or stale slot state.

Upgrade mode updates kit-owned files and preserves:
- `docs/software-overview.md`
- `docs/limits.md`
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
missing (an install predating `.gk/`) the installer cannot prove the
file is untouched, so it fails closed and preserves it.

Every replaced root file is also copied to `.gk/pre-upgrade/` before being written.

Kit files also say so in their first lines: a short banner naming them kit-owned and
pointing at `docs/project-rules.md`. The release gate asserts the banner is present,
so an edit cannot quietly remove the one thing that tells the next agent where to write.

### Operator values: `{{…}}` slots and `.gk/operator.json`

Kit files never contain the operator's real name or account — they carry `{{…}}` slots
(double braces around an UPPERCASE name), because personal data must not sit in tracked
kit source. The answers live in **`.gk/operator.json`**, written by
`governancekit install-agents` and kept out of git, so each programmer on a project
establishes their own identity rather than inheriting a colleague's name from the
repository. That is the point — the operator's name and account are the personal data
the slot scheme exists to keep out of the repo, and sharing one file would only move
the leak from `AGENTS.md` into a JSON. (A legacy `.credentials/identity.json` from the
retired shell installer is read by `governancekit configure` as a legacy source for
the operator name; `install-agents` itself does not read it.)

On every install and `--upgrade`, the installer re-applies the stored values, so a
filled slot is not drift: the file on disk and the incoming kit version match, and
the upgrade neither burns the value nor asks you to merge one. In an interactive
terminal it prompts for a missing `OPERATOR_NAME` value; in a run without a TTY (closed
stdin — the decision is `isatty`, not a flag) a missing value is **reported as a
warning and the slot stays unfilled** — read the
run's output (and run `governancekit doctor`) rather than relying on the exit code.
`.credentials/` is a directory no upgrade path replaces.

Only *declared* tokens are substituted, so a GitHub Actions `${{ … }}` expression or a
mustache template you ship as an example is left alone. Braces are used rather than
brackets because `[MANDATORY]`, `[PROHIBITED]` and `[DEFAULT]` are content vocabulary
in these documents: a bracket token cannot be told from prose without a hand-maintained
allowlist, a `{{…}}` token always can.

### Migrating an existing or legacy target

A project installed before all this usually has both problems at once: project rules
typed into `AGENTS.md`, and operator values typed over the placeholders. The upgrade
path handles both without guessing: a hand-edited `AGENTS.md` is **preserved** and the
incoming version is written beside it as `AGENTS.md.kit-new` for a manual merge, and
`--migrate-content` extracts legacy project contracts into `docs/project-rules/`:

```bash
governancekit --root /path/to/your-project install-agents --upgrade --migrate-content
```

Important:
- `governancekit doctor` is the readiness gate: it fails until
  - `docs/software-overview.md` has `project_context_ready: yes`
  - `docs/limits.md` has `limits_ready: yes`

After installing, adapt only what is project-specific — fill
`docs/software-overview.md` (product context, architecture, objectives) and
`docs/limits.md` (hard boundaries, prohibited actions, approval gates); both are
mandatory. Keep kit-owned contracts generic: project extensions go in
`docs/project-rules.md`, never into `AGENTS.md` or `.docs/`. Do not hand-copy or
symlink kit files into a target — the installer is the only writer, and `--upgrade`
refuses symlinks inside managed kit directories.

## Programmer Workflow (Required)

Before coding in a target project:
1. Read `docs/software-overview.md` to understand what is being built.
2. Read `docs/limits.md` to understand what is allowed/prohibited.
3. Plan and implement only within those boundaries.
4. If a request conflicts with `docs/limits.md`, stop and request explicit human approval.

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
- `docs/software-overview.md`: product description, architecture, key modules, dependencies.
- `docs/limits.md`: scope boundaries, security boundaries, branch/approval rules, forbidden operations.

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
- Install AI-GovernanceKit as a Python package (`pip install git+https://github.com/EDortta/AI-GovernanceKit.git`)
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
- `.docs/workflows/unattended-run.md`: rules an unsupervised run must satisfy — when it stops, what it may never do, and what it reports in the morning

## Articles

- EN: `.docs/articles/ai-agents-in-vscodium-chat.md`
- PT-BR: `.docs/articles/ai-agents-in-vscodium-chat-ptbr.md`
- ES: `.docs/articles/ai-agents-in-vscodium-chat-es.md`
- Author perspective on the programming path: [I used to turn off the internet for my developers](https://edortta71.medium.com/i-used-to-turn-off-the-internet-for-my-developers-f0d1747ee78f)
