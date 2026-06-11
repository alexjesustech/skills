# Changelog

Todas as mudanças notáveis deste repositório são documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o
projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Adicionado

- **qualidade/pytest-async-testing**, **qualidade/pytest-run-triage** e
  **operacao/daemon-health-check** v1.0.0 — receitas pytest-asyncio (event
  loop, mocking de singletons, timeouts, sincronização determinística com
  `asyncio.Event`), execução de suíte com triagem de falhas file:line, e
  health-check de daemon (systemd → endpoint → dependências). Renomeadas dos
  nomes genéricos originais (`testing`, `run-tests`, `health-check`) ao serem
  publicadas; a Receita 5 de sincronização teve um bug corrigido na
  generalização (o `Event.set()` era inalcançável e o `await` pós-`cancel()`
  não suprimia `CancelledError`). Nova categoria `operacao/`.

- **dados/chunking-rules** v1.0.0 — governança determinística do pipeline de
  chunking: versionamento de modelo/parâmetros (mudou → reindex), invariante de
  modelo único, protocolo de cutover com dual-write e gate de regressão.
- **dados/ir-modeling** v1.0.0 — evolução segura de schema de representação
  intermediária com Zod estrito + SemVer (`schemaVersion`): minor =
  opcional/default, major = migração explícita.
- **especificacao/planta-baixa** v1.0.0 — vocabulário pt-BR de planta baixa
  (cômodos, paredes, aberturas, medidas) mapeado para campos de uma IR/schema;
  didática, domínio CAD.
- **git/gitea-pr**, **git/gitea-pr-merge**, **git/gitea-claude-mention**
  v1.0.0 — fluxo completo para Gitea self-hosted: push + PR via API com token
  de longa vida (`<GITEA_HOST>`/`<OWNER>` parametrizados), merge com gate
  (mergeable + CI verde + confirmação humana, pegadinha `MergeMessageField`),
  e workflow @claude em issues/PRs via act_runner (asset `claude.yml` incluso).
- **qualidade/resolve-knowndebt** v1.0.0 — lista, prioriza e resolve dívidas
  técnicas registradas como `$knownDebts` em testes de arquitetura (Pest/arch
  tests): inventário → priorização por esforço → fix canônico → baixa da dívida
  → guard puro; regra "nunca `->ignoring()` novo".
- **scaffold/shadcn** v1.0.0 — gestão de componentes shadcn/ui via CLI
  (princípios, regras críticas de composição/estilo/formulários/ícones, presets,
  smart merge); inclui referências `rules/`, `cli.md`, `customization.md` e
  `mcp.md`. Derivada da documentação oficial do shadcn/ui
  (https://ui.shadcn.com, MIT) — upstream creditado.

- **14 skills novas** (segunda leva, generalizadas de uso real): `dados/`
  `retrieval-eval`, `sqlite-migration`, `migration-safe`; `especificacao/`
  `prd-authoring`, `spec-driven-development`, `adr-authoring`; `git/`
  `branch-fan-in`, `prune-branches`; `governanca/` `conventional-commits`
  (guia de estilo, complementar a automações de commit); `mcp/` `mcp-debug`,
  `mcp-tool`; `qualidade/` `error-triage`, `harness-evals` (avaliação da
  bateria de testes do código — não de modelos LLM); `scaffold/`
  `scaffold-module-full` (Laravel + React/Inertia). Catálogo do README
  reordenado por categoria.
- **Documentação de Instalação**: Adicionadas instruções específicas de carregamento nativo de skills para o Antigravity no README e na seção de adaptação das skills `trim-agents-md` e `validate-harness`.

### Removido

- Ferramentas de curadoria saíram do repositório (`scripts/check-public-hygiene.sh`
  e o hook `pre-push`): a curadoria de publicação é função do mantenedor e roda
  fora daqui. O CI público passa a validar somente a **estrutura** das skills.

### Alterado

- `scripts/ci-local.sh` segue como espelho exato do workflow (agora só
  `validate-skills.sh`); `.githooks/` mantém apenas o `pre-commit`
  (branch-guard + gitleaks).

## [0.1.0] — 2026-06-11

### Adicionado

- Bootstrap do repositório: estrutura por categoria, convenção de skill
  (cabeçalho `TOOL · vX.Y.Z · autor`, seções "Quando NÃO usar" e "Adaptação"),
  licença MIT e guia de contribuição (issues e PRs abertos).
- **Gate verde local e determinístico** (`scripts/ci-local.sh`): espelho exato
  do workflow — a verificação não depende do GitHub Actions. Hooks versionados
  em `.githooks/` (`pre-commit` branch-guard + gitleaks; `pre-push` CI local +
  curadoria de publicação), ativados com `git config core.hooksPath .githooks`.
- Curadoria de publicação em camadas: CI público de higiene genérica
  (`scripts/check-public-hygiene.sh`) + gate local do mantenedor com denylist
  privada (fora do repositório). Regra canônica no `AGENTS.md` § Curadoria.
- **governanca/trim-agents-md** v1.0.0 — enxuga arquivos de governança grandes
  (AGENTS.md/CLAUDE.md/GEMINI.md > 40k chars) separando REFERÊNCIA de REGRA;
  inclui `scripts/measure_sections.py`.
- **governanca/validate-harness** v1.0.0 — gate estrutural do `.claude/` com
  script auto-contido (`validate-harness.sh`).
- **comunicacao/gera-fluxo** v1.1.0 — padrão de diagramas SVG (a linha de
  trailer de commit segue a convenção do repositório adotante).
- **comunicacao/diretriz-cromatica-html** v1.0.0 — quatro paletas OKLCH com
  seletor persistente e reversão de impressão; assets CSS/JSON/HTML inclusos.
