---
name: prune-branches
description: Poda branches de feature já mergeadas na branch de integração (local + todos os remotes) com salvaguardas. Use quando pedirem "limpar branches", "podar branches", "remover branches mergeadas", "higiene de branches", "/prune-branches", ou ao notar acúmulo de feature branches antigas. Dry-run primeiro; NÃO toca branches de vida longa nem branches de worktree ativo.
---

# prune-branches — poda segura de branches mergeadas (TOOL · v1.0.0 · Alex Jesus)

Wrapper de um script de poda (`scripts/prune-merged-branches.sh`, exposto como
`make prune-branches`). Remove branches de `feature/fix/chore/docs` já integradas na
**branch de integração** do fluxo do repo (ex.: `develop` ou `main`), em todos os
lugares de uma vez: local + remotes (ex.: dois forges atrás de um mesmo `origin`
multi-push).

## Procedimento

### 1. Dry-run SEMPRE primeiro
```bash
make prune-branches
```
Lista o que seria deletado (local + remotas). Revise a lista.

### 2. Confirmar com o humano
Mostre a lista e **peça confirmação explícita** antes de aplicar — é ação destrutiva.

### 3. Aplicar
```bash
make prune-branches-apply
```

## Salvaguardas (já no script — nunca burlar)
- Base = a **branch de integração** do fluxo; só poda o que é **ancestral** de `origin/<base>` (safe-delete `git branch -d` no local — nunca `-D` força bruta).
- NUNCA toca branches de vida longa (`main`/`master`/`develop`), branches **checked out em worktree ativo** (são infraestrutura, não feature work), nem a branch atual.
- **Aborta** se houver outra sessão de agente `in_progress` registrada no arquivo de estado compartilhado do repo — evita colisão com trabalho paralelo no mesmo working tree.
- Em `origin` **multi-push** (um remote com múltiplas push URLs), um único `git push origin --delete <branch>` cobre todos os destinos; ref ausente em um deles é **tolerado** (não é erro).
- Detecção de integração é por **ancestralidade** (`--merged`) — branches integradas via **squash merge** não aparecem como mergeadas; nesses casos a poda é manual, branch a branch, após verificação humana.

## Quando NÃO usar
- Para remover **uma** branch específica junto com seu worktree — use o procedimento/skill de teardown de worktree.
- Para sincronizar branches de integração entre si (ex.: `develop` ↔ `main` pós-release) — é outro fluxo.
- Quando o repositório não tem o script/target instalado — primeiro porte o script (ver Adaptação); não improvise um one-liner destrutivo com `xargs git branch -D`.
- Quando há trabalho paralelo em andamento no mesmo working tree.

## Adaptação
- **`scripts/prune-merged-branches.sh` / `make prune-branches[-apply]`** — nomes convencionais; ajuste para o script/target equivalente do seu repo. O contrato mínimo do script: modo dry-run por padrão, modo apply explícito, e as salvaguardas da seção acima.
- **`<base>`** — a branch de integração do seu fluxo de Git (GitHub Flow → `main`; Git Flow/variantes → `develop`).
- **Branches protegidas/permanentes** — parametrize a lista de branches que o script jamais poda: vida longa + branches presas a worktrees permanentes (o Git já impede `branch -d` de branch checked out, mas o filtro explícito evita até a tentativa).
- **Arquivo de estado de sessões paralelas** — se o repo coordena múltiplos agentes via arquivo de estado (ex.: `.agents-state/active-tasks.md`), o script deve checá-lo e abortar com sessão `in_progress`; sem esse mecanismo, remova a checagem.
- **Multi-remote** — a tolerância a ref ausente só se aplica a `origin` com múltiplas push URLs; com remotes nomeados separados, delete em cada um explicitamente.
- **Squash merge** — se o seu fluxo usa squash como padrão, a detecção por ancestralidade quase nunca acha nada; considere detecção por PR fechado via API do forge.
