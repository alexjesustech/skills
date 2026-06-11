---
name: conventional-commits
description: "Guia de estilo para mensagens de commit no padrão Conventional Commits, com trailers opcionais de rastreio de autoria por IA. Consulte sempre que for compor uma mensagem de commit, preparar um PR, ou quando o usuário mencionar commit, histórico, changelog ou versionamento. Define o padrão da mensagem — NÃO executa o commit: a automação de commitar pertence à ferramenta/fluxo do repositório adotante."
---

# conventional-commits — guia de estilo de mensagens de commit com rastreio de co-autoria de IA (TOOL · v1.0.0 · Alex Jesus)

> **Escopo:** esta skill é um **guia de estilo** — define como a mensagem de commit deve
> ser escrita. Ela **não** é um executor de commit: o ato de stagear, commitar e a
> política de branches/push são responsabilidade da ferramenta ou do fluxo do
> repositório que a adota.

## Formato

```
<tipo>(<escopo>): <descrição imperativa, minúscula, sem ponto final>

<corpo: o PORQUÊ da mudança, não o que o diff já mostra>

<trailers>
```

- **Tipos**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `build`, `ci`.
- **Escopo**: módulo/bounded context (ex.: `feat(auth): ...`).
- **Breaking change**: `!` após o escopo + rodapé `BREAKING CHANGE:`.

## Trailers (rastreio de IA) — opcionais e configuráveis

Quando o repositório adotante rastreia a participação de IA no histórico, use os
trailers definidos na convenção local (ver § Adaptação). Padrões comuns:

- `@ai-generated` — quando o artefato foi gerado/assistido por IA.
- `@reviewed-by: <revisor humano>` — aplicado pelo revisor humano (ou pelo fluxo de
  code review) ao aprovar.

## Disciplina

- Um commit = uma intenção coesa. Sem "wip" em histórico consolidado.
- Mensagem no idioma padrão do repositório; termos técnicos consagrados em inglês
  permanecem.

## Quando NÃO usar

- **Não** use esta skill para executar o commit em si (staging, hooks, push, abertura
  de PR) — isso é papel da automação/fluxo do repositório adotante.
- **Não** use para definir política de branches, versionamento SemVer ou formato de
  CHANGELOG — ela cobre somente a **mensagem** do commit (embora se componha bem com
  essas práticas).

## Adaptação

Ao adotar esta skill num repositório, defina:

- **`<revisor humano>`** — nome/identificador usado no trailer de aprovação (ex.:
  `@reviewed-by: Fulana de Tal` ou um handle). Use a convenção do seu repositório.
- **Convenção de trailers de co-autoria** — escolha e documente UMA por repositório;
  opções comuns (não prescrevemos nenhuma):
  - `@ai-generated` (com ou sem o modelo: `@ai-generated: <modelo>`);
  - `@reviewed-by: <revisor>` para aprovação humana;
  - `Co-Authored-By: <nome> <email>` (formato nativo do Git/GitHub para co-autoria).
- **Idioma da mensagem** — esta skill nasceu em contexto pt-BR; ajuste a regra de
  idioma da seção "Disciplina" para o idioma padrão do seu projeto.
- **Lista de escopos** — opcionalmente, enumere os escopos válidos do seu projeto
  (módulos/bounded contexts) para mensagens consistentes.
