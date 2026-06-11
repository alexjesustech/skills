---
name: migration-safe
description: "Helper para criar migrations Laravel complexas com checklist de segurança: backward compatibility (zero downtime), rollback robusto, schema-pin em PostgreSQL multi-schema, FK constraints cross-schema, índices, idempotência. Gatilho: \"migration segura\", \"criar migration\", \"nova migration\", \"/migration-safe\"."
---

# migration-safe — criação segura de migrations Laravel (TOOL · v1.0.0 · Alex Jesus)

Helper para criar migrations complexas em um monolito (modular ou não) com checklist de
segurança, levando em conta PostgreSQL **multi-schema** (um schema por módulo), o
**schema-pin** obrigatório no `search_path` e as regras de integridade do projeto
(SoftDeletes + trilha de auditoria).

---

## Passo 1 — Coletar contexto

Perguntar (ou inferir da conversa):

1. **Módulo/schema afetado** (ex.: `order`, `billing`, `catalog`, `core`)
2. **Tipo de migration**:
   - `CREATE TABLE` — nova entidade
   - `ADD COLUMN` — adicionar campo a tabela existente
   - `ALTER COLUMN` — modificar tipo ou constraint
   - `DROP COLUMN` — remover campo
   - `CREATE INDEX` — índice sem alterar estrutura
   - `DATA MIGRATION` — transformação de dados (atenção: pode ser irreversível)
   - `DROP TABLE` — remoção de tabela (raramente necessário; confirmar com usuário)
3. **Nome descritivo** para a migration (ex.: `add_cancelled_at_to_order_orders`)
4. **Tem rollback possível?** — data migrations podem ser irreversíveis; documentar explicitamente

Se o usuário omitir informações críticas (módulo, tipo), perguntar antes de prosseguir.

---

## Passo 2 — Checklist de segurança pré-criação

Antes de gerar qualquer arquivo, verificar cada item:

### Schema e search_path (multi-schema PostgreSQL)
- [ ] Identificar o schema do módulo na lista de schemas do projeto. Módulos de suporte (ACL, RBAC) podem ficar em `public` — confirmar se a migration é de negócio ou de suporte.
- [ ] `up()` deve começar com **schema-pin** antes de qualquer DDL:
  ```php
  DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');
  ```
- [ ] `down()` deve ter o **mesmo schema-pin** no início:
  ```php
  DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');
  ```
- [ ] FKs cross-schema usam nome **qualificado**:
  ```php
  $table->foreign('order_id')->references('id')->on('order.orders');
  // NÃO: ->on('orders') — a resolução dependeria do search_path ativo
  ```

### Integridade (SoftDeletes obrigatório, se o projeto adota a regra)
- [ ] Se `CREATE TABLE`: incluir `$table->softDeletes()` — nunca criar tabela de entidade sem `deleted_at`
- [ ] Se `ADD COLUMN` para nova entidade: verificar se a tabela já tem `deleted_at`; se não, adicionar nesta migration
- [ ] Se `DROP COLUMN`: confirmar que nenhum arquivo PHP referencia a coluna
  ```bash
  grep -rn '<nome_da_coluna>' app/
  ```

### Backward compatibility (zero downtime)
- [ ] `ADD COLUMN`: tem `->default(valor)` ou `->nullable()` para não quebrar registros existentes
- [ ] `ALTER COLUMN`: se mudar tipo, confirmar que todos os valores existentes são compatíveis com o novo tipo
- [ ] `RENAME COLUMN`: evitar — quebra queries existentes; preferir ADD + data migration + DROP em fases
- [ ] `NOT NULL` sem default em tabela populada: proibido — sempre nullable ou com default primeiro

### Model correspondente (trilha de auditoria)
- [ ] Se `CREATE TABLE`: o Model que será criado deve usar o trait de auditoria do projeto (ex.: `HasAuditTrail`, que já inclui SoftDeletes)
- [ ] Se `ADD COLUMN`: verificar se a coluna nova deve ser adicionada a `$fillable` no Model

### Índices e performance
- [ ] Colunas usadas em `WHERE`, `ORDER BY` ou como FK devem ter índice
- [ ] Índices compostos planejados para queries com múltiplos filtros frequentes
- [ ] Índice único (`->unique()`) para colunas com constraint de unicidade

### Idempotência
- [ ] `CREATE TABLE`: usar `Schema::hasTable()` ou `Schema::createIfNotExists()` quando possível
- [ ] `ADD COLUMN`: verificar `Schema::hasColumn()` antes de adicionar
- [ ] `CREATE INDEX`: usar `hasIndex()` ou `$table->index(...)` (Eloquent ignora duplicata)

---

## Passo 3 — Gerar o arquivo de migration

```bash
php artisan make:migration <nome_descritivo> --no-interaction
```

(Em projetos com Laravel Sail, prefixar com `./vendor/bin/sail`.)

O nome deve seguir a convenção snake_case descritiva:
- `create_<modulo>_<tabela>_table`
- `add_<coluna>_to_<tabela>_table`
- `alter_<tabela>_<descricao>`
- `drop_<tabela>_table`
- `data_migrate_<descricao>` (para data migrations)

---

## Passo 4 — Implementar com template

### Template CREATE TABLE

```php
declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // schema-pin: garante DDL no schema correto
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::create('<schema>.<tabela>', function (Blueprint $table) {
            $table->id();
            // ... colunas do domínio
            $table->timestamps();
            $table->softDeletes(); // obrigatório se o projeto veta exclusão física
        });
    }

    public function down(): void
    {
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::dropIfExists('<schema>.<tabela>');
    }
};
```

### Template ADD COLUMN

```php
declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::table('<schema>.<tabela>', function (Blueprint $table) {
            $table-><tipo>('<coluna>')->nullable()->after('<coluna_referencia>');
        });
    }

    public function down(): void
    {
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::table('<schema>.<tabela>', function (Blueprint $table) {
            $table->dropColumn('<coluna>');
        });
    }
};
```

### Template DATA MIGRATION (irreversível)

```php
declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * ATENÇÃO: data migration irreversível.
     * down() documenta o motivo e não recria o estado anterior.
     * Para reverter completamente: php artisan migrate:fresh --seed.
     */
    public function up(): void
    {
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        // ... transformação de dados
    }

    public function down(): void
    {
        // Irreversível — ver docblock da classe.
    }
};
```

---

## Passo 5 — Verificar com pretend

Após implementar, rodar o pretend para confirmar que o SQL gerado está correto:

```bash
php artisan migrate --pretend
```

Revisar o output e confirmar:
- Schema-pin aparece antes dos DDL statements
- Nomes de tabelas incluem o schema qualificado (ex.: `order.order_orders`)
- FKs cross-schema usam nome qualificado
- `deleted_at` presente em novas tabelas de entidade
- Tipos de coluna corretos para PostgreSQL (ex.: `uuid`, `bigint`, não `int unsigned`)

---

## Passo 6 — Executar a migration

Após confirmar o pretend:

```bash
php artisan migrate --no-interaction
```

Se houver erro de schema ou FK, diagnosticar antes de tentar novamente.
Em dev com dados descartáveis, recriar do zero é aceitável:

```bash
php artisan migrate:fresh --seed --no-interaction
```

---

## Passo 7 — Atualizar a documentação de schema

Após rodar a migration, atualizar a doc de banco do projeto (ex.: `docs/DATABASE.md`)
com as mudanças de schema:
- Nova tabela: adicionar seção com colunas e propósito
- Nova coluna: adicionar à tabela correspondente
- Índices adicionados

Se o projeto tiver um comando de sincronização de docs, executá-lo **antes de commitar**.

---

## Notas de segurança (PostgreSQL multi-schema)

### Schemas e search_path
Em um banco multi-schema (um schema por módulo), migrations que não configuram o
`search_path` criam objetos no schema `public` por padrão, violando o isolamento
modular. O **schema-pin** é obrigatório em todo DDL — no `up()` E no `down()`.

### Tabelas sem deleted_at
Se o projeto proíbe exclusão física, nenhuma tabela de entidade nasce sem
`deleted_at`. Exceções documentadas costumam existir apenas para tabelas de sistema
(log de auditoria imutável, tabelas de RBAC em `public`). Novas tabelas de domínio
não têm exceção.

### FKs cross-schema
PostgreSQL resolve nomes de tabela via `search_path`. Uma FK para `orders` sem
qualificação pode apontar para `billing.orders` em vez de `order.orders` dependendo
do `search_path` ativo na sessão. Sempre qualificar: `schema.tabela`.

### Data migrations com Eloquent
Em data migrations que usam Models Eloquent diretamente, cuidar com:
- Events/observers que disparam no save (podem causar loops ou audits indesejados)
- Usar `Model::withoutEvents()` ou `$model->saveQuietly()` quando a data migration
  não deve gerar trilha de auditoria

---

## Quando NÃO usar
- Migrations triviais de projeto **single-schema** sem regras de integridade especiais — o `make:migration` padrão basta (mas o checklist de backward compat continua boa prática).
- Mudanças de schema fora do Laravel (SQL puro, outra stack de migrations) — os princípios valem, os templates não.
- Como substituto da revisão humana em `DROP TABLE`/`DROP COLUMN` ou data migrations irreversíveis — sempre confirmar com o dono.

## Adaptação
- **`<schema>`** — schema PostgreSQL do módulo afetado (convenção comum: `strtolower` do nome do módulo).
- **`<schemas_compartilhados>`** — schemas que precisam estar visíveis no `search_path` durante a migration (ex.: schema de núcleo compartilhado, schema de extensões do Postgres). Liste-os na ordem de precedência do seu projeto.
- **Regra de SoftDeletes / trait de auditoria** — parametrize conforme a norma do seu projeto (ex.: trait `HasAuditTrail`); se o projeto não veta exclusão física, os itens correspondentes do checklist são opcionais.
- **`docs/DATABASE.md`** — caminho convencional da documentação de schema; ajuste para o do seu repo.
- **Sail vs. PHP local** — os comandos `artisan` assumem execução direta; em ambiente Sail, prefixar `./vendor/bin/sail`.
- **Localização das migrations** — em monolito modular, as migrations podem viver dentro do módulo (`app/Modules/<Nome>/.../Migrations`); use `--path=` no `make:migration` nesse caso.
- **Exemplos de domínio** — `order`/`billing`/`catalog` são ilustrativos; troque pelos módulos reais.
