# Checklist — corte da próxima tag e fechamento do elo 3 (A1)

- work_id: WK-20260804-governancekit-contract-reassessment
- date: 2026-08-26
- executor: **operador** (todos os passos abaixo envolvem push/publicação; nenhum é do agente)

Estado no momento da escrita: `v1.2.1` existe no origin e é o `DEFAULT_REF` do
GovernanceKit (com sha256 pinado). O que falta publicar é o que `development` acumulou
depois dela: os gates da épica 006 (`40f925b`), o contrato de unattended-run
(`95aec8e`) e o batch `feature/006-reconcile-batch` (retirada do instalador shell,
A5). Nada disso chega ao parque instalado até a próxima tag + `DEFAULT_REF` novo.

## Versão recomendada: `v1.3.0`

Minor, não patch: o release adiciona seções `[MANDATORY]` novas ao contrato (§3c
fronteira de repositório; §1b passa a exigir `doctor`; gates incondicionais no
git-delivery §7) **e remove um componente distribuído** (`scripts/install-agents-kit.sh`,
decisão AC-30). Se preferir a convenção cronológica de patch usada até aqui, `v1.2.2`
funciona igual — os passos não mudam; troque o número em todos eles.

## Passos — AI-Agents

1. Mesclar a PR `feature/006-reconcile-batch` → `development` (revisão humana primeiro).
2. Em `development` atualizado:
   - editar `.docs/governancekit-integration.json`: `ai_agents.ref` → `"v1.3.0"`;
   - commit: `release(WK-20260804-governancekit-contract-reassessment): prepara v1.3.0`.
   - `bash scripts/run-checks.sh` → precisa terminar `all checks passed`
     (o check 10c aceita ref à frente da última tag exatamente para este momento).
3. **Antes de sair de `development`: abra este checklist em outra janela** (ou
   copie-o para fora do repo) — o passo seguinte remove `docs/issues/` do disco
   (`merge-to-main.sh` faz `checkout main` e `rm -rf docs/issues` **durante o
   próprio passo 3**), e este arquivo só volta ao disco no passo 5.
   Então: `scripts/merge-to-main.sh` — mescla `development` → `main` excluindo
   memória de sessão. Conferir o resumo que ele imprime.
4. Em `main`, **com o remoto já em dia**: `git pull origin main` primeiro, e só
   então `./new-tag.sh 1.3.0`.
   Motivo: o script cria a tag anotada **antes** do `git pull` interno
   (`new-tag.sh:55` vs `:60`). Se o pull trouxer commits, a tag aponta para o
   estado pré-pull (o tarball publicado não conterá o que o pull trouxe); se o
   pull abortar, a tag local já existe e o guard de imutabilidade queima o
   número. Com o pull feito antes, o script roda o gate (`run-checks.sh`), cria
   a tag e **faz push de `main` + tags** — este é o passo de publicação.
   Se mesmo assim uma tag local ficar órfã sem push (`git ls-remote --tags
   origin | grep v1.3.0` vazio), `git tag -d v1.3.0` e recomece o passo 4 —
   apagar tag **local nunca publicada** não viola a imutabilidade de release.
5. Voltar o checkout para `development` (`git checkout development`) e
   `git push origin development`.

## Passos — GovernanceKit (elo 3)

6. Calcular o checksum do tarball publicado (só depois do push da tag):

   ```bash
   curl -fsSL https://codeload.github.com/EDortta/AI-Agents/tar.gz/v1.3.0 | sha256sum
   ```

   (é a mesma URL que `_download()` usa: `https://codeload.github.com/{repo}/tar.gz/{ref}`.)

7. No repo GovernanceKit, branch `development`, editar
   `governancekit/install_agents.py`:
   - `DEFAULT_REF = "v1.3.0"` (linha ~22);
   - acrescentar à `KNOWN_TARBALL_SHA256`:
     `(REPO, "v1.3.0"): "<sha256 do passo 6>",`
   - **antes de rodar a suíte** — o bump de `DEFAULT_REF` sozinho reprova três
     coisas de lá, e elas têm de entrar no MESMO commit/release (lista completa em
     "Coordenação pendente" no `RESUME.md` desta pasta):
     - `scripts/refresh-kit-snapshot.py` exige `scripts/install-agents-kit.sh`
       dentro do tarball e aborta (`_member` → SystemExit) num release que não o
       traz mais — sem ajuste, o snapshot nunca descreve o release novo e
       `tests/test_kit_drift.py` falha;
     - `tests/test_advanced_usage_docs.py:96` exige que a landing de lá aponte
       `curl` para `.../{DEFAULT_REF}/scripts/install-agents-kit.sh` — com
       `v1.3.0` isso é uma URL 404; o teste e as páginas (`docs/index.html` **e**
       `docs/melhorias.html`) trocam juntos para o fluxo `governancekit`;
     - `tests/test_advanced_usage_docs.py:115-123` exige que toda ocorrência
       `v1.x.y` nas 4 páginas seja igual ao `DEFAULT_REF` — o bump arrasta as
       páginas.
   - rodar a suíte (`python3 -m pytest tests/` ou o runner do repo) — verde.
8. Commit no `development` do GovernanceKit e seguir o fluxo de release de lá —
   **incluindo o merge `development` → `main` e a tag própria** (bump `0.3.x`,
   CHANGELOG): o `pip install git+…` que toda a documentação publica instala a
   branch `main`, então AC-30 e o `DEFAULT_REF` novo só existem para o operador
   depois desse merge. **Nunca publique AC-30 antes do `DEFAULT_REF` apontar para
   `v1.3.0`**: um release intermediário (withdraw + `DEFAULT_REF=v1.2.1`) apaga o
   script do alvo e no mesmo `--upgrade` reinstala o `AGENTS.md` de `v1.2.1` —
   que manda rodá-lo (§1a passo 2 daquela versão). Os dois mudam no mesmo release.

## Verificação de fechamento (elo 4 — parque)

9. Num projeto governado real:

   ```bash
   governancekit --root <projeto> install-agents --upgrade
   governancekit --root <projeto> doctor
   ```

   Esperado: `AGENTS.md` do alvo com §3c e §1b citando `doctor`;
   `scripts/install-agents-kit.sh` do alvo **removido** (withdraw do AC-30);
   `.gk/manifest.json` com `ref: v1.3.0`; `doctor` sem `FAIL` novo.

## Notas

- A partir deste batch o tarball **não carrega mais** `scripts/install-agents-kit.sh`
  — cortar a tag é o que faz o script sumir do release publicado. As tags antigas
  (≤ `v1.2.1`) continuam servindo o script para sempre (tags são imutáveis); a
  instrução `curl | bash` viva nas páginas do GovernanceKit (`docs/index.html` e
  `docs/melhorias.html`) aponta para elas e precisa sair **do lado de lá**
  (needs-coordination — lista completa em "Coordenação pendente" no `RESUME.md`
  desta pasta, que também vai no corpo da PR).
- `new-tag.sh` recusa tag existente (releases são imutáveis) — se `v1.3.0` já
  existir, corte a próxima, nunca mova a tag.
- O pin de checksum faz o elo 2/3 falhar **fechado**: um tarball adulterado ou uma
  tag movida aborta a instalação em vez de instalar silenciosamente outra coisa.
- Ordem importa: checksum (passo 6) só depois do push (passo 4); `DEFAULT_REF`
  (passo 7) só depois do checksum.
