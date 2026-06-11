---
name: harness-evals
description: "Estratégia de testes (Harness) e gate de qualidade (Evals) para código gerado/assistido por IA: pirâmide de testes por camada, métricas mínimas (cobertura, mutation testing, lint/tipos/segredos) e protocolo de execução antes do merge. Aqui, 'Evals' = avaliação da bateria de testes do código — NÃO avaliação de modelos de LLM. Consulte sempre que for escrever testes, planejar cobertura, validar antes do merge, ou quando o usuário mencionar QA, teste de aceitação, arch test, teste de segurança, cobertura, mutation testing ou acessibilidade. Acione em paralelo a qualquer implementação — nada consolida sem Evals verdes."
---

# harness-evals — pirâmide de testes, métricas e gate de qualidade do harness para código gerado por IA (TOOL · v1.0.0 · Alex Jesus)

> **Desambiguação:** nesta skill, **Harness** é a bateria de testes que cerca o código e
> **Evals** são as métricas/gates que essa bateria precisa atingir antes do merge.
> **Não** se trata de "LLM evals" (avaliação de qualidade de modelos/prompts).

Código gerado por IA **não vai para produção sem Harness**. O teste de aceitação nasce **junto** com a implementação.

## Pirâmide de testes (alvo por camada)

- **Base** — Unit (mocks): serviços, DTOs, value objects. **Architecture**: fronteiras, naming, auditoria, soft delete. **Security**: injeção, mass assignment, controle de acesso.
- **Meio** — **Spec/SDD**: cada requisito funcional identificado na especificação (ex.: `<RF-NNN>`) tem teste correspondente. **Feature** (banco real): contratos HTTP 200/403/422. **Contract**: estrutura da resposta da API. **Policy/RBAC**.
- **Topo** — **A11y** (axe-core, WCAG AA). **E2E**: fluxo crítico ponta a ponta.

## Métricas (Evals)

- **Cobertura ≥ 80%** em serviços e repositórios.
- **Mutation testing** onde o custo se justifica (lógica de domínio crítica).
- Lint, checagem de tipos, scan de segredos como gate de CI.

## Protocolo de execução

1. Rode a bateria; **documente falhas**; corrija o trivial; ajuste o plano; **reapresente relatório**.
2. **Não** execute push nem PR — decisão humana/devops.
3. **Circuit breaker**: 2 falhas sob a mesma premissa → pare e questione a premissa raiz.

## Ferramenta por stack (referência, não imposição)

PHP/Laravel → Pest (unit/feature/architecture). JS/TS → Vitest + Playwright (E2E) + axe-core. Python → pytest. A escolha segue a stack decidida no registro de decisões arquiteturais do projeto (ex.: ADRs).

## Quando NÃO usar

- **Não** é uma skill de **LLM evals**: não avalia qualidade de modelos, prompts,
  respostas de IA ou benchmarks de agentes — o objeto avaliado aqui é o **código** e
  sua bateria de testes.
- **Não** substitui a decisão humana de merge/deploy: ela produz o relatório e o gate;
  push, PR e release continuam fora do seu escopo.
- **Não** use para definir a stack de testes do zero sem decisão arquitetural — a
  tabela "Ferramenta por stack" é referência, não imposição.

## Adaptação

Ao adotar esta skill num repositório, defina:

- **`<RF-NNN>`** — placeholder para o esquema de identificação de requisitos
  funcionais da SUA especificação (PRD, spec SDD, backlog rastreável). Substitua pelo
  formato local (ex.: `REQ-042`, `US-12`, issue vinculada) e mantenha a regra: **cada
  requisito tem teste correspondente**.
- **Limiar de cobertura** — 80% em serviços/repositórios é o piso sugerido; ajuste por
  criticidade do domínio e documente o valor no CI.
- **Camadas aplicáveis** — projetos sem UI podem omitir A11y/E2E de interface; mantenha
  o princípio da pirâmide (muitos testes baratos na base, poucos caros no topo).
- **Registro de decisões** — onde a skill menciona "decisão arquitetural", aponte para
  o mecanismo do seu projeto (ADRs, RFCs, design docs).
- **Gates de CI** — integre lint/tipos/segredos/cobertura ao pipeline do repositório
  adotante; esta skill define O QUE travar, não COMO o seu CI implementa a trava.
