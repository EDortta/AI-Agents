# 01 - First Day Setup

## Happy story: Lia started the right way
Lia is a junior developer. She wants AI speed without losing control. On day one, she does not start coding. She first prepares context and boundaries, so the agent works with clarity.

## What is yours (programmer)
- Write real project context in `.docs/software-overview.md`.
- Define hard boundaries in `.docs/limits.md`.
- Set readiness flags to `yes`.

## What is the agent's
- Read these files before planning or editing.
- Respect boundaries and flag conflicts.
- Propose a plan consistent with project reality.

## Step by step

**1. Copy the policy pack into your project.**

```bash
git clone https://github.com/EDortta/AI-Agents.git
cp -r AI-Agents/AGENTS.md AI-Agents/.docs AI-Agents/docs AI-Agents/handoff.md AI-Agents/CLAUDE.md ./
```

Or copy only the files you need. At minimum you need `AGENTS.md`, `.docs/software-overview.md`, `.docs/limits.md`, and `handoff.md`.

**2. Install GovernanceKit (the CLI companion).**

```bash
pip install git+https://github.com/EDortta/AI-GovernanceKit.git
```

Python 3.10+ required. No other dependencies.

**3. Validate the setup.**

```bash
governancekit doctor
```

You will see a list of checks. Most will fail on a fresh install — that is expected. Fix each `[FAIL]` line before moving on.

**4. Fill `.docs/software-overview.md`** with your product purpose, tech stack, and main modules.

**5. Fill `.docs/limits.md`** with what agents are allowed and not allowed to do in this project.

**6. Set the readiness flags.**

Open both files and set:
```
project_context_ready: yes
limits_ready: yes
```

Run `governancekit doctor` again — it should pass now.

**7. Generate the code map.**

```bash
governancekit map
```

This creates `docs/codemap.md` — a Markdown index of your files and symbols. Commit it. Agents read this at session start instead of scanning files one by one.

**8. Only then request implementation.**

## Prompt starter
"Run `governancekit resume` first, then read AGENTS.md, software-overview, and limits. Confirm constraints and propose a short plan before coding."

## Definition of done
- `governancekit doctor` passes all checks.
- `docs/codemap.md` exists and is committed.
- The agent knows what to do and what to avoid.
- You can restart any session without losing context.
