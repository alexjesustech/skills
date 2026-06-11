---
name: retrieval-eval
description: "Avaliação de regressão de retrieval (busca semântica, lexical ou híbrida) contra um golden dataset. Acionar ao alterar chunker, tokenizador, modelo de embedding, fusão de rankings (ex.: RRF) ou parâmetros de busca; ao interpretar relatórios Recall@K / MRR@K / NDCG@K vs baseline; ou ao decidir merge/bloqueio de PR que toca o pipeline de retrieval."
---

# retrieval-eval — valida mudanças de retrieval contra golden dataset com gates mecânicos de regressão (TOOL · v1.0.0 · Alex Jesus)

## Quando usar

Carregue esta skill quando a task envolver:

- Alteração no módulo de indexação/busca: chunker, tokenizador, embedder, retrieval, fusão de rankings (ex.: RRF).
- Mudança na camada de busca (semântica, lexical, híbrida) ou nos repositórios de busca.
- Ajuste de parâmetros de fusão (ex.: `alpha` do RRF) ou de chunking (`TOKEN_MAX`, `TOKEN_MIN`, `OVERLAP`).
- Troca do modelo de embedding ativo.
- Antes de bump SemVer minor/major do componente de busca.
- PR cujo checklist exige rodar a suite de evals (`<run-evals>`).
- Interpretar a saída do runner/subagente de evals do projeto.

## Quando NÃO usar

- Mudanças cosméticas em UI, docs ou camadas que **não tocam retrieval** — rodar a eval mede ruído e desperdiça tempo.
- Projetos **sem golden dataset** ainda: primeiro construa o dataset (queries + documentos relevantes esperados); esta skill pressupõe a existência dele.
- Avaliação de **geração** (qualidade de resposta de LLM, fidelidade de RAG end-to-end) — aqui só se mede a etapa de **recuperação**; avaliação de geração exige outro harness (LLM-judge, rubricas).

## Passos

### 1. Identificar o eixo da mudança

Antes de rodar a eval, classifique o tipo de mudança — isso define se promove baseline ou não:

| Eixo | Promove baseline? | Justificativa |
| :--- | :---: | :--- |
| Bug fix em retrieval | Sim, se houver delta positivo | Restaura comportamento correto |
| Troca de modelo de embedding | Sim (nova baseline obrigatória) | Métricas não são comparáveis entre modelos diferentes |
| Ajuste de parâmetro (alpha, chunk size) | Apenas se houver delta positivo e per-query limpo | Trade-off intencional |
| Refactor sem mudança comportamental | Não (delta deve ser ~0) | Drift indica bug |

### 2. Rodar evals em branch base e branch da mudança

**Sempre reindexar antes de medir** — chunks stale invalidam o resultado:

```bash
<clean-data>     # remove DBs e corpus de teste
<migrate>        # aplica schema limpo
<run-evals>      # roda o golden dataset → eval/current.json
```

Para comparação branch-a-branch:

```bash
# Na branch base (ex.: develop/main):
git checkout <base>
<clean-data> && <migrate> && <run-evals>
cp eval/current.json /tmp/eval-base.json

# Na branch da mudança:
git checkout feature/<branch>
<clean-data> && <migrate> && <run-evals>
cp eval/current.json /tmp/eval-feat.json
```

### 3. Comparar contra baseline

```bash
<eval-compare>
# tipicamente algo como:
#   <eval-runner> compare --baseline eval/baseline.json --current eval/current.json
```

Saída típica de um comparador de evals:

```
Metric           Baseline   Current    Delta
mrr_at_10        0.820      0.835     +0.015  OK
recall_at_10     0.850      0.833     -0.017  WARN
recall_at_20     0.910      0.915     +0.005  OK
ndcg_at_10       0.780      0.795     +0.015  OK

Per-query regressions:
  Q007: rank 1 -> 3
  Q014: rank 2 -> 8
```

### 4. Aplicar gates (ver §Gates abaixo)

Aplicar a tabela de bloqueio **mecanicamente**. Não negociar threshold "porque a regressão é pequena" — se passar do limite, **bloqueia**.

### 5. Decisão final no PR

- **Aprova** → comentar no PR com a tabela de deltas + decisão de promover baseline (sim/não). Se promover, gerar PR follow-up:
  ```bash
  cp eval/current.json eval/baseline.json
  git add eval/baseline.json
  git commit -m "chore(evals): atualiza baseline pós-<mudança>"
  ```
- **Bloqueia** → marcar `request changes` (ou acionar o agente revisor do projeto, se existir) com a métrica violada + per-query offenders. Não merge.

### 6. Se a baseline estiver desatualizada

Sinais de baseline stale:

- `baseline.json` foi gerada com modelo de embedding diferente do atual.
- O `git_sha` registrado na baseline tem mais de ~30 dias.
- O golden dataset teve queries adicionadas/removidas desde a baseline.

**Não promover baseline no mesmo PR que muda algoritmo** — invalida a comparação (antipadrão clássico). Abrir PR separado **antes**: regenerar a baseline com a branch base limpa, commitar como `chore(evals): refresh baseline`, e só então o PR da mudança roda contra a baseline nova.

## Métricas

Definições operacionais:

- **Recall@10**: fração das queries em que **pelo menos um chunk relevante** aparece nos top-10. Métrica de cobertura — "o sistema encontra a resposta?". Alvo absoluto sugerido: ≥ 0.80 (`<RECALL_MIN>`) sobre o conjunto completo de queries do golden — recomenda-se um golden com **pelo menos ~30 queries**; abaixo disso cada query vale >3 pontos percentuais e o gate vira loteria estatística.

- **MRR@10** (Mean Reciprocal Rank): média de `1/rank` da **primeira ocorrência relevante** no top-10; 0 se não aparece. Métrica de qualidade do ranking — "quão alto está o melhor resultado?". Sensível à primeira posição: rank 1 = 1.0, rank 2 = 0.5, rank 3 = 0.33.

- **NDCG@10** (Normalized Discounted Cumulative Gain): considera **todas as posições** no top-10 com desconto logarítmico, normalizado pelo ranking ideal. Métrica composta — "quão bem ordenado está o conjunto inteiro?". Mais robusta que MRR para queries com múltiplos relevantes.

- **Recall@20**: cobertura estendida; útil para diagnosticar se o problema é de **ranking** (Recall@10 baixo, Recall@20 alto) ou de **representação** (ambos baixos — o chunk não está sendo encontrado em nenhum top-K).

Heurística rápida de diagnóstico:

| Sintoma | Causa provável |
| :--- | :--- |
| Recall@10 cai, Recall@20 estável | Problema de ranking (fusão/RRF, alpha) |
| Recall@10 e Recall@20 caem | Problema de representação (embedder, chunker) |
| MRR cai, Recall estável | Resultado relevante desce no rank — degradação fina |
| NDCG cai, MRR estável | Múltiplos relevantes mal ordenados |

## Gates

Regras mecânicas de bloqueio (thresholds default recomendados — parametrize no `<GATE-DOC>` do seu projeto):

| Condição | Decisão |
| :--- | :--- |
| Recall@10 regressão > 3 pontos percentuais | **BLOQUEIA** merge (gate canônico de CI) |
| MRR@10 regressão > 2 pontos percentuais | Exige justificativa explícita no PR; **bloqueia** se > 5pp |
| > 5 queries com queda > 5 posições no rank | **BLOQUEIA** merge |
| Query com `priority: high` no golden caindo do top-10 | **BLOQUEIA** (regressão crítica, independente de média) |
| < 3 queries afetadas com drift pequeno (≤ 2 posições) | **APROVA** com nota — provável ruído de empate na fusão de rankings |
| Recall@10 absoluto cai abaixo de `<RECALL_MIN>` (ex.: 0.80) | **BLOQUEIA** incondicionalmente |
| NDCG@10 regressão > 4 pontos percentuais sem explicação | Exige investigação per-query antes de aprovar |

## Quando NÃO bloquear

Aprovação com nota (não bloqueia) é válida quando:

- **Baseline desatualizada** detectada (ver §Passo 6) — exigir refresh em PR separado, mas o PR atual não é o culpado.
- **Golden curado com erros** identificados durante a análise (`doc_id` obsoleto, query ambígua, relevância dúbia). Abrir issue `chore(evals): audita golden Qxxx`, não bloquear o PR de pipeline.
- **Mudança intencional de modelo de embedding** com decisão arquitetural registrada (ADR ou equivalente) — métricas não são comparáveis entre modelos. Promover nova baseline no mesmo PR é **obrigatório** nesse caso.
- **Trade-off documentado** — ex.: troca por modelo menor para reduzir latência aceita -2pp de Recall em troca de -40% no p95. A decisão precisa estar **explícita** no corpo do PR + registro de decisão.
- **Regressão em 1 query de `priority: low`** com outras causas identificadas (corpus de teste alterado, chunk antigo deletado).

## Armadilhas comuns

- **Golden dataset com erros silenciosos.** `doc_id` obsoleto após refactor, query ambígua, relevância subjetiva. **Auditar o golden a cada ~30 dias** ou ao adicionar 5+ queries; rodar smoke test que confirma que todos os documentos em `relevant_docs` ainda existem no corpus de teste.

- **Comparar contra baseline gerada com modelo diferente.** Invalida a métrica — chunks/vetores de modelos diferentes não são comparáveis. Sempre conferir o campo `embedding_model` no header da baseline.

- **Aceitar drift "pequeno" sem investigar per-query.** A métrica agregada esconde regressão concentrada em queries críticas. Sempre olhar a seção `Per-query regressions:` do report; uma query `priority: high` caindo do rank 1 para o 6 é mais grave que 5 queries `low` indo de 8 para 9.

- **Rodar eval sem reindexar.** Chunks ficam stale e a comparação mede ruído de cache, não a mudança. Sempre `<clean-data> && <migrate> && <run-evals>` antes de medir — a limpeza é obrigatória, não opcional.

- **Misturar mudança de algoritmo com mudança de dataset.** Adicionar/remover queries do golden no mesmo PR que muda o pipeline torna a comparação inválida. PRs de dataset são separados, com label `chore(evals): refresh golden`.

- **Promover baseline sem revisão humana.** Auto-promoção em CI gera *baseline rot* silencioso. Promoção é commit explícito (`chore(evals): atualiza baseline pós-<mudança>`) com diff revisado.

- **Ignorar `rank_first_relevant = 0`** no per-query. Significa "não encontrou nada relevante em k" — o pior tipo de regressão. Conta como queda de ∞ posições, não como "ruído".

## Verificação

Antes de marcar a eval como concluída e o PR como aprovado:

```bash
# 1. Pipeline limpo (a limpeza de dados é obrigatória)
<clean-data> && <migrate> && <run-evals>

# 2. Comparação contra baseline
<eval-compare>

# 3. Conferir baseline antes de promover (se aprovado)
diff eval/baseline.json eval/current.json

# 4. Gate de PR completo (lint + testes + evals)
<verify>
```

Checklist final:

- [ ] `embedding_model` do `current.json` confere com o da `baseline.json` (ou a troca de modelo está justificada em registro de decisão).
- [ ] Nenhum gate da §Gates foi violado.
- [ ] Per-query offenders foram inspecionados manualmente (não só o agregado).
- [ ] Decisão de promover baseline está explícita no PR body (sim/não + razão).
- [ ] Se promovida, o commit `chore(evals): atualiza baseline pós-<mudança>` está no histórico.

## Adaptação

Pontos parametrizáveis ao adotar esta skill num projeto:

- **`<run-evals>`** — comando que executa a suite contra o golden dataset (ex.: `just evals`, `make evals`, `npm run evals`). Deve produzir um relatório versionável (ex.: `eval/current.json`).
- **`<eval-compare>` / `<eval-runner>`** — comando/binário que compara `current` vs `baseline` e imprime deltas + regressões per-query.
- **`<clean-data>` / `<migrate>`** — comandos que zeram os dados de teste e reaplicam o schema limpo antes de reindexar.
- **`<verify>`** — gate local completo do projeto (lint + testes + evals).
- **`<base>`** — branch de integração do repositório (`develop`, `main`...).
- **`<RECALL_MIN>`** — piso absoluto de Recall@10 (default recomendado: 0.80). Registre-o no documento de gates do projeto.
- **`<GATE-DOC>`** — documento onde os thresholds dos gates ficam registrados como norma (spec de avaliação, ADR, doc de CI). Os valores da tabela §Gates são defaults sensatos, não dogma.
- **Layout dos artefatos** — `eval/golden.yaml` (dataset: queries com `priority` e lista de `relevant_docs`), `eval/baseline.json` e `eval/current.json` (com header contendo `embedding_model` e `git_sha`). Adapte os caminhos ao layout do repositório.
- **`doc_id` / `relevant_docs` / corpus** — nomes genéricos para o identificador de documento, a lista de relevantes por query e o conjunto de documentos de teste; renomeie conforme o domínio (notas, artigos, tickets...).
- **Subagentes** — se o projeto tiver um subagente executor de evals e/ou um revisor que bloqueia merges, acione-os nos passos 3 e 5; senão, execute manualmente.
