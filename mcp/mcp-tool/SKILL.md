---
name: mcp-tool
description: "Use ao implementar ou modificar uma tool MCP num servidor com contratos versionados em SPEC. Cobre o caminho completo: contrato no documento de contratos, handler com tipos derivados, validação de invariantes, registro de auditoria, dry-run em writes e testes de aceitação. Aciona-se para qualquer alteração no módulo de tools do servidor MCP."
---
# mcp-tool — implementar uma tool MCP com contrato versionado (TOOL · v1.0.0 · Alex Jesus)

Fluxo spec → teste → implementação → auditoria para servidores MCP que mantêm
um documento de contratos de tools (`<SPEC-contratos>`) como referência humana
e derivam o JSON Schema vivo dos tipos da linguagem.

## Quando usar

Adicionar nova tool, modificar contrato de tool existente ou alterar
comportamento de tool no servidor MCP do projeto.

## Quando NÃO usar

- Diagnosticar tool call que falhou em runtime (use a skill `mcp-debug`).
- Mudanças no transporte MCP (stdio/SSE, handshake) — fora do escopo do
  contrato de tools.
- Projetos sem documento de contratos: adote primeiro a prática (passo 1 exige
  o documento), ou esta skill perde a espinha dorsal.

## Checklist em 10 passos

### 1. Localizar o contrato canônico no documento de contratos

Abrir `<SPEC-contratos>` e confirmar que a tool está catalogada com:

- Nome `<prefixo>.<verbo>_<entidade>`
- JSON Schema de input
- JSON Schema de output
- Erros possíveis
- Declaração de idempotência

Se não existir, **parar e propor adição ao `<SPEC-contratos>`** (bump minor).
Não implementar tool ad-hoc.

### 2. Identificar invariantes aplicáveis

Para tools de **escrita**, no mínimo:

- **Auditoria obrigatória** — toda mutação gera entrada na
  `<tabela_de_auditoria>`.
- **Concorrência otimista** — toda escrita exige `expected_content_hash`.
- **Paridade de índices** — pares de tabelas-índice derivadas (ex.:
  `chunks ↔ fts ↔ vec`) permanecem consistentes.

Para tools de **leitura**:

- **Identidade de embeddings** — busca semântica compara apenas chunks do
  mesmo modelo/versão/dimensão.

### 3. Localizar o módulo certo

Organize as tools por família no módulo de tools do servidor (exemplo de
layout):

```
<modulo_mcp>/src/tools/
├── search.rs        ← tools de busca (semântica, lexical, híbrida)
├── read.rs          ← tools de leitura (get, listar, ler seções)
├── graph.rs         ← tools de grafo/conexões
├── write.rs         ← tools de escrita (criar, append, update, mover)
└── admin.rs         ← reindex, stats, health
```

### 4. Implementar o handler com tipos derivados

Derive o JSON Schema dos tipos da linguagem (ex.: `schemars` em Rust) —
**nunca escreva schema à mão duplicando o que está no documento de
contratos**. O schema vivo é o gerado; o documento é a referência humana.

```rust
use rmcp::tool;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct UpdateSectionInput {
    pub doc_id: String,
    pub section_id: String,
    pub new_content: String,
    pub expected_content_hash: String,
    #[serde(default)]
    pub dry_run: bool,
}

#[derive(Debug, Serialize, JsonSchema)]
pub struct UpdateSectionOutput {
    pub before_hash: String,
    pub after_hash: String,
    pub diff_unified: String,
}

#[tool(name = "<prefixo>.update_section", description = "...")]
pub async fn update_section(
    ctx: &McpContext,
    input: UpdateSectionInput,
) -> Result<UpdateSectionOutput, McpError> {
    // 1. Validar entrada
    // 2. Ler estado atual + comparar expected_content_hash → STALE_CONTENT se divergir
    // 3. Adquirir advisory lock (timeout 5s) → LOCK_TIMEOUT se falhar
    // 4. Calcular diff
    // 5. Se dry_run, retornar sem mutar
    // 6. Escrita atômica: tmp + fsync + rename
    // 7. Enfileirar reindex async
    // 8. Registrar na <tabela_de_auditoria>
    // 9. Liberar lock
    // 10. Retornar output
}
```

### 5. Erros tipados

```rust
#[derive(Debug, thiserror::Error)]
pub enum McpError {
    #[error("STALE_CONTENT: expected {expected}, found {actual}")]
    StaleContent { expected: String, actual: String },

    #[error("SECTION_NOT_FOUND: {section_path}")]
    SectionNotFound { section_path: String },

    #[error("LOCK_TIMEOUT: could not acquire lock on {path} within 5s")]
    LockTimeout { path: String },
    // ...
}
```

**Códigos de erro = strings estáveis do `<SPEC-contratos>`.** Não inventar
códigos novos sem bump do documento.

### 6. Registro de auditoria

Antes do retorno (sucesso OU erro tratado), gravar:

```rust
ctx.audit().record(AuditEntry {
    caller: Caller::Llm(ctx.caller_id()),
    action: "<prefixo>.update_section",
    target: Some(EntityId::Doc(doc_id)),
    args_hash: blake3_of(&input),
    result_status: result.as_audit_status(),
    diff: Some(unified_diff),
    // timestamp etc.
}).await?;
```

### 7. Dry-run obrigatório para writes

Toda tool de escrita aceita `dry_run: bool`:

- `dry_run = true`: computa o diff completo, **não muta nada**, retorna como
  se tivesse mutado.
- `dry_run = false`: aplica de fato.

Implemente como uma única função com branch no fim:

```rust
let plan = compute_plan(...).await?;  // sempre executa
if input.dry_run {
    return Ok(plan.to_output_preview());
}
apply_plan(plan).await?;
```

### 8. Teste de aceitação

No diretório de testes de aceitação do projeto
(`<diretório_de_testes_de_aceitação>`), adicionar o cenário correspondente do
documento de testes de aceitação (`<SPEC-testes>`). Se o projeto tiver um
subagente de autoria de testes, usá-lo — o teste vem **antes** da
implementação.

### 9. Registrar a tool no server

```rust
// <modulo_mcp>/src/server.rs
server.register_tool::<UpdateSection>();
```

### 10. Verificar end-to-end

```bash
<check>                  # fmt + lint com warnings como erro
<test> <modulo_mcp>      # suite do módulo MCP
<comando_harness>        # testes de aceitação/harness
<cli> serve --data <fixture_de_dados>
# Em outro terminal:
mcp-cli call <prefixo>.update_section '{"doc_id":"...","section_id":"...","new_content":"...","expected_content_hash":"...","dry_run":true}'
```

## Armadilhas comuns

- **Esquecer o prefixo de namespace (`<prefixo>.`)** no nome — outros
  servidores MCP no mesmo cliente podem colidir.
- **Schema do documento de contratos e schema gerado divergem** — fixar com
  testes que comparam ambos.
- **Lock que não é liberado em erro** — usar guard pattern (`Drop` libera
  automaticamente).
- **`expected_content_hash` opcional** — em writes, é obrigatório; tornar
  `String`, não `Option<String>`.
- **Auditoria dentro da transação errada** — se a escrita falhar, a auditoria
  deve registrar a tentativa com `result_status = error:<code>`. Logar fora da
  transação principal.
- **Snapshot de `diff_unified` em teste com paths absolutos** — usar paths
  relativos.

## Verificação antes de marcar como pronto

- [ ] Tool está no `<SPEC-contratos>` com schema completo.
- [ ] Handler implementa todos os 10 passos.
- [ ] Teste de aceitação correspondente passa.
- [ ] Lint limpo com warnings tratados como erro (ex.:
      `cargo clippy -- -D warnings`).
- [ ] `<tabela_de_auditoria>` contém entrada após cada chamada (sucesso e
      erro).
- [ ] Para tools de escrita: dry-run + apply ambos cobertos por teste.
- [ ] Cabeçalho de autoria do projeto presente (ex.: `@ai-generated` +
      `@spec <SPEC-contratos> §X.Y`), se o projeto usar marcação de autoria.

## Adaptação

Parametrize ao adotar num projeto:

- `<SPEC-contratos>` — documento versionado que cataloga as tools (nome,
  schemas, erros, idempotência); `<SPEC-testes>` — documento que enumera os
  cenários de aceitação. Se o projeto não os tem, criar antes de usar a skill.
- `<prefixo>` — namespace das tools do servidor (evita colisão entre
  servidores MCP no mesmo cliente).
- `<tabela_de_auditoria>` — tabela append-only de auditoria; o snippet do
  passo 6 ilustra a forma (caller, action, target, args_hash, result_status,
  diff) — adapte à sua API de auditoria.
- Invariantes do passo 2 — substitua pelos IDs do modelo de domínio do seu
  projeto (auditoria obrigatória, concorrência otimista, paridade de índices,
  identidade de embeddings); remova os que não se aplicam (ex.: identidade de
  embeddings só existe se houver busca semântica).
- `<modulo_mcp>` — crate/módulo do servidor MCP; o layout do passo 3 é
  sugestão de organização por família, não obrigação.
- `<check>` / `<test>` / `<comando_harness>` / `<cli>` /
  `<fixture_de_dados>` — comandos canônicos e fixture de dados do projeto
  (um task runner como `just`/`make` costuma encapsular).
- Os exemplos de código são Rust (`rmcp` + `schemars` + `thiserror`); em outra
  linguagem, mantenha a mecânica — tipos com schema derivado, erros tipados
  com códigos estáveis, guard de lock com liberação automática.
- `STALE_CONTENT` / `SECTION_NOT_FOUND` / `LOCK_TIMEOUT` — exemplos de códigos
  estáveis; alinhe com o catálogo do seu `<SPEC-contratos>` (mesma tabela
  usada pela skill `mcp-debug`).
