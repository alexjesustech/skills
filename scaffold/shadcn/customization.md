# Customização e theming

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

Os componentes referenciam tokens semânticos de CSS variables. Mude as variables para
mudar todos os componentes.

## Conteúdo

- Como funciona (CSS variables → utilities Tailwind → componentes)
- Variables de cor e formato OKLCH
- Setup de dark mode
- Trocando o tema (presets, CSS variables)
- Adicionando cores custom (Tailwind v3 e v4)
- Border radius
- Customizando componentes (variants, className, wrappers)
- Checando atualizações

---

## Como funciona

1. CSS variables definidas em `:root` (claro) e `.dark` (dark mode).
2. O Tailwind as mapeia para utilities: `bg-primary`, `text-muted-foreground`, etc.
3. Os componentes usam essas utilities — mudar uma variable muda todos os componentes
   que a referenciam.

---

## Variables de cor

Toda cor segue a convenção `name` / `name-foreground`. A variable base é para fundos;
`-foreground` é para texto/ícones sobre aquele fundo.

| Variable                                     | Propósito                            |
| -------------------------------------------- | ------------------------------------ |
| `--background` / `--foreground`              | Fundo da página e texto default      |
| `--card` / `--card-foreground`               | Superfícies de Card                  |
| `--primary` / `--primary-foreground`         | Botões e ações primárias             |
| `--secondary` / `--secondary-foreground`     | Ações secundárias                    |
| `--muted` / `--muted-foreground`             | Estados muted/desabilitados          |
| `--accent` / `--accent-foreground`           | Estados de hover e acento            |
| `--destructive` / `--destructive-foreground` | Erros e ações destrutivas            |
| `--border`                                   | Cor de borda default                 |
| `--input`                                    | Bordas de inputs de formulário       |
| `--ring`                                     | Cor do anel de foco                  |
| `--chart-1` a `--chart-5`                    | Gráficos/visualização de dados       |
| `--sidebar-*`                                | Cores específicas da Sidebar         |
| `--surface` / `--surface-foreground`         | Superfície secundária                |

As cores usam OKLCH: `--primary: oklch(0.205 0 0)`, onde os valores são lightness (0–1),
chroma (0 = cinza) e hue (0–360).

---

## Dark mode

Toggle baseado em classe via `.dark` no elemento raiz. Em Next.js, use `next-themes`:

```tsx
import { ThemeProvider } from "next-themes"

<ThemeProvider attribute="class" defaultTheme="system" enableSystem>
  {children}
</ThemeProvider>
```

---

## Trocando o tema

```bash
# Aplicar um código de preset de ui.shadcn.com.
npx shadcn@latest apply --preset a2r6bw

# Atalho posicional também funciona.
npx shadcn@latest apply a2r6bw

# Trocar para um preset nomeado sobrescrevendo os componentes existentes.
npx shadcn@latest apply --preset nova

# Preservar os componentes existentes.
npx shadcn@latest init --preset nova --force --no-reinstall

# Usar uma URL de tema custom.
npx shadcn@latest apply --preset "https://ui.shadcn.com/init?base=radix&style=nova&theme=blue&..."
```

Ou edite as CSS variables diretamente no `globals.css`.

---

## Adicionando cores custom

Adicione as variables ao arquivo apontado por `tailwindCssFile` em
`npx shadcn@latest info` (tipicamente `globals.css`). Nunca crie um arquivo CSS novo
para isso.

```css
/* 1. Definir no arquivo CSS global. */
:root {
  --warning: oklch(0.84 0.16 84);
  --warning-foreground: oklch(0.28 0.07 46);
}
.dark {
  --warning: oklch(0.41 0.11 46);
  --warning-foreground: oklch(0.99 0.02 95);
}
```

```css
/* 2a. Registrar no Tailwind v4 (@theme inline). */
@theme inline {
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
}
```

Quando `tailwindVersion` for `"v3"` (cheque via `npx shadcn@latest info`), registre no
`tailwind.config.js`:

```js
// 2b. Registrar no Tailwind v3 (tailwind.config.js).
module.exports = {
  theme: {
    extend: {
      colors: {
        warning: "oklch(var(--warning) / <alpha-value>)",
        "warning-foreground":
          "oklch(var(--warning-foreground) / <alpha-value>)",
      },
    },
  },
}
```

```tsx
// 3. Usar nos componentes.
<div className="bg-warning text-warning-foreground">Warning</div>
```

---

## Border radius

`--radius` controla o border radius globalmente. Os componentes derivam valores dele
(`rounded-lg` = `var(--radius)`, `rounded-md` = `calc(var(--radius) - 2px)`).

---

## Customizando componentes

Ver também: [rules/styling.md](./rules/styling.md) para exemplos Incorreto/Correto.

Prefira estas abordagens, nesta ordem:

### 1. Variants embutidas

```tsx
<Button variant="outline" size="sm">
  Click
</Button>
```

### 2. Classes Tailwind via `className`

```tsx
<Card className="mx-auto max-w-md">...</Card>
```

### 3. Adicionar uma variant nova

Edite o código-fonte do componente para adicionar uma variant via `cva`:

```tsx
// components/ui/button.tsx
warning: "bg-warning text-warning-foreground hover:bg-warning/90",
```

### 4. Componentes wrapper

Componha primitivos do shadcn/ui em componentes de mais alto nível:

```tsx
export function ConfirmDialog({ title, description, onConfirm, children }) {
  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>{children}</AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm}>Confirm</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
```

---

## Checando atualizações

```bash
npx shadcn@latest add button --diff
```

Para pré-visualizar exatamente o que mudaria antes de atualizar, use `--dry-run` e `--diff`:

```bash
npx shadcn@latest add button --dry-run        # ver todos os arquivos afetados
npx shadcn@latest add button --diff button.tsx # ver o diff de um arquivo específico
```

Ver [Atualizando componentes no SKILL.md](./SKILL.md#atualizando-componentes) para o
workflow completo de smart merge.
