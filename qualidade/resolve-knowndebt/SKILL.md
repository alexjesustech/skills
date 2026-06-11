---
name: resolve-knowndebt
description: Lista, prioriza e resolve dívidas técnicas registradas como $knownDebts nos testes de arquitetura (Pest/arch tests). Dada uma regra do documento de arquitetura do repositório (ex.: §6, §28), identifica as entradas de $knownDebts correspondentes, propõe a correção canônica, implementa, dá baixa na dívida e confirma o guard puro. Gatilho: "resolver knownDebts", "fechar dívida §N", "limpar $knownDebts", "/resolve-knowndebt §N".
---

# resolve-knowndebt — resolução de dívidas técnicas em arch tests (TOOL · v1.0.0 · Alex Jesus)

Skill para inspecionar, priorizar e eliminar entradas de `$knownDebts` em testes de
arquitetura (arch tests Pest) versionados em `tests/Architecture/`. O padrão `$knownDebts`
é um array, dentro do próprio arch test, que documenta **violações intencionais e
conhecidas** das regras de arquitetura do repositório (definidas no documento de regras —
ex.: `AGENTS.md`): em vez de mascarar a violação com `->ignoring()`, o teste a registra
como dívida explícita (chave = arquivo afetado, valor = descrição, comentário = `// §N`
da regra violada) para não bloquear o CI. O objetivo desta skill é **zerar essas dívidas
progressivamente**, mantendo o guard puro.

> **Regra de ouro:** os arch tests são a fonte da verdade — **nunca usar `->ignoring()`
> para mascarar uma violação** (nem adicionar um `->ignoring()` novo durante a resolução).
> Violação que não pode ser corrigida agora vira entrada documentada em `$knownDebts`
> (ou `@skip` com justificativa), nunca exceção silenciosa.

## Argumentos

- `§N` — filtra as dívidas pela regra do documento de arquitetura referenciada
  (ex.: `/resolve-knowndebt §6`)
- `--list` — só lista e prioriza, não implementa nenhuma correção
- `--all` — tenta resolver todas as dívidas de todas as regras (usar com cuidado: alto esforço)

Sem argumentos: lista todos os `$knownDebts` encontrados, agrupados por regra (§), e
aguarda o usuário selecionar quais resolver.

---

## Passo 1 — Inventariar $knownDebts

Varrer todos os arquivos em `tests/Architecture/` e extrair as entradas de `$knownDebts`:

```bash
grep -rn '\$knownDebts\s*=\s*\[' tests/Architecture/
```

Para cada arquivo com entries não-vazias, coletar:
- Arquivo de teste (ex.: `LayerFlowArchTest.php`)
- Regra (§) referenciada no comentário da entry (ex.: `// §4a`)
- Controller/arquivo afetado (chave do array)
- Descrição da violação (valor do array)

Exemplos típicos de arch tests e das regras que costumam guardar (**descobrir os
arquivos reais do repositório a cada execução** — esta tabela é ilustrativa):

| Arquivo (exemplo) | Violação típica |
|---|---|
| `LayerFlowArchTest.php` | controller chama repository direto, sem UseCase |
| `ValidationArchTest.php` | controller sem FormRequest dedicado |
| `ApiResourceArchTest.php` | controller sem ApiResource / serialização manual |
| `ComplianceArchTest.php` | model sem SoftDeletes ou sem a trait de auditoria do projeto |
| `CrossModuleBoundariesTest.php` | import de classe interna de outro módulo |
| `RbacArchTest.php` | verificação manual de role nas camadas Domain/Application |
| `ModelAttributesArchTest.php` | model sem os atributos/anotações exigidos pela convenção |

Se `§N` foi passado como argumento, filtrar somente as entries que contêm `§N` no comentário.

---

## Passo 2 — Apresentar lista priorizada

Para cada dívida encontrada, exibir em tabela (exemplo com domínio genérico Order/Item):

| # | Arquivo afetado | § | Violação | Fix canônico | Esforço |
|---|---|---|---|---|---|
| 1 | `OrderController` | §4a | chama `repository->update()` sem UseCase | Criar `UpdateOrder` UseCase; controller delega | M |
| 2 | `ItemSettingsController` | §6 | `update()` usa `Request` base | Criar `UpdateItemSettingsRequest` FormRequest | XS |
| ... | ... | ... | ... | ... | ... |

Escala de esforço:
- **XS** — criar FormRequest vazio ou trivial (< 15 min)
- **S** — criar FormRequest com validações (15–30 min)
- **M** — criar UseCase e refatorar controller (30–60 min)
- **L** — refatorar múltiplas camadas ou resolver violação cross-module (> 60 min)

Se `--list` foi passado, **encerrar aqui** e aguardar o usuário.

---

## Passo 3 — Confirmar seleção

Perguntar ao usuário quais entries deseja resolver nesta sessão (por número da tabela).
Se `--all` foi passado, selecionar todas automaticamente.

Para cada dívida selecionada, verificar a regra (§) correspondente no documento de
arquitetura do repositório **antes** de implementar — garante que o fix canônico está
alinhado com a regra vigente.

---

## Passo 4 — Implementar correção (por dívida)

Para cada dívida selecionada, implementar (ou delegar a um sub-agente de implementação,
se o harness do repositório tiver um — ex.: `backend`) com o contexto específico:

```
Contexto da correção:
  Arquivo: <controller/model afetado>
  Violação: <descrição exata do $knownDebts>
  Regra violada: §<N> do documento de arquitetura
  Fix canônico: <descrição do fix>
  Restrições:
    - Seguir os padrões obrigatórios do documento de regras do repositório
    - $request->validated() sempre (nunca $request->all())
    - Marcador de rastreabilidade spec↔código, se o projeto usar (ex.: anotação de requisito)
    - Controller delega 100% para UseCase (zero lógica de negócio)
```

### Fixes canônicos por tipo de violação (exemplos Laravel)

> Comandos abaixo assumem Laravel Sail (`./vendor/bin/sail php artisan ...`). Sem Sail,
> usar `php artisan ...` direto. Adapte os namespaces à estrutura modular do repositório.

**Controller chama repository sem UseCase:**
```bash
./vendor/bin/sail php artisan make:class \
  app/Modules/<Modulo>/Application/UseCases/<Acao><Entidade>UseCase.php \
  --no-interaction
```
Mover a lógica do controller para o UseCase; controller chama `$this-><acao>UseCase->execute($dto)`.

**Controller sem FormRequest dedicado:**
```bash
./vendor/bin/sail php artisan make:request \
  Modules/<Modulo>/Presentation/FormRequests/<Acao><Entidade>Request \
  --no-interaction
```
Substituir `Request $request` por `<Acao><Entidade>Request $request` no método do controller.

**Controller sem ApiResource:**
```bash
./vendor/bin/sail php artisan make:resource \
  Modules/<Modulo>/Presentation/Resources/<Entidade>Resource \
  --no-interaction
```
Substituir array manual por `<Entidade>Resource::make($model)` ou `<Entidade>Resource::collection(...)`.

**Model sem SoftDeletes ou sem trait de auditoria:**
Adicionar a trait de auditoria do projeto (se ela já incluir SoftDeletes, basta ela) no
topo do model. Criar migration para adicionar `deleted_at` se a tabela não tiver:
```bash
./vendor/bin/sail php artisan make:migration \
  add_deleted_at_to_<tabela>_table \
  --no-interaction
```

**Import cross-module de classe interna:**
Substituir o import direto pela interface em `Contracts/` do módulo destino.
Se o contrato não existir, criar `app/Modules/<Modulo>/Contracts/<Interface>.php` primeiro.

**Verificação manual de role em Domain/Application:**
Mover a verificação para uma Policy (`make:policy`) ou para um middleware/Gate definido
na camada de Presentation/Infrastructure. Domain e Application não conhecem RBAC.

**Model sem os atributos/anotações da convenção:**
Adicionar os atributos exigidos pela convenção do repositório (ex.: `#[Table('...')]`,
`#[Fillable([...])]`, `#[Hidden([...])]`). Verificar o schema real da tabela na
documentação de banco do projeto ou direto no banco antes de preencher.

---

## Passo 5 — Verificar com testes após cada fix

Após cada correção, rodar o arch test correspondente:

```bash
./vendor/bin/sail php artisan test \
  --compact \
  --filter "<NomeDoArquivoDeTesteArq>" \
  tests/Architecture/<ArquivoDeTesteArq>.php
```

Se o teste passar, a violação foi corrigida — prosseguir para o Passo 6.
Se falhar com erro diferente da entry corrigida, diagnosticar antes de avançar.

---

## Passo 6 — Dar baixa na dívida (remover a entry do $knownDebts)

Localizar a entry exata no arquivo de teste e removê-la.
Manter o comentário `// §N — descrição` apenas se houver múltiplas entries no mesmo bloco.
Se o array `$knownDebts` ficou vazio após a remoção, deixar `$knownDebts = [];`.

Se o repositório tiver um **teste-guard de dívida obsoleta** (um teste que verifica se
cada `$knownDebts` documentado ainda procede — i.e., detecta entries listadas cuja
violação já não existe), rodá-lo após a remoção para confirmar que a lista e o código
continuam coerentes.

---

## Passo 7 — Guard de regressão puro

Após limpar todas as entries de uma regra (§) num dado arquivo de teste, rodar o arch
test completo sem `$knownDebts` para confirmar que o guard é puro (sem exceções ativas):

```bash
./vendor/bin/sail php artisan test \
  --compact \
  tests/Architecture/<ArquivoDeTesteArq>.php
```

Se passar: o guard está limpo para a regra.
Se houver regressão (nova violação não-documentada): diagnosticar. **Não adicionar de
volta ao `$knownDebts` sem justificativa** — o objetivo é manter o guard puro.

---

## Passo 8 — Commitar cada fix

Um commit atômico por fix, seguindo a convenção de commits do repositório adotante
(Conventional Commits + trailers locais, se houver). Mensagem sugerida:

```
refactor(<modulo>): resolve $knownDebts §N — <descrição curta>

Remove entry de $knownDebts em <ArquivoDeTesteArq>.php após corrigir
<violação específica> em <arquivo afetado>.

<trailers conforme a convenção do repositório>
```

Se o harness tiver uma automação de commit (ex.: um command `/auto-commit`), usá-la.

---

## Notas importantes

- Cada entry de `$knownDebts` é uma violação **intencional e documentada** — remover a
  entry sem corrigir o código quebra o guard e mascara a dívida real.
- A ordem sugerida de resolução é crescente de esforço: XS → S → M → L.
- Dívidas cross-module podem impactar testes de integração além do arch test — rodar a
  suíte rápida do projeto após resolver.
- Dívidas que exigem migration têm impacto em deploy — documentar no `CHANGELOG.md`.
- Ao finalizar, atualizar o documento de estado/handoff do repositório (se houver) e o
  `CHANGELOG.md [Unreleased]` com as dívidas fechadas.

## Quando NÃO usar

- Quando o repositório **não tem arch tests com o padrão `$knownDebts`** — primeiro
  estabeleça o padrão (array documentado por teste + comentário com a regra violada).
- Para **silenciar** uma violação nova: adicionar entry em `$knownDebts` (ou pior, um
  `->ignoring()`) sem decisão consciente não é "resolver dívida" — é criá-la escondida.
- Para refatorações amplas sem vínculo com uma violação registrada — use o fluxo normal
  de refactor do repositório.
- Quando a regra de arquitetura em si está em discussão — primeiro atualize o documento
  de regras (com o rito do repositório), depois trate as dívidas.

## Adaptação

- **Documento de regras de arquitetura** — esta skill assume que o repositório tem um
  documento normativo com regras numeradas (`§N`) — ex.: `AGENTS.md`/`ARCHITECTURE.md`.
  Ajuste as referências `§N` ao identificador de regra que o seu projeto usa.
- **`tests/Architecture/`** — caminho convencional dos arch tests (Pest). Ajuste se o
  seu projeto os versiona em outro lugar.
- **Stack dos exemplos** — os fixes canônicos do Passo 4 assumem Laravel (monolito
  modular com UseCase/FormRequest/ApiResource/Policy). Em outra stack, preserve a
  mecânica (inventariar → priorizar → corrigir → dar baixa → guard puro) e troque os
  fixes pelos equivalentes locais.
- **`./vendor/bin/sail`** — prefixo para projetos com Laravel Sail; sem Sail, use
  `php artisan` (ou o runner do projeto).
- **Sub-agentes `backend`/`tester`** — opcionais; se o harness não tiver sub-agentes,
  o próprio agente principal implementa e verifica.
- **`OrderController`/`ItemSettingsController`** — exemplos com domínio genérico
  Order/Item; substitua pelas entidades reais do seu projeto.
- **Marcador de rastreabilidade** — se o projeto rastreia spec↔código (ex.: anotação de
  requisito no corpo do commit/classe), inclua-o no fix e no commit.
- **Teste-guard de dívida obsoleta** — opcional, mas recomendado: um teste que falha se
  uma entry de `$knownDebts` aponta violação que já não existe (mantém a lista honesta).
