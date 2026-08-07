# Sending Email

Where the transport and the credentials live, and the rule that they never enter a
repository.

`../agents/credentials-operations.md` covers *configuring providers during project
adoption*; this file covers the one capability an agent may need mid-task.

Load this file only when a task requires sending email.
If this file conflicts with `/AGENTS.md`, follow `/AGENTS.md`.

## Sending Email

When a task requires sending email, credentials and mechanism live in `~/.config/email/` — **local-only, never tracked in any repo**.

| File | Purpose |
|------|---------|
| `~/.config/email/credentials.conf` | SMTP account (`{{SMTP_ACCOUNT}}`) + app password |
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
