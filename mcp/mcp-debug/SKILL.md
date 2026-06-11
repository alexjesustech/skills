---
name: mcp-debug
description: "Use ao diagnosticar tool call MCP que falhou, retornou erro estável inesperado (STALE_CONTENT/LOCK_TIMEOUT/VALIDATION), devolveu resultado vazio em busca semântica, ou ao interrogar a tabela de auditoria para reproduzir cenário reportado por LLM/usuário. Cobre catálogo de códigos de erro estáveis, queries canônicas de auditoria e níveis de tracing por módulo."
---
# mcp-debug — diagnóstico de tool calls MCP que falharam (TOOL · v1.0.0 · Alex Jesus)

Skill para servidores MCP que seguem o padrão: **códigos de erro estáveis**
catalogados num documento de contratos (`<SPEC-contratos>`), **tabela de
auditoria append-only** (`<tabela_de_auditoria>`) registrando toda chamada, e
**escrita com concorrência otimista** (hash esperado do conteúdo).

## Quando usar

Carregar quando:

- Tool call retornou erro inesperado (códigos do catálogo `<SPEC-contratos>`).
- `<tabela_de_auditoria>` precisa ser interrogada para reconstituir o que
  aconteceu numa sessão.
- O daemon/servidor em dev precisa ser instrumentado para reproduzir um bug.
- LLM ou usuário reportou resultado errado (vazio, divergente, hash mismatch).
- Suspeita de quebra de invariante do modelo de domínio (auditoria obrigatória,
  concorrência otimista, identidade de embeddings, paridade de índices — ver
  § Adaptação).

## Quando NÃO usar

- Implementar ou alterar uma tool MCP (use a skill `mcp-tool`).
- Problemas de transporte/handshake do protocolo MCP em si (negociação de
  capabilities, framing stdio/SSE) — esta skill cobre o diagnóstico **da
  aplicação** atrás das tools.
- Servidores sem tabela de auditoria nem códigos de erro estáveis — boa parte
  das queries pressupõe esse desenho.

## Códigos de erro estáveis (catálogo de exemplo)

Strings canônicas definidas no `<SPEC-contratos>`; **não inventar** código novo
sem bump do documento. Pareiam com o campo `result_status` da
`<tabela_de_auditoria>` no formato `error:<código>`.

| Código | Origem | Diagnóstico rápido |
| :--- | :--- | :--- |
| `VALIDATION` | Qualquer | Input não passou no guard inicial do handler. Comparar com o JSON Schema gerado a partir dos tipos (ex.: `schemars` em Rust). Exemplos típicos: query vazia, título vazio, valor de enum inválido. |
| `STALE_CONTENT` | Escrita | `expected_content_hash` não bate com o hash em disco — alguém escreveu no meio do caminho. O LLM precisa re-ler o documento e tentar de novo (fluxo write-safe do `<SPEC-contratos>`). Erro tipado carrega `path`/`expected`/`actual`. |
| `LOCK_TIMEOUT` | Escrita | Advisory lock (ex.: `fd-lock`) não liberou no timeout (ex.: 5s). Outra escrita concorrente ou processo travado/crash. |
| `<ENTIDADE>_NOT_FOUND` | Leitura/escrita | ID ou path do alvo inexistente. Pode ser soft-delete (`deleted_at IS NOT NULL`) ou rename detectado pelo watcher mudando o path. |
| `SECTION_NOT_FOUND` | Escrita | ID/path da seção não encontrado dentro do documento. O parser de seções ressincronizou os headings? |
| `EMBEDDING_UNAVAILABLE` | Busca semântica | Modelo de embeddings ainda não carregado (servidor inicializando ou OOM na thread de inferência). Retry após 1-2s. |
| `PATH_COLLISION` | Criação/move | Path destino já ocupado por outro documento. |
| `INVALID_TITLE` | Criação | Título viola regras de filename (chars proibidos). |
| `INVALID_QUERY` | Busca lexical | Sintaxe de full-text inválida (ex.: operadores FTS5 não escapados). |
| `INDEX_CORRUPTED` | Qualquer | `PRAGMA integrity_check` falhou. Rodar o comando de verificação de DB do projeto (`<cli> db check`). |
| `STORAGE` | Qualquer | Erro genérico da camada de persistência. Ler o tipo de erro da camada de storage. |

## Passos canônicos de diagnóstico

### 1. Capturar o erro completo

Coletar do trace do MCP client:

- Código do erro (string estável da tabela acima).
- Mensagem completa (inclui `path:`/`expected:`/`actual:` em `STALE_CONTENT`).
- `caller_id` (se o cliente MCP envia — campo opcional nos params das tools).
- Timestamp aproximado da chamada.

### 2. Interrogar a tabela de auditoria

Schema de referência (colunas típicas: `timestamp`, `caller_kind`,
`caller_id`, `action`, `target_kind`, `target_id`, `result_status`,
`diff_unified`; índices em timestamp e em `(target_kind, target_id)`):

```sql
-- Últimas 20 entradas (consulta dominante, suportada pelo índice de timestamp).
SELECT timestamp, caller_kind, caller_id, action, target_kind, target_id, result_status
  FROM <tabela_de_auditoria>
  ORDER BY timestamp DESC
  LIMIT 20;

-- Entradas de um caller específico (sessão MCP).
SELECT timestamp, action, target_id, result_status, diff_unified
  FROM <tabela_de_auditoria>
  WHERE caller_id = '<session-id>'
  ORDER BY timestamp DESC
  LIMIT 50;

-- Histórico de um alvo (suportado pelo índice composto de target).
SELECT timestamp, caller_kind, action, result_status, diff_unified
  FROM <tabela_de_auditoria>
  WHERE target_kind = '<tipo>' AND target_id = '<uuid>'
  ORDER BY timestamp DESC;

-- Só erros nas últimas 24h (filtra ok; pega 'error:<código>').
SELECT timestamp, action, target_id, result_status
  FROM <tabela_de_auditoria>
  WHERE result_status LIKE 'error:%'
    AND timestamp >= datetime('now', '-1 day')
  ORDER BY timestamp DESC;

-- Frequência de cada código de erro nas últimas 24h.
SELECT result_status, COUNT(*) AS n
  FROM <tabela_de_auditoria>
  WHERE result_status LIKE 'error:%'
    AND timestamp >= datetime('now', '-1 day')
  GROUP BY result_status
  ORDER BY n DESC;
```

Conectar ao DB de dev (exemplo SQLite):

```bash
sqlite3 <caminho_do_indice>.db
.headers on
.mode column
```

### 3. Diagnóstico por código

#### `STALE_CONTENT`

1. Ler o arquivo atual: `cat $DATA_DIR/<path>`.
2. Calcular o hash com o mesmo algoritmo do projeto (ex.: `blake3sum`), ou usar
   o comando de verificação (`<cli> db check`) que computa para todos os
   documentos.
3. Comparar com o `expected_content_hash` que o LLM enviou.
4. Se divergir, identificar o autor da escrita intermediária na
   `<tabela_de_auditoria>` (filtrar por `target_id = '<uuid>'` em janela de
   tempo).
5. **Ação para o LLM:** re-ler via `<tool_de_leitura>`, pegar o novo hash de
   conteúdo, repetir o fluxo write-safe do `<SPEC-contratos>` do início.

#### `LOCK_TIMEOUT`

1. Verificar processos do servidor: `pgrep -a <daemon>`.
2. Listar locks ativos no diretório de dados:
   `lsof +D $DATA_DIR 2>/dev/null | grep -i lock`.
3. Se o daemon estiver travado: subir log do módulo de escrita em `debug`
   (`RUST_LOG=<crate_watcher>=debug`, ou equivalente) e relançar; checar o
   último log de "atomic write OK" no módulo de escrita atômica.
4. Se houve crash anterior: locks advisory (ex.: `fd-lock`) morrem com o
   processo (kernel libera), então um `LOCK_TIMEOUT` persistente normalmente
   indica contenção real, não lock órfão.

#### `VALIDATION` inesperado

1. Reproduzir o input exato que o LLM enviou (capturar do trace MCP).
2. Comparar com o JSON Schema publicado pelo servidor:
   ```bash
   # listar tools e schemas via cliente MCP
   mcp-cli tools/list   # ou o comando equivalente do seu cliente
   ```
3. Conferir o guard correspondente no handler — guards fail-fast no topo do
   handler (query vazia, título vazio, path inválido, enum inválida).
4. Se o input deveria ser válido mas falhou, o schema gerado a partir dos tipos
   (ex.: `schemars`) pode estar fora de sincronia com o handler — bug a
   reportar.

#### Resultado vazio em busca semântica/híbrida (mas chunks existem)

**Suspeitar do invariante de identidade de embeddings antes de tudo.** A busca
semântica compara apenas chunks da mesma tripla `(name, version, dim)` do
embedder ativo.

1. Verificar o embedder ativo:
   ```bash
   <cli> db check  # imprime a identidade do embedder
   ```
2. Verificar a identidade dos chunks gravados:
   ```sql
   SELECT embedding_model_name, embedding_model_version, embedding_dim, COUNT(*)
     FROM chunks
     GROUP BY embedding_model_name, embedding_model_version, embedding_dim;
   ```
3. Se a tripla do embedder ativo não aparece no grupo, **reindexar**: o corpus
   foi indexado com outro modelo. Localize o filtro de modelo na camada de
   busca para confirmar a mecânica.
4. Se a tripla bate mas vem vazio, validar a paridade entre as tabelas-índice
   pareadas (`chunks ↔ chunks_fts ↔ chunks_vec`):
   ```sql
   SELECT
     (SELECT COUNT(*) FROM chunks)      AS n_chunks,
     (SELECT COUNT(*) FROM chunks_fts)  AS n_fts,
     (SELECT COUNT(*) FROM chunks_vec)  AS n_vec;
   ```

### 4. Reproduzir o cenário

Três caminhos, do mais leve ao mais pesado:

```bash
# (a) Teste unitário isolado do handler — preferido p/ repro de bugs determinísticos.
<test> <nome_do_teste> -- --nocapture

# (b) Harness com fixture de dados realista.
<comando_harness>

# (c) Servidor em dev contra o diretório de dados de dev, mais cliente MCP de teste.
<comando_dev>
# Em outro terminal, com seu cliente MCP favorito:
mcp-cli call <tool_de_busca> '{"query":"...","k":10}'
mcp-cli call <tool_de_criacao> '{"title":"...","content":"...","caller_id":"repro-session-001"}'
```

## Tracing — níveis por módulo (exemplo Rust)

Com `tracing_subscriber` + `EnvFilter` lendo `RUST_LOG` (default
`<app>=info`), receitas úteis:

```bash
# Tudo do MCP server em debug.
RUST_LOG=<crate_mcp>=debug <comando_dev>

# Investigar o watcher (writes atômicos, locks, reconciliação FS↔DB).
RUST_LOG=<crate_watcher>=debug <comando_dev>

# Storage (PRAGMA integrity, carga de extensões SQLite).
RUST_LOG=<crate_storage>=debug <comando_dev>

# Combinado — comum em sessão de debug intensa.
RUST_LOG=<crate_mcp>=debug,<crate_watcher>=debug,<crate_storage>=info <comando_dev>

# Trace global (verboso; filtrar libs HTTP pra não estourar).
RUST_LOG=trace,h2=off,hyper=off <comando_dev>
```

Por módulo, o que esperar:

- Watcher/escrita: `debug!` de "atomic write OK", "rename detectado" e `warn!`
  de "path fora do diretório de dados".
- Storage: `debug!` de `PRAGMA integrity_check: ok`; `info!` em marcos de
  carga; `debug!` no registro de extensões.
- Handlers MCP: se ainda enxutos em logging, adicionar `tracing::debug!` em
  branches inesperados quando estiver instrumentando.

**Privacidade:** nunca logar conteúdo de documento do usuário em `info!`. Em
`debug!`, usar hash + tamanho em vez de texto.

## Armadilhas comuns

- **Filtrar a `<tabela_de_auditoria>` por `result_status = 'ok'` quando o
  objetivo é investigar falha** — perde justamente as linhas que importam. Use
  `LIKE 'error:%'` ou ausência de filtro.
- **Comparar hash do conteúdo SEM o frontmatter quando deveria incluir.** Se o
  projeto hasheia o documento inteiro (frontmatter + corpo), hash do corpo
  isolado não bate. Confira o que o handler de criação hasheia.
- **Subir o servidor sem reindexar e culpar o embedder pela paridade de índices
  falhando.** Se trocou o modelo de embedding, os chunks antigos têm tripla
  diferente — não somem, só são filtrados. Sintoma: busca retorna `[]` mas
  `SELECT COUNT(*) FROM chunks` é > 0.
- **Confundir o ID do documento com o ID do chunk em queries de auditoria.**
  `target_kind` distingue os tipos; filtrar pelos dois campos juntos
  (`target_kind = '<x>' AND target_id = '<y>'`) — usar só `target_id` ignora o
  índice composto.
- **Tomar `LOCK_TIMEOUT` como bug da lib de lock.** Em 99% dos casos é
  contenção legítima ou daemon travado em outra operação. Locks advisory
  liberam no `Drop`/encerramento do processo; lock órfão sobrevivendo a crash
  é raro (kernel limpa).

## Verificação (smoke test canônico)

```bash
# Integridade do DB + identidade do embedder + invariantes básicos.
<cli> db check

# Suite de testes do módulo MCP isoladamente (rápido).
<test> <modulo_mcp>

# Inspecionar a auditoria direto.
sqlite3 <caminho_do_indice>.db \
  "SELECT timestamp, action, result_status FROM <tabela_de_auditoria> ORDER BY timestamp DESC LIMIT 10;"

# Verificar que o servidor está respondendo.
RUST_LOG=<crate_mcp>=debug <comando_dev>
# noutro terminal: mcp-cli call <tool_de_busca> '{"query":"smoke","k":3}'
```

## Adaptação

Parametrize ao adotar num projeto:

- `<SPEC-contratos>` — o documento do projeto que cataloga os contratos das
  tools e os códigos de erro estáveis (a tabela acima é um **exemplo de
  catálogo**; substitua pelos códigos do seu projeto, mantendo o princípio:
  strings estáveis, formato `error:<código>` na auditoria, sem inventar código
  sem bump do documento).
- `<tabela_de_auditoria>` — tabela append-only de auditoria de chamadas;
  adapte nomes de colunas/índices se o seu schema divergir do esquema de
  referência usado nas queries.
- `<ENTIDADE>_NOT_FOUND` — code de "alvo inexistente" com o nome da sua
  entidade principal (documento, nota, registro).
- Invariantes citados (substitua pelos IDs do seu modelo de domínio):
  *auditoria obrigatória* (toda mutação gera linha de audit), *concorrência
  otimista* (escrita exige hash esperado), *identidade de embeddings* (busca
  compara só a mesma tripla name/version/dim), *paridade de índices* (tabelas
  `chunks ↔ fts ↔ vec` consistentes).
- `<cli>`, `<daemon>`, `<comando_dev>`, `<comando_harness>`, `<test>` —
  binário CLI, processo do servidor e comandos canônicos do projeto (ex. Rust:
  `cargo run -p <crate_cli> --`, `cargo test -p <crate>`; um task runner como
  `just`/`make` costuma encapsular).
- `<crate_mcp>` / `<crate_watcher>` / `<crate_storage>` — nomes dos
  módulos/crates nos filtros de log (`RUST_LOG` é específico do ecossistema
  Rust `tracing`; em outra stack, use o mecanismo de log levels equivalente).
- `<caminho_do_indice>.db` e `$DATA_DIR` — caminho do índice SQLite e do
  diretório de dados (vault/corpus) em dev.
- `<tool_de_leitura>` / `<tool_de_busca>` / `<tool_de_criacao>` — nomes reais
  das tools MCP do seu servidor.
- Nomes de tabela `chunks`/`chunks_fts`/`chunks_vec` e colunas
  `embedding_model_*` — ajuste ao schema do seu pipeline de
  chunking/embeddings.
- A regra de privacidade de logs deve apontar para a política do seu projeto.
