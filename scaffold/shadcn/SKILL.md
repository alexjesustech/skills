---
name: shadcn
description: Gerencia componentes e projetos shadcn/ui — adicionar, buscar, corrigir, depurar, estilizar e compor UI. Fornece contexto do projeto, docs de componentes e exemplos de uso. Aplica-se ao trabalhar com shadcn/ui, registries de componentes, presets, códigos --preset ou qualquer projeto com components.json. Gatilhos: "shadcn init", "criar app com --preset", "trocar para --preset", adicionar/atualizar componente shadcn.
allowed-tools: Bash(npx shadcn@latest *), Bash(pnpm dlx shadcn@latest *), Bash(bunx --bun shadcn@latest *)
---

# shadcn — gestão de componentes shadcn/ui via CLI (TOOL · v1.0.0 · Alex Jesus)

> **Crédito upstream:** esta skill deriva da skill/documentação oficial do
> [shadcn/ui](https://ui.shadcn.com) (© shadcn, licença MIT — licença do upstream
> respeitada). Conteúdo adaptado para pt-BR; comandos, código e identificadores
> preservados na forma original.

Um framework para construir UI, componentes e design systems. Os componentes são
adicionados como **código-fonte** ao projeto do usuário via CLI.

> **IMPORTANTE:** Execute todos os comandos de CLI com o package runner do projeto:
> `npx shadcn@latest`, `pnpm dlx shadcn@latest` ou `bunx --bun shadcn@latest` — conforme
> o `packageManager` do projeto. Os exemplos abaixo usam `npx shadcn@latest`; substitua
> pelo runner correto.

## Contexto do projeto atual

```json
!`npx shadcn@latest info --json`
```

O JSON acima contém a configuração do projeto e os componentes instalados. Use
`npx shadcn@latest docs <component>` para obter documentação e URLs de exemplo de
qualquer componente.

## Princípios

1. **Use componentes existentes primeiro.** Use `npx shadcn@latest search` para checar os
   registries antes de escrever UI custom. Cheque registries da comunidade também.
2. **Componha, não reinvente.** Página de configurações = Tabs + Card + controles de
   formulário. Dashboard = Sidebar + Card + Chart + Table.
3. **Variants embutidas antes de estilos custom.** `variant="outline"`, `size="sm"`, etc.
4. **Cores semânticas.** `bg-primary`, `text-muted-foreground` — nunca valores crus como
   `bg-blue-500`.

## Regras críticas

Estas regras são **sempre aplicadas**. Cada uma linka um arquivo com pares de código
Incorreto/Correto.

### Styling & Tailwind → [styling.md](./rules/styling.md)

- **`className` para layout, não para estilo.** Nunca sobrescreva cores ou tipografia do componente.
- **Sem `space-x-*` ou `space-y-*`.** Use `flex` com `gap-*`. Para pilhas verticais, `flex flex-col gap-*`.
- **Use `size-*` quando largura e altura forem iguais.** `size-10`, não `w-10 h-10`.
- **Use o atalho `truncate`.** Não `overflow-hidden text-ellipsis whitespace-nowrap`.
- **Sem overrides manuais de cor `dark:`.** Use tokens semânticos (`bg-background`, `text-muted-foreground`).
- **Use `cn()` para classes condicionais.** Não escreva ternários manuais em template literals.
- **Sem `z-index` manual em componentes de overlay.** Dialog, Sheet, Popover, etc. gerenciam o próprio empilhamento.

### Formulários e inputs → [forms.md](./rules/forms.md)

- **Formulários usam `FieldGroup` + `Field`.** Nunca `div` cru com `space-y-*` ou `grid gap-*` para layout de formulário.
- **`InputGroup` usa `InputGroupInput`/`InputGroupTextarea`.** Nunca `Input`/`Textarea` crus dentro de `InputGroup`.
- **Botões dentro de inputs usam `InputGroup` + `InputGroupAddon`.**
- **Conjuntos de opções (2–7 escolhas) usam `ToggleGroup`.** Não itere `Button` com estado ativo manual.
- **`FieldSet` + `FieldLegend` para agrupar checkboxes/radios relacionados.** Não use `div` com heading.
- **Validação de campo usa `data-invalid` + `aria-invalid`.** `data-invalid` no `Field`, `aria-invalid` no controle. Para desabilitado: `data-disabled` no `Field`, `disabled` no controle.

### Estrutura de componentes → [composition.md](./rules/composition.md)

- **Items sempre dentro do seu Group.** `SelectItem` → `SelectGroup`. `DropdownMenuItem` → `DropdownMenuGroup`. `CommandItem` → `CommandGroup`.
- **Use `asChild` (radix) ou `render` (base) para triggers custom.** Cheque o campo `base` de `npx shadcn@latest info`. → [base-vs-radix.md](./rules/base-vs-radix.md)
- **Dialog, Sheet e Drawer sempre precisam de Title.** `DialogTitle`, `SheetTitle`, `DrawerTitle` são obrigatórios por acessibilidade. Use `className="sr-only"` se visualmente oculto.
- **Use a composição completa de Card.** `CardHeader`/`CardTitle`/`CardDescription`/`CardContent`/`CardFooter`. Não despeje tudo em `CardContent`.
- **Button não tem `isPending`/`isLoading`.** Componha com `Spinner` + `data-icon` + `disabled`.
- **`TabsTrigger` deve estar dentro de `TabsList`.** Nunca renderize triggers direto em `Tabs`.
- **`Avatar` sempre precisa de `AvatarFallback`.** Para quando a imagem falhar ao carregar.

### Use componentes, não markup custom → [composition.md](./rules/composition.md)

- **Use componentes existentes antes de markup custom.** Cheque se existe componente antes de escrever um `div` estilizado.
- **Callouts usam `Alert`.** Não construa divs estilizadas custom.
- **Empty states usam `Empty`.** Não construa markup custom de estado vazio.
- **Toast via `sonner`.** Use `toast()` de `sonner`.
- **Use `Separator`** em vez de `<hr>` ou `<div className="border-t">`.
- **Use `Skeleton`** para placeholders de carregamento. Sem divs custom `animate-pulse`.
- **Use `Badge`** em vez de spans estilizados custom.

### Ícones → [icons.md](./rules/icons.md)

- **Ícones em `Button` usam `data-icon`.** `data-icon="inline-start"` ou `data-icon="inline-end"` no ícone.
- **Sem classes de tamanho em ícones dentro de componentes.** Os componentes dimensionam ícones via CSS. Sem `size-4` ou `w-4 h-4`.
- **Passe ícones como objetos, não como chaves string.** `icon={CheckIcon}`, não um lookup por string.

### CLI

- **Nunca decodifique códigos de preset nem monte URLs de preset manualmente.** Use `npx shadcn@latest preset decode <code>`, `preset url <code>` ou `preset open <code>`. Para detecção de preset ciente do projeto, use `npx shadcn@latest preset resolve`.
- **Aplique códigos de preset direto pela CLI.** Use `npx shadcn@latest apply <code>` em projetos existentes, ou `npx shadcn@latest init --preset <code>` na inicialização.

## Padrões-chave

Estes são os padrões mais comuns que diferenciam código shadcn/ui correto. Para casos de
borda, veja os arquivos de regras linkados acima.

```tsx
// Layout de formulário: FieldGroup + Field, não div + Label.
<FieldGroup>
  <Field>
    <FieldLabel htmlFor="email">Email</FieldLabel>
    <Input id="email" />
  </Field>
</FieldGroup>

// Validação: data-invalid no Field, aria-invalid no controle.
<Field data-invalid>
  <FieldLabel>Email</FieldLabel>
  <Input aria-invalid />
  <FieldDescription>Invalid email.</FieldDescription>
</Field>

// Ícones em botões: data-icon, sem classes de tamanho.
<Button>
  <SearchIcon data-icon="inline-start" />
  Search
</Button>

// Espaçamento: gap-*, não space-y-*.
<div className="flex flex-col gap-4">  // correto
<div className="space-y-4">           // errado

// Dimensões iguais: size-*, não w-* h-*.
<Avatar className="size-10">   // correto
<Avatar className="w-10 h-10"> // errado

// Cores de status: variants de Badge ou tokens semânticos, não cores cruas.
<Badge variant="secondary">+20.1%</Badge>    // correto
<span className="text-emerald-600">+20.1%</span> // errado
```

## Seleção de componentes

| Necessidade                 | Use                                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------- |
| Botão/ação                  | `Button` com a variant apropriada                                                                   |
| Inputs de formulário        | `Input`, `Select`, `Combobox`, `Switch`, `Checkbox`, `RadioGroup`, `Textarea`, `InputOTP`, `Slider` |
| Alternar entre 2–5 opções   | `ToggleGroup` + `ToggleGroupItem`                                                                   |
| Exibição de dados           | `Table`, `Card`, `Badge`, `Avatar`                                                                  |
| Navegação                   | `Sidebar`, `NavigationMenu`, `Breadcrumb`, `Tabs`, `Pagination`                                     |
| Overlays                    | `Dialog` (modal), `Sheet` (painel lateral), `Drawer` (painel inferior), `AlertDialog` (confirmação) |
| Feedback                    | `sonner` (toast), `Alert`, `Progress`, `Skeleton`, `Spinner`                                        |
| Command palette             | `Command` dentro de `Dialog`                                                                        |
| Gráficos                    | `Chart` (envolve Recharts)                                                                          |
| Layout                      | `Card`, `Separator`, `Resizable`, `ScrollArea`, `Accordion`, `Collapsible`                          |
| Empty states                | `Empty`                                                                                             |
| Menus                       | `DropdownMenu`, `ContextMenu`, `Menubar`                                                            |
| Tooltips/informação         | `Tooltip`, `HoverCard`, `Popover`                                                                   |

## Campos-chave

O contexto de projeto injetado contém estes campos-chave:

- **`aliases`** → use o prefixo de alias real para imports (ex.: `@/`, `~/`), nunca hardcode.
- **`isRSC`** → quando `true`, componentes que usam `useState`, `useEffect`, event handlers ou APIs de browser precisam de `"use client"` no topo do arquivo. Sempre consulte este campo ao orientar sobre a diretiva.
- **`tailwindVersion`** → `"v4"` usa blocos `@theme inline`; `"v3"` usa `tailwind.config.js`.
- **`tailwindCssFile`** → o arquivo CSS global onde as CSS variables custom são definidas. Sempre edite este arquivo, nunca crie um novo.
- **`style`** → tratamento visual dos componentes (ex.: `nova`, `vega`).
- **`base`** → biblioteca de primitivos (`radix` ou `base`). Afeta APIs e props disponíveis.
- **`iconLibrary`** → determina os imports de ícones. Use `lucide-react` para `lucide`, `@tabler/icons-react` para `tabler`, etc. Nunca assuma `lucide-react`.
- **`resolvedPaths`** → destinos exatos no filesystem para componentes, utils, hooks, etc.
- **`framework`** → convenções de roteamento e arquivos (ex.: Next.js App Router vs Vite SPA).
- **`packageManager`** → use para instalar dependências não-shadcn (ex.: `pnpm add date-fns` vs `npm install date-fns`).
- **`preset`** → código e valores resolvidos do preset do projeto atual. Use `npx shadcn@latest preset resolve --json` quando precisar só da informação de preset.

Referência completa de campos: [cli.md — comando `info`](./cli.md).

## Docs, exemplos e uso de componentes

Rode `npx shadcn@latest docs <component>` para obter as URLs de documentação, exemplos e
referência de API de um componente. Busque essas URLs para obter o conteúdo real.

```bash
npx shadcn@latest docs button dialog select
```

**Ao criar, corrigir, depurar ou usar um componente, sempre rode `npx shadcn@latest docs`
e busque as URLs primeiro.** Isso garante que você trabalha com a API e os padrões de uso
corretos em vez de adivinhar.

## Workflow

1. **Obtenha o contexto do projeto** — já injetado acima. Rode `npx shadcn@latest info` de novo se precisar atualizar.
2. **Cheque os componentes instalados primeiro** — antes de rodar `add`, sempre confira a lista `components` do contexto do projeto ou liste o diretório `resolvedPaths.ui`. Não importe componentes que não foram adicionados e não re-adicione os já instalados.
3. **Encontre componentes** — `npx shadcn@latest search`.
4. **Obtenha docs e exemplos** — rode `npx shadcn@latest docs <component>` para obter URLs e busque-as. Use `npx shadcn@latest view` para navegar itens de registry não instalados. Para pré-visualizar mudanças em componentes instalados, use `npx shadcn@latest add --diff`.
5. **Instale ou atualize** — `npx shadcn@latest add`. Ao atualizar componentes existentes, use `--dry-run` e `--diff` para pré-visualizar as mudanças (ver [Atualizando componentes](#atualizando-componentes) abaixo).
6. **Corrija imports em componentes de terceiros** — após adicionar componentes de registries da comunidade (ex.: `@bundui`, `@magicui`), cheque nos arquivos não-UI adicionados paths de import hardcoded como `@/components/ui/...`. Eles podem não bater com os aliases reais do projeto. Use `npx shadcn@latest info` para obter o alias `ui` correto (ex.: `@workspace/ui/components`) e reescreva os imports. A CLI reescreve imports dos próprios arquivos de UI, mas componentes de registry de terceiros podem usar paths default que não batem com o projeto.
7. **Revise os componentes adicionados** — após adicionar um componente ou block de qualquer registry, **sempre leia os arquivos adicionados e verifique se estão corretos**. Cheque sub-componentes faltando (ex.: `SelectItem` sem `SelectGroup`), imports faltando, composição incorreta ou violações das [Regras críticas](#regras-críticas). Substitua também imports de ícone pelo `iconLibrary` do contexto do projeto (ex.: se o item do registry usa `lucide-react` mas o projeto usa `hugeicons`, troque imports e nomes de ícones). Corrija tudo antes de seguir.
8. **Registry deve ser explícito** — quando o usuário pedir para adicionar um block ou componente, **não adivinhe o registry**. Se nenhum foi especificado (ex.: "adiciona um block de login" sem dizer `@shadcn`, `@tailark`, etc.), pergunte qual usar. Nunca assuma um registry pelo usuário.
9. **Troca de presets** — pergunte ao usuário primeiro: **overwrite**, **partial**, **merge** ou **skip**?
   - **Inspecionar o preset atual**: `npx shadcn@latest preset resolve`. Use `--json` quando precisar de valores estruturados.
   - **Inspecionar o preset novo**: `npx shadcn@latest preset decode <code>`. Use `preset url <code>` ou `preset open <code>` para compartilhar ou abrir o preset builder.
   - **Overwrite**: `npx shadcn@latest apply <code>`. Sobrescreve componentes detectados, fontes e CSS variables.
   - **Partial**: `npx shadcn@latest apply <code> --only theme,font`. Atualiza só as partes selecionadas do preset sem reinstalar componentes de UI. Valores suportados: `theme` e `font`; combinações separadas por vírgula são permitidas. `icon` é intencionalmente não suportado, porque trocar ícones pode exigir reinstalação completa dos componentes e transforms.
   - **Merge**: `npx shadcn@latest init --preset <code> --force --no-reinstall`, depois rode `npx shadcn@latest info` para listar os componentes instalados e, para cada um, use `--dry-run` e `--diff` para fazer o [smart merge](#atualizando-componentes) individualmente.
   - **Skip**: `npx shadcn@latest init --preset <code> --force --no-reinstall`. Só atualiza config e CSS, deixa os componentes como estão.
   - **Importante**: sempre rode comandos de preset dentro do diretório do projeto do usuário. `apply` só funciona em projeto existente com `components.json`. A CLI preserva automaticamente o base atual (`base` vs `radix`) do `components.json`. Se precisar usar um diretório temporário (ex.: para comparações `--dry-run`), passe `--base <base-atual>` explicitamente — códigos de preset não codificam o base.

## Atualizando componentes

Quando o usuário pedir para atualizar um componente a partir do upstream mantendo as
mudanças locais, use `--dry-run` e `--diff` para mesclar de forma inteligente. **NUNCA
busque arquivos crus do GitHub manualmente — sempre use a CLI.**

1. Rode `npx shadcn@latest add <component> --dry-run` para ver todos os arquivos afetados.
2. Para cada arquivo, rode `npx shadcn@latest add <component> --diff <file>` para ver o que mudou upstream vs local.
3. Decida por arquivo com base no diff:
   - Sem mudanças locais → seguro sobrescrever.
   - Com mudanças locais → leia o arquivo local, analise o diff e aplique as atualizações do upstream preservando as modificações locais.
   - Usuário diz "atualiza tudo" → use `--overwrite`, mas confirme antes.
4. **Nunca use `--overwrite` sem aprovação explícita do usuário.**

## Referência rápida

```bash
# Criar um projeto novo.
npx shadcn@latest init --name my-app --preset base-nova
npx shadcn@latest init --name my-app --preset a2r6bw --template vite

# Criar um projeto monorepo.
npx shadcn@latest init --name my-app --preset base-nova --monorepo
npx shadcn@latest init --name my-app --preset base-nova --template next --monorepo

# Inicializar projeto existente.
npx shadcn@latest init --preset base-nova
npx shadcn@latest init --defaults  # atalho: --template=next --preset=nova (style base implícito)

# Aplicar um preset a um projeto existente.
npx shadcn@latest apply a2r6bw
npx shadcn@latest apply a2r6bw --only theme
npx shadcn@latest apply a2r6bw --only font
npx shadcn@latest apply a2r6bw --only theme,font

# Inspecionar códigos de preset e o estado de preset do projeto.
npx shadcn@latest preset decode a2r6bw
npx shadcn@latest preset url a2r6bw
npx shadcn@latest preset open a2r6bw
npx shadcn@latest preset resolve
npx shadcn@latest preset resolve --json

# Adicionar componentes.
npx shadcn@latest add button card dialog
npx shadcn@latest add @magicui/shimmer-button
npx shadcn@latest add --all

# Pré-visualizar mudanças antes de adicionar/atualizar.
npx shadcn@latest add button --dry-run
npx shadcn@latest add button --diff button.tsx
npx shadcn@latest add @acme/form --view button.tsx

# Buscar nos registries.
npx shadcn@latest search @shadcn -q "sidebar"
npx shadcn@latest search @tailark -q "stats"

# Obter URLs de docs e exemplos de componentes.
npx shadcn@latest docs button dialog select

# Ver detalhes de item de registry (itens ainda não instalados).
npx shadcn@latest view @shadcn/button
```

**Presets nomeados:** `nova`, `vega`, `maia`, `lyra`, `mira`, `luma`
**Templates:** `next`, `vite`, `start`, `react-router`, `astro` (todos suportam `--monorepo`) e `laravel` (sem suporte a monorepo)
**Códigos de preset:** strings base62 com prefixo de versão (ex.: `a2r6bw` ou `b0`), de [ui.shadcn.com](https://ui.shadcn.com).

## Referências detalhadas

- [rules/forms.md](./rules/forms.md) — FieldGroup, Field, InputGroup, ToggleGroup, FieldSet, estados de validação
- [rules/composition.md](./rules/composition.md) — Groups, overlays, Card, Tabs, Avatar, Alert, Empty, Toast, Separator, Skeleton, Badge, loading em Button
- [rules/icons.md](./rules/icons.md) — data-icon, dimensionamento de ícones, ícones como objetos
- [rules/styling.md](./rules/styling.md) — cores semânticas, variants, className, espaçamento, size, truncate, dark mode, cn(), z-index
- [rules/base-vs-radix.md](./rules/base-vs-radix.md) — asChild vs render, Select, ToggleGroup, Slider, Accordion
- [cli.md](./cli.md) — comandos, flags, presets, templates
- [customization.md](./customization.md) — theming, CSS variables, extensão de componentes
- [mcp.md](./mcp.md) — servidor MCP da CLI do shadcn (busca/instalação de componentes via tools)

## Quando NÃO usar

- Em projetos **sem `components.json`** e sem intenção de adotar shadcn/ui — as regras de
  composição/estilo daqui pressupõem os componentes do shadcn/ui no projeto.
- Para bibliotecas de componentes **distribuídas como dependência npm** (MUI, Ant Design,
  Chakra etc.) — o modelo do shadcn/ui é código-fonte copiado para o projeto; as práticas
  não se transferem.
- Para decidir o **design system visual do produto** (paletas, identidade) — a skill
  governa o uso correto dos componentes, não a direção de design.
- Para buscar arquivos de componentes crus fora da CLI (GitHub raw etc.) — fluxo
  explicitamente proibido pelas regras acima.

## Adaptação

- **Bloco de contexto injetado** (` !`npx shadcn@latest info --json` ` no topo) — sintaxe
  de pré-execução do Claude Code (comando roda ao carregar a skill). Em ferramentas sem
  esse recurso, remova o bloco e rode `npx shadcn@latest info --json` como primeiro passo
  do workflow.
- **`allowed-tools` (frontmatter)** — campo específico do Claude Code que pré-autoriza os
  comandos da CLI; outras ferramentas podem ignorá-lo ou removê-lo.
- **Package runner** — os exemplos usam `npx shadcn@latest`; substitua por
  `pnpm dlx`/`bunx --bun` conforme o `packageManager` do projeto adotante.
- **Registries da comunidade** (`@magicui`, `@tailark`, `@bundui`, `@acme` nos exemplos) —
  ilustrativos; configure os registries reais do seu projeto no `components.json`.
- **Versões/recursos da CLI** — presets, `preset decode/resolve`, `--only theme,font` e o
  campo `base` (radix vs base) refletem a CLI do shadcn/ui na data de publicação;
  confirme contra a documentação oficial (https://ui.shadcn.com) se a CLI evoluir.
- **Idioma** — labels de UI nos exemplos estão em inglês (forma original do upstream);
  localize os textos de interface conforme o idioma do seu produto.
