# Base vs Radix

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

Diferenças de API entre `base` e `radix`. Cheque o campo `base` de `npx shadcn@latest info`.

## Conteúdo

- Composição: asChild vs render
- Button / trigger como elemento não-button
- Select (prop items, placeholder, posicionamento, multiple, valores-objeto)
- ToggleGroup (type vs multiple)
- Slider (escalar vs array)
- Accordion (type e defaultValue)

---

## Composição: asChild (radix) vs render (base)

Radix usa `asChild` para substituir o elemento default. Base usa `render`. Não envolva
triggers em elementos extras.

**Incorreto:**

```tsx
<DialogTrigger>
  <div>
    <Button>Open</Button>
  </div>
</DialogTrigger>
```

**Correto (radix):**

```tsx
<DialogTrigger asChild>
  <Button>Open</Button>
</DialogTrigger>
```

**Correto (base):**

```tsx
<DialogTrigger render={<Button />}>Open</DialogTrigger>
```

Vale para todos os componentes de trigger e close: `DialogTrigger`, `SheetTrigger`,
`AlertDialogTrigger`, `DropdownMenuTrigger`, `PopoverTrigger`, `TooltipTrigger`,
`CollapsibleTrigger`, `DialogClose`, `SheetClose`, `NavigationMenuLink`,
`BreadcrumbLink`, `SidebarMenuButton`, `Badge`, `Item`.

---

## Button / trigger como elemento não-button (só base)

Quando `render` troca o elemento por um não-button (`<a>`, `<span>`), adicione
`nativeButton={false}`.

**Incorreto (base):** faltando `nativeButton={false}`.

```tsx
<Button render={<a href="/docs" />}>Read the docs</Button>
```

**Correto (base):**

```tsx
<Button render={<a href="/docs" />} nativeButton={false}>
  Read the docs
</Button>
```

**Correto (radix):**

```tsx
<Button asChild>
  <a href="/docs">Read the docs</a>
</Button>
```

O mesmo para triggers cujo `render` não é um `Button`:

```tsx
// base.
<PopoverTrigger render={<InputGroupAddon />} nativeButton={false}>
  Pick date
</PopoverTrigger>
```

---

## Select

**Prop items (só base).** Base exige uma prop `items` na raiz. Radix usa só JSX inline.

**Incorreto (base):**

```tsx
<Select>
  <SelectTrigger><SelectValue placeholder="Select a fruit" /></SelectTrigger>
</Select>
```

**Correto (base):**

```tsx
const items = [
  { label: "Select a fruit", value: null },
  { label: "Apple", value: "apple" },
  { label: "Banana", value: "banana" },
]

<Select items={items}>
  <SelectTrigger>
    <SelectValue />
  </SelectTrigger>
  <SelectContent>
    <SelectGroup>
      {items.map((item) => (
        <SelectItem key={item.value} value={item.value}>{item.label}</SelectItem>
      ))}
    </SelectGroup>
  </SelectContent>
</Select>
```

**Correto (radix):**

```tsx
<Select>
  <SelectTrigger>
    <SelectValue placeholder="Select a fruit" />
  </SelectTrigger>
  <SelectContent>
    <SelectGroup>
      <SelectItem value="apple">Apple</SelectItem>
      <SelectItem value="banana">Banana</SelectItem>
    </SelectGroup>
  </SelectContent>
</Select>
```

**Placeholder.** Base usa um item `{ value: null }` no array de items. Radix usa
`<SelectValue placeholder="...">`.

**Posicionamento do conteúdo.** Base usa `alignItemWithTrigger`. Radix usa `position`.

```tsx
// base.
<SelectContent alignItemWithTrigger={false} side="bottom">

// radix.
<SelectContent position="popper">
```

---

## Select — seleção múltipla e valores-objeto (só base)

Base suporta `multiple`, children render-function em `SelectValue` e valores-objeto com
`itemToStringValue`. Radix é single-select com valores string apenas.

**Correto (base — seleção múltipla):**

```tsx
<Select items={items} multiple defaultValue={[]}>
  <SelectTrigger>
    <SelectValue>
      {(value: string[]) => value.length === 0 ? "Select fruits" : `${value.length} selected`}
    </SelectValue>
  </SelectTrigger>
  ...
</Select>
```

**Correto (base — valores-objeto):**

```tsx
<Select defaultValue={plans[0]} itemToStringValue={(plan) => plan.name}>
  <SelectTrigger>
    <SelectValue>{(value) => value.name}</SelectValue>
  </SelectTrigger>
  ...
</Select>
```

---

## ToggleGroup

Base usa a prop booleana `multiple`. Radix usa `type="single"` ou `type="multiple"`.

**Incorreto (base):**

```tsx
<ToggleGroup type="single" defaultValue="daily">
  <ToggleGroupItem value="daily">Daily</ToggleGroupItem>
</ToggleGroup>
```

**Correto (base):**

```tsx
// Single (sem prop), defaultValue é sempre array.
<ToggleGroup defaultValue={["daily"]} spacing={2}>
  <ToggleGroupItem value="daily">Daily</ToggleGroupItem>
  <ToggleGroupItem value="weekly">Weekly</ToggleGroupItem>
</ToggleGroup>

// Multi-seleção.
<ToggleGroup multiple>
  <ToggleGroupItem value="bold">Bold</ToggleGroupItem>
  <ToggleGroupItem value="italic">Italic</ToggleGroupItem>
</ToggleGroup>
```

**Correto (radix):**

```tsx
// Single, defaultValue é string.
<ToggleGroup type="single" defaultValue="daily" spacing={2}>
  <ToggleGroupItem value="daily">Daily</ToggleGroupItem>
  <ToggleGroupItem value="weekly">Weekly</ToggleGroupItem>
</ToggleGroup>

// Multi-seleção.
<ToggleGroup type="multiple">
  <ToggleGroupItem value="bold">Bold</ToggleGroupItem>
  <ToggleGroupItem value="italic">Italic</ToggleGroupItem>
</ToggleGroup>
```

**Valor único controlado:**

```tsx
// base — embrulhar/desembrulhar arrays.
const [value, setValue] = React.useState("normal")
<ToggleGroup value={[value]} onValueChange={(v) => setValue(v[0])}>

// radix — string simples.
const [value, setValue] = React.useState("normal")
<ToggleGroup type="single" value={value} onValueChange={setValue}>
```

---

## Slider

Base aceita um número simples para thumb único. Radix sempre exige array.

**Incorreto (base):**

```tsx
<Slider defaultValue={[50]} max={100} step={1} />
```

**Correto (base):**

```tsx
<Slider defaultValue={50} max={100} step={1} />
```

**Correto (radix):**

```tsx
<Slider defaultValue={[50]} max={100} step={1} />
```

Ambos usam arrays para sliders de faixa. `onValueChange` controlado no base pode exigir cast:

```tsx
// base.
const [value, setValue] = React.useState([0.3, 0.7])
<Slider value={value} onValueChange={(v) => setValue(v as number[])} />

// radix.
const [value, setValue] = React.useState([0.3, 0.7])
<Slider value={value} onValueChange={setValue} />
```

---

## Accordion

Radix exige `type="single"` ou `type="multiple"` e suporta `collapsible`; `defaultValue`
é string. Base não usa prop `type`, usa o booleano `multiple` e `defaultValue` é sempre
array.

**Incorreto (base):**

```tsx
<Accordion type="single" collapsible defaultValue="item-1">
  <AccordionItem value="item-1">...</AccordionItem>
</Accordion>
```

**Correto (base):**

```tsx
<Accordion defaultValue={["item-1"]}>
  <AccordionItem value="item-1">...</AccordionItem>
</Accordion>

// Multi-seleção.
<Accordion multiple defaultValue={["item-1", "item-2"]}>
  <AccordionItem value="item-1">...</AccordionItem>
  <AccordionItem value="item-2">...</AccordionItem>
</Accordion>
```

**Correto (radix):**

```tsx
<Accordion type="single" collapsible defaultValue="item-1">
  <AccordionItem value="item-1">...</AccordionItem>
</Accordion>
```
