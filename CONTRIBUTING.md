# Contribuindo

Issues e pull requests são bem-vindos — em português ou inglês.

## Issues

- **Bug numa skill** (instrução errada, script quebrado, exemplo que não roda):
  descreva a skill, a ferramenta (Claude Code, OpenCode, ...) e o comportamento
  observado × esperado.
- **Proposta de skill nova**: abra uma issue antes do PR descrevendo o problema
  que ela resolve e em qual categoria entraria.

## Pull requests

1. Base: branch `develop` (a `main` recebe via PR de release).
2. Toda skill segue a convenção do [`AGENTS.md`](./AGENTS.md): pasta
   `<categoria>/<nome-kebab-case>/` com `SKILL.md` (frontmatter `name` +
   `description`), cabeçalho `TOOL · vX.Y.Z · autor`, seções **"Quando NÃO
   usar"** e **"Adaptação"**.
3. Rode o gate local antes de abrir o PR (espelho exato do CI):
   ```bash
   bash scripts/ci-local.sh
   ```
   Opcional: `git config core.hooksPath .githooks` ativa o `pre-commit` do
   repo (branch-guard + gitleaks).
   Antes do merge, o mantenedor aplica uma verificação própria de curadoria
   sobre o PR; evite incluir caminhos pessoais, e-mails ou dados de ambiente
   nos exemplos.
4. Atualize o `CHANGELOG.md` (`[Unreleased]`).
5. Skills auto-contidas: sem dependência de segredo, serviço pago ou caminho de
   máquina específica. Conteúdo derivado de terceiros credita o upstream e
   respeita a licença de origem.

## Escopo

Skills generalizadas e reutilizáveis para agentes de código. Skills acopladas a
um produto/projeto específico não entram — mas podem virar exemplo numa issue.
