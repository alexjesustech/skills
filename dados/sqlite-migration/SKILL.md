---
name: sqlite-migration
description: "Use ao adicionar tabela, índice, coluna, view ou trigger num banco SQLite versionado por migrations. Garante numeração correta, cabeçalho obrigatório, idempotência, reversibilidade, padrão de duas migrations para mudanças destrutivas e atualização concomitante da documentação de schema."
---

# sqlite-migration — migrations SQLite disciplinadas: numeração, cabeçalho, idempotência e reversibilidade (TOOL · v1.0.0 · Alex Jesus)

## Quando usar

Qualquer alteração de schema do banco SQLite do projeto: novas tabelas, colunas, índices, triggers, views, FKs.

## Quando NÃO usar

- Mudanças que **não tocam o schema**: dados gravados pela aplicação, ou informação que cabe numa coluna JSON já existente (ver §Passo 1).
- Bancos que **não são SQLite** — as armadilhas e os padrões de idempotência aqui são específicos do SQLite (ex.: ausência de `ALTER TABLE ... IF NOT EXISTS` para colunas).
- Projetos cujo schema é gerenciado por ORM com fluxo próprio de migrations geradas (ex.: Django, Prisma, Eloquent) — siga o fluxo do ORM; esta skill assume migrations SQL escritas à mão.

## Passos

### 1. Confirmar necessidade

Antes de criar a migration, verificar:

- O caso de uso está descrito no documento de schema/domínio do projeto (`<DOC-SCHEMA>`) ou num registro de decisão (ADR) novo? Se não, **parar** e propor primeiro a atualização da documentação de domínio.
- A mudança pode ser feita sem schema change (uso de uma coluna JSON já existente, ex.: `metadata JSON`)? Se sim, **prefira** — evita migration desnecessária.

### 2. Numerar

```bash
ls migrations/ | grep -E '^V[0-9]{3}__' | sort | tail -1
```

Próximo = max + 1, formato `V<NNN>__<slug>.sql` (3 dígitos zero-padded).

### 3. Aplicar template canônico

Cabeçalho **não negociável**:

```sql
-- ============================================================================
-- Migration: V<NNN>__<slug>.sql
-- Autor:     <handle>
-- Data:      YYYY-MM-DD
-- Referência: <DOC-SCHEMA> §X.Y  ou  <ADR> §X
-- Propósito: <uma frase>
-- Reversível: sim/não  (se não, justificar)
-- Idempotente: sim/não
-- Pré-condições: V<NNN-1> aplicada
-- ============================================================================
```

### 4. Convenções de tipos

| Tipo de domínio | Tipo SQLite | Notas |
| :--- | :--- | :--- |
| ID (UUID v7) | `TEXT` | Lowercase hex 36 chars. |
| Hash de conteúdo (ex.: BLAKE3) | `TEXT` | Lowercase hex 64 chars. |
| Timestamp | `TEXT` | ISO-8601 UTC com `Z` (ex.: `2026-05-22T13:45:00Z`). |
| Booleano | `INTEGER` | `0` ou `1`. |
| JSON arbitrário | `TEXT` | Validar parse no app, não no DB. |
| Vetor embedding | `BLOB` | Em tabela virtual vetorial (ex.: gerenciada pelo sqlite-vec). |
| Enum (status, categoria) | `TEXT` | Validar via `CHECK` constraint quando o conjunto é finito. |

### 5. Idempotência

Toda DDL **deve ser idempotente quando viável**:

- `CREATE TABLE IF NOT EXISTS ...`
- `CREATE INDEX IF NOT EXISTS ...`
- `CREATE TRIGGER IF NOT EXISTS ...`

SQLite não tem `ALTER TABLE ... IF NOT EXISTS` para colunas. Para idempotência de `ADD COLUMN`, ou:

(a) garantir que o runner de migrations (ex.: `refinery`, `golang-migrate`, `dbmate`) nunca reaplica migrations já registradas (caminho default — OK);
(b) ou usar guard via `PRAGMA table_info(...)` em script de migration controlado pela aplicação.

### 6. Comentários nas colunas de domínio

Colunas de domínio recebem comentário inline no idioma do projeto (aqui, PT-BR):

```sql
CREATE TABLE documents (
    id            TEXT PRIMARY KEY,       -- UUID v7, ordenável por tempo
    path          TEXT NOT NULL UNIQUE,   -- caminho relativo à raiz do corpus
    content_hash  TEXT NOT NULL,          -- hash hex do arquivo bruto (ex.: BLAKE3)
    status        TEXT NOT NULL           -- enum: Active|Archived|Draft
        CHECK (status IN ('Active','Archived','Draft')),
    ...
);
```

### 7. Índices

- **Índice parcial** sempre que o filtro for fixo: `WHERE deleted_at IS NULL`.
- **Índice composto** com a coluna mais seletiva primeiro.
- Não criar índice "preventivo" — só quando há query que comprovadamente se beneficia.

### 8. Triggers de espelhamento (tabela-fonte ↔ FTS5 ↔ tabela vetorial)

Se o projeto espelha uma tabela-fonte em tabelas derivadas (ex.: `<tabela>` → `<tabela>_fts` para FTS5 e `<tabela>_vec` para busca vetorial), **qualquer alteração na tabela-fonte exige revisão dos triggers de espelhamento**. A consistência fonte↔derivadas é um invariante do sistema.

Em caso de dúvida, rodar o teste de invariante de espelhamento do projeto (`<TEST-ESPELHAMENTO>`) e garantir que continua passando.

### 9. Atualizar a documentação de schema simultaneamente

Mudanças que **adicionam, removem ou alteram semântica** de coluna/tabela exigem PR concomitante atualizando o documento de schema (`<DOC-SCHEMA>`), com bump SemVer minor se o documento for versionado.

**DB com drift em relação à documentação de schema = débito técnico imediato.** PR sem o update da doc é rejeitado em revisão.

### 10. Verificar

```bash
<migrate>           # aplica em DB de dev
<test-storage>      # testes da camada de persistência
<db-check>          # PRAGMA integrity_check + invariantes do projeto
<verify>            # gate completo (lint + testes)
```

## Padrão para mudanças destrutivas

Mudanças destrutivas (`DROP COLUMN`, `DROP TABLE`, mudança de tipo incompatível) seguem **duas migrations**:

1. `V<N>__add_new_column.sql` — adiciona o novo, mantém o antigo. O código de aplicação passa a ler/escrever em ambos.
2. `V<N+k>__drop_old_column.sql` — só depois que o código não usa mais o antigo e há backup.

A migration 2 fica **bloqueada por flag de configuração** que só é ativada após inspeção em ambiente real:

```sql
-- A flag `migration_v_NN_authorized = true` deve estar no arquivo de config
-- de migrations do projeto (ex.: config/migrations.toml).
-- Falhar com mensagem clara se não estiver.
```

## Armadilhas

- **Renomear coluna direto.** SQLite suporta a partir de versões recentes, mas quebra clientes intermediários. Usar o padrão de duas migrations.
- **FK sem `ON DELETE`.** O default é restritivo; explicitar `CASCADE` ou `SET NULL`, ou justificar `RESTRICT`.
- **Migration que toca muitas tabelas.** Misturar mudanças não relacionadas numa migration dificulta rollback. **Uma migration = um propósito.**
- **Mudar tabela vetorial sem dropar/recriar.** Alterar a dimensão do embedding numa tabela virtual vetorial (ex.: sqlite-vec) exige `DROP TABLE` + `CREATE` novo + reindex completo. Não pode ser `ALTER`.
- **`PRAGMA user_version`** é controlado pelo runner de migrations; não tocar manualmente.

## Verificação antes de marcar como pronto

- [ ] Migration tem cabeçalho completo.
- [ ] Numeração contínua a partir da última.
- [ ] PR inclui update do documento de schema (`<DOC-SCHEMA>`) quando o schema muda.
- [ ] `<migrate>` aplica sem erro em banco de teste.
- [ ] Teste de invariante de espelhamento (`<TEST-ESPELHAMENTO>`) passa, se aplicável.
- [ ] Comentários no idioma do projeto onde o domínio é institucional.
- [ ] Idempotência declarada e verificada.

## Adaptação

Pontos parametrizáveis ao adotar esta skill num projeto:

- **`<DOC-SCHEMA>`** — documento canônico do modelo de domínio/schema do projeto (spec, ERD versionado, doc de arquitetura). Toda migration o referencia no cabeçalho e o atualiza quando a semântica muda. **Se o projeto não mantém um**, o cabeçalho da migration passa a ser a própria documentação (preencha "Propósito" com mais rigor) — ou crie um `docs/SCHEMA.md` mínimo na primeira migration.
- **`<ADR>`** — registro de decisão arquitetural do projeto, citado quando a migration nasce de uma decisão estrutural.
- **Runner de migrations** — esta skill assume layout `migrations/V<NNN>__<slug>.sql` (estilo `refinery`/Flyway). Adapte numeração e nomes ao runner em uso (ex.: `golang-migrate` usa pares `up`/`down`).
- **`<migrate>` / `<test-storage>` / `<db-check>` / `<verify>`** — comandos canônicos do projeto: aplicar migrations, testar a camada de persistência, checar integridade/invariantes (`PRAGMA integrity_check` + checks de domínio) e o gate completo de PR.
- **`<TEST-ESPELHAMENTO>`** — teste que valida a consistência entre tabela-fonte e tabelas derivadas (FTS5/vetorial), se o projeto usa espelhamento por triggers. Sem espelhamento, ignore o §Passo 8.
- **Tabela de exemplo (`documents`)** — o `CREATE TABLE` do §Passo 6 é ilustrativo; substitua nomes de tabela/colunas/enum pelos do seu domínio.
- **Flag de mudança destrutiva** — o caminho `config/migrations.toml` é exemplo; use o mecanismo de configuração do seu projeto, mantendo a regra: a migration destrutiva falha com mensagem clara se a flag não estiver ativada.
- **Idioma dos comentários** — o original exige PT-BR para colunas de domínio; ajuste à convenção de idioma do seu repositório.
