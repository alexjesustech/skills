---
name: prd-authoring
description: "Como redigir, estruturar e normalizar um PRD (Product Requirements Document) em projetos dirigidos por especificação. Consulte sempre que for criar um PRD do zero (Modo A), normalizar um PRD recebido ou rodar gap analysis (Modo B), ou quando o usuário mencionar requisitos, escopo, objetivos, personas, critérios de aceitação, RF/RNF ou invariantes de negócio. Acione mesmo quando o pedido vier como 'documenta os requisitos' ou 'monta a especificação'."
---

# prd-authoring — redação e normalização de PRD como camada Specification (TOOL · v1.0.0 · Alex Jesus)

O PRD é **lei** para a arquitetura. Se o projeto mantém um template de PRD próprio (`<template-de-prd>`), use-o; senão, siga a estrutura mínima abaixo.

## Princípio de testabilidade
Todo **RF-NNN** precisa de critério de aceite verificável. Se não dá para escrever o aceite, **ainda não é requisito** — é desejo a refinar.

## Numerário
- **RF-NNN** — requisitos funcionais (comportamento observável).
- **RNF-NNN** — não-funcionais: segurança/privacidade (ex.: LGPD/GDPR), performance, **acessibilidade (WCAG 2.1/2.2 AA)**, observabilidade, portabilidade.
- **INV-NNN** — invariantes de negócio (sempre verdadeiras, independentemente do fluxo).

## Estrutura mínima
1. Visão / problema (BLUF). 2. Objetivos e métricas. 3. Não-objetivos. 4. Personas. 5. RF-NNN. 6. RNF-NNN. 7. Invariantes. 8. Restrições e premissas (stack, ambiente). 9. Critérios de aceitação (liga RF → aceite). 10. Riscos e mitigação. 11. Decisões em aberto / ADRs relacionados.

## Gap analysis (Modo B)
Ao ingerir um PRD pronto, sinalize: requisitos não testáveis, invariantes ausentes, ambiguidade denotativa, RNF implícitos (segurança, a11y, performance), conflitos internos. Saída: `<dir-de-docs>/PRD-gap-analysis.md` + uma pergunta cirúrgica por lacuna bloqueante.

## Frontmatter do PRD (compatível com Obsidian)
YAML obrigatório: `title`, `status`, `versao` (SemVer), `data`, `tags`.

## Quando NÃO usar
- Decisões de arquitetura/tecnologia (trade-offs, escolha de stack) — isso é assunto da skill `adr-authoring`, não do PRD.
- Passo-a-passo de implementação ou plano de execução — o PRD define *o quê*, não *como*.
- Documentos sem dimensão de requisito (README, changelog, ata, tutorial).
- Microajustes em requisito existente que não mudam escopo nem aceite.

## Adaptação
- `<template-de-prd>` — caminho do template de PRD do seu projeto (ex.: `templates/PRD.template.md` ou `docs/templates/PRD.md`). Sem template, a "Estrutura mínima" acima é autossuficiente.
- `<dir-de-docs>` — diretório de documentação do projeto onde a gap analysis é gravada (ex.: `docs/`).
- Numerário (`RF-`/`RNF-`/`INV-`) — prefixos parametrizáveis; mantenha-os estáveis no projeto, pois ADRs e testes de aceitação referenciam esses IDs.
- Frontmatter — os campos listados pressupõem vault Markdown (Obsidian-compat); adapte às convenções de metadados do seu repositório, preservando ao menos versão (SemVer) e status.
