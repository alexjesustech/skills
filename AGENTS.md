# skills — regras do repositório

Repositório **público** de skills generalizadas para agentes de código —
fonte única cross-tool (Claude Code, Antigravity, OpenCode, Gemini CLI).
Este arquivo é a fonte única de regras; `CLAUDE.md` é um ponteiro.

## O que entra aqui

- Skills **generalizadas**: nenhuma referência a projeto, máquina, segredo ou
  serviço específico do autor. Acoplamentos viram placeholders documentados na
  seção "Adaptação" da própria skill.
- Cada skill vive em `<categoria>/<nome-da-skill>/` com `SKILL.md` auto-contido
  (+ `scripts/`/`assets/` se necessário). Nome da pasta em **kebab-case** e
  igual ao `name` do frontmatter.

## Convenção obrigatória por skill

1. Frontmatter YAML: `name` e `description` (a description carrega os gatilhos
   de uso — é o que a ferramenta lê para decidir disparar).
2. Primeira linha do corpo: `# <nome> — <resumo> (TOOL · vMAJOR.MINOR.PATCH · autor)`.
3. Seções **"Quando NÃO usar"** e **"Adaptação"** presentes.
4. Conteúdo em pt-BR; código/identificadores na forma original.
5. Skill derivada de material de terceiros credita o upstream e respeita a
   licença de origem.

## Qualidade e CI

- **O gate verde é LOCAL e determinístico**: `bash scripts/ci-local.sh` espelha
  exatamente o workflow (`validate-skills.sh`) — verde local = verde remoto,
  sem depender do GitHub Actions. O Actions roda o MESMO script em push/PR
  como confirmação redundante.
- Hook versionado em `.githooks/` (ative com `git config core.hooksPath
  .githooks`): `pre-commit` (branch-guard + gitleaks).
- Documentação obrigatória: toda mudança atualiza o `CHANGELOG.md`
  (`[Unreleased]`, Keep a Changelog + SemVer). Versão da skill (`TOOL · vX.Y.Z`)
  acompanha mudanças de conteúdo da skill (SemVer por skill).
- Estado de sessão entre agentes (`docs/ESTADO.md`) é **local-only**
  (gitignored) — planejamento interno não é publicado.

## Git

- Branch principal `main`; trabalho em `develop` e feature branches
  (`feature/`/`fix/`/`chore/<slug>`), merge via PR.
- Conventional Commits (`feat`/`fix`/`docs`/`chore`/...); commits de agente
  levam `@ai-generated` + `Co-Authored-By`.
- **Sem CI self-hosted neste repo** (é público — workflows rodam só no GitHub
  Actions cloud).

## Curadoria de publicação (repositório PÚBLICO — regra inegociável)

Todo conteúdo passa por **curadoria do mantenedor** antes da publicação —
generalização completa (nenhuma referência a projeto, máquina, documento
interno ou infraestrutura pessoal) e verificação por ferramenta própria, que
roda fora deste repositório. O CI público valida a **estrutura** das skills.
Em caso de dúvida sobre um conteúdo, ele não é publicado.

## Segurança

- Proibido qualquer token, credencial, PII, caminho de máquina pessoal ou
  referência a infraestrutura privada nas skills e nos exemplos.
