---
name: scaffold-module-full
description: "Cria um módulo completo end-to-end em um monolito modular Laravel + React/Inertia: estrutura PHP (Domain/Application/Infrastructure/Presentation/Contracts) + página Inertia React + migration com schema-pin (PostgreSQL multi-schema) + testes Pest básicos + entrada no seeder de menu/ACL. Usa sub-agentes backend + frontend + tester em sequência. Gatilho: 'novo módulo completo', 'scaffold completo', 'criar módulo', '/scaffold-module-full <nome>'."
---

# scaffold-module-full — scaffold end-to-end de módulo Laravel + React/Inertia (TOOL · v1.0.0 · Alex Jesus)

> **Extends**: um command base de scaffold (ex.: `/scaffold-module`) que cria apenas a estrutura PHP
> **Sub-agentes envolvidos**: `backend` → `frontend` → `tester`
> **Escopo**: criação de módulo completo end-to-end — PHP + React + migration + testes + ACL

Esta skill expande o scaffold base (estrutura PHP) para entregar um módulo pronto para
uso: migration com schema-pin, página Inertia, testes smoke e entrada no menu de ACL.

---

## Argumentos

| Argumento       | Tipo        | Obrigatório | Descrição                                                     |
|-----------------|-------------|-------------|---------------------------------------------------------------|
| `<nome>`        | PascalCase  | Sim         | Nome do módulo. Ex: `Report`, `Budget`, `Template`            |
| `--no-frontend` | flag        | Não         | Pula criação de página Inertia React (Passo 3)                |
| `--no-acl`      | flag        | Não         | Pula inserção no menu de navegação (Passo 5)                  |
| `--public`      | flag        | Não         | Gera rotas sem middleware `auth` + `verified` (padrão: auth)  |

---

## Pré-condições

Verificar antes de qualquer criação de arquivo:

1. **Módulo não existe**: confirmar que `app/Modules/<Nome>/` não existe.
   ```bash
   ls app/Modules/ | grep -i <nome>
   ```
   Se existir: abortar e reportar ao usuário.

2. **Nome em PascalCase**: aceitar apenas `[A-Z][a-zA-Z]+`. Rejeitar `order`, `my_module`, `My-Module`.

3. **Domínio documentado** (pré-req do scaffold base): o domínio do módulo deve estar
   descrito na documentação de domínio do projeto (ex.: `docs/DOMAIN.md`). Se não estiver,
   instruir o usuário a documentar a seção correspondente antes de prosseguir.

---

## Passo 1 — Estrutura PHP (agente `backend`)

Invocar o command base de scaffold (`/scaffold-module <nome>`), se o harness tiver um,
para criar a estrutura completa — **sem command base, crie manualmente a árvore abaixo**
(ela é a especificação; o command é só conveniência):

```
app/Modules/<Nome>/
├── Contracts/
│   ├── DTOs/
│   ├── Events/
│   └── <Nome>QueryInterface.php
├── Domain/
│   ├── Models/
│   │   └── <Nome>.php            ← Model com trait de auditoria + PHP Attributes
│   ├── Repositories/
│   │   └── <Nome>RepositoryInterface.php
│   ├── Services/
│   └── ValueObjects/
├── Application/
│   ├── DTOs/
│   ├── Listeners/
│   ├── Queries/
│   └── UseCases/
│       ├── Create<Nome>.php
│       ├── Update<Nome>.php
│       └── Delete<Nome>.php
├── Infrastructure/
│   ├── Persistence/
│   │   ├── Factories/
│   │   │   └── <Nome>Factory.php
│   │   ├── Migrations/           ← migration criada no Passo 2
│   │   └── Seeders/
│   └── Repositories/
│       └── Eloquent<Nome>Repository.php
├── Presentation/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── <Nome>Controller.php
│   │   ├── Requests/
│   │   └── Resources/
│   ├── Policies/
│   └── Routes/
│       └── web.php
└── <Nome>ServiceProvider.php
```

Após executar o scaffold base, verificar:
- `bootstrap/providers.php` contém `App\Modules\<Nome>\<Nome>ServiceProvider::class`
- `<Nome>ServiceProvider.php` registra bindings e carrega rotas/migrations

### Checklist de conformidade do Model

Para o Model `<Nome>.php` gerado, verificar antes de avançar (conforme as regras do projeto):

- [ ] Trait de auditoria presente (ex.: `use HasAuditTrail` — registra toda mutação em log imutável)
- [ ] `implements Auditable` + `getAuditExclude()` se o modelo tem campos sensíveis
- [ ] Interface de proprietário único (ex.: `HasOwner` + relação `owner()`) se a entidade pertence a um único usuário
- [ ] Casts de ValueObject (ex.: `#[Casts([...])]`) se existe campo com ValueObject no domínio (prioridade, status etc.)
- [ ] PHP Attributes `#[Table]`, `#[Fillable]`, `#[Hidden]` em vez de propriedades protegidas (se o projeto adota essa convenção)

---

## Passo 2 — Migration com schema-pin (agente `backend`)

Criar a migration principal com **schema-pin obrigatório** (PostgreSQL multi-schema —
ver skill irmã `migration-safe`).

### 2.1 Criar o arquivo via Artisan

```bash
php artisan make:migration create_<nome_plural>_table \
    --path=app/Modules/<Nome>/Infrastructure/Persistence/Migrations
```

`<nome_plural>` = plural snake_case do nome do módulo. Exemplos:
- `Budget` → `budgets`
- `Report` → `reports`
- `Template` → `templates`

### 2.2 Convenção de nome de tabela

Prefixo da tabela = `strtolower($nome)` + `_` + `plural_snake_case`.
Exemplos: `Budget` → tabela `budget_budgets`; `Report` → tabela `report_reports`.

### 2.3 Conteúdo da migration

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // schema-pin obrigatório em toda migration (multi-schema)
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::create('<prefixo>_<plural>', function (Blueprint $table) {
            $table->id();
            // ... campos específicos do módulo ...
            $table->foreignId('<contexto>_id')->constrained('<schema_do_contexto>.<tabela_do_contexto>')->cascadeOnDelete();
            $table->timestamps();
            $table->softDeletes(); // obrigatório se o projeto veta exclusão física
        });
    }

    public function down(): void
    {
        DB::statement('SET search_path TO <schema>,public,<schemas_compartilhados>');

        Schema::dropIfExists('<prefixo>_<plural>');
    }
};
```

`<schema>` = `strtolower($nome)` do módulo. O schema-pin garante que a migration opera
no schema correto mesmo em ambientes PostgreSQL com múltiplos schemas.

### 2.4 Campos mínimos obrigatórios

| Campo         | Tipo                  | Obrigação                                          |
|---------------|-----------------------|-----------------------------------------------------|
| `id`          | `bigIncrements`       | Sempre                                              |
| `<contexto>_id` | `foreignId`         | Se a entidade pertence a um agregador (tenant, grupo) |
| `timestamps`  | `timestamps()`        | Sempre                                              |
| `deleted_at`  | `softDeletes()`       | **Sempre**, se o projeto proíbe exclusão física     |
| `cancelled_at`| `timestamp nullable`  | Se a entidade pode ser cancelada (cancelado ≠ deletado: permanece visível, read-only) |

---

## Passo 3 — Página Inertia React (agente `frontend`)

> Pular se `--no-frontend` fornecido.

### 3.1 Controller — método `index`

Atualizar `<Nome>Controller.php` para retornar a página Inertia:

```php
use Inertia\Inertia;
use Inertia\Response;

public function index(): Response
{
    $this->authorize('viewAny', <Nome>::class);

    $items = <Nome>::query()
        ->orderBy('created_at', 'desc')
        ->paginate(20);

    return Inertia::render('<Nome>/Index', [
        'items' => <Nome>Resource::collection($items),
    ]);
}
```

### 3.2 Rota web

Em `app/Modules/<Nome>/Presentation/Routes/web.php`, registrar:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('<nome_kebab>', <Nome>Controller::class)->only(['index', 'store', 'update', 'destroy']);
});
```

Se `--public` fornecido, remover o middleware `auth` + `verified`.

Nome da rota gerada: `<nome_kebab>.index`, `<nome_kebab>.store`, etc.

### 3.3 Página React

Criar `resources/js/Pages/<Nome>/Index.tsx`:

```tsx
import { Head } from '@inertiajs/react';
import { PageProps } from '@/types';
import AppLayout from '@/Layouts/AppLayout';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/Components/ui/table';

// Tipo mínimo — expandir conforme o Model
interface <Nome>Item {
    id: number;
    // adicionar campos do módulo aqui
    created_at: string;
}

interface Props extends PageProps {
    items: {
        data: <Nome>Item[];
        meta: {
            current_page: number;
            last_page: number;
            total: number;
        };
    };
}

export default function <Nome>Index({ items }: Props) {
    return (
        <AppLayout>
            <Head title="<Label do módulo>" />

            <div className="space-y-4">
                <div className="flex items-center justify-between">
                    <h1 className="text-2xl font-semibold tracking-tight">
                        <Label do módulo>
                    </h1>
                </div>

                {items.data.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 text-muted-foreground">
                        <p className="text-sm">Nenhum item encontrado.</p>
                    </div>
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>ID</TableHead>
                                {/* adicionar colunas específicas do módulo */}
                                <TableHead>Criado em</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {items.data.map((item) => (
                                <TableRow key={item.id}>
                                    <TableCell>{item.id}</TableCell>
                                    {/* adicionar células */}
                                    <TableCell>{item.created_at}</TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </div>
        </AppLayout>
    );
}
```

**Regras frontend obrigatórias (padrão Inertia):**
- Zero `fetch()`/`axios` dentro da Page — dados chegam via props Inertia
- Mutations usam `router.post/patch/delete()` do Inertia
- TypeScript strict — sem `any`

---

## Passo 4 — Testes Pest básicos (agente `tester`)

### 4.1 Feature test — smoke do controller

Criar `tests/Feature/<Nome>/<Nome>ControllerTest.php`:

```php
<?php

declare(strict_types=1);

use App\Modules\Core\Domain\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('index redireciona visitante não autenticado', function () {
    $this->get(route('<nome_kebab>.index'))
        ->assertRedirect(route('login'));
});

test('index retorna 200 para usuário autenticado com permissão', function () {
    $user = User::factory()->create();
    // Atribuir permissão '<nome_kebab>.view' se RBAC estiver ativo
    // $user->givePermissionTo('<nome_kebab>.view');

    $this->actingAs($user)
        ->get(route('<nome_kebab>.index'))
        ->assertSuccessful();
});
```

**Armadilhas (Pest):**
- Nunca `use Mockery;` no topo — Mockery é global
- Se `--public` fornecido, o teste de redirecionamento não se aplica — remover
- `uses(RefreshDatabase::class)` obrigatório ao chamar `->create()` (toca banco)

### 4.2 Architecture test — verificar conformidade estrutural

Se o projeto tem teste arquitetural de estrutura de módulos (ex.:
`tests/Architecture/ModuleStructureArchTest.php`), verificar:
- O módulo novo **não** deve entrar na lista de débitos conhecidos (ex.: constante `MODULE_KNOWN_DEBTS`) — módulo novo nasce com estrutura completa
- Se por alguma razão uma pasta for intencionalmente omitida, adicionar entrada na lista de débitos com justificativa clara (nunca usar `->ignoring()` para mascarar)

### 4.3 Executar testes

```bash
# Apenas o novo módulo
php artisan test --compact tests/Feature/<Nome>/

# Architecture tests (garantir que o novo módulo passa)
php artisan test --compact --testsuite=Architecture
```

(Em ambiente Sail, prefixar com `./vendor/bin/sail`.)

---

## Passo 5 — Entrada no menu ACL (agente `backend`)

> Pular se `--no-acl` fornecido.

Perguntar ao usuário:

> "O módulo `<Nome>` deve aparecer no menu de navegação lateral?
> Se sim, informe: seção pai (uma das seções do menu do projeto),
> label, ícone (ex.: Lucide) desejado e ordem numérica dentro da seção."

Se o usuário confirmar, adicionar no seeder de menu/ACL do projeto (ex.: `AclMenuSeeder`):

**1. Permissions na lista de permissões:**
```php
'<nome_kebab>.view',
'<nome_kebab>.create',
'<nome_kebab>.update',
'<nome_kebab>.delete',
```

**2. Entrada na árvore de menu:**
```php
// Formato: [slug, label, parent_slug|null, route_name|null, icon, order, [perms...]]
['<nome_kebab>', '<Label>', '<secao_pai>', '<nome_kebab>.index', '<icone>', <order>, ['<nome_kebab>.view']],
```

Exemplo para um módulo `Report` numa seção de relatórios:
```php
// Em PERMISSIONS:
'reports.view', 'reports.create', 'reports.update', 'reports.delete',

// Em MENU_TREE:
['reports', 'Relatórios', '<secao_pai>', 'reports.index', 'bar-chart-3', 10, ['reports.view']],
```

O seeder deve ser idempotente (`updateOrCreate`) — pode ser re-executado sem duplicar dados.

---

## Passo 6 — Feedback loop (gates obrigatórios)

Após todos os passos, executar na ordem (prefixar `./vendor/bin/sail` em ambiente Sail):

```bash
# 1. Linting PHP
vendor/bin/pint --dirty --format agent

# 2. Testes do módulo + architecture
php artisan test --compact tests/Feature/<Nome>/
php artisan test --compact --testsuite=Architecture

# 3. Build frontend (verificar que a página compila sem erros TS)
npm run build -- --mode=production 2>&1 | tail -20
```

Se qualquer gate falhar: corrigir antes de reportar ao usuário.

---

## Passo 7 — Relatório final

Reportar ao usuário no formato:

```
Módulo <Nome> criado com sucesso

Estrutura PHP:
  app/Modules/<Nome>/

ServiceProvider:
  App\Modules\<Nome>\<Nome>ServiceProvider (registrado em bootstrap/providers.php)

Migration:
  app/Modules/<Nome>/Infrastructure/Persistence/Migrations/..._create_<tabela>_table.php
  schema-pin: SET search_path TO <schema>,...

Página Inertia:
  resources/js/Pages/<Nome>/Index.tsx
  Rota: <nome_kebab>.index → GET /<nome_kebab>

Testes:
  tests/Feature/<Nome>/<Nome>ControllerTest.php (2 casos)
  Architecture test: módulo na lista de conformidade

ACL:
  [adicionado no seeder de menu / pulado com --no-acl]

VALIDACAO VISUAL PENDENTE:
  Abrir /<nome_kebab> no browser e verificar que a página carrega sem erros de JS.
  Executar o dev server (ex.: npm run dev) e acessar http://localhost:<porta>/<nome_kebab>
```

---

## Regras de arquitetura aplicadas (monolito modular)

| Regra | Aplicação nesta skill |
|---|---|
| Organização por domínio | Tudo em `app/Modules/<Nome>/` — não por camada técnica |
| 5 subpastas + ServiceProvider | Verificado no Passo 1 + arch test no Passo 4 |
| Zero lógica em Controllers | Controller gerado delega para UseCase |
| Sem rotas de auth alternativas | O scaffold não cria fluxos de autenticação próprios |
| SoftDeletes | `$table->softDeletes()` na migration (se o projeto veta exclusão física) |
| Trilha de auditoria | Todo Model usa o trait de auditoria — checklist no Passo 1 |
| `$request->validated()` | Nunca `$request->all()` nos FormRequests gerados |
| Prefixo de tabela | `<modulo>_<tabela>` em todas as migrations |
| PHP Attributes | `#[Table]`, `#[Fillable]`, `#[Hidden]` nos Models (se o projeto adota) |
| Schema PostgreSQL por módulo | `<schema>` = `strtolower($nome)` |
| Schema-pin | `DB::statement('SET search_path TO ...')` obrigatório nas migrations |

---

## Quando NÃO usar
- Para adicionar uma feature a um módulo **existente** — use o fluxo normal de implementação, não o scaffold.
- Para criar apenas a estrutura PHP — use o command base de scaffold diretamente.
- Em projetos que **não** seguem monolito modular Laravel + React/Inertia — a estrutura de pastas e os gates não se aplicam.
- Quando o domínio do módulo ainda não foi documentado/decidido — documentar primeiro (pré-condição 3).

## Adaptação
- **Command base `/scaffold-module`** — esta skill estende um command que gera a estrutura PHP; se o seu harness não tem um, o Passo 1 vira criação manual da árvore de pastas mostrada.
- **Sub-agentes `backend`/`frontend`/`tester`** — nomes convencionais; mapeie para os agentes do seu harness, ou execute tudo na sessão principal.
- **`<schema>` / `<schemas_compartilhados>`** — multi-schema PostgreSQL; em projeto single-schema, remova o schema-pin e os nomes qualificados (ver skill `migration-safe`).
- **`<contexto>_id`** — FK para a entidade agregadora do seu domínio (tenant, grupo, conta); o exemplo `Order/Item` clássico seria `order_id` → `order.orders`.
- **Trait de auditoria / `HasOwner` / casts de ValueObject** — substitua pelos traits/interfaces equivalentes do seu projeto; remova os itens do checklist que o projeto não adota.
- **Seeder de menu/ACL** — `AclMenuSeeder`, `PERMISSIONS` e `MENU_TREE` são um padrão; adapte aos nomes/formato do seu seeder de navegação + RBAC (ex.: Spatie Laravel Permission).
- **`docs/DOMAIN.md` / docs de arquitetura e banco** — caminhos convencionais; aponte para as docs reais do seu repo.
- **Skills complementares** — se disponíveis no ambiente, ativar skills de Pest, Inertia/React e boas práticas Laravel nos Passos 3–4.
- **Porta do dev server** — `http://localhost:<porta>` conforme o ambiente local.
- **Idioma dos labels** — os labels de UI seguem o idioma do produto.
