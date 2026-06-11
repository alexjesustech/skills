---
name: validate-harness
description: Checagem rápida (~2s) de integridade ESTRUTURAL de um setup .claude/ de qualquer projeto — frontmatter de agents/skills/rules, JSON válido em settings.json, referências de hook resolvidas/executáveis e seções Nygard dos ADRs. Use antes de abrir um PR que toca .claude/, ou para confirmar que nada quebrou após editar agent/skill/rule/hook. Valida estrutura/sintaxe, NUNCA conteúdo.
---

# validate-harness — gate estrutural do `.claude/` (TOOL · v1.0.0 · Alex Jesus)

Roda um script auto-contido que valida o harness `.claude/` do **projeto atual** (ou de um
diretório informado) em ~2 segundos.

## Como usar

Rode o script bundle e relate o resultado:

```bash
bash <pasta-desta-skill>/validate-harness.sh        # valida ./.claude do cwd
bash <pasta-desta-skill>/validate-harness.sh <dir>  # valida <dir>/.claude
```

- **Exit 0** → "integridade do harness: OK" + sumário das contagens.
- **Exit 1** → lista cada achado e diz qual arquivo corrigir.
- **Exit 2** → diretório inválido ou sem `.claude/`.

## O que verifica (6 checagens, só estrutura)

1. **Agents** — `.claude/agents/*/agent.md` **ou** `.claude/agents/*.md` com frontmatter
   (`name`, `description`; `allowed-tools`/`tools` → recomendado).
2. **Skills** — `.claude/skills/*/SKILL.md` com frontmatter (`name`, `description`).
3. **Rules** — `.claude/rules/*.md`; `paths` no frontmatter é **recomendado** (warning, não falha — o formato varia entre Claude/Antigravity/OpenCode).
4. **settings.json** — parseia como JSON válido (ausência = warning).
5. **Hooks** — todo `command` em `hooks.*` aponta para arquivo existente e executável (com remap pelo nome do repo p/ funcionar em qualquer checkout/CI).
6. **ADRs** — `docs/adr/*.md` têm as 4 seções Nygard (Status/Contexto/Decisão/Consequências) → warning.

## Quando NÃO usar

- Para revisar **conteúdo** (se a regra/skill é útil, se o prompt do agente faz sentido) —
  use revisão humana ou `/code-review`. Esta skill é um gate **estrutural/sintático**.
- Em projeto sem `.claude/` (sai com código 2 sem erro fatal).

## Adaptação

Auto-contida: nenhum placeholder obrigatório. Instale em `~/.claude/skills/validate-harness/` (Claude Code) ou `~/.gemini/config/plugins/<seu-plugin>/skills/validate-harness/` (Antigravity)
ou `<repo>/.claude/skills/validate-harness/` (por projeto). As checagens 1–3 assumem
o layout padrão `.claude/{agents,skills,rules}`; a checagem de ADR assume `docs/adr/`. Ajuste
esses caminhos no script se o projeto usa outra convenção. Falhas só ocorrem para problemas
reais (frontmatter ausente/malformado, JSON inválido, hook quebrado); o resto é warning.
Também funciona como **gate de CI**: rode o script num workflow e falhe o job no exit 1.
