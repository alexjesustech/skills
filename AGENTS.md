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
  exatamente o workflow (`validate-skills.sh` + `check-public-hygiene.sh`) —
  verde local = verde remoto, sem depender do GitHub Actions. O Actions roda os
  MESMOS scripts em push/PR como confirmação redundante e gate de contribuição
  externa.
- Hooks versionados em `.githooks/` (ative com `git config core.hooksPath
  .githooks`): `pre-commit` (branch-guard + gitleaks) e `pre-push` (CI local +
  curadoria com denylist privada do mantenedor).
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

Nada entra neste repositório sem passar pela curadoria. Três camadas:

1. **Passe de generalização (autor/agente):** antes de trazer qualquer conteúdo
   derivado de material interno, remover/abstrair TODO acoplamento — nomes de
   projetos privados, hostnames, caminhos de máquina, nomes de documentos
   internos, detalhes de infraestrutura pessoal. Em caso de dúvida, não publica.
2. **CI público (genérico):** `scripts/check-public-hygiene.sh` roda em todo
   push/PR e bloqueia caminhos pessoais absolutos, hostnames internos
   (`*.lan`/`*.local`), IPs de rede privada, chaves privadas e e-mails
   não-públicos.
3. **Gate local do mantenedor:** o `pre-push` versionado em `.githooks/` roda o
   CI local e varre a árvore pushada com uma **denylist privada** (mantida FORA
   deste repositório — versioná-la aqui exporia os próprios termos).
   Fail-closed: sem denylist, sem push (contribuidor externo:
   `SKIP_CURADORIA=1`).

## Segurança

- Proibido qualquer token, credencial, PII, caminho de máquina pessoal ou
  referência a infraestrutura privada nas skills e nos exemplos.
