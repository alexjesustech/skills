# Styling & customização

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

Veja [customization.md](../customization.md) para theming, CSS variables e cores custom.

## Conteúdo

- Cores semânticas
- Variants embutidas primeiro
- className só para layout
- Sem space-x-* / space-y-*
- Prefira size-* a w-* h-* quando iguais
- Prefira o atalho truncate
- Sem overrides manuais de cor dark:
- Use cn() para classes condicionais
- Sem z-index manual em componentes de overlay

---

## Cores semânticas

**Incorreto:**

```tsx
<div className="bg-blue-500 text-white">
  <p className="text-gray-600">Secondary text</p>
</div>
```

**Correto:**

```tsx
<div className="bg-primary text-primary-foreground">
  <p className="text-muted-foreground">Secondary text</p>
</div>
```

---

## Sem cores cruas para indicadores de status/estado

Para indicadores positivos, negativos ou de status, use variants de Badge, tokens
semânticos como `text-destructive`, ou defina CSS variables custom — não recorra a cores
cruas do Tailwind.

**Incorreto:**

```tsx
<span className="text-emerald-600">+20.1%</span>
<span className="text-green-500">Active</span>
<span className="text-red-600">-3.2%</span>
```

**Correto:**

```tsx
<Badge variant="secondary">+20.1%</Badge>
<Badge>Active</Badge>
<span className="text-destructive">-3.2%</span>
```

Se precisar de uma cor de sucesso/positivo que não existe como token semântico, use uma
variant de Badge ou pergunte ao usuário sobre adicionar uma CSS variable custom ao tema
(ver [customization.md](../customization.md)).

---

## Variants embutidas primeiro

**Incorreto:**

```tsx
<Button className="border border-input bg-transparent hover:bg-accent">
  Click me
</Button>
```

**Correto:**

```tsx
<Button variant="outline">Click me</Button>
```

---

## className só para layout

Use `className` para layout (ex.: `max-w-md`, `mx-auto`, `mt-4`), **não** para
sobrescrever cores ou tipografia do componente. Para mudar cores, use tokens semânticos,
variants embutidas ou CSS variables.

**Incorreto:**

```tsx
<Card className="bg-blue-100 text-blue-900 font-bold">
  <CardContent>Dashboard</CardContent>
</Card>
```

**Correto:**

```tsx
<Card className="max-w-md mx-auto">
  <CardContent>Dashboard</CardContent>
</Card>
```

Para customizar a aparência de um componente, prefira nesta ordem:
1. **Variants embutidas** — `variant="outline"`, `variant="destructive"`, etc.
2. **Tokens semânticos de cor** — `bg-primary`, `text-muted-foreground`.
3. **CSS variables** — defina cores custom no arquivo CSS global (ver [customization.md](../customization.md)).

---

## Sem space-x-* / space-y-*

Use `gap-*`. `space-y-4` → `flex flex-col gap-4`. `space-x-2` → `flex gap-2`.

```tsx
<div className="flex flex-col gap-4">
  <Input />
  <Input />
  <Button>Submit</Button>
</div>
```

---

## Prefira size-* a w-* h-* quando iguais

`size-10`, não `w-10 h-10`. Vale para ícones, avatares, skeletons, etc.

---

## Prefira o atalho truncate

`truncate`, não `overflow-hidden text-ellipsis whitespace-nowrap`.

---

## Sem overrides manuais de cor dark:

Use tokens semânticos — eles tratam claro/escuro via CSS variables.
`bg-background text-foreground`, não `bg-white dark:bg-gray-950`.

---

## Use cn() para classes condicionais

Use a utility `cn()` do projeto para nomes de classe condicionais ou mesclados. Não
escreva ternários manuais em strings de className.

**Incorreto:**

```tsx
<div className={`flex items-center ${isActive ? "bg-primary text-primary-foreground" : "bg-muted"}`}>
```

**Correto:**

```tsx
import { cn } from "@/lib/utils"

<div className={cn("flex items-center", isActive ? "bg-primary text-primary-foreground" : "bg-muted")}>
```

---

## Sem z-index manual em componentes de overlay

`Dialog`, `Sheet`, `Drawer`, `AlertDialog`, `DropdownMenu`, `Popover`, `Tooltip`,
`HoverCard` gerenciam o próprio empilhamento. Nunca adicione `z-50` ou `z-[999]`.
