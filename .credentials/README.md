# Credentials Folder

Portuguese version: [README-ptbr.md](./README-ptbr.md)  
Spanish version: [README-es.md](./README-es.md)

This folder stores local credentials used by AI agents and automation.

## Security Rules

- Never commit real credentials.
- Keep this folder local-only on developer machines.
- Use `.example` files as templates.

## Files

- `programmer.token`: GitHub token used by programmer-agent workflows.
- `reviewer.token`: GitHub token used by reviewer-agent workflows.
- `jira.json`: Jira API credentials.

Templates provided:
- `programmer.token.example`
- `reviewer.token.example`
- `jira.json.example`

## Setup

1. Create real files from templates:
- `cp programmer.token.example programmer.token`
- `cp reviewer.token.example reviewer.token`
- `cp jira.json.example jira.json`

2. Fill each file with real values.
3. Ensure file permissions are restricted.

Example:

```bash
chmod 600 programmer.token reviewer.token jira.json
```

## Required By

- `AGENTS.md` credential handling rules
- automation steps for GitHub/Jira operations
