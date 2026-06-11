# Referência da CLI do shadcn

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

A configuração é lida do `components.json`.

> **IMPORTANTE:** Sempre rode os comandos com o package runner do projeto:
> `npx shadcn@latest`, `pnpm dlx shadcn@latest` ou `bunx --bun shadcn@latest`. Cheque o
> `packageManager` do contexto do projeto para escolher o correto. Os exemplos abaixo
> usam `npx shadcn@latest`; substitua pelo runner do projeto.

> **IMPORTANTE:** Use apenas as flags documentadas abaixo. Não invente nem adivinhe
> flags — se uma flag não está listada aqui, ela não existe. A CLI auto-detecta o
> package manager pelo lockfile do projeto; não há flag `--package-manager`.

## Conteúdo

- Comandos: init, apply, add (dry-run, smart merge), search, view, docs, info, build
- Templates: next, vite, start, react-router, astro
- Presets: nomeados, código, formatos de URL e campos
- Troca de presets

---

## Comandos

### `init` — inicializar ou criar um projeto

```bash
npx shadcn@latest init [components...] [options]
```

Inicializa o shadcn/ui em um projeto existente ou cria um projeto novo (quando `--name`
é fornecido). Opcionalmente instala componentes no mesmo passo.

| Flag                    | Curta | Descrição                                                  | Default |
| ----------------------- | ----- | ---------------------------------------------------------- | ------- |
| `--template <template>` | `-t`  | Template (next, start, vite, next-monorepo, react-router)  | —       |
| `--preset [name]`       | `-p`  | Configuração de preset (nomeado, código ou URL)            | —       |
| `--yes`                 | `-y`  | Pula o prompt de confirmação                               | `true`  |
| `--defaults`            | `-d`  | Usa defaults (`--template=next --preset=base-nova`)        | `false` |
| `--force`               | `-f`  | Força sobrescrita da configuração existente                | `false` |
| `--cwd <cwd>`           | `-c`  | Diretório de trabalho                                      | atual   |
| `--name <name>`         | `-n`  | Nome do projeto novo                                       | —       |
| `--silent`              | `-s`  | Silencia a saída                                           | `false` |
| `--rtl`                 |       | Habilita suporte a RTL                                     | —       |
| `--reinstall`           |       | Reinstala os componentes de UI existentes                  | `false` |
| `--monorepo`            |       | Faz scaffold de um projeto monorepo                        | —       |
| `--no-monorepo`         |       | Pula o prompt de monorepo                                  | —       |

`npx shadcn@latest create` é um alias de `npx shadcn@latest init`.

### `apply` — aplicar um preset a um projeto existente

```bash
npx shadcn@latest apply [preset] [options]
```

Aplica um preset a um projeto existente, sobrescrevendo config orientada a preset,
fontes, CSS variables e componentes de UI detectados.

| Flag                | Curta | Descrição                                       | Default |
| ------------------- | ----- | ----------------------------------------------- | ------- |
| `--preset <preset>` | —     | Configuração de preset (nomeado, código ou URL) | —       |
| `--yes`             | `-y`  | Pula o prompt de confirmação                    | `false` |
| `--cwd <cwd>`       | `-c`  | Diretório de trabalho                           | atual   |
| `--silent`          | `-s`  | Silencia a saída                                | `false` |

`[preset]` é um atalho para `--preset <preset>`. Se ambos forem passados, devem ser iguais.
Sem preset, a CLI oferece abrir o preset builder custom em `ui.shadcn.com/create`.

### `add` — adicionar componentes

> **IMPORTANTE:** Para comparar componentes locais contra o upstream ou pré-visualizar
> mudanças, SEMPRE use `npx shadcn@latest add <component> --dry-run`, `--diff` ou
> `--view`. NUNCA busque arquivos crus do GitHub ou outras fontes manualmente. A CLI
> resolve registry, paths de arquivo e diff de CSS automaticamente.

```bash
npx shadcn@latest add [components...] [options]
```

Aceita nomes de componentes, nomes prefixados por registry (`@magicui/shimmer-button`),
URLs ou paths locais.

| Flag            | Curta | Descrição                                                                                                                  | Default |
| --------------- | ----- | --------------------------------------------------------------------------------------------------------------------------| ------- |
| `--yes`         | `-y`  | Pula o prompt de confirmação                                                                                               | `false` |
| `--overwrite`   | `-o`  | Sobrescreve arquivos existentes                                                                                            | `false` |
| `--cwd <cwd>`   | `-c`  | Diretório de trabalho                                                                                                      | atual   |
| `--all`         | `-a`  | Adiciona todos os componentes disponíveis                                                                                  | `false` |
| `--path <path>` | `-p`  | Path de destino do componente                                                                                              | —       |
| `--silent`      | `-s`  | Silencia a saída                                                                                                           | `false` |
| `--dry-run`     |       | Pré-visualiza todas as mudanças sem escrever arquivos                                                                      | `false` |
| `--diff [path]` |       | Mostra diffs. Sem path, mostra os 5 primeiros arquivos. Com path, mostra só aquele arquivo (implica `--dry-run`)           | —       |
| `--view [path]` |       | Mostra o conteúdo dos arquivos. Sem path, mostra os 5 primeiros. Com path, mostra só aquele arquivo (implica `--dry-run`)  | —       |

#### Modo dry-run

Use `--dry-run` para pré-visualizar o que o `add` faria sem escrever nenhum arquivo.
`--diff` e `--view` implicam `--dry-run`.

```bash
# Pré-visualizar todas as mudanças.
npx shadcn@latest add button --dry-run

# Mostrar diffs de todos os arquivos (top 5).
npx shadcn@latest add button --diff

# Mostrar o diff de um arquivo específico.
npx shadcn@latest add button --diff button.tsx

# Mostrar o conteúdo de todos os arquivos (top 5).
npx shadcn@latest add button --view

# Mostrar o conteúdo completo de um arquivo específico.
npx shadcn@latest add button --view button.tsx

# Funciona com URLs também.
npx shadcn@latest add https://api.npoint.io/abc123 --dry-run

# Diffs de CSS.
npx shadcn@latest add button --diff globals.css
```

**Quando usar dry-run:**

- Quando o usuário perguntar "que arquivos isso vai adicionar?" ou "o que vai mudar?" — use `--dry-run`.
- Antes de sobrescrever componentes existentes — use `--diff` para pré-visualizar as mudanças.
- Quando o usuário quiser inspecionar o código-fonte do componente sem instalar — use `--view`.
- Ao checar quais mudanças de CSS seriam feitas no `globals.css` — use `--diff globals.css`.
- Quando o usuário pedir para revisar/auditar código de registry de terceiros antes de instalar — use `--view`.

> **`npx shadcn@latest add --dry-run` vs `npx shadcn@latest view`:** prefira
> `npx shadcn@latest add --dry-run/--diff/--view` quando o usuário quiser pré-visualizar
> mudanças no projeto dele. `npx shadcn@latest view` mostra apenas metadata crua do
> registry. `npx shadcn@latest add --dry-run` mostra exatamente o que aconteceria no
> projeto: paths resolvidos, diffs contra arquivos existentes e atualizações de CSS.
> Use `npx shadcn@latest view` só para navegar informações do registry sem contexto de
> projeto.

#### Smart merge a partir do upstream

Ver [Atualizando componentes no SKILL.md](./SKILL.md#atualizando-componentes) para o
workflow completo.

### `search` — buscar nos registries

```bash
npx shadcn@latest search <registries...> [options]
```

Busca fuzzy entre registries. Também aliasada como `npx shadcn@latest list`. Sem `-q`,
lista todos os itens.

| Flag                | Curta | Descrição                  | Default |
| ------------------- | ----- | -------------------------- | ------- |
| `--query <query>`   | `-q`  | Termo de busca             | —       |
| `--limit <number>`  | `-l`  | Máx. de itens por registry | `100`   |
| `--offset <number>` | `-o`  | Itens a pular              | `0`     |
| `--cwd <cwd>`       | `-c`  | Diretório de trabalho      | atual   |

### `view` — ver detalhes de um item

```bash
npx shadcn@latest view <items...> [options]
```

Exibe informações do item, incluindo conteúdo dos arquivos. Exemplo:
`npx shadcn@latest view @shadcn/button`.

### `docs` — obter URLs de documentação de componentes

```bash
npx shadcn@latest docs <components...> [options]
```

Emite URLs resolvidas de documentação, exemplos e referência de API dos componentes.
Aceita um ou mais nomes. Busque as URLs para obter o conteúdo real.

Exemplo de saída para `npx shadcn@latest docs input button`:

```
base  radix

input
  docs      https://ui.shadcn.com/docs/components/radix/input
  examples  https://raw.githubusercontent.com/.../examples/input-example.tsx

button
  docs      https://ui.shadcn.com/docs/components/radix/button
  examples  https://raw.githubusercontent.com/.../examples/button-example.tsx
```

Alguns componentes incluem um link `api` para a biblioteca subjacente (ex.: `cmdk` para
o componente command).

### `diff` — checar atualizações

Não use este comando. Use `npx shadcn@latest add --diff`.

### `info` — informações do projeto

```bash
npx shadcn@latest info [options]
```

Exibe informações do projeto e a configuração do `components.json`. Rode primeiro para
descobrir framework, aliases, versão do Tailwind e paths resolvidos.

| Flag          | Curta | Descrição             | Default |
| ------------- | ----- | --------------------- | ------- |
| `--cwd <cwd>` | `-c`  | Diretório de trabalho | atual   |

**Campos de Project Info:**

| Campo                | Tipo      | Significado                                                          |
| -------------------- | --------- | -------------------------------------------------------------------- |
| `framework`          | `string`  | Framework detectado (`next`, `vite`, `react-router`, `start`, etc.)  |
| `frameworkVersion`   | `string`  | Versão do framework (ex.: `15.2.4`)                                  |
| `isSrcDir`           | `boolean` | Se o projeto usa diretório `src/`                                    |
| `isRSC`              | `boolean` | Se React Server Components estão habilitados                         |
| `isTsx`              | `boolean` | Se o projeto usa TypeScript                                          |
| `tailwindVersion`    | `string`  | `"v3"` ou `"v4"`                                                     |
| `tailwindConfigFile` | `string`  | Path do arquivo de config do Tailwind                                |
| `tailwindCssFile`    | `string`  | Path do arquivo CSS global                                           |
| `aliasPrefix`        | `string`  | Prefixo de alias de import (ex.: `@`, `~`, `@/`)                     |
| `packageManager`     | `string`  | Package manager detectado (`npm`, `pnpm`, `yarn`, `bun`)             |

**Campos de components.json:**

| Campo                | Tipo      | Significado                                                                                   |
| -------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| `base`               | `string`  | Biblioteca de primitivos (`radix` ou `base`) — determina APIs e props disponíveis              |
| `style`              | `string`  | Estilo visual (ex.: `nova`, `vega`)                                                            |
| `rsc`                | `boolean` | Flag de RSC da config                                                                          |
| `tsx`                | `boolean` | Flag de TypeScript                                                                             |
| `tailwind.config`    | `string`  | Path da config do Tailwind                                                                     |
| `tailwind.css`       | `string`  | Path do CSS global — é onde vão as CSS variables custom                                        |
| `iconLibrary`        | `string`  | Biblioteca de ícones — determina o pacote de import (ex.: `lucide-react`, `@tabler/icons-react`) |
| `aliases.components` | `string`  | Alias de import de componentes (ex.: `@/components`)                                           |
| `aliases.utils`      | `string`  | Alias de utils (ex.: `@/lib/utils`)                                                            |
| `aliases.ui`         | `string`  | Alias de componentes de UI (ex.: `@/components/ui`)                                            |
| `aliases.lib`        | `string`  | Alias de lib (ex.: `@/lib`)                                                                    |
| `aliases.hooks`      | `string`  | Alias de hooks (ex.: `@/hooks`)                                                                |
| `resolvedPaths`      | `object`  | Paths absolutos no filesystem para cada alias                                                  |
| `registries`         | `object`  | Registries custom configurados                                                                 |

**Campos de Links:**

A saída do `info` inclui uma seção **Links** com URLs templadas para docs, fonte e
exemplos de componentes. Para URLs resolvidas, use `npx shadcn@latest docs <component>`.

### `build` — construir um registry custom

```bash
npx shadcn@latest build [registry] [options]
```

Compila o `registry.json` em arquivos JSON individuais para distribuição. Input default:
`./registry.json`; output default: `./public/r`.

| Flag              | Curta | Descrição             | Default      |
| ----------------- | ----- | --------------------- | ------------ |
| `--output <path>` | `-o`  | Diretório de saída    | `./public/r` |
| `--cwd <cwd>`     | `-c`  | Diretório de trabalho | atual        |

---

## Templates

| Valor          | Framework      | Suporte a monorepo |
| -------------- | -------------- | ------------------ |
| `next`         | Next.js        | Sim                |
| `vite`         | Vite           | Sim                |
| `start`        | TanStack Start | Sim                |
| `react-router` | React Router   | Sim                |
| `astro`        | Astro          | Sim                |
| `laravel`      | Laravel        | Não                |

Todos os templates suportam scaffold de monorepo via flag `--monorepo`. Quando passada,
a CLI usa um diretório de template específico de monorepo (ex.: `next-monorepo`,
`vite-monorepo`). Sem `--monorepo` nem `--no-monorepo`, a CLI pergunta interativamente.
Laravel não suporta scaffold de monorepo.

---

## Presets

Três formas de especificar um preset via `--preset`:

1. **Nomeado:** `--preset nova` ou `--preset lyra`
2. **Código:** `--preset a2r6bw` (string base62 com prefixo de versão, ex.: `a2r6bw` ou `b0`)
3. **URL:** `--preset "https://ui.shadcn.com/init?base=radix&style=nova&..."`

> **IMPORTANTE:** Nunca tente decodificar, buscar ou resolver códigos de preset
> manualmente. Códigos de preset são opacos — passe-os direto a
> `npx shadcn@latest init --preset <code>` e deixe a CLI resolver.
> Use `npx shadcn@latest apply --preset <code>` ao sobrescrever o preset de um projeto
> existente.

## Troca de presets

Pergunte ao usuário primeiro: **overwrite**, **merge** ou **skip** dos componentes
existentes?

- **Overwrite / reinstalar** → `npx shadcn@latest apply --preset <code>`. Sobrescreve
  todos os arquivos de componente detectados com os estilos do preset novo. Use quando o
  usuário não customizou os componentes.
- **Merge** → `npx shadcn@latest init --preset <code> --force --no-reinstall`, depois
  rode `npx shadcn@latest info` para listar os componentes instalados e use o
  [workflow de smart merge](./SKILL.md#atualizando-componentes) para atualizá-los um a
  um, preservando mudanças locais. Use quando o usuário customizou componentes.
- **Skip** → `npx shadcn@latest init --preset <code> --force --no-reinstall`. Só
  atualiza config e CSS variables, deixa os componentes como estão.

Sempre rode comandos de preset dentro do diretório do projeto do usuário. `apply` só
funciona em projeto existente com `components.json`. A CLI preserva automaticamente o
base atual (`base` vs `radix`) do `components.json`. Se precisar usar um diretório
temporário (ex.: para comparações `--dry-run`), passe `--base <base-atual>`
explicitamente — códigos de preset não codificam o base.
