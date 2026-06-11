# Formulários e inputs

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

## Conteúdo

- Formulários usam FieldGroup + Field
- InputGroup exige InputGroupInput/InputGroupTextarea
- Botões dentro de inputs usam InputGroup + InputGroupAddon
- Conjuntos de opções (2–7 escolhas) usam ToggleGroup
- FieldSet + FieldLegend para agrupar campos relacionados
- Estados de validação e desabilitado em Field

---

## Formulários usam FieldGroup + Field

Sempre use `FieldGroup` + `Field` — nunca `div` cru com `space-y-*`:

```tsx
<FieldGroup>
  <Field>
    <FieldLabel htmlFor="email">Email</FieldLabel>
    <Input id="email" type="email" />
  </Field>
  <Field>
    <FieldLabel htmlFor="password">Password</FieldLabel>
    <Input id="password" type="password" />
  </Field>
</FieldGroup>
```

Use `Field orientation="horizontal"` em páginas de configurações. Use
`FieldLabel className="sr-only"` para labels visualmente ocultos.

**Escolhendo controles de formulário:**

- Texto simples → `Input`
- Dropdown com opções predefinidas → `Select`
- Dropdown com busca → `Combobox`
- Select HTML nativo (sem JS) → `native-select`
- Toggle booleano → `Switch` (configurações) ou `Checkbox` (formulários)
- Escolha única entre poucas opções → `RadioGroup`
- Alternar entre 2–5 opções → `ToggleGroup` + `ToggleGroupItem`
- Código OTP/verificação → `InputOTP`
- Texto multilinha → `Textarea`

---

## InputGroup exige InputGroupInput/InputGroupTextarea

Nunca use `Input` ou `Textarea` crus dentro de um `InputGroup`.

**Incorreto:**

```tsx
<InputGroup>
  <Input placeholder="Search..." />
</InputGroup>
```

**Correto:**

```tsx
import { InputGroup, InputGroupInput } from "@/components/ui/input-group"

<InputGroup>
  <InputGroupInput placeholder="Search..." />
</InputGroup>
```

---

## Botões dentro de inputs usam InputGroup + InputGroupAddon

Nunca posicione um `Button` direto dentro/adjacente a um `Input` com posicionamento custom.

**Incorreto:**

```tsx
<div className="relative">
  <Input placeholder="Search..." className="pr-10" />
  <Button className="absolute right-0 top-0" size="icon">
    <SearchIcon />
  </Button>
</div>
```

**Correto:**

```tsx
import { InputGroup, InputGroupInput, InputGroupAddon } from "@/components/ui/input-group"

<InputGroup>
  <InputGroupInput placeholder="Search..." />
  <InputGroupAddon>
    <Button size="icon">
      <SearchIcon data-icon="inline-start" />
    </Button>
  </InputGroupAddon>
</InputGroup>
```

---

## Conjuntos de opções (2–7 escolhas) usam ToggleGroup

Não itere `Button` manualmente com estado ativo.

**Incorreto:**

```tsx
const [selected, setSelected] = useState("daily")

<div className="flex gap-2">
  {["daily", "weekly", "monthly"].map((option) => (
    <Button
      key={option}
      variant={selected === option ? "default" : "outline"}
      onClick={() => setSelected(option)}
    >
      {option}
    </Button>
  ))}
</div>
```

**Correto:**

```tsx
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"

<ToggleGroup spacing={2}>
  <ToggleGroupItem value="daily">Daily</ToggleGroupItem>
  <ToggleGroupItem value="weekly">Weekly</ToggleGroupItem>
  <ToggleGroupItem value="monthly">Monthly</ToggleGroupItem>
</ToggleGroup>
```

Combine com `Field` para toggle groups com rótulo:

```tsx
<Field orientation="horizontal">
  <FieldTitle id="theme-label">Theme</FieldTitle>
  <ToggleGroup aria-labelledby="theme-label" spacing={2}>
    <ToggleGroupItem value="light">Light</ToggleGroupItem>
    <ToggleGroupItem value="dark">Dark</ToggleGroupItem>
    <ToggleGroupItem value="system">System</ToggleGroupItem>
  </ToggleGroup>
</Field>
```

> **Nota:** as props `defaultValue` e `type`/`multiple` diferem entre base e radix.
> Ver [base-vs-radix.md](./base-vs-radix.md#togglegroup).

---

## FieldSet + FieldLegend para agrupar campos relacionados

Use `FieldSet` + `FieldLegend` para checkboxes, radios ou switches relacionados — não
`div` com heading:

```tsx
<FieldSet>
  <FieldLegend variant="label">Preferences</FieldLegend>
  <FieldDescription>Select all that apply.</FieldDescription>
  <FieldGroup className="gap-3">
    <Field orientation="horizontal">
      <Checkbox id="dark" />
      <FieldLabel htmlFor="dark" className="font-normal">Dark mode</FieldLabel>
    </Field>
  </FieldGroup>
</FieldSet>
```

---

## Estados de validação e desabilitado em Field

Os dois atributos são necessários — `data-invalid`/`data-disabled` estiliza o campo
(label, description), enquanto `aria-invalid`/`disabled` estiliza o controle.

```tsx
// Inválido.
<Field data-invalid>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <Input id="email" aria-invalid />
  <FieldDescription>Invalid email address.</FieldDescription>
</Field>

// Desabilitado.
<Field data-disabled>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <Input id="email" disabled />
</Field>
```

Funciona para todos os controles: `Input`, `Textarea`, `Select`, `Checkbox`,
`RadioGroupItem`, `Switch`, `Slider`, `NativeSelect`, `InputOTP`.
