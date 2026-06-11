# Ícones

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

**Sempre use o `iconLibrary` configurado no projeto para os imports.** Cheque o campo
`iconLibrary` do contexto do projeto: `lucide` → `lucide-react`, `tabler` →
`@tabler/icons-react`, etc. Nunca assuma `lucide-react`.

---

## Ícones em Button usam o atributo data-icon

Adicione `data-icon="inline-start"` (prefixo) ou `data-icon="inline-end"` (sufixo) ao
ícone. Sem classes de tamanho no ícone.

**Incorreto:**

```tsx
<Button>
  <SearchIcon className="mr-2 size-4" />
  Search
</Button>
```

**Correto:**

```tsx
<Button>
  <SearchIcon data-icon="inline-start"/>
  Search
</Button>

<Button>
  Next
  <ArrowRightIcon data-icon="inline-end"/>
</Button>
```

---

## Sem classes de tamanho em ícones dentro de componentes

Os componentes dimensionam ícones via CSS. Não adicione `size-4`, `w-4 h-4` ou outras
classes de tamanho a ícones dentro de `Button`, `DropdownMenuItem`, `Alert`, `Sidebar*`
ou outros componentes shadcn — a menos que o usuário peça explicitamente tamanhos custom.

**Incorreto:**

```tsx
<Button>
  <SearchIcon className="size-4" data-icon="inline-start" />
  Search
</Button>

<DropdownMenuItem>
  <SettingsIcon className="mr-2 size-4" />
  Settings
</DropdownMenuItem>
```

**Correto:**

```tsx
<Button>
  <SearchIcon data-icon="inline-start" />
  Search
</Button>

<DropdownMenuItem>
  <SettingsIcon />
  Settings
</DropdownMenuItem>
```

---

## Passe ícones como objetos de componente, não chaves string

Use `icon={CheckIcon}`, não uma chave string para um mapa de lookup.

**Incorreto:**

```tsx
const iconMap = {
  check: CheckIcon,
  alert: AlertIcon,
}

function StatusBadge({ icon }: { icon: string }) {
  const Icon = iconMap[icon]
  return <Icon />
}

<StatusBadge icon="check" />
```

**Correto:**

```tsx
// Importe do iconLibrary configurado no projeto (ex.: lucide-react, @tabler/icons-react).
import { CheckIcon } from "lucide-react"

function StatusBadge({ icon: Icon }: { icon: React.ComponentType }) {
  return <Icon />
}

<StatusBadge icon={CheckIcon} />
```
