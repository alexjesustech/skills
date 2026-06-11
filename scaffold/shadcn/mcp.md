# Servidor MCP do shadcn

> Derivado da documentação oficial do [shadcn/ui](https://ui.shadcn.com) — © shadcn, licença MIT.

A CLI inclui um servidor MCP que permite a assistentes de IA buscar, navegar, ver e
instalar componentes a partir de registries.

---

## Setup

```bash
shadcn mcp        # inicia o servidor MCP (stdio)
shadcn mcp init   # escreve a config para o seu editor
```

Arquivos de config por editor:

| Editor | Arquivo de config |
|--------|-------------------|
| Claude Code | `.mcp.json` |
| Cursor | `.cursor/mcp.json` |
| VS Code | `.vscode/mcp.json` |
| OpenCode | `opencode.json` |
| Codex | `~/.codex/config.toml` (manual) |

---

## Tools

> **Dica:** as tools MCP cobrem operações de registry (busca, visualização, instalação).
> Para configuração do projeto (aliases, framework, versão do Tailwind), use
> `npx shadcn@latest info` — não há equivalente MCP.

### `shadcn:get_project_registries`

Retorna os nomes de registry do `components.json`. Erro se não existir `components.json`.

**Input:** nenhum

### `shadcn:list_items_in_registries`

Lista todos os itens de um ou mais registries.

**Input:** `registries` (string[]), `limit` (number, opcional), `offset` (number, opcional)

### `shadcn:search_items_in_registries`

Busca fuzzy entre registries.

**Input:** `registries` (string[]), `query` (string), `limit` (number, opcional), `offset` (number, opcional)

### `shadcn:view_items_in_registries`

Vê detalhes de itens, incluindo o conteúdo completo dos arquivos.

**Input:** `items` (string[]) — ex.: `["@shadcn/button", "@shadcn/card"]`

### `shadcn:get_item_examples_from_registries`

Encontra exemplos de uso e demos com código-fonte.

**Input:** `registries` (string[]), `query` (string) — ex.: `"accordion-demo"`, `"button example"`

### `shadcn:get_add_command_for_items`

Retorna o comando de instalação da CLI.

**Input:** `items` (string[]) — ex.: `["@shadcn/button"]`

### `shadcn:get_audit_checklist`

Retorna um checklist para verificar componentes (imports, deps, lint, TypeScript).

**Input:** nenhum

---

## Configurando registries

Registries são definidos no `components.json`. O registry `@shadcn` é sempre embutido.

```json
{
  "registries": {
    "@acme": "https://acme.com/r/{name}.json",
    "@private": {
      "url": "https://private.com/r/{name}.json",
      "headers": { "Authorization": "Bearer ${MY_TOKEN}" }
    }
  }
}
```

- Nomes devem começar com `@`.
- URLs devem conter `{name}`.
- Referências `${VAR}` são resolvidas de variáveis de ambiente.

Índice de registries da comunidade: `https://ui.shadcn.com/r/registries.json`
