---
name: chunking-rules
description: "Governança do pipeline de chunking de um corpus de documentos (indexação para busca semântica/RAG). Acionar ao tocar no chunker, no tokenizador, no orquestrador de ingestão, nas constantes de chunking (TOKEN_MAX/TOKEN_MIN/OVERLAP_SENTENCES), na ChunkerConfig, no prefixo passage: ou na identidade do modelo de embedding ativo. Previne quebra de determinismo, mistura de modelos num mesmo documento, pulo do prefixo passage: em chunks indexados e mudança silenciosa de parâmetros sem cutover obrigatório."
---

# chunking-rules — garante determinismo e governança de mudanças no pipeline de chunking (TOOL · v1.0.0 · Alex Jesus)

## Quando usar

Carregue esta skill em qualquer task que toque:

- O **módulo do chunker** — os passes 1/2/3 do algoritmo (ex.: `chunk_markdown`, `chunk_markdown_full`, `split_one_long`, `pass2_split_long`, `pass3_merge_short` na implementação de referência).
- O **módulo de tokenização** — a abstração `Tokenizer` (trait/interface) e suas implementações (ex.: `WhitespaceTokenizer` offline, `HfTokenizer` real), além do splitter de sentenças.
- O **orquestrador de ingestão** (`<fn-ingest>`) — o fluxo documento → chunker → embedder.
- O **embedder** — a identidade do modelo (`EmbedderIdentity` ou equivalente) e o ponto único onde o prefixo `passage:` é aplicado.
- Qualquer campo da **`ChunkerConfig`** (`token_max`, `token_min`, `overlap_sentences`, extensões do parser Markdown).
- O **modelo de embedding ativo** na configuração do serviço de indexação (troca de E5-small por BGE-M3 etc.).

Em qualquer um desses casos o gate é o mesmo: **a mudança não pode quebrar determinismo, o invariante de modelo único por documento (`<INV-modelo-unico>`), o prefixo `passage:` nem o protocolo de cutover.**

## Quando NÃO usar

- Mudanças que **não tocam o pipeline de chunking/ingestão** (UI, docs, camadas de transporte) — o checklist inteiro mede ruído.
- Avaliação de regressão de **retrieval** em si (Recall@K / MRR@K vs baseline) — isso é assunto da skill `retrieval-eval`; esta skill governa a **mudança** no chunking, e delega a medição a ela.
- Projetos **sem corpus indexado em produção/uso real**: se nada foi indexado ainda, não há chunks a invalidar — o protocolo de cutover não se aplica (mas determinismo e versionamento já valem desde o primeiro commit).

## Princípios inegociáveis

1. **Determinismo** — mesma entrada + mesma `ChunkerConfig` + mesmo tokenizador → mesmos chunks (`ChunkDraft`s ou equivalente) na mesma ordem. Validado por testes de determinismo no próprio módulo (rodar a função 2× e comparar) **e** pelos testes de aceitação de chunking do projeto (`<SPEC-testes>`).
2. **Tokenização real** — contagem de tokens passa **sempre** pela abstração `Tokenizer`. A heurística "1 token ≈ 4 chars" é **proibida** (`<SPEC-chunking>` deve registrar essa proibição como norma).
3. **Versionamento da config** — qualquer alteração em `token_max`, `token_min` ou `overlap_sentences` produz chunks com **fronteiras diferentes** ao reindexar. Isso obriga bump SemVer da `<SPEC-chunking>` e cutover (re-enfileirar todos os documentos vivos do corpus).
4. **Tripla `(name, version, dim)` por chunk** — invariante `<INV-modelo-unico>`: chunks do mesmo documento compartilham identidade de embedder idêntica; a busca semântica filtra por essa tripla. Trocar o modelo sem cutover deixa chunks órfãos invisíveis ao retrieval.
5. **Prefixo `passage: ` em chunks indexados** — modelos da família E5 exigem o prefixo aplicado **dentro** do embedder, não pelo chamador. Para queries usa-se `query: ` (simetricamente, no método de embed de query). Outros modelos (BGE-M3) podem dispensar; **nunca presumir** — confirmar no registro de decisão do modelo (`<ADR-embeddings>`) e na identidade do embedder da implementação.

## Passos

### 1. Identificar a classe de mudança

Categorize antes de tocar em código. Cada classe tem checklist diferente.

| Classe | Exemplo | Gravidade |
| :--- | :--- | :--- |
| **A — Constante de chunking** | Mudar `token_max` 480 → 512 | Alta (cutover obrigatório) |
| **B — Lógica do chunker** | Alterar o passe de merge para fundir com o vizinho seguinte | Alta (cutover + snapshot) |
| **C — Tokenizador** | Substituir o splitter de sentenças por algo unicode-aware | Média (afeta o overlap no Pass 2) |
| **D — Modelo de embedding** | Trocar E5-small por BGE-M3 | Crítica (registro de decisão + dual-write) |
| **E — Refactor sem mudança de saída** | Renomear função, extrair helper | Baixa (basta snapshot + lint) |

### 2. Consultar a especificação e o registro de decisão de referência

Antes de editar, abrir e **citar no PR/commit** o trecho normativo que embasa a mudança:

- **Constantes** (`token_max`/`token_min`/`overlap_sentences`): tabela de defaults da `<SPEC-chunking>`.
- **Algoritmo dos passes** (split por estrutura → split por tamanho → merge de curtos): seção do algoritmo na `<SPEC-chunking>`.
- **Prefixo `passage:`:** `<SPEC-chunking>` + `<ADR-embeddings>`.
- **Tokenização real (não heurística):** seção de convenções de tokenização da `<SPEC-chunking>`.
- **Invariante de modelo único:** `<SPEC-dominio>` (`<INV-modelo-unico>`) + o erro tipado correspondente (ex.: `ModelMismatch`).
- **Cutover de modelo:** `<ADR-embeddings>` § estratégia de migração (dual-write até 100% reembedado).

Se a especificação não cobre o caso → **parar** e atualizar a spec **antes** de qualquer linha de código (acionando o processo/subagente de guarda de spec do projeto, se existir).

### 3. Bump SemVer na spec de chunking quando a mudança altera fronteiras

Regra clara:

- **Patch (`0.x.y → 0.x.(y+1)`):** correção de typo, refactor sem mudança observável, docstring nova.
- **Minor (`0.x.y → 0.(x+1).0`):** novo parâmetro opcional na `ChunkerConfig`, nova extensão do parser Markdown, novo modelo de embedding **aditivo** (dual-write em curso).
- **Major (`0.x.y → 1.0.0` ou bump de major):** mudança que produz chunks diferentes para a mesma entrada — `token_max`, `token_min`, `overlap_sentences`, troca da regra de qualquer passe.

A regra de ouro: **se a saída da função principal de chunking muda para algum input pré-existente do golden dataset, é major.**

### 4. Cutover obrigatório em mudanças que invalidam chunks

Quando classe A, B ou D acima:

1. Criar issue/task "**cutover obrigatório — re-enfileirar todos os documentos vivos com `reason='chunker_params_changed'`**" (ou `'embedding_model_changed'`).
2. Confirmar que a operação de reindexação do repositório de chunks é **transacional**: `DELETE` dos chunks antigos do documento + `INSERT` dos novos, atomicamente (nunca um estado intermediário visível à busca).
3. Para troca de modelo, seguir a estratégia de migração do `<ADR-embeddings>`: **dual-write com cutover**, não bloqueio. Buscas operam em duas pools até 100% reembedado.
4. Trilha de auditoria registra início e fim do cutover (se o projeto mantém invariante de auditoria — `<INV-auditoria>`).

### 5. Garantir prefixos consistentes

Conferir, em PR que toque embedder ou ingestão:

- O método de embed de passagens aplica `passage: ` **internamente** (ex.: `format!("passage: {t}")`); chamadores **passam texto bruto**.
- O método de embed de query aplica `query: ` simetricamente.
- Se introduzir novo modelo, decidir **explicitamente** no registro de decisão se ele exige prefixo. **Default seguro:** assumir que exige e implementar via método na abstração de identidade do embedder (ex.: `EmbedderIdentity::passage_prefix()`) em vez de literal espalhado. Se o prefixo estiver hoje embutido numa implementação concreta, generalizar para a abstração **antes** de adicionar o segundo modelo.

### 6. Adicionar snapshot test para mudanças no chunker

Mudanças no chunker que **mudam intencionalmente** a saída exigem snapshot novo (em Rust, via `insta`; em outras stacks, o mecanismo de snapshot equivalente):

```rust
#[test]
fn snapshot_chunks_fixture_canonica() {
    let txt = include_str!("../../tests/fixtures/exemplo-canonico.md");
    let chunks = chunk_markdown_full(txt, &ChunkerConfig::default(), &WhitespaceTokenizer);
    insta::assert_yaml_snapshot!(chunks);
}
```

Sem snapshot, "determinismo" vira promessa não verificável.

### 7. Rodar evals antes/depois para capturar drift

```bash
<run-evals>         # baseline atual
# ... aplicar mudança ...
<run-evals>         # novo
```

Comparar Recall@10 / MRR@10. Regressão acima do gate do projeto (default recomendado: **>3 pontos percentuais em Recall@10**) **bloqueia merge**. Se a mudança é deliberada e mantém qualidade, anotar o baseline novo no PR (procedimento completo na skill `retrieval-eval`).

## Armadilhas comuns

- **"1 token = 4 chars".** Antipadrão explícito. Sempre passar pela abstração `Tokenizer`. Em testes pesados use a implementação offline (ex.: `WhitespaceTokenizer`); em produção, o tokenizador real do modelo (ex.: `HfTokenizer` carregando o `tokenizer.json` do modelo).
- **Mudar `token_max` silenciosamente sem cutover.** Chunks antigos ficam fora da janela do novo recorte; a busca semântica degrada sem mensagem clara. Sempre acompanhar de re-enfileiramento total.
- **Esquecer o prefixo `passage: ` em chunks indexados.** Modelos E5 são treinados com prefixo; sem ele, os embeddings são piores e ainda assim "funcionam" (sem crash), degradando o retrieval em silêncio. Manter o literal num **ponto único** do embedder — se sair dali, validar para onde foi.
- **Misturar identidades de modelo diferentes no mesmo documento.** Viola `<INV-modelo-unico>`; a busca semântica pode retornar lista vazia ou ranking incoerente. Garantir que o orquestrador de ingestão lê a identidade do embedder **uma vez por documento** e a propaga para todos os chunks.
- **Marcar o chunker como "determinístico" sem snapshot test.** Um assert `r1 == r2` na mesma execução **não** garante que a saída não mudou entre commits. Snapshot é o único cinto de segurança real.
- **Quebrar o overlap em tabelas/blocos de código.** Se a spec do projeto define que tabelas e code blocks **não** carregam overlap entre sub-chunks, e o passe de split corta por `\n\n` (parágrafo) sem distinção — qualquer refinamento precisa respeitar esse contrato explicitamente.
- **Renumerar `position` fora do ponto final.** Se a implementação re-numera as posições dos chunks **uma única vez ao fim** do pipeline, funções intermediárias deixam `position = 0`. Não reordenar fora desse ponto.
- **Alterar o passe de merge sem reler a spec.** Divergências conhecidas entre spec e implementação (ex.: a spec diz "funde com o vizinho seguinte" e o código funde com o **anterior**) devem estar documentadas; qualquer refinamento exige bump da spec ou da implementação para casar — nunca deixar a divergência crescer em silêncio.

## Verificação

Antes de marcar o PR como pronto:

- [ ] **Classe da mudança identificada** (A–E) e checklist aplicado.
- [ ] **`<SPEC-chunking>` atualizada** com bump SemVer apropriado quando a saída muda.
- [ ] **Cutover planejado** (issue criada + registro na trilha de auditoria) em mudanças classe A/B/D.
- [ ] **Snapshot** adicionado/aprovado quando a lógica do chunker muda.
- [ ] **Prefixo `passage: `** preservado em chunks indexados.
- [ ] **Identidade de embedder única** por documento nos chunks resultantes.
- [ ] **Abstração `Tokenizer`** usada em qualquer contagem nova; nenhuma estimativa por chars.
- [ ] **Testes passam** (`<run-tests>`), incluindo os testes de determinismo e dos passes do chunker.
- [ ] **Evals rodadas** (`<run-evals>`); regressão de Recall@10 dentro do gate ou justificada no PR.
- [ ] **Lint limpo** (`<verify>` — fmt + lint do projeto sem warnings).

```bash
<run-tests> chunker
<run-tests> tokenizer
<verify>
<run-evals>
```

## Adaptação

Pontos parametrizáveis ao adotar esta skill num projeto:

- **`<SPEC-chunking>`** — documento normativo do pipeline de chunking/retrieval: tabela de defaults (`TOKEN_MAX`/`TOKEN_MIN`/`OVERLAP_SENTENCES`), algoritmo dos passes, convenções de tokenização (incl. a proibição da heurística de chars), regra de overlap em tabelas/code blocks e o gate de CI de regressão. Se o projeto não tem spec, crie ao menos um doc curto com esses itens — esta skill pressupõe a existência de uma norma citável.
- **`<SPEC-dominio>` / `<INV-modelo-unico>`** — onde o projeto registra o invariante "todos os chunks de um documento compartilham a mesma identidade de modelo de embedding `(name, version, dim)`" e o erro tipado correspondente (ex.: `ModelMismatch`).
- **`<SPEC-testes>`** — os testes de aceitação de chunking do projeto. Cobertura mínima recomendada: documento canônico com headings, split por `token_max` e bloco atômico sem headings.
- **`<ADR-embeddings>`** — registro de decisão do modelo de embedding: qual modelo, se exige prefixos `passage:`/`query:`, normalização (ex.: L2) e a estratégia de migração de modelo (dual-write com cutover).
- **`<INV-auditoria>`** — invariante de trilha de auditoria, se o projeto mantém audit log de mutações; senão, registre início/fim do cutover na issue.
- **`<fn-ingest>`** — função/serviço orquestrador da ingestão (documento → chunker → embedder → persistência).
- **`<run-tests>` / `<run-evals>` / `<verify>`** — comandos do projeto para testes (ex.: `cargo test -p <crate>`, `pytest`), suite de evals contra o golden dataset (ex.: `just evals`, `make evals`) e gate local completo (fmt + lint + testes).
- **Identificadores de código** — `ChunkerConfig`, `ChunkDraft`, `EmbedderIdentity`, `Tokenizer`, `WhitespaceTokenizer`, `HfTokenizer`, `chunk_markdown_full` etc. são nomes da implementação de referência (Rust); mapeie para os equivalentes do seu codebase. O snapshot do passo 6 usa `insta` (Rust) — em JS/TS use snapshots do Jest/Vitest, em Python `syrupy`.
- **Domínio** — "documento" aqui é a unidade indexável do corpus (nota, artigo, ticket, página); renomeie conforme o domínio.
- **Skill complementar** — a medição de regressão do passo 7 está detalhada na skill `retrieval-eval` (gates mecânicos, baseline, per-query).
