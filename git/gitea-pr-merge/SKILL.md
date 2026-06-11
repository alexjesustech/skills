---
name: gitea-pr-merge
description: Revisa e mergeia um PR num Gitea self-hosted via API, lendo o token de um secret manager ou variável de ambiente (GITEA_API_TOKEN). Mostra diff, commits, mergeabilidade e status de CI; só mergeia após checks verdes + confirmação humana explícita. Complementa a skill gitea-pr (que abre o PR). Use quando o usuário pedir para revisar, fechar ou mergear um PR do Gitea.
---

# gitea-pr-merge — revisar + mergear PR no Gitea (TOOL · v1.0.0 · Alex Jesus)

Par da skill `gitea-pr` (que **abre** o PR). Esta cobre o fechamento: revisar o
diff e o status de CI, e só então mergear na `main` protegida — via API, pois
push direto em `main` é sempre rejeitado. **Merge na `main` exige checks verdes +
revisão/confirmação humana.** Nunca mergear no improviso.

## Quando NÃO usar

- Para **abrir** o PR — isso é da skill irmã `gitea-pr`.
- Sem confirmação humana explícita do merge nesta sessão — o gate do passo 3
  não é negociável.
- Com CI `pending`/`failure` ou `mergeable:false`, salvo `--force-merge`
  autorizado pelo dono com motivo registrado.
- Em repositório sem remote Gitea — use o fluxo do forge que o repo usa.

## Procedimento

### 1. Pre-flight — identificar PR, repo e host

Número do PR: do argumento (`/gitea-pr-merge 5`) ou, se omitido, detectar o PR
aberto da branch atual.

```bash
branch=$(git branch --show-current)
gitea_url=$(git remote -v | grep push | grep gitea | awk '{print $2}' | head -1)
# git@<GITEA_HOST>:<OWNER>/<repo>.git  →  host=<GITEA_HOST>  owner_repo=<OWNER>/<repo>
```

Extrair `GITEA_HOST`, `OWNER_REPO`, `API=https://$GITEA_HOST/api/v1`. Verificar
que a instância está acessível (ex.: `curl -sk "$API/version"`). Sem remote
Gitea → abortar. O token (passo 4) é necessário só a partir da leitura
autenticada; a leitura pública pode dispensar token se o repo for público.

### 2. Revisão — reunir o que o humano precisa para decidir

```bash
# metadados do PR (estado, mergeabilidade, base/head, sha do head)
curl -sk "$API/repos/$OWNER_REPO/pulls/$PR" \
  | jq '{state, mergeable, title, base:.base.ref, head:.head.ref, sha:.head.sha}'

# status combinado de CI no sha do head (success | pending | failure | error)
curl -sk "$API/repos/$OWNER_REPO/commits/$HEAD_SHA/status" \
  | jq '{state, checks:[.statuses[]|{context,state,target_url}]}'

# commits e estatística do diff (local é mais barato que a API)
git --no-pager log --oneline "origin/${BASE}..${HEAD_REF}" 2>/dev/null || \
  curl -sk "$API/repos/$OWNER_REPO/pulls/$PR/commits" | jq -r '.[]|"\(.sha[0:8]) \(.commit.message|split("\n")[0])"'
git --no-pager diff --stat "origin/${BASE}...${HEAD_REF}" 2>/dev/null
```

Apresentar ao humano: título, base←head, **mergeable**, **status de CI**, lista de
commits e diff --stat. Para mudança de código não-trivial, oferecer uma revisão
de código no diff antes de mergear. Para docs puras, o diff --stat costuma bastar.

### 3. Gate de merge (NUNCA pular)

Só prosseguir para o merge se **todas** forem verdadeiras:
- `state == "open"` e `mergeable == true` (sem conflito);
- status de CI `== "success"` (ou o repo não tem checks);
- o humano **confirmou explicitamente** o merge nesta sessão.

Se CI estiver `pending` → **esperar/avisar**, não mergear. Se `failure`/conflito →
**parar** e reportar. Override só com confirmação explícita do dono (`--force-merge`)
e registro do motivo.

### 4. Ler o token de API (fail-closed)

Leia o token de um **secret manager ou variável de ambiente**
(`GITEA_API_TOKEN`) — SOPS+age, `pass`, Vault ou equivalente:

```bash
TOKEN="${GITEA_API_TOKEN:?token ausente}"   # ou: TOKEN=$(<seu secret manager>)
```

Reusar **um único** token de longa vida (ex.: `<nome-do-token>`, escopo
`write:repository`) — **não** gerar um token por operação (acumula tokens
órfãos; versões antigas do Gitea não têm API/CLI de revogação). O valor vive
**só na variável do processo** — nunca impresso, nunca em arquivo. Se `TOKEN`
vier vazio, **abortar** e (re)provisionar (ver skill `gitea-pr` § 4; rotação
conforme a administração do seu Gitea).

### 5. Merge via API

```bash
HTTP=$(curl -sk -o /tmp/gitea_merge_resp -w '%{http_code}' -X POST \
  -H "Authorization: token $TOKEN" -H 'Content-Type: application/json' \
  -d "$(jq -n --arg do "${METHOD:-merge}" \
        '{Do:$do, delete_branch_after_merge:true}')" \
  "$API/repos/$OWNER_REPO/pulls/$PR/merge")
# 200 = mergeado; 405 = não-mergeável (conflito/checks); 409 = base mudou
```

- `METHOD` (arg `--method`): `merge` (default, sempre permitido), `squash`,
  `rebase`, `rebase-merge`, `fast-forward-only`. Respeitar o que o branch protegido
  permite — método desabilitado → a API recusa; reportar e sugerir outro.
- `delete_branch_after_merge:true` remove a feature branch no Gitea (passar
  `--keep-branch` para preservar).
- ⚠️ Se for definir a mensagem de merge, o campo é `MergeMessageField`
  (**M maiúsculo**) — `merge_message_field` retorna 405.

### 6. Pós-merge — reconciliar o multi-push (ARMADILHA)

Só se aplica a repos com **multi-push** (mesmo `origin` com 2 push URLs: Gitea +
um espelho, ex.: GitHub). O merge avança **só a `main` do Gitea**. Se o `origin`
faz *fetch* do espelho, este **não** recebeu o merge → a `main` do espelho e a
local ficam atrás (sintoma clássico: "PR mergeado no Gitea, espelho divergente").
Reconciliar:

```bash
git fetch git@<GITEA_HOST>:<OWNER>/<repo>.git main       # traz a main mergeada do Gitea
git switch main && git merge --ff-only FETCH_HEAD        # FF da local (sem tocar em feature trees sujas: usar worktree se preciso)
git push git@github.com:<OWNER>/<repo>.git main          # só o espelho (push em origin tentaria a main protegida do Gitea → rejeição)
```

**Anunciar** o que foi feito. Se a branch ativa tiver working tree sujo, fazer
o FF num worktree isolado em vez de trocar de branch.

### 7. Output

```
PR #N mergeado (<método>) em <owner>/<repo>: <url>
Branch <head> removida no Gitea (ou preservada com --keep-branch).
Reconciliação: main do espelho atualizada por FF.  | ou:  PENDENTE — rodar passo 6.
```

## Argumentos

- `<número>` — PR a mergear (default: PR aberto da branch atual)
- `--method <m>` — `merge` (default) | `squash` | `rebase` | `rebase-merge` | `fast-forward-only`
- `--no-merge` — só revisa (passos 1–2), não mergeia
- `--keep-branch` — não remove a head branch após o merge
- `--force-merge` — override do gate de CI/mergeabilidade (exige confirmação + motivo registrado)
- `--no-reconcile` — pula o passo 6 (reconciliação do espelho fica pendente)

## NUNCA

- Mergear sem **checks verdes + confirmação humana explícita** (gate do passo 3)
- Mergear com conflito (`mergeable:false`) ou CI `pending`/`failure` sem `--force-merge` autorizado
- Imprimir ou persistir o valor do token, ou gerar um token novo por operação — reuse o token de longa vida custodiado
- `git push ... main` para o Gitea (branch protegida — rejeitado); reconciliar o espelho por FF
- Reescrever história / force-push para resolver divergência

## Adaptação

- **`<GITEA_HOST>` / `<OWNER>` / `<repo>`** — detectados do remote; os exemplos
  usam placeholders.
- **Fonte do token** — `GITEA_API_TOKEN` de qualquer secret manager (SOPS+age,
  `pass`, Vault, secrets do CI) ou variável de ambiente; mantenha o invariante
  fail-closed + valor só no processo.
- **`<nome-do-token>`** — token de longa vida nomeado e identificável, escopo
  `write:repository`; rotação conforme a administração do seu Gitea.
- **Passo 6 (reconciliação)** — remova-o se o repo não usa multi-push com
  espelho; com remotes nomeados separados, ajuste os comandos para o nome do
  remote em vez de URLs.
- **Política de push da `main` reconciliada** — aqui o push do FF é tratado
  como sync autônomo anunciado; se a governança do repo adotante exige pedido
  explícito para qualquer push, peça confirmação antes.
- **Base default** — `main`; ajuste se a base de integração for outra.
