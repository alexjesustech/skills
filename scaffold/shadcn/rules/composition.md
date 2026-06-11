# Composição de componentes

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

## Conteúdo

- Items sempre dentro do seu componente Group
- Callouts usam Alert
- Empty states usam o componente Empty
- Notificações toast usam sonner
- Escolhendo entre componentes de overlay
- Dialog, Sheet e Drawer sempre precisam de Title
- Estrutura de Card
- Button não tem prop isPending ou isLoading
- TabsTrigger deve estar dentro de TabsList
- Avatar sempre precisa de AvatarFallback
- Use Separator em vez de hr cru ou divs com borda
- Use Skeleton para placeholders de carregamento
- Use Badge em vez de spans estilizados custom

---

## Items sempre dentro do seu componente Group

Nunca renderize items direto dentro do container de conteúdo.

**Incorreto:**

```tsx
<SelectContent>
  <SelectItem value="apple">Apple</SelectItem>
  <SelectItem value="banana">Banana</SelectItem>
</SelectContent>
```

**Correto:**

```tsx
<SelectContent>
  <SelectGroup>
    <SelectItem value="apple">Apple</SelectItem>
    <SelectItem value="banana">Banana</SelectItem>
  </SelectGroup>
</SelectContent>
```

Vale para todos os componentes baseados em grupo:

| Item | Group |
|------|-------|
| `SelectItem`, `SelectLabel` | `SelectGroup` |
| `DropdownMenuItem`, `DropdownMenuLabel`, `DropdownMenuSub` | `DropdownMenuGroup` |
| `MenubarItem` | `MenubarGroup` |
| `ContextMenuItem` | `ContextMenuGroup` |
| `CommandItem` | `CommandGroup` |

---

## Callouts usam Alert

```tsx
<Alert>
  <AlertTitle>Warning</AlertTitle>
  <AlertDescription>Something needs attention.</AlertDescription>
</Alert>
```

---

## Empty states usam o componente Empty

```tsx
<Empty>
  <EmptyHeader>
    <EmptyMedia variant="icon"><FolderIcon /></EmptyMedia>
    <EmptyTitle>No projects yet</EmptyTitle>
    <EmptyDescription>Get started by creating a new project.</EmptyDescription>
  </EmptyHeader>
  <EmptyContent>
    <Button>Create Project</Button>
  </EmptyContent>
</Empty>
```

---

## Notificações toast usam sonner

```tsx
import { toast } from "sonner"

toast.success("Changes saved.")
toast.error("Something went wrong.")
toast("File deleted.", {
  action: { label: "Undo", onClick: () => undoDelete() },
})
```

---

## Escolhendo entre componentes de overlay

| Caso de uso | Componente |
|-------------|-----------|
| Tarefa focada que exige input | `Dialog` |
| Confirmação de ação destrutiva | `AlertDialog` |
| Painel lateral com detalhes ou filtros | `Sheet` |
| Painel inferior mobile-first | `Drawer` |
| Informação rápida no hover | `HoverCard` |
| Conteúdo contextual pequeno no clique | `Popover` |

---

## Dialog, Sheet e Drawer sempre precisam de Title

`DialogTitle`, `SheetTitle`, `DrawerTitle` são obrigatórios por acessibilidade. Use
`className="sr-only"` se visualmente oculto.

```tsx
<DialogContent>
  <DialogHeader>
    <DialogTitle>Edit Profile</DialogTitle>
    <DialogDescription>Update your profile.</DialogDescription>
  </DialogHeader>
  ...
</DialogContent>
```

---

## Estrutura de Card

Use a composição completa — não despeje tudo em `CardContent`:

```tsx
<Card>
  <CardHeader>
    <CardTitle>Team Members</CardTitle>
    <CardDescription>Manage your team.</CardDescription>
  </CardHeader>
  <CardContent>...</CardContent>
  <CardFooter>
    <Button>Invite</Button>
  </CardFooter>
</Card>
```

---

## Button não tem prop isPending ou isLoading

Componha com `Spinner` + `data-icon` + `disabled`:

```tsx
<Button disabled>
  <Spinner data-icon="inline-start" />
  Saving...
</Button>
```

---

## TabsTrigger deve estar dentro de TabsList

Nunca renderize `TabsTrigger` direto dentro de `Tabs` — sempre envolva em `TabsList`:

```tsx
<Tabs defaultValue="account">
  <TabsList>
    <TabsTrigger value="account">Account</TabsTrigger>
    <TabsTrigger value="password">Password</TabsTrigger>
  </TabsList>
  <TabsContent value="account">...</TabsContent>
</Tabs>
```

---

## Avatar sempre precisa de AvatarFallback

Sempre inclua `AvatarFallback` para quando a imagem falhar ao carregar:

```tsx
<Avatar>
  <AvatarImage src="/avatar.png" alt="User" />
  <AvatarFallback>JD</AvatarFallback>
</Avatar>
```

---

## Use componentes existentes em vez de markup custom

| Em vez de | Use |
|---|---|
| `<hr>` ou `<div className="border-t">` | `<Separator />` |
| `<div className="animate-pulse">` com divs estilizadas | `<Skeleton className="h-4 w-3/4" />` |
| `<span className="rounded-full bg-green-100 ...">` | `<Badge variant="secondary">` |
