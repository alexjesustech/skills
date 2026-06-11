---
name: gitea-claude-mention
description: >-
  Habilita mencionar @claude direto em issues e PRs de um repositório num Gitea
  self-hosted com act_runner — o equivalente caseiro do /install-github-app,
  que é só GitHub. Instala um workflow do Gitea Actions
  (.gitea/workflows/claude.yml) que, ao detectar "@claude" num comentário, roda
  o Claude Code headless com o contexto da issue/PR e responde como comentário.
  Use quando o usuário pedir "@claude no Gitea", "install-gitea-app",
  "responder menções no Gitea", ou para ligar/depurar essa integração num repo.
---

# gitea-claude-mention — `@claude` em issues/PRs do Gitea (TOOL · v1.0.0 · Alex Jesus)

## O que é

Não existe "Gitea App" oficial da Anthropic (o instalador `/install-github-app` é
exclusivo do GitHub). Num Gitea self-hosted (`<GITEA_HOST>`) com `act_runner`
registrado, o equivalente é um **workflow do Gitea Actions** acionado pelo evento
`issue_comment`: quando alguém escreve `@claude ...` num comentário de issue ou
PR, o job instala o Claude Code CLI, roda em modo headless com o repositório em
checkout e **responde como comentário**.

O template pronto está em `assets/claude.yml` (ao lado deste arquivo).

## Quando NÃO usar

- **Repo público ou com colaborador externo** — `@claude` viraria vetor de
  execução arbitrária num runner privilegiado. Só em repos privados/solo.
- No GitHub — lá use o instalador oficial (`/install-github-app` /
  `claude-code-action`).
- Sem `act_runner` registrado ou sem Actions habilitado na instância.
- Quando se quer que o Claude **edite/commite** no PR — o template é somente
  leitura por desenho; escalar exige decisão explícita (ver "Escopo do template").

## Pré-requisitos (verificar antes)

- **Gitea ≥ 1.20 com Actions habilitado** e `act_runner` registrado, com jobs
  numa imagem com Node (ex.: `node:20-bookworm`) e **saída para a internet**
  (precisa alcançar `api.anthropic.com`). Confirmar na UI do Gitea
  (Site Administration → Actions → Runners) ou nos logs do runner.
- **Repo com remote Gitea** — o workflow só dispara em quem recebe o push para
  o Gitea.
- **Token OAuth do Claude** (se a sua auth for por assinatura Pro/Max, não API
  key metered). Gerado pelo usuário com `claude setup-token`.

## Passos para habilitar num repo

### 1. Gerar o token OAuth (o usuário roda — é interativo, abre o browser)

Peça ao usuário para rodar no terminal da sessão:

```
! claude setup-token
```

Copia o token gerado (`CLAUDE_CODE_OAUTH_TOKEN`). Ele usa a assinatura Claude
(Pro/Max), sem cobrança por uso extra, e é revogável. **Nunca** vai para o repo.

### 2. Cadastrar o secret no Gitea (não commitar)

No Gitea: **repo → Settings → Actions → Secrets → Add Secret**:
- Nome: `CLAUDE_CODE_OAUTH_TOKEN`  · Valor: (o token do passo 1)

> Por que no cofre de Actions do Gitea e não em arquivo no repo: secrets de
> Actions são injetados como `${{ secrets.* }}` no job e **nunca** tocam o
> working tree — segredo fora do código.
> Opcional: `CLAUDE_GITEA_TOKEN` (token de um usuário-bot dedicado) se não quiser
> usar o `github.token` automático para postar a resposta.

### 3. Instalar o workflow na BRANCH DEFAULT

⚠️ **Crítico:** o evento `issue_comment` roda a versão do workflow que está na
**branch default** do repo no Gitea (não na branch do PR). Então o `claude.yml`
precisa estar na default (`main`/`develop` conforme o repo) e pushado pro Gitea.

- Copie `assets/claude.yml` → `<repo>/.gitea/workflows/claude.yml`.
- Ajuste a **allowlist de autores** (`github.actor == '<OWNER>'`) para o(s)
  login(s) Gitea autorizados. ⚠️ Se o runner monta `docker.sock` (≈ root no
  host): manter a allowlist é o que impede uma conta qualquer de executar
  comandos no host via `@claude`.
- Commit (Conventional Commits) + **push**.

> 📌 **Diretiva de push — a mágica (CI) é no Gitea.** Se o repo usa multi-push
> (mesmo `origin` escrevendo no Gitea e num espelho, ex.: GitHub), a ordem
> importa pelo papel de cada um:
> 1. **Gitea** (`<GITEA_HOST>`) — **é aqui que a mágica acontece**: o
>    `act_runner` recebe o push, registra e **dispara** o workflow. **Só o
>    Gitea executa o CI** e, portanto, o `@claude`.
> 2. **Espelho (ex.: GitHub)** — só visibilidade. **Não executa** o
>    `claude.yml` (está em `.gitea/`, que o GitHub ignora) — recebe o arquivo
>    apenas como espelho.
>
> Ou seja: o `@claude` só ganha vida no **Gitea**. Se o repo não tiver remote
> Gitea, a integração simplesmente não roda.

### 4. Habilitar Actions no repo (se ainda não)

Gitea: **repo → Settings → Advanced → Enable Actions**.

### 5. Testar

Numa issue/PR do repo no Gitea, comente: `@claude resuma esta issue`.
Em segundos deve aparecer a reação 👀 e depois um comentário **🤖 Claude**.
Acompanhe o job na aba **Actions** do repo.

### 6. Documentar

Registre a integração conforme a convenção do repositório adotante (ex.:
entrada no `CHANGELOG.md` e uma linha no `README.md` — "comente `@claude` em
issues/PRs"). Não commitar/pushar sem o usuário pedir.

## Escopo do template (e como escalar)

O `claude.yml` entregue é **somente leitura** (responde/consulta; `--allowedTools`
restrito a `Read/Grep/Glob` + `git log/diff/show`). Ele **não** edita arquivos nem
faz commit no PR — escolha deliberada por causa do `docker.sock` no runner.

Para escalar para "Claude edita o PR" (estilo `claude-code-action` do GitHub):
adicionar um step que cria branch + commit + abre/atualiza PR via API do Gitea, e
ampliar `--allowedTools` (`Edit`, `Write`, `Bash(git ...)`). **Só com decisão
explícita** — aumenta a superfície de risco do runner privilegiado. Documentar a
decisão (ex.: um ADR no repositório) antes de ligar.

## Troubleshooting

- **Nada dispara ao comentar:** (a) o `claude.yml` está na branch **default** no
  Gitea? (b) Actions habilitado no repo? (c) o autor do comentário casa a allowlist?
  (d) os logs do runner mostram o evento chegando?
- **`actions/checkout@v4` não resolve:** o act_runner busca actions no github.com por
  padrão; com saída de internet costuma resolver. Se bloqueado,
  trocar por um `git clone` manual com o `github.token`, ou apontar o runner para um
  mirror (`code.forgejo.org/actions`).
- **Falha de TLS ao postar comentário:** use o endpoint **interno** do container
  (ex.: `http://gitea:3000`, já o default do template, se o runner compartilha a
  rede Docker do Gitea) — evita o certificado interno do reverse proxy em
  `https://<GITEA_HOST>`.
- **403 ao postar:** o `github.token` do Gitea pode não ter escopo de escrita no repo;
  cadastre `CLAUDE_GITEA_TOKEN` de um usuário com acesso e o template o usa por preferência.
- **Token OAuth expirado/revogado:** rode `claude setup-token` de novo e atualize o secret.

## Anti-padrões

- ❌ Commitar o token no repo / `.env` versionado — vai no cofre de Actions do Gitea.
- ❌ Remover a allowlist de autores num runner com `docker.sock`.
- ❌ Ligar escrita/commit automático sem decisão registrada e sem entender o risco do runner privilegiado.
- ❌ Usar em repo público ou com colaborador externo — `@claude` viraria vetor de execução.
- ❌ Pôr o workflow só numa feature branch e esperar que dispare (tem de estar na default).

## Adaptação

- **`<GITEA_HOST>`** — domínio da sua instância Gitea self-hosted.
- **`<OWNER>`** — login Gitea autorizado na allowlist do workflow
  (`github.actor == '<OWNER>'`); aceita lista (`contains(fromJSON(...))`) se
  houver mais de um autor confiável.
- **Endpoint interno da API** — o template usa `http://gitea:3000` (nome do
  container na mesma rede Docker); ajuste para o hostname/porta reais do seu
  deployment, ou para `https://<GITEA_HOST>` se o runner confia no certificado.
- **Imagem do job** — qualquer imagem com Node ≥ 18 e `apt-get`/equivalente
  (o template instala `jq` e o CLI via npm).
- **Auth do Claude** — o template assume `CLAUDE_CODE_OAUTH_TOKEN` (assinatura);
  com API key metered, troque a env para `ANTHROPIC_API_KEY`.
- **Idioma da resposta** — o prompt do template pede pt-BR; ajuste ao idioma do
  seu time.
