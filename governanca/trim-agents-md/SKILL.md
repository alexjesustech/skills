---
name: trim-agents-md
description: >-
  Corrige o aviso "Large AGENTS.md will impact performance (NN.Nk chars > 40.0k)"
  (vale também para CLAUDE.md/GEMINI.md grandes). Mede o peso por seção, identifica
  os blocos de REFERÊNCIA/ÍNDICE (inventários, catálogos, históricos, setups passo-a-passo)
  que estão inflando o arquivo, e os move para docs/ deixando um ponteiro em link —
  SEM tocar nas regras de negócio nem usar @import. Use quando aparecer esse aviso,
  quando um AGENTS.md/CLAUDE.md/GEMINI.md passar de ~40k chars, ou quando o usuário
  pedir para "enxugar/encolher/reduzir o AGENTS.md".
---

# trim-agents-md — enxugar arquivos de governança grandes (TOOL · v1.0.0 · Alex Jesus)

## Quando isto dispara

O Claude Code (e outras ferramentas) avisam **"Large AGENTS.md will impact performance
(NN.Nk chars > 40.0k)"** quando um arquivo de contexto sempre-carregado passa de ~40 mil
**caracteres**. Acima disso, todo turno carrega o arquivo inteiro, gastando contexto e
degradando a performance. O mesmo vale para `CLAUDE.md` e `GEMINI.md` grandes.

> ⚠️ O aviso conta **caracteres unicode**, não bytes. Em idiomas com acentos cada acento
> é 1 char mas 2 bytes — por isso `wc -c` (bytes) **superestima**. Sempre medir com o
> script abaixo (`len(str)` em Python), nunca com `wc -c`.

## A ideia central (não negociável)

O arquivo é grande quase sempre porque **conteúdo de REFERÊNCIA/ÍNDICE** (que deveria ser
lido sob demanda) está misturado com as **REGRAS** (que precisam estar sempre carregadas).
A correção **não é resumir as regras** — é **separar referência de regra**:

| Tipo de conteúdo | Exemplos | Destino |
|---|---|---|
| **REGRA / política / comportamento** | "agente nunca toca `main`", DoD, convenções de commit, governança multi-LLM, fluxos | **FICA inline** no AGENTS.md (fonte única) |
| **REFERÊNCIA / índice / arquivo histórico** | inventários, catálogos de repos, históricos de remoção, setups passo-a-passo, trade-offs, tabelas longas | **VAI para `docs/<slug>.md`** com ponteiro em link |

**Regras de ouro:**

1. **Regra de negócio NUNCA sai do AGENTS.md.** Ele é a fonte única cross-tool (Claude
   Code, Antigravity, OpenCode e Gemini CLI o leem). Mover regra para `docs/` quebra a
   fonte única.
2. **Ponteiro é LINK Markdown comum** (`[docs/x.md](./docs/x.md)`), **NUNCA `@import`**.
   O `@import` é *expandido recursivamente* pelo Claude Code (e pelo memory-import do
   Gemini CLI) — ele puxaria o conteúdo de volta para o contexto e o aviso voltaria.
   Link comum é seguido **sob demanda**: o peso sai do contexto sempre-carregado.
3. **Nada se perde.** Todo conteúdo extraído vai integral para o doc; o AGENTS.md mantém
   um resumo enxuto + link. Para um inventário, mantenha inline só as **linhas ativas/vigentes**
   e mande o histórico/arquivo morto para o doc.
4. **Não inventar.** Extrair e re-linkar, sem reescrever o sentido das seções.

## Procedimento

### 1. Medir e diagnosticar

```bash
python3 <pasta-desta-skill>/scripts/measure_sections.py CAMINHO/AGENTS.md
```

O script imprime: total de chars, status vs. limite, peso/% de cada seção `##`, a classe
heurística (REGRA/REFERÊNCIA/MISTO) e quais seções de REFERÊNCIA já resolvem o aviso se
extraídas. Use isso para escolher o **menor conjunto de seções de REFERÊNCIA** que derruba
o arquivo abaixo de ~38k (limite 40k com folga).

### 2. Propor antes de aplicar

Mostre ao usuário: arquivo atual (chars) → projeção depois, e **quais seções** serão
movidas e para onde. **Confirme antes de mexer** se houver qualquer seção MISTO ou dúvida
se é regra. Mis-classificar uma regra como referência é o único erro grave aqui.

### 3. Extrair

Para cada seção de REFERÊNCIA escolhida:

1. Crie `docs/<slug>.md` (slug kebab-case derivado do título) com:
   - um cabeçalho explicando que foi **extraído do AGENTS.md** (data + motivo: ficar < 40k);
   - uma linha deixando claro que **"fonte única de regras continua no AGENTS.md; este doc é só índice/referência"**;
   - o conteúdo **integral** da seção.
2. No AGENTS.md, **substitua** a seção pelo bloco enxuto: 1 parágrafo-ponteiro com o link +
   (se for índice) só as entradas **ativas/vigentes**.
3. Prefira fazer a cirurgia com um script Python determinístico (localizar a seção pelos
   headers `## ` e fatiar) em vez de um Edit gigante e frágil.

> Onde versionar o doc: confira o `.gitignore` do projeto. Em repos com **allowlist**
> restritiva, garanta que `docs/**` está liberado; em blocklist normal, costuma ser
> automático. Se o projeto ignora `docs/`, ajuste a exceção — mover conteúdo para um
> arquivo não versionado o perde.

### 4. Re-medir

Rode o script de novo no AGENTS.md. Confirme `STATUS: OK`. Se ainda acima, extraia a próxima
seção de REFERÊNCIA da lista.

### 5. Documentar a mudança

Registre a extração no `CHANGELOG.md` `[Unreleased]` do projeto (ex.: "Inventário movido
para `docs/inventario.md`; AGENTS.md de 54.7k → 29.6k chars") e, se o projeto mantém um
arquivo de estado/handoff entre sessões, atualize-o. Não commitar/pushar sem o usuário pedir.

## Quando NÃO usar

- Quando o arquivo é grande porque tem **regra demais de verdade** (raro): aí a conversa
  é revisar a governança com o dono, não extrair referência.
- Para "resumir" um documento qualquer — esta skill é específica de arquivos de contexto
  sempre-carregados (AGENTS.md/CLAUDE.md/GEMINI.md).

## Anti-padrões (não faça)

- ❌ Resumir/cortar as **regras** para caber — perde governança; o problema é a referência, não a regra.
- ❌ Usar `@docs/arquivo.md` como ponteiro — o import expande e o aviso volta.
- ❌ Mover conteúdo para um arquivo **ignorado pelo git** — vira handoff que morre com a sessão.
- ❌ Aplicar em lote sem confirmar seções MISTO.
- ❌ Medir tamanho com `wc -c` (bytes) — use o script (chars unicode).

## Adaptação

- **Caminho do script**: instale esta pasta em `~/.claude/skills/trim-agents-md/` (global)
  ou `<repo>/.claude/skills/trim-agents-md/` (por projeto) e chame o
  `scripts/measure_sections.py` pelo caminho correspondente.
- **Limite**: 40k chars é o limiar do aviso do Claude Code; se a sua ferramenta usar outro,
  ajuste o alvo de ~38k proporcionalmente.
- **Idioma**: os docs extraídos seguem o idioma do projeto.
