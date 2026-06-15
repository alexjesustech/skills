# skills

Skills reutilizáveis para **agentes de código** — fonte única cross-tool:
funcionam no [Claude Code](https://claude.com/claude-code) e em qualquer
ferramenta que consuma Markdown de instruções (Antigravity, OpenCode, Gemini
CLI), pois cada skill é auto-contida, com frontmatter e sem dependência de
runtime.

Cada skill é uma pasta com `SKILL.md` (frontmatter `name`/`description` +
instruções) e, quando preciso, `scripts/` e `assets/` próprios. Todas foram
extraídas de uso real e **generalizadas** para qualquer repositório.

## Status

`0.1.0` — em evolução. As skills são usáveis; o catálogo cresce e convenções podem mudar
([SemVer](https://semver.org/lang/pt-BR/) `0.y.z`).

## Catálogo

| Categoria | Skill | O que faz |
|---|---|---|
| `comunicacao/` | [diretriz-cromatica-html](./comunicacao/diretriz-cromatica-html/) | 4 paletas OKLCH + seletor persistente + impressão para documentos HTML de leitura |
| `comunicacao/` | [gera-fluxo](./comunicacao/gera-fluxo/) | Padrão de diagramas SVG: semântica de cores, legibilidade, saída versionada |
| `dados/` | [chunking-rules](./dados/chunking-rules/) | Governança determinística do pipeline de chunking (versionar modelo/parâmetros → reindex) |
| `dados/` | [ir-modeling](./dados/ir-modeling/) | Evolução segura de schema de IR com Zod estrito + SemVer (`schemaVersion`) |
| `dados/` | [migration-safe](./dados/migration-safe/) | Checklist de migration segura (backward compat, rollback, índices, zero-downtime) |
| `dados/` | [retrieval-eval](./dados/retrieval-eval/) | Valida pipeline de retrieval com golden dataset (Recall/MRR/NDCG + gates) |
| `dados/` | [sqlite-migration](./dados/sqlite-migration/) | Migrations SQLite com cabeçalho, idempotência e rastreabilidade |
| `especificacao/` | [adr-authoring](./especificacao/adr-authoring/) | Redação de ADRs (formato Nygard) com alternativas obrigatórias |
| `especificacao/` | [planta-baixa](./especificacao/planta-baixa/) | Vocabulário pt-BR de planta baixa → campos de uma IR/schema (didática, domínio CAD) |
| `especificacao/` | [prd-authoring](./especificacao/prd-authoring/) | Estrutura/normaliza PRD + gap analysis (2 modos) |
| `especificacao/` | [spec-driven-development](./especificacao/spec-driven-development/) | Disciplina SDD: spec → aceite → código → refactoring, com circuit breaker |
| `git/` | [branch-fan-in](./git/branch-fan-in/) | Integra branches paralelas que editam o mesmo registro compartilhado |
| `git/` | [gitea-claude-mention](./git/gitea-claude-mention/) | Workflow @claude em issues/PRs de Gitea self-hosted (act_runner) |
| `git/` | [gitea-pr](./git/gitea-pr/) | Push de branch + abertura de PR via API do Gitea com token custodiado |
| `git/` | [gitea-pr-merge](./git/gitea-pr-merge/) | Revisão e merge de PR no Gitea (gate: mergeable + CI verde + confirmação humana) |
| `git/` | [prune-branches](./git/prune-branches/) | Poda segura de branches mergeadas (dry-run, multi-remote, proteções) |
| `governanca/` | [conventional-commits](./governanca/conventional-commits/) | Guia de estilo de mensagens de commit + trailers de co-autoria de IA |
| `governanca/` | [trim-agents-md](./governanca/trim-agents-md/) | Enxuga AGENTS.md/CLAUDE.md acima de 40k chars movendo REFERÊNCIA para `docs/` (regras ficam) |
| `governanca/` | [validate-harness](./governanca/validate-harness/) | Gate estrutural do `.claude/` (~2s): frontmatter, settings.json, hooks, ADRs |
| `mcp/` | [mcp-debug](./mcp/mcp-debug/) | Diagnostica tool calls MCP (códigos de erro, auditoria, queries) |
| `mcp/` | [mcp-tool](./mcp/mcp-tool/) | Implementa/altera tool MCP — checklist contrato→teste→implementação→auditoria |
| `operacao/` | [daemon-health-check](./operacao/daemon-health-check/) | Health-check de serviço daemon: unit systemd → endpoint → dependências externas |
| `qualidade/` | [error-triage](./qualidade/error-triage/) | Classifica erro esperado × real via catálogo determinístico |
| `qualidade/` | [harness-evals](./qualidade/harness-evals/) | Pirâmide de testes, métricas e gate de qualidade para código gerado por IA |
| `qualidade/` | [pytest-async-testing](./qualidade/pytest-async-testing/) | Receitas pytest-asyncio: event loop, mocking de singletons, timeouts, sincronização |
| `qualidade/` | [pytest-run-triage](./qualidade/pytest-run-triage/) | Roda a suíte pytest e faz triagem de falhas com file:line |
| `qualidade/` | [resolve-knowndebt](./qualidade/resolve-knowndebt/) | Lista, prioriza e resolve dívidas `$knownDebts` em arch tests (Pest), mantendo o guard puro |
| `scaffold/` | [scaffold-module-full](./scaffold/scaffold-module-full/) | Scaffold de módulo completo Laravel + React/Inertia (migration, testes, ACL) |
| `scaffold/` | [shadcn](./scaffold/shadcn/) | Gestão de componentes shadcn/ui via CLI: composição, regras críticas, presets, smart merge (upstream: ui.shadcn.com) |

## Instalação por ferramenta

**Claude Code** — global (todos os projetos) ou por projeto:

```bash
cp -r <categoria>/<skill> ~/.claude/skills/<skill>          # global
cp -r <categoria>/<skill> <repo>/.claude/skills/<skill>     # por projeto
```

**Antigravity (Agy)** — instale nativamente copiando para um plugin:

```bash
cp -r <categoria>/<skill> ~/.gemini/config/plugins/<seu-plugin>/skills/<skill>
```

**OpenCode / Gemini CLI** — o conteúdo é Markdown puro: aponte o
mecanismo de instruções da ferramenta para o `SKILL.md` (campo `instructions`
do `opencode.json`, regra em `.agents/rules/`, comando TOML do Gemini CLI) ou
incorpore o corpo como regra/comando. A seção **Adaptação** de cada skill lista
os pontos parametrizáveis.

Nenhuma skill depende de segredo, serviço externo ou caminho de máquina
específica.

## Convenção das skills

- Frontmatter YAML com `name` (= nome da pasta) e `description` (gatilhos de uso).
- Cabeçalho `TOOL · vMAJOR.MINOR.PATCH · autor` na primeira linha do corpo.
- Seções **"Quando NÃO usar"** e **"Adaptação"** obrigatórias.
- Conteúdo em pt-BR; código e identificadores na forma original.
- Skills derivadas de material de terceiros creditam o upstream.

## Validação (gate local + CI)

O gate canônico é **local e determinístico** — não depende do GitHub Actions:

```bash
bash scripts/ci-local.sh   # validate-skills (espelho do workflow)
```

O GitHub Actions roda o mesmo script em todo push/PR como confirmação
redundante. Hook opcional (recomendado): `git config core.hooksPath .githooks`
ativa branch-guard + gitleaks no commit.

## Contribuindo

Issues e PRs são bem-vindos — veja o [CONTRIBUTING.md](./CONTRIBUTING.md).

## Licença

[MIT](./LICENSE) — Alex Jesus ([@alexjesustech](https://github.com/alexjesustech)).
