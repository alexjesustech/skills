---
name: error-triage
description: Classifica um erro / saída de comando como ESPERADO (benigno) vs ERRO REAL consultando um catálogo determinístico versionado (ex.: docs/expected-errors.md). Use quando um comando "falhar" mas o erro parecer esperado (ex.: forge rejeita push direto em branch protegida, erro HTTP transitório de API no merge, WARN de delete em remote multi-push, processo de redeploy em background), ou quando perguntarem "esse erro é esperado?" / "/error-triage". NÃO suprime erro real nem aceita categorias amplas.
---

# error-triage — classifica erro como esperado vs real via catálogo determinístico (TOOL · v1.0.0 · Alex Jesus)

Camada de leitura sobre um **catálogo determinístico de erros esperados** versionado no
repositório (`docs/expected-errors.md`). Serve para **dois** objetivos, nesta ordem de
prioridade: (1) **não mascarar erro real**; (2) não tratar erro benigno-conhecido como falha.

## Procedimento
1. **Casar** a saída/erro contra as assinaturas do catálogo (`docs/expected-errors.md`).
2. **Match → ESPERADO:** reportar `esperado (razão)` + a **ação correta** registrada na tabela do catálogo e seguir o fluxo. Não tratar como falha.
3. **Sem match → ERRO REAL (padrão):** diagnosticar/corrigir. **NUNCA** assumir benigno só porque "parece".
4. **Recorrente e benigno (auto-ajuste governado):** PROPOR uma linha nova no catálogo e **pedir confirmação humana** antes de versionar (a entrada vai a PR; Definition of Done: atualizar o `CHANGELOG.md`).

## Salvaguardas (nunca violar)
- O catálogo é a **fonte determinística**; o LLM só consulta e propõe — nunca decide sozinho que um erro é benigno.
- **Humano confirma** toda nova entrada "esperada" antes de versionar.
- **Nunca** entradas amplas (ex.: "ignore erros de push/teste") — só assinaturas específicas (mensagem/código de saída/contexto).
- **Nível 2** (mudar regra/hook por causa de um erro): sempre proposta → PR, **nunca** auto-aplicado. Jamais silenciar um erro só para "fazer passar" (nunca `--no-verify`).

## Exemplos típicos de entradas no catálogo
- Forge self-hosted (ex.: Gitea) com branch protegida rejeita `git push` direto em `main`/`<branch de integração>` — esperado quando o fluxo do repo integra via PR.
- Erro HTTP transitório (ex.: 405/409 momentâneo) da API do forge durante merge — esperado com ação "retry após N segundos".
- `WARN` de delete de ref ausente em setup multi-remote (um `push --delete` cobre dois remotes; a ref pode não existir em um deles) — esperado e tolerado.
- Comando de redeploy que continua em background após o shell retornar — saída "incompleta" esperada.

## Quando NÃO usar
- Para **suprimir ou rebaixar** um erro que não tem assinatura no catálogo — sem match, o default é ERRO REAL.
- Para criar categorias genéricas de supressão ("ignorar falhas de teste", "ignorar erros de push").
- Como substituto de diagnóstico: a skill classifica; a correção de erro real segue o fluxo normal de debug.
- Em repositório que ainda não tem catálogo — primeiro crie o `docs/expected-errors.md` (pode nascer vazio) com confirmação do dono.

## Adaptação
- **`docs/expected-errors.md`** — caminho convencional do catálogo; ajuste para onde seu repo versiona o catálogo de erros esperados. Formato sugerido: tabela com colunas *assinatura* (trecho literal/regex da saída), *razão*, *ação correta*.
- **Exemplos de entradas** — os exemplos acima refletem um fluxo com forge self-hosted + multi-remote; substitua pelas assinaturas reais do seu ambiente.
- **`<branch de integração>`** — a branch protegida do seu fluxo (`main`, `develop` etc.).
- **Regras de Git do repositório** — as entradas de push/merge devem complementar (nunca contradizer) a doc de fluxo de Git do seu repo (`AGENTS.md`/`CONTRIBUTING.md`).
- **Espelhamento opcional** — se o ambiente tiver uma base de conhecimento semântica (grafo/memória de agente), entradas podem ser espelhadas lá para recall; o arquivo **versionado continua a fonte da verdade**.
