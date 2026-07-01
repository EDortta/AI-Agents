# 01 - Setup do Primeiro Dia

## História feliz: Lia começou certo
Lia é programadora júnior. Ela quer usar agentes sem perder controle do projeto. No primeiro dia, ela não começa codando. Primeiro, prepara o terreno: contexto, limites e regras. O agente passa a trabalhar a favor dela, não no escuro.

## O que é seu (programador)
- Escrever o contexto real em `.docs/software-overview.md`.
- Definir limites reais em `.docs/limits.md`.
- Decidir o que pode e o que não pode ser feito.
- Validar se os readiness flags viraram `yes`.

## O que é do agente
- Ler esses arquivos antes de planejar/editar.
- Respeitar limites e avisar quando houver conflito.
- Propor plano coerente com o contexto.

## Passo a passo

**1. Copie o policy pack para o seu projeto.**

```bash
git clone https://github.com/EDortta/AI-Agents.git
cp -r AI-Agents/AGENTS.md AI-Agents/.docs AI-Agents/docs AI-Agents/handoff.md AI-Agents/CLAUDE.md ./
```

No mínimo você precisa de `AGENTS.md`, `.docs/software-overview.md`, `.docs/limits.md` e `handoff.md`.

**2. Instale o GovernanceKit (a CLI companion).**

```bash
pip install git+https://github.com/EDortta/AI-GovernanceKit.git
```

Requer Python 3.10+. Sem dependências externas.

**3. Valide o setup.**

```bash
governancekit doctor
```

Você verá uma lista de verificações. A maioria vai falhar numa instalação nova — isso é esperado. Corrija cada linha `[FAIL]` antes de continuar.

**4. Preencha `.docs/software-overview.md`** com o propósito do produto, stack tecnológico e módulos principais.

**5. Preencha `.docs/limits.md`** com o que os agentes podem e não podem fazer neste projeto.

**6. Marque os readiness flags.**

Abra os dois arquivos e defina:
```
project_context_ready: yes
limits_ready: yes
```

Rode `governancekit doctor` novamente — deve passar agora.

**7. Gere o mapa de código.**

```bash
governancekit map
```

Isso cria `docs/codemap.md` — um índice Markdown dos seus arquivos e símbolos. Faça commit. Os agentes leem isso no início da sessão em vez de escanear arquivo por arquivo.

**8. Só então peça implementação ao agente.**

## Prompt sugerido
"Rode `governancekit resume` primeiro, depois leia AGENTS.md, software-overview e limits. Confirme entendimento e proponha um plano curto antes de codar."

## Definição de pronto
- `governancekit doctor` passa em todas as verificações.
- `docs/codemap.md` existe e está commitado.
- O agente sabe o que fazer e o que evitar.
- Você consegue reiniciar qualquer sessão sem perder contexto.
