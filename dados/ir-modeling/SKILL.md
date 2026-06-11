---
name: ir-modeling
description: Como evoluir com segurança o schema de uma representação intermediária (IR) — Zod estrito, versionamento SemVer (campo schemaVersion), regras de retrocompatibilidade e migração. Use ao adicionar ou alterar entidades do modelo de dados canônico de um projeto spec-first.
---
# ir-modeling — evolução segura de schema de IR com Zod estrito e SemVer (TOOL · v1.0.0 · Alex Jesus)

Padrão para projetos em que uma **representação intermediária (IR)** é a fonte da verdade: um
documento de especificação (`<spec-da-IR>`) descreve as entidades, e um pacote (`<pacote-da-IR>`)
as implementa com **Zod**. O código não contradiz a spec — mudou o modelo, muda-se a spec primeiro.

## Regras

- **Todo objeto é `.strict()`** — campo desconhecido é **erro de validação**, não é ignorado em
  silêncio. Os tipos TypeScript **derivam do schema** via `z.infer`, nunca o contrário:

  ```ts
  const EntidadeSchema = z.object({
    id: z.string().min(1),
    espessura: z.number().positive(),
  }).strict();

  type Entidade = z.infer<typeof EntidadeSchema>;
  ```

- **Mudança de schema = bump de versão.** O documento raiz da IR carrega um campo de versão
  (aqui chamado `schemaVersion`, em **SemVer**) que identifica o schema com que o documento foi
  escrito. Todo bump atualiza, em conjunto: o campo, a `<spec-da-IR>` e o registro de decisão
  (ADR ou equivalente).

- **Adição retrocompatível ⇒ minor:** campo novo **opcional**, com `.default()` quando existe
  valor natural — documentos antigos continuam válidos **sem migração**:

  ```ts
  cor: z.string().default('branco'),        // minor — documento antigo continua válido
  material: MaterialSchema.optional(),      // minor — a ausência tem semântica definida
  ```

  Enquanto as versões antigas permanecerem compatíveis, aceite-as no próprio campo de versão
  (ex.: `schemaVersion: z.enum(['0.1.0', '0.2.0'])`), em vez de forçar reescrita dos documentos.

- **Renomear/remover campo ou mudar semântica ⇒ major** + função de migração explícita
  (ex.: `migrar_X_para_Y`) + nota de migração na `<spec-da-IR>`.

- **Contrato de saída derivado pode evoluir sem bump:** estruturas produzidas por
  redução/derivação **pura** a partir da IR (geometria resolvida, agregados, relatórios) não são
  entidades da IR — um campo aditivo nelas não exige bump do `schemaVersion`, pois nenhum
  documento persistido muda de forma.

- **Invariante que o Zod não expressa** (referência cruzada entre entidades, restrição
  geométrica/relacional — ex.: "a abertura cabe no vão da parede") vai para uma camada de
  validação à parte (validador de invariantes), não para gambiarras no schema.

## Ao alterar

1. Atualize **primeiro** a `<spec-da-IR>` (a lei).
2. Reflita no `<pacote-da-IR>` (schema Zod + tipos derivados).
3. Ajuste as funções de redução/derivação que consomem a IR e os respectivos testes.
4. Rode a suíte de verificação do projeto (typecheck + testes + validação).

## Quando NÃO usar

- Quando o schema **não** é fonte canônica de documentos persistidos/versionados — para validar
  input efêmero de API ou formulário, Zod simples basta; o aparato de SemVer + migração é
  sobrecarga.
- Em protótipos descartáveis, antes de o modelo de dados estabilizar.
- Em projetos sem TypeScript/Zod — os princípios (strict, versionar o schema, opcional+default
  para retrocompatibilidade, migração explícita em quebra) valem, mas os exemplos não se aplicam
  diretamente.

## Adaptação

- **`schemaVersion`** é um nome genérico — troque pelo nome real do campo de versão na entidade
  raiz da sua IR (no projeto de origem o campo tinha outro nome, específico do domínio; o que
  importa é existir **um** campo SemVer na raiz do documento).
- **`<spec-da-IR>`** — substitua pelo caminho real do documento normativo do seu repositório
  (ex.: `docs/spec/<nome>.md`) e referencie as seções pelo seu próprio sumário.
- **`<pacote-da-IR>`** — substitua pelo nome real do pacote/módulo que implementa os schemas Zod.
- **Camada de validação de invariantes** — aponte para o mecanismo real do seu projeto
  (subagente, lib de geometria, serviço de validação); o skill só exige que ela exista e seja
  acionada após mutações.
- **Registro de decisão** — se o projeto não usa ADRs, substitua pelo artefato equivalente
  (RFC, entrada de CHANGELOG de design), mantendo a regra: bump de schema sempre deixa rastro
  escrito do porquê.
