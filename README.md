# skills

Skills reutilizáveis para **agentes de código** — fonte única cross-tool:
funcionam no [Claude Code](https://claude.com/claude-code) e em qualquer
ferramenta que consuma Markdown de instruções (Antigravity, OpenCode, Gemini
CLI), pois cada skill é auto-contida, com frontmatter e sem dependência de
runtime.

Cada skill é uma pasta com `SKILL.md` (frontmatter `name`/`description` +
instruções) e, quando preciso, `scripts/` e `assets/` próprios. Todas foram
extraídas de uso real e **generalizadas** para qualquer repositório.

## Catálogo

| Categoria | Skill | O que faz |
|---|---|---|
| `governanca/` | [trim-agents-md](./governanca/trim-agents-md/) | Enxuga AGENTS.md/CLAUDE.md acima de 40k chars movendo REFERÊNCIA para `docs/` (regras ficam) |
| `governanca/` | [validate-harness](./governanca/validate-harness/) | Gate estrutural do `.claude/` (~2s): frontmatter, settings.json, hooks, ADRs |
| `comunicacao/` | [gera-fluxo](./comunicacao/gera-fluxo/) | Padrão de diagramas SVG: semântica de cores, legibilidade, saída versionada |
| `comunicacao/` | [diretriz-cromatica-html](./comunicacao/diretriz-cromatica-html/) | 4 paletas OKLCH + seletor persistente + impressão para documentos HTML de leitura |

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
