---
name: branch-fan-in
description: "Use ao integrar (fan-in) várias branches/worktrees de feature paralelas que editam o MESMO arquivo de registro compartilhado — ex.: N branches, cada uma adicionando um item (função, tool, rota, export, teste) nos mesmos arquivos, convergindo numa branch de integração antes de entrar na branch-base."
---
# branch-fan-in — integração de branches paralelas sobre registro compartilhado (TOOL · v1.0.0 · Alex Jesus)

## Quando usar

Quando N branches independentes (tipicamente uma por feature/módulo, vivendo em
worktrees Git paralelas) precisam entrar na branch de integração do repositório
(`<branch-base>`, ex.: `develop` ou `main`), e todas tocam os **mesmos arquivos
em regiões sobrepostas**. Caso típico: uma esteira em que cada branch adiciona
um método num mesmo bloco de implementação, tipos auxiliares (`*Params`/
`*Result`), testes e uma entrada na lista de exports (`pub use`/`use`,
`export`, `__all__`) — tudo concentrado num pequeno conjunto de arquivos
compartilhados (`<arquivo_de_registro>`, `<arquivo_de_exports>`,
`<arquivo_de_testes>`).

Sintoma de diagnóstico: `git branch --merged <branch-base>` mostra vazio (fluxo
é squash-merge, history não-ancestral), mas `git diff <branch-base>..<branch>`
mostra centenas de linhas por branch.

## Quando NÃO usar

- Merge de uma única branch, ou de branches que tocam arquivos **disjuntos** —
  o fluxo normal de PR resolve sem esta skill.
- Conflitos de **lógica divergente** (duas branches alterando o MESMO item de
  formas incompatíveis) — isso é decisão de design, não fan-in mecânico;
  resolva com o autor antes de integrar.
- Repositório sem suporte a worktrees/sem Git.

## Passos

1. **Não pode antes de conferir.** `git worktree list` +
   `git diff <branch-base>..<b>` por branch. Branches checked out em worktree
   não podem ser deletadas até o `git worktree remove`.
2. **Crie uma branch de integração** a partir de `<branch-base>`
   (`integration/<marco>-...`). Nunca integre direto na `<branch-base>`.
3. **Ordene:** helpers/infra-base primeiro (branches que só adicionam código de
   suporte), depois as features que registram itens. Helpers entram limpos;
   features colidem entre si.
4. **Merge uma a uma**, `git merge --no-edit <b>`. Para conflitos triviais
   (itens distintos no mesmo ponto de inserção), resolva por **união** — manter
   os dois lados, remover as 3 linhas-marcador:
   `grep -vE '^(<<<<<<< |=======$|>>>>>>> )' f > f.tmp && mv f.tmp f`.
5. **Conserte o estrago da união, guiado pelo compilador/test runner:**
   - Listas de import/export: a união duplica identificadores (em Rust, erro
     E0252). Funda numa lista deduplicada e ordenada.
   - Delimitadores perdidos: cada hunk tende a perder 1 fechamento (`}`) do
     item do lado HEAD (o delimitador de contexto comum sobra só uma vez). O
     build (`<build>`/`<test>`) aponta "unclosed delimiter" (ou equivalente) na
     linha exata.
6. **REGRA DE OURO — entrelaçamento:** quando dois itens de corpo quase
   idêntico se misturam (campos duplicados na mesma struct/objeto literal,
   função cortada no meio), **NÃO confie na união**. Pegue o item canônico da
   branch: `git show <branch>:<arquivo>` e substitua o trecho defeituoso
   inteiro. União só é segura quando os dois lados adicionam itens DISTINTOS em
   pontos distintos.
7. Suite verde por merge (`<test>` no módulo afetado); então
   `git add -A && git commit --no-edit`.
8. Ao fim: polish dos comentários de documentação acumulados, formatador
   (`<fmt>`), gate completo (`<fmt> --check` + `<lint>` com warnings como erro
   + `<test>` na suite inteira).
9. Merge da branch de integração em `<branch-base>` (`--no-ff` preserva
   rastreabilidade; `--squash` para history linear).
10. Limpeza: `git worktree remove` dos integrados, `git branch -d` (delete
    seguro confirma integração), `git push origin --delete` +
    `git fetch --prune`.

## Armadilhas comuns

- **Detecção de conflito frágil:** checar só a string "CONFLICT" no output do
  merge é insuficiente — os merges seguintes falham com "MERGE_HEAD exists" sem
  essa string. Cheque `git diff --name-only --diff-filter=U` ou `git status`.
- **União cega = bug silencioso:** caso real — um campo duplicado dentro de um
  mesmo objeto literal de resultado, e corpos de duas funções vizinhas fundidos
  num só. Compila, mas está errado. Só a regra do passo 6 protege.
- `git merge` **não aceita** `-F -` (stdin) como `git commit`; use arquivo.
- zsh **não tem** `mapfile`; use `$(... | grep ...)` direto.
- Worktrees fora do escopo da esteira (de outras linhas de trabalho) NÃO devem
  ser podados junto — confira o escopo antes do laço de remoção.

## Verificação

- Contagem de itens no registro bate com o esperado (ex.: N features →
  `grep -oE 'pub fn (<nomes>)\b' <arquivo_de_registro> | sort -u | wc -l`).
- Zero marcadores residuais:
  `grep -rnE '^(<<<<<<<|=======|>>>>>>>)' <diretório_de_código>/`.
- Gate verde: `<fmt> --check`, `<lint>` com warnings tratados como erro,
  `<test>` na suite completa (0 failed).

## Adaptação

Parametrize ao adotar num projeto:

- `<branch-base>` — branch de integração do repositório (`develop`, `main`).
- `<arquivo_de_registro>` / `<arquivo_de_exports>` / `<arquivo_de_testes>` — o
  conjunto de arquivos compartilhados onde as branches colidem (ex.: módulo de
  registro de handlers, arquivo de exports do pacote, suite de testes comum).
- `<build>` / `<test>` / `<fmt>` / `<lint>` — comandos canônicos do projeto
  (ex. Rust: `cargo build` / `cargo test` / `cargo fmt` /
  `cargo clippy --workspace --all-targets -- -D warnings`; outros ecossistemas:
  equivalentes do toolchain). Os exemplos de erro citados (E0252, "unclosed
  delimiter") são do compilador Rust — em outra linguagem, use o erro
  equivalente de import duplicado/delimitador.
- `<diretório_de_código>` — raiz varrida na checagem de marcadores residuais.
- `<nomes>` — lista dos identificadores esperados no registro após o fan-in.
- O local das worktrees (ex.: `../<projeto>-wt/*`) segue a convenção do seu
  repositório.
