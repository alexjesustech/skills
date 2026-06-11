# Changelog

Todas as mudanças notáveis deste repositório são documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o
projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Adicionado

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
