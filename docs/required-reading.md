# Required Reading

**O índice único da leitura obrigatória deste projeto** — inclusive das fontes que
moram fora do checkout. A coluna "Dono" (`.docs/` é do kit e some no `--upgrade`;
`docs/` é do projeto) só importa na hora de **escrever**, não de ler.

<!-- AI-AGENTS:BEGIN kit reading list — gerado por install-agents-kit.sh; edições aqui dentro são substituídas no --upgrade. Escreva fora do bloco. -->
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
| **antes do commit de entrega** (e revisão adversarial de trabalho aprovado) | `.docs/agents/council.md` |
| mudança com impacto em runtime | `.docs/agents/security.md` + `.docs/agents/security-standards.md` |
| tratar dado pessoal | `.docs/agents/privacy-compliance.md` |
| retomar / fechar sessão | `.docs/workflows/session-restore.md`, `.docs/workflows/session-close.md`, `.docs/workflows/session-memory.md` |
| implementar seleção/orçamento de contexto | `.docs/context-optimization.md` |
| adotar, inicializar ou definir o escopo do projeto | `.docs/agents/domains-and-capabilities.md` + `.docs/agents/credentials-operations.md` |
| classificar mudança estrutural | `.docs/agents/architecture-classification.md` |
<!-- AI-AGENTS:END -->

## Deste projeto

Documentos deste repositório. Seção 100% do projeto: nenhum upgrade a toca. Use
`- (none)` se não houver nenhum.

- `docs/napkin-lessons.md` — lições curtas; leia ao retomar trabalho relacionado

## Fontes locais — fora do checkout

Regra não rastreável (credencial, agenda, perfil). Registre **caminho e propósito,
nunca conteúdo**. `obrigatório` reprova no `doctor`; `opcional` só avisa.

| Caminho | Obrigatório | O que é |
|---|---|---|
| `~/.config/USER.md` | opcional | perfil do operador; tom, não governança |
| `~/.local/state/ai-agents/agent-status.json` | opcional | sessões vivas (§8a) |
| `~/.config/email/send.py` | opcional | **o transporte de e-mail deste projeto** — `.docs/workflows/sending-email.md` exige que o projeto diga qual é o seu; este é o daqui, e não vale para nenhum outro |
| `~/.config/email/credentials.conf` | opcional | credenciais do transporte acima; nunca citar |

**Lista de destinatários deste projeto: não existe.** Este repositório não tem
destinatário recorrente nem regra de CC. Todo envio daqui é pontual: pergunte ao
operador quem recebe. `.docs/workflows/sending-email.md` proíbe deduzir isso do e-mail
do harness, que identifica a conta logada e não o operador.

## Por área

Leitura escopada: só quem mexer na área precisa.

<!-- Exemplo: `docs/architecture.md` — ao tocar na camada de orquestração -->

- (none)
