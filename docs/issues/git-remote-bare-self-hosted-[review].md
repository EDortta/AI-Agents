# Remote Git auto-hospedado (bare repo) como facilidade do kit

- work_id: WK-20260711-git-remote-bare-self-hosted
- date: 2026-07-11
- status: [draft]

## Problema

Vários projetos do operador vivem apenas no disco local, sem nenhum remote
(`git remote -v` vazio). O backup, quando existe, é o Syncthing replicando a
pasta `.git/` junto com o resto — o que **não é backup versionado**: corromper o
repo replica a corrupção, e um `git reset --hard` errado se propaga.

GitHub (mesmo privado) não é a resposta óbvia para todos eles. Projetos como o
GestaoContasFernanda carregam dados financeiros e documentação de sistema
pessoal; empurrar o histórico inteiro para um host de terceiros é uma decisão de
risco que o operador tende a adiar — e assim o projeto fica sem remote nenhum,
que é o pior dos mundos.

Quase todo operador que usa o kit já tem um servidor próprio (VPS, homelab, a
máquina onde a aplicação roda) com acesso SSH por chave. Nesse servidor, um
**bare repo** (repositório sem working tree, só objetos e refs — o que o GitHub
hospeda por baixo) resolve o caso em três comandos. O que falta não é
tecnologia: é a facilidade estar no kit, documentada e roteirizada, para que
ninguém precise redescobrir o procedimento nem hesitar sobre segurança.

## Definition of Done

1. **Documentação** no kit explicando o quê e o porquê: o que é um bare repo, por
   que não se pode dar push para um repo com working tree na branch empurrada, e
   quando esta opção é preferível a GitHub/GitLab (dados sensíveis, projeto
   pessoal, servidor já existente) e quando não é (colaboração, CI, PRs).

2. **Helper roteirizado** (`scripts/git-bare-remote.sh` ou equivalente, seguindo
   o padrão de `agent-worktree.sh`), com no mínimo:

   - `init <user@host> <caminho> [nome-do-remote]` — cria o bare no servidor via
     SSH (`git init --bare`), adiciona o remote localmente, faz o primeiro push
     das branches e configura o upstream.
   - `status` — mostra se o projeto atual tem remote e se está sincronizado.

   O script deve ser idempotente (rodar duas vezes não quebra nada) e falhar de
   forma legível se o caminho remoto já existir e não for um bare repo.

3. **Gate de segurança antes do primeiro push** — a parte que justifica isto ser
   uma facilidade do kit em vez de um punhado de comandos no README. Antes de
   empurrar, o helper precisa verificar e **exigir confirmação explícita**
   quando encontrar risco:

   - segredos versionados no histórico (não só no working tree): varredura por
     `.env`, `*.credentials*`, chaves privadas, tokens — o `.gitignore` de hoje
     não protege o que já foi commitado ontem;
   - permissões do diretório remoto (o bare não deve ficar world-readable num
     servidor compartilhado);
   - confirmação de que o host de destino é de fato do operador.

   Um remote errado é irreversível na prática: o histórico sai da máquina.

4. **Regra de autonomia**: criar o bare mexe num servidor remoto. Isso cai sob a
   proibição de ação autônoma em ambiente remoto já vigente no kit — o agente
   pode preparar e explicar os comandos, mas a execução exige aprovação
   explícita do operador. Deixar isso escrito na doc da facilidade, não só no
   `AGENTS.md`.

## Esboço (o núcleo é pequeno; o valor está no entorno)

```bash
# no servidor, uma vez
git init --bare /srv/git/<projeto>.git

# na máquina do operador
git remote add origin <user>@<host>:/srv/git/<projeto>.git
git push -u origin main
```

## Fora de escopo

- Hooks no servidor para deploy automático a partir do push (`post-receive`).
  Deploy é passo gateado por aprovação humana; misturar as duas coisas convida
  exatamente o acidente que a regra de deploy existe para impedir.
- Mirror/espelhamento para GitHub. É uma issue companheira, se algum dia fizer
  sentido.
- Gestão de chaves SSH e provisionamento do servidor. Pressupõe-se que o
  operador já entra na máquina por chave.

## Resolução (2026-07-16) — WK-20260716-ai-issues-sweep

Os quatro itens da DoD entregues.

1. **Documentação**: `.docs/workflows/git-bare-remote.md`. Cobre o que é um bare repo,
   **por que** não se pode dar push para a branch que um repo com working tree tem
   checada (o git recusa: o push faria o working tree discordar do HEAD sem tocar os
   arquivos — daí um "remote" que é um clone normal funcionar até o dia em que você
   empurra a branch em que ele está sentado), e quando esta opção é ou não preferível a
   GitHub/GitLab.
2. **Helper**: `scripts/git-bare-remote.sh` (`gbr`), no padrão do `agent-worktree.sh`
   (mesmo cabeçalho-porquê, mesmo `install`/`uninstall` por symlink, mesma validação de
   entrada, mesmos códigos de saída). Comandos: `init`, `status`, `scan` (o gate sozinho,
   sem empurrar nada), `install`, `uninstall`.
   **Idempotente**: reusa bare existente e remote já correto. **Falha legível** quando o
   path existe e não é bare (exit 5), quando o remote já aponta para outro lugar (exit 5 —
   repontar em silêncio redirecionaria seus pushes) e quando o path é relativo/tem `..`/tem
   metacaractere de shell (exit 6).
3. **Gate de segurança**: varre o **histórico** (`git log --all`, `git rev-list --all`),
   não o working tree — porque o `.gitignore` não protege o que foi commitado ontem, e
   apagar o arquivo num commit novo não adianta: o blob velho continua no histórico que
   você vai empurrar. Procura nomes (`.env`, `*.credentials*`, chaves privadas, keystores,
   `.netrc`, `.pgpass`, service accounts) e conteúdo (PEM, AWS/GitHub/Slack/OpenAI/Google).
   Mais: permissão do diretório remoto e confirmação explícita de que o host é seu.
   Gate estreito de propósito — gate que grita lobo é ignorado, e gate ignorado é pior que
   gate nenhum.
4. **Regra de autonomia**: escrita na doc da facilidade, como a issue pede — e **imposta
   pelo próprio script**: `confirm()` recusa quando stdin não é terminal, então pipeline
   ou shell dirigido por agente não consegue responder aos prompts. **Não existe flag
   `--yes`, por desenho** — seria exatamente o buraco que a regra existe para fechar
   (antecedente: o `deploy.sh --yes` de 2026-06-25).

Indexado em `README.md` (Structure) e `.docs/workflows/dev-workflow-integration.md`.

**Validado — executado de verdade, não só `bash -n`:**

| Cenário | Resultado |
|---|---|
| `status` sem remote | mostra "(none)" + o comando para criar |
| `scan` em histórico limpo | exit 0 |
| `scan` com `.env` commitado **e apagado depois** | exit 1, acha o blob no histórico |
| `init` sem terminal (agente/pipeline) | **recusa**, exit 3 — resiste até a `yes yes \|` |
| `init` com path relativo / `..` / `$(...)` | recusa, exit 6 |
| `init` caminho feliz (ssh simulado) | cria bare mode **700**, adiciona remote |
| `init` 2ª vez | reusa bare, sem erro (idempotente) |
| `init` contra repo não-bare | recusa, exit 5, com explicação |

**Dois bugs reais que só o teste de execução pegou:**

1. `die "msg" 3` imprimia `"gbr: msg 3"` — o código de saída vazava para dentro da
   mensagem (`$*` em vez de `$1`).
2. `git init --bare --shared=0600` produz modo **2700** (bit setgid), e o gate de
   permissão disparava alarme falso num diretório que **é** privado. Pior: `--shared`
   existe para *alargar* acesso a um grupo — o oposto do que um remote privado quer.
   Agora é `git init --bare` + `chmod 700`, e o gate julga só os bits de grupo/outros.

**Não validado:** o `git push` real por ssh (o teste usou um stub de ssh; o push em si é
`git push`, não lógica deste script). Criar o bare num servidor de verdade é passo do
operador, por definição desta issue.

## Origem

Levantado em 2026-07-11 durante trabalho no GestaoContasFernanda: o repositório
não tem remote nenhum, um `git push` do operador não tinha para onde ir, e a
conversa sobre o que seria um bare repo no servidor da aplicação mostrou que a
facilidade é genérica — vale para todo mundo que usa o kit, não para aquele
projeto.
