---
name: spec-driven-development
description: "A disciplina SDD (Specification Driven Development) que rege o ciclo de trabalho em projetos dirigidos por especificação. Consulte sempre que for planejar a ordem de execução de uma feature, decidir o que vem antes (spec, teste ou código), ou quando o usuário mencionar XP, SDD, especificação como fonte da verdade, ou a sequência spec → aceite → implementação. Acione antes de começar a implementar qualquer coisa."
---

# spec-driven-development — disciplina SDD: spec → aceite → código → refactoring (TOOL · v1.0.0 · Alex Jesus)

A especificação **antecede** o código. O paradigma é XP/SDD.

## As quatro camadas (a inferior não contradiz a superior)
```
Specification  →  Acceptance  →  Implementation  →  Refactoring
   (PRD/ADR)       (testes)        (código)         (melhoria)
```

1. **Specification** — PRD (RF/RNF/INV) + ADRs. É lei.
2. **Acceptance** — o teste de aceitação que traduz cada RF-NNN. Escrito **em paralelo** ao código, não depois.
3. **Implementation** — código que satisfaz o aceite, conforme os ADRs.
4. **Refactoring** — melhoria **com cobertura comportamental** preservada (sem big-bang).

## Regras operacionais
- Antes de implementar, confirme: existe RF-NNN? existe critério de aceite? existe ADR para as decisões consequentes?
- Se a spec é ambígua, **pare e pergunte** (uma pergunta) — não decida silenciosamente.
- A IA gera força bruta + harness (o teste de aceitação que acompanha o código gerado); o humano audita e autoriza o merge.

## Circuit breaker
Se a mesma solução falhar **2× sob as mesmas premissas**: **pare**, **declare o bloqueio** e **formule uma pergunta** sobre a premissa raiz. Não há terceira tentativa sob a mesma premissa.

## Quando NÃO usar
- Hotfix trivial/emergencial sem impacto de escopo (typo, bump de dependência) — exigir spec formal aí é burocracia, não disciplina.
- Spike/protótipo exploratório declaradamente descartável — o objetivo é aprender, não satisfazer aceite (mas o resultado do spike deve alimentar a spec antes de virar produto).
- Projetos sem camada de especificação (sem PRD/ADR) onde não há intenção de adotá-la — a skill pressupõe que a spec existe ou será criada.

## Adaptação
- **PRD e numerário (`RF-`/`RNF-`/`INV-`)** — pressupõe um PRD estruturado conforme a skill `prd-authoring` (ou equivalente do seu projeto); adapte os prefixos de IDs ao seu padrão, mantendo a rastreabilidade requisito → teste de aceite.
- **ADRs** — pressupõe registro de decisões conforme a skill `adr-authoring` (ou formato Nygard equivalente).
- **Harness** — termo usado aqui para o conjunto de testes de aceitação gerados em paralelo ao código; mapeie para a infraestrutura de testes do seu projeto (framework, diretório, comando de execução).
- **Gate humano** — o passo "o humano audita e autoriza o merge" materializa-se conforme o fluxo do repo (PR review, trailer de revisão, branch protegida); defina onde fica esse gate no seu projeto.
