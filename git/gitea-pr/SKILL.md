---
name: gitea-pr
description: Publica a feature branch num Gitea self-hosted e abre o PR via API, lendo o token de um secret manager ou variável de ambiente (GITEA_API_TOKEN). Fluxo obrigatório para repos com a branch principal protegida — push direto em main sempre rejeitado. Use quando o usuário pedir para abrir PR no Gitea, publicar branch, ou ao fechar trabalho num repo com CI self-hosted.
---

# gitea-pr — push de branch + PR no Gitea (TOOL · v1.0.0 · Alex Jesus)

Para repositórios Gitea com a `main` protegida, push direto é **sempre
rejeitado** pelo pre-receive — mesmo para administradores. Esta skill cobre o
fluxo obrigatório completo: push da feature branch → PR via API → URL para
merge manual na UI (ou via a skill irmã `gitea-pr-merge`).

## Quando NÃO usar

- Repositório sem remote Gitea configurado — adicione o remote primeiro (ver
  Adaptação) ou use o fluxo do forge que o repo realmente usa (ex.: `gh pr create`).
- Para **mergear** um PR — isso é da skill irmã `gitea-pr-merge` (gate de
  CI verde + confirmação humana).
- Branch atual é `main`/`master` — nunca abrir PR de `main` → `main`.
- Quando há divergência entre a branch local e a remota — resolva manualmente;
  esta skill nunca faz force-push.

## Procedimento

### 1. Pre-flight

```bash
branch=$(git branch --show-current)
```

Abortar se branch for `main` ou `master` — nunca abrir PR de `main` → `main`.

Verificar que a instância Gitea está acessível (ex.: `curl -sk
https://<GITEA_HOST>/api/v1/version`; se o Gitea rodar em container no próprio
host, `docker ps --filter name=gitea` também serve).

### 2. Detectar repo e host Gitea a partir do remote

```bash
gitea_remote_url=$(git remote -v \
  | grep push \
  | grep 'gitea' \
  | awk '{print $2}' \
  | head -1)
# Exemplos de formato:
#   git@<GITEA_HOST>:<OWNER>/<repo>.git
#   ssh://git@<GITEA_HOST>:2222/<OWNER>/<repo>.git
```

Extrair:
- **host** — domínio (ex: `<GITEA_HOST>`)
- **owner/repo** — path após o host (ex: `<OWNER>/<repo>`)
- **API base** — `https://<host>/api/v1`

Se não houver remote Gitea configurado, abortar com instrução para adicionar:
```
git remote set-url --add --push origin git@<GITEA_HOST>:<OWNER>/<repo>.git
```

### 3. Push da branch para o Gitea

```bash
git push "$gitea_remote_url" "$branch" 2>&1
```

- Se a branch **não existe** no Gitea → cria (new branch).
- Se já existe e é fast-forward → atualiza normalmente.
- Se divergência → **abortar**; nunca force-push automático.
- Erro de auth/network → reportar e aguardar humano.

### 4. Ler o token de API (fail-closed)

Leia o token de um **secret manager ou variável de ambiente**
(`GITEA_API_TOKEN`) — por exemplo via SOPS+age, `pass`, Vault, ou um `export`
seguro da sessão:

```bash
TOKEN="${GITEA_API_TOKEN:?token ausente}"   # ou: TOKEN=$(<seu secret manager>)
```

Boas práticas (obrigatórias na skill):
- Reusar **um único** token de longa vida (ex.: `<nome-do-token>`, escopo
  `write:repository`, do usuário `<OWNER>`) — **não** gerar um token novo por
  operação (`gitea admin user generate-access-token`): versões antigas do Gitea
  não têm API/CLI de revogação e o padrão acumula tokens órfãos.
- O valor vive **apenas na variável do processo** — nunca impresso, nunca
  persistido em arquivo.
- Se `TOKEN` vier vazio (chave ausente/secret manager indisponível),
  **abortar** (fail-closed) e instruir a (re)provisionar o token na UI do
  Gitea (Settings → Applications) ou via
  `gitea admin user generate-access-token --username <OWNER> --scopes
  write:repository --token-name <nome-do-token> --raw`, custodiando-o no seu
  secret manager. **Rotação:** gerar token novo → atualizar o secret →
  revogar o antigo conforme a administração do seu Gitea.

### 5. Auto-fill do título e body

**Título** (se não fornecido via argumento):
- Primeira linha do último commit, truncada em 72 chars.

**Body** (markdown):
```markdown
## Sumário

<primeiros 2 parágrafos do corpo do último commit, ou lista --oneline desde main>

## Mudanças

<git diff origin/main..HEAD --stat>

## Plano de validação

- [ ] CI verde
- [ ] Revisão humana
- [ ] Smoke test (se UI/DB/auth tocados)

---
🤖 Gerado com Claude Code via /gitea-pr
```

Se o repo usa referências de rastreabilidade nos commits (ex.: `@spec RF-x.x.x`),
detectá-las e adicionar uma seção `## Refs`.

### 6. Criar PR via API

```bash
curl -sk -X POST \
  -H "Authorization: token $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n \
      --arg head "$branch" \
      --arg base "${BASE:-main}" \
      --arg title "$TITLE" \
      --arg body "$BODY" \
      '{head:$head,base:$base,title:$title,body:$body}')" \
  "https://${GITEA_HOST}/api/v1/repos/${OWNER_REPO}/pulls" \
| jq '{number:.number, url:.html_url, state:.state}'

# Para mergear um PR existente via API (use após review):
# ⚠️ Campo obrigatório: "MergeMessageField" (capital M) — "merge_message_field" retorna 405
# curl -sk -X POST -H "Authorization: token $TOKEN" -H 'Content-Type: application/json' \
#   -d '{"Do":"merge","MergeMessageField":"<mensagem>","delete_branch_after_merge":false}' \
#   "https://${GITEA_HOST}/api/v1/repos/${OWNER_REPO}/pulls/${PR_NUMBER}/merge"
```

HTTP 201 = sucesso. Qualquer outro código → reportar body bruto.

### 7. Output

```
PR #N aberto: https://<GITEA_HOST>/<owner>/<repo>/pulls/N
Branch: <branch> → main
Próxima ação: revisar + mergear via UI do Gitea
```

## Argumentos

- *(vazio)* — detecta tudo automaticamente (branch, repo, título, body)
- `--title "..."` — override do título
- `--base <branch>` — base diferente de `main`
- `--dry-run` — mostra o que faria sem criar o PR

## NUNCA

- Tentar `git push ... main` para o Gitea (branch protegida — sempre rejeitado)
- Imprimir ou persistir o valor do token, ou decifrá-lo para um arquivo
- Gerar um token novo por operação (`generate-access-token`) — reuse o token de longa vida custodiado
- Force-push automático
- Mergear o PR nesta skill (merge tem gate próprio — ver `gitea-pr-merge`)

## Adaptação

- **`<GITEA_HOST>`** — o domínio da sua instância Gitea self-hosted; a skill o
  detecta do remote, mas os exemplos acima usam o placeholder.
- **`<OWNER>`/`<repo>`** — usuário/organização e repositório no Gitea,
  extraídos do path do remote.
- **Fonte do token** — `GITEA_API_TOKEN` pode vir de qualquer secret manager
  (SOPS+age, `pass`, Vault, secrets do CI) ou de variável de ambiente da
  sessão; ajuste a linha de leitura do passo 4. Mantenha o invariante:
  fail-closed sem token, valor só na variável do processo.
- **`<nome-do-token>`** — nomeie o token de longa vida de forma identificável
  (ex.: `agent-skills`) para facilitar auditoria e rotação.
- **Base default** — `main` aqui; ajuste se a base de integração do repo for
  outra (ex.: `develop`).
- **Wrappers por repo** — repos podem ter um comando local fino
  (ex.: `.claude/commands/gitea-pr.md`) com defaults preenchidos (host,
  owner/repo); o wrapper delega para esta skill — não duplica a lógica.
