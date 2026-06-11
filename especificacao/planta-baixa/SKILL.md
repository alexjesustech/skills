---
name: planta-baixa
description: Vocabulário e convenções de planta baixa em PT-BR (paredes, aberturas, cômodos, lajes, pé-direito, cotas, layers, hachuras) e como cada conceito mapeia para campos de uma representação intermediária (IR). Use ao traduzir pedidos em linguagem natural em mutações de um modelo de planta baixa.
---
# planta-baixa — dicionário PT-BR de planta baixa e seu mapeamento para uma IR (TOOL · v1.0.0 · Alex Jesus)

Conhecimento de projeto arquitetônico necessário para traduzir o pedido do usuário em **mutações da
IR/schema do seu projeto**. A IR (o modelo canônico, descrito na spec do projeto) é a fonte da
verdade; este skill é o **dicionário** entre a linguagem do usuário e os campos da IR. Os nomes de
campo abaixo (`eixo`, `espessura`, `peitoril`, …) são o vocabulário de exemplo — renomeie conforme
o seu schema (ver Adaptação), preservando a semântica.

## Vocabulário → IR

### Parede (`Parede`)
- **Eixo / linha de centro** (`eixo`: `{ inicio, fim }`) — a parede é desenhada por sua **linha de
  centro**, não pela face. `inicio ≠ fim`.
- **Espessura** (`espessura`, mm, `> 0`) — largura da parede; cresce a partir do eixo conforme o
  alinhamento.
- **Alinhamento** (`alinhamento`: `"centro" | "esquerda" | "direita"`) — para que lado do eixo a
  espessura cresce (centro = metade para cada lado). Default `"centro"`.
- **Altura** (`altura`, mm) — se ausente, herda o **pé-direito** do nível (`Nivel.peDireito`).

### Abertura (`Abertura`: `porta` | `janela`)
- Vão hospedado **numa parede** (`paredeId` → `Parede.id` do **mesmo nível**).
- **Posição** (`posicao`, mm) — distância ao longo do eixo, medida a partir de `eixo.inicio`.
- **Largura / altura** (mm, `> 0`) — dimensões do vão.
- **Peitoril / sill** (`peitoril`, mm, `≥ 0`) — altura da base do vão. **Porta ⇒ `0`**;
  **janela ⇒ `> 0`**.

### Espaço / cômodo (`Espaco`)
- **Cômodo** com `nome` (ex.: "Sala", "Quarto") e **contorno** (`contorno`: `Ponto2D[]`, polígono
  fechado implícito, **≥ 3 vértices**, sem auto-interseção). Área e perímetro são **derivados**
  (calculados pela camada de geometria), nunca armazenados na IR.

### Laje (`Laje`)
- **Piso/teto** com `contorno` (≥ 3 vértices) e `espessura`, extrudada **a partir de**
  `Nivel.elevacao` (para baixo).

### Nível / pavimento (`Nivel`)
- **Elevação** (`elevacao`, mm) — cota `Z` da **base** do nível.
- **Pé-direito** (`peDireito`, mm, `> 0`, default `2800`) — altura padrão das paredes do nível.
- Num modelo simples, as entidades são **aninhadas no nível**; referências cruzadas (como
  `paredeId`) resolvem **dentro do mesmo nível**.

## Convenções de desenho 2D (produzidas na derivação, não na IR)

A IR guarda só a **intenção**; o desenho 2D nasce de uma função de redução pura (ex.:
`reduzirPara2D`), que emite primitivas **por camada (layer)** — um padrão clássico de CAD:

- **Layers / camadas:** `paredes`, `vaos`, `espacos`, `lajes`, `rotulos` — cada uma vira um *layer*
  no DXF e um grupo no PDF/SVG.
- **Hachuras:** preenchimento que denota material/corte de parede — é **representação 2D**,
  derivada, não um campo da IR.
- **Cotas (dimensões):** anotações de medida — se o seu schema ainda não as cobre, **não invente
  campo** para elas; entram pelo fluxo de evolução do schema (bump de versão + registro de
  decisão — ver o skill `ir-modeling`).
- **Convenções espaciais:** unidade é **milímetro**; coordenadas no plano `XY` com **Z-up** na IR;
  conversões de convenção de eixos (ex.: para o Y-up do three.js) acontecem **só na derivação 3D**,
  nunca na IR.

## Ao modelar/editar a planta

1. **Leia a spec da IR do seu projeto** antes de propor campos — spec antes de código.
2. Traduza o pedido em **mutações da IR** (pelas tools/funções de edição do projeto), nunca em
   geometria resolvida — a IR não armazena polígonos/malhas derivados.
3. Respeite os invariantes relacionais/geométricos: `id` único global, `paredeId` existente,
   abertura cabe no vão (`largura/2 ≤ posicao ≤ comprimento − largura/2`) e na altura
   (`peitoril + altura ≤ altura da parede`), contorno simples (sem auto-interseção), peitoril
   coerente com o tipo — acione o validador geométrico do projeto após mutar.
4. Conceito novo que a IR não cobre (móveis, escadas, telhado, cotas manuais…) ⇒ **não
   improvise**: exige evolução versionada do schema (skill `ir-modeling`).

## Quando NÃO usar

- O domínio não é planta baixa / projeto arquitetônico 2D — o vocabulário (parede por linha de
  centro, peitoril, pé-direito, layers de CAD) não transfere para outros modelos espaciais.
- O projeto não tem uma representação intermediária canônica: se a fonte da verdade é o próprio
  desenho (DXF/SVG editado à mão), o mapeamento vocabulário→campos perde o sentido.
- Mockups de interface ou diagramas genéricos — isto é modelagem semântica de edificação, não
  desenho livre.

## Adaptação

- **"A IR do seu projeto"** — este skill assume um modelo canônico validado por schema (descrito
  num doc de spec e implementado em código). Substitua as menções genéricas pelo caminho real da
  sua spec e pelo nome real do seu pacote/módulo de schema.
- **Nomes de campos** (`eixo`, `espessura`, `alinhamento`, `posicao`, `peitoril`, `contorno`,
  `elevacao`, `peDireito`, `paredeId`) — são o vocabulário PT-BR sugerido; renomeie para o padrão
  do seu schema mantendo a semântica e as restrições (unidades em mm, `> 0`, `≥ 3` vértices).
- **`reduzirPara2D` / derivação 3D** — nomes ilustrativos das funções de redução pura; aponte
  para as funções reais do seu projeto. O que é normativo: derivação **pura** (não muta a IR) e
  derivados **nunca** persistidos de volta nela.
- **Validador geométrico** — substitua pela camada real que checa os invariantes que o schema não
  expressa (referências cruzadas, contenção do vão, polígonos simples).
- **Defaults de domínio** (pé-direito `2800` mm, peitoril `0` em porta) — valores usuais no Brasil;
  ajuste à norma/prática do seu contexto.
- **Skill `ir-modeling`** — companheiro deste skill (em `dados/ir-modeling/`), que define o fluxo
  de evolução versionada do schema referenciado acima.
