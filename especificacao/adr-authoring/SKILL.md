---
name: adr-authoring
description: "Como escrever Architecture Decision Records (ADR) no formato Nygard. Consulte sempre que registrar uma decisão técnica consequente, escolher entre tecnologias, definir bounded contexts, ou quando o usuário mencionar ADR, decisão de arquitetura, trade-off ou justificativa técnica. Acione também ao revisitar/substituir uma decisão anterior."
---

# adr-authoring — registro de decisões arquiteturais no formato Nygard (TOOL · v1.0.0 · Alex Jesus)

Toda decisão arquitetural consequente vira ADR. Se o projeto mantém um template próprio (`<template-de-adr>`), use-o. Numeração sequencial **NNNN** por unidade de versionamento (projeto, app ou módulo), em `<dir-de-adr>`.

## Quando escrever
- Escolha de stack, padrão arquitetural, fronteira de contexto, estratégia de migração, decisão de segurança/dados.
- Não para microdecisões reversíveis sem impacto sistêmico.

## Estrutura
- **Título**: `ADR-NNNN: <decisão>`.
- **Status**: Proposto · Aceito · Rejeitado · Substituído por ADR-XXXX · Obsoleto.
- **Contexto** — em 1ª pessoa (voz do autor que assina): forças em jogo, restrições.
- **Decisão** — o que foi decidido, afirmativo.
- **Consequências** — positivas, negativas e neutras (custo honesto).
- **Alternativas consideradas** — obrigatório; ADR sem alternativas é antipadrão.
- **Referências** — RFCs, docs, RF-NNN do PRD.

## Disciplina
A implementação **não pode contradizer** um ADR Aceito. Mudou a decisão? Novo ADR que substitui o anterior (status atualizado nos dois).

## Quando NÃO usar
- Microdecisões reversíveis sem impacto sistêmico (nome de variável, lib utilitária trivial) — não inflar a sequência de ADRs.
- Passo-a-passo efêmero de execução (plano de tarefa) — ADR registra *decisão durável*, não roteiro de implementação.
- Requisitos de produto (o quê/para quem) — pertencem ao PRD (skill `prd-authoring`), não a um ADR.
- Reescrever/editar o conteúdo de um ADR já Aceito para "atualizá-lo" — decisão mudada gera ADR novo substituto, nunca edição retroativa.

## Adaptação
- `<template-de-adr>` — caminho do template de ADR do seu projeto (ex.: `templates/ADR.template.md`). Sem template, a seção "Estrutura" acima é autossuficiente.
- `<dir-de-adr>` — diretório onde a sequência vive (ex.: `docs/adr/` na raiz; em monorepos, um diretório de ADRs por app/pacote, cada um com numeração própria).
- **Escopo da numeração** — defina a unidade que possui a sequência NNNN (repo inteiro vs. por app em monorepo) e mantenha-a estável.
- **Voz do Contexto em 1ª pessoa** — pressupõe que um autor humano assina o ADR; se o seu fluxo usa voz impessoal, adapte, preservando a explicitação das forças e restrições.
- **Referências a RF-NNN** — pressupõem PRD com numerário conforme a skill `prd-authoring`; troque pelo identificador de requisito do seu projeto.
