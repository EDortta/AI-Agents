## Sempre, antes de qualquer issue

| Documento | Dono | O que é |
|---|---|---|
| `AGENTS.md` | kit | contrato universal de operação |
| `docs/software-overview.md` | kit→**projeto** | produto, stack, módulos, comportamento |
| `docs/limits.md` | kit→**projeto** | fronteiras duras do agente |
| `docs/project-rules.md` | **projeto** | regras que valem só aqui |

## Conforme o papel do trabalho

| Vai fazer | Leia também (tudo do kit) |
|---|---|
| codar / resolver issue | `.docs/agents/programmer.md` + `.docs/agents/design-standards.md` |
| revisar código ou PR | `.docs/agents/reviewer.md` + `.docs/agents/design-standards.md` |
| automatizar issue/PR | `.docs/agents/issue-automation.md` |
| implementar, revisar ou declarar entrega pronta | `.docs/workflows/delivery-loop.md` |
| criar branch/issue/PR, commitar, mesclar em `main`, deploy | `.docs/workflows/git-delivery.md` |
| enviar e-mail | `.docs/workflows/sending-email.md` |
| armar ou revisar esteira sem supervisão (noturna, cron, autopilot) | `.docs/workflows/unattended-run.md` |
| **antes do commit de entrega** (e revisão adversarial de trabalho aprovado) | `.docs/agents/council.md` |
| mudança com impacto em runtime | `.docs/agents/security.md` + `.docs/agents/security-standards.md` |
| tratar dado pessoal | `.docs/agents/privacy-compliance.md` |
| retomar / fechar sessão | `.docs/workflows/session-restore.md`, `.docs/workflows/session-close.md`, `.docs/workflows/session-memory.md` |
| implementar seleção/orçamento de contexto | `.docs/context-optimization.md` |
| adotar, inicializar ou definir o escopo do projeto | `.docs/agents/domains-and-capabilities.md` + `.docs/agents/credentials-operations.md` |
| classificar mudança estrutural | `.docs/agents/architecture-classification.md` |
