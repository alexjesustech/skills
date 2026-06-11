---
name: gera-fluxo
description: >-
  Padrão para geração de fluxos, fluxogramas e diagramas de arquitetura ou
  processo. Disparar SEMPRE que o pedido envolver criar, desenhar, diagramar
  ou atualizar um fluxo/diagrama — em qualquer projeto. Define SVG como
  formato padrão, a semântica de cores, as regras de legibilidade e o local
  de saída versionado. Não disparar para mockups de interface (HTML) nem
  para ERDs/schemas de banco (Mermaid erDiagram).
---

# gera-fluxo — padrão de diagramas (TOOL · v1.1.0 · Alex Jesus)

## Regra de ouro

**Formato padrão: SVG puro**, salvo instrução contrária explícita no pedido.
Se o pedido nomear outro formato (Mermaid, HTML interativo, PNG, draw.io),
o pedido vence — sem perguntar, sem justificar a troca.

## Exceções automáticas (desviar do SVG sem perguntar)

- **ERD / schema de banco** → Mermaid `erDiagram` (layout de tabelas à mão
  em SVG falha sistematicamente).
- **Mockup de interface** → HTML + CSS (não é escopo desta skill).
- **Diagrama destinado a README do GitHub onde diff textual importa mais
  que controle visual** → oferecer Mermaid como alternativa em 1 linha,
  mas entregar SVG se o autor não responder de outra forma.

## Especificação do SVG

**Estrutura:**
- `viewBox="0 0 680 H"` — largura fixa 680; H justa ao conteúdo + 40px.
- `role="img"` com `<title>` e `<desc>` como primeiros filhos (acessibilidade).
- Marker de seta único reutilizado via `<defs>`; conectores sempre com
  `fill="none"`; traço 0.5px em bordas.
- Sem gradientes, sombras, filtros ou texto rotacionado. Fundo transparente.

**Tipografia:**
- Apenas dois tamanhos: 14px (títulos de nó) e 12px (subtítulos, legendas).
- Sentence case em todos os rótulos. Subtítulo de caixa: máximo 5 palavras.
- Largura da caixa ≥ (caracteres do maior rótulo × 8px) + 24px de folga.
- Texto centrado verticalmente com `dominant-baseline="central"`.

**Semântica de cores (codifica natureza, nunca sequência):**

| Cor | Significado fixo |
| :-- | :-- |
| Cinza | Etapa determinística (script, gate, artefato estrutural) |
| Roxo | Etapa com juízo de agente IA |
| Teal | Ato ou decisão humana |
| Âmbar | Alerta, estado degradado ou pendência |

- Máximo 3 cores por diagrama + legenda de 1 linha no topo quando a cor
  carregar significado.
- Texto sobre fundo colorido usa tom escuro da MESMA família — nunca preto.

**Layout:**
- Fluxo em direção única (topo→base ou esquerda→direita); máx. 4 caixas
  por linha; 60px entre caixas; setas nunca atravessam caixas (usar desvio
  em L).
- Ciclo/realimentação: glifo `↻` + nota textual, nunca seta longa de retorno.
- Mais de 5–6 nós → dividir em visão geral + diagramas de detalhe.

## Saída e versionamento

- Salvar em `docs/arquitetura/<slug-descritivo>.svg` no repositório do
  contexto (criar o diretório se não existir).
- Referenciar no README ou doc pertinente com `![](docs/arquitetura/...)`.
- Commit próprio: `docs(arquitetura): adiciona fluxo <slug>` + o trailer de
  co-autoria de IA adotado no repositório (se houver).
- Atualização de diagrama existente = editar o MESMO arquivo (diff legível
  no Git), nunca criar variante numerada.

## Quando NÃO usar

- Mockups de interface (HTML/CSS) e protótipos de produto.
- ERDs e schemas de banco (Mermaid `erDiagram` direto).
- Gráficos de dados (séries, barras, dispersão) — isso é plotagem, não fluxo.

## Antipadrões

- Caixa com texto transbordando (calcular largura ANTES de desenhar).
- Cores em arco-íris sequencial sem semântica.
- Diagrama-monólito com 10+ nós quando o pedido aceitaria decomposição.
- Trocar o formato padrão por preferência própria sem pedido explícito.

## Adaptação

Auto-contida — nenhum placeholder obrigatório. Pontos que você pode querer
ajustar ao adotar:

- **Diretório de saída** (`docs/arquitetura/`): troque pela convenção do seu
  projeto, mantendo a regra "salvar versionado + referenciar no doc".
- **Trailer de commit**: a linha de co-autoria segue a convenção do SEU
  repositório (ex.: `@ai-generated`, `Co-Authored-By: ...`) — ou nenhuma.
- **Paleta**: os 4 significados fixos importam mais que os tons exatos;
  se trocar os tons, preserve o contraste e a regra "máx. 3 cores".
