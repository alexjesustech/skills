---
name: diretriz-cromatica-html
description: Aplica uma diretriz cromática consistente a documentos HTML gerados por agente (relatórios, especificações, dossiês, atas, diretrizes). Usar sempre que produzir um documento HTML de leitura — fornece as quatro paletas aprovadas (atual, grafite, óxido, noite), o seletor de visualização persistente e as regras tipográficas e de impressão.
---

# diretriz-cromatica-html — documentos HTML de leitura (TOOL · v1.0.0 · Alex Jesus)

Fonte da verdade visual para qualquer documento HTML de leitura gerado por agente.
Quatro esquemas OKLCH selecionáveis pelo leitor, com persistência e impressão corretas.

## Quando aplicar

Todo documento HTML destinado a leitura humana: relatório, especificação,
ADR longo, dossiê, ata, diretriz normativa.

## Quando NÃO usar

Protótipos de interface de aplicação — estes seguem o design system do
produto em questão, não esta diretriz.

## Regras (não negociáveis)

1. **Tokens canônicos em OKLCH.** Copiar os 4 blocos de
   `assets/paletas-cromaticas.css` para o `<style>` do documento (ou linkar a
   folha). O hex sRGB nos comentários é equivalência informativa. Novos tons
   derivam-se em OKLCH — nunca em rgb/hsl (desvio de matiz sob acento).
2. **Seleção por `data-theme`** no elemento `<html>`:
   `atual | grafite | oxido | noite`. `:root` replica o esquema **atual**
   como fallback. Todo estilo do documento consome `var(--*)` — nenhuma cor
   literal fora dos blocos de tema.
3. **Seletor de visualização no próprio documento** — quatro botões com
   tríade de amostras (papel / tinta / acento), rótulo mono em caixa alta.
   A escolha persiste em `localStorage`, chave `diretriz-tema`. Sem
   dependência de framework: HTML + JS vanilla (receita abaixo).
4. **Um único acento saturado por esquema** (`--accent`), reservado a ênfase
   pontual: itálico do título, capitular, marcador. Proibido em hover, foco,
   links, fundos. Sem cores semafóricas de sucesso/alerta/informação.
5. **Impressão:** ocultar o seletor (`display:none`); o esquema *noite*
   reverte aos valores do *grafite* com `--paper:#ffffff` dentro de
   `@media print` (tinta clara sobre papel branco não imprime).
6. **Tipografia:** Newsreader (títulos, serifa editorial), Inter (corpo),
   JetBrains Mono (rótulos, código, masthead meta). Pesos 400/500/600.
   Valores numéricos sempre com `tabular-nums`.
7. **Idioma do layout:** masthead com fio escuro de 2px, título serifado com
   ênfase em itálico no acento, tabelas com `thead` mono em caixa alta e
   fios pontilhados, rodapé serifado em itálico. Referência completa de
   markup em `assets/exemplo-diretriz.html`.

## Receita mínima

```html
<html lang="pt-BR" data-theme="atual">
<head>
  <style>
    /* 1. colar aqui os blocos html[data-theme="..."] de assets/paletas-cromaticas.css */
    /* 2. estilos do documento consomem var(--paper), var(--ink-text), var(--accent)... */
    @media print { .temas { display: none; } /* + bloco de reversão do tema noite */ }
  </style>
</head>
<body>
  <nav class="temas" aria-label="Esquema de visualização">
    <button type="button" data-tema="atual" aria-pressed="true">P1 · atual</button>
    <button type="button" data-tema="grafite" aria-pressed="false">P2 · grafite</button>
    <button type="button" data-tema="oxido" aria-pressed="false">P3 · oxido</button>
    <button type="button" data-tema="noite" aria-pressed="false">P4 · noite</button>
  </nav>
  <!-- conteúdo -->
  <script>
    (function () {
      var KEY = "diretriz-tema";
      var btns = Array.prototype.slice.call(document.querySelectorAll(".temas button"));
      function apply(t) {
        document.documentElement.setAttribute("data-theme", t);
        btns.forEach(function (b) { b.setAttribute("aria-pressed", String(b.getAttribute("data-tema") === t)); });
        try { localStorage.setItem(KEY, t); } catch (e) {}
      }
      btns.forEach(function (b) { b.addEventListener("click", function () { apply(b.getAttribute("data-tema")); }); });
      var saved = null;
      try { saved = localStorage.getItem(KEY); } catch (e) {}
      apply(["atual", "grafite", "oxido", "noite"].indexOf(saved) >= 0 ? saved : "atual");
    })();
  </script>
</body>
</html>
```

## Assets

| Arquivo | Uso |
|---|---|
| `assets/paletas-cromaticas.css` | Blocos `html[data-theme]` prontos, com hex em comentário |
| `assets/paletas-cromaticas.json` | Tokens estruturados (nome, papel, valor OKLCH, hex) para automação |
| `assets/exemplo-diretriz.html` | Documento de referência completo — markup, seletor, impressão |

## Adaptação

- **Fontes**: Newsreader/Inter/JetBrains Mono carregam via Google Fonts no exemplo;
  troque por fontes locais ou equivalentes (serifa editorial / sans humanista / mono)
  mantendo os papéis.
- **Paletas**: os 4 esquemas são um conjunto fechado e testado; para adicionar um 5º,
  derive em OKLCH e respeite as regras 2–5.
- **Idioma**: `lang` e rótulos do seletor seguem o idioma do documento.
