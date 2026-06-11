#!/usr/bin/env bash
# validate-harness — checagem de integridade estrutural de um setup .claude/ em ~2s.
# Versão genérica e auto-contida.
#
# Verifica (estrutura/sintaxe, nunca conteúdo):
#   1. Agents  — .claude/agents/*/agent.md OU .claude/agents/*.md com frontmatter (name, description)
#   2. Skills  — .claude/skills/*/SKILL.md com frontmatter (name, description)
#   3. Rules   — .claude/rules/*.md com frontmatter (paths é recomendado → warn)
#   4. settings.json — JSON válido (se existir)
#   5. Hooks   — todo command em hooks.* aponta para arquivo existente e executável
#   6. ADRs    — docs/adr/*.md com as 4 seções Nygard (Status/Contexto/Decisão/Consequências) → warn
#
# Uso:
#   validate-harness.sh [DIR]    # DIR = raiz do projeto (default: diretório atual)
#   sai 0 se OK, 1 se houver falha (warns não falham)
set -uo pipefail

ROOT="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "diretório inválido: ${1:-.}" >&2; exit 2; }
CLAUDE_DIR="$ROOT/.claude"
REPO="$(basename "$ROOT")"
EXIT_CODE=0

[ -d "$CLAUDE_DIR" ] || { echo "sem .claude/ em $ROOT — nada a validar" >&2; exit 2; }

RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); RESET=$(printf '\033[0m')
fail() { printf '%s✗%s %s\n' "$RED" "$RESET" "$1"; EXIT_CODE=1; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
ok()   { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$1"; }

extract_frontmatter() { awk '/^---$/{flag++; next} flag==1' "$1"; }
has_key() { extract_frontmatter "$1" | grep -Eq "^${2}:"; }
has_frontmatter() { head -1 "$1" | grep -q '^---$'; }

# ---- 1. Agents (suporta layout por-pasta e arquivo-único) -----------------
agents_checked=0
check_agent_file() {
    local file="$1" name="$2"
    has_frontmatter "$file" || { fail "agent '$name': sem frontmatter YAML"; return; }
    for key in name description; do
        has_key "$file" "$key" || fail "agent '$name': falta '$key' no frontmatter"
    done
    has_key "$file" "allowed-tools" || has_key "$file" "tools" || warn "agent '$name': sem 'allowed-tools' (recomendado)"
    agents_checked=$((agents_checked + 1))
}
for d in "$CLAUDE_DIR"/agents/*/; do
    [ -d "$d" ] || continue
    [ -f "$d/agent.md" ] && check_agent_file "$d/agent.md" "$(basename "$d")" || { [ -e "$d/agent.md" ] || true; }
done
for f in "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    check_agent_file "$f" "$(basename "$f" .md)"
done
ok "agents: $agents_checked validados"

# ---- 2. Skills ------------------------------------------------------------
skills_checked=0
for d in "$CLAUDE_DIR"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"; file="$d/SKILL.md"
    [ -f "$file" ] || { fail "skill '$name': falta SKILL.md"; continue; }
    has_frontmatter "$file" || { fail "skill '$name': sem frontmatter YAML"; continue; }
    for key in name description; do
        has_key "$file" "$key" || fail "skill '$name': falta '$key' no frontmatter"
    done
    skills_checked=$((skills_checked + 1))
done
ok "skills: $skills_checked validadas"

# ---- 3. Rules (paths é warning, não falha — formatos variam por ferramenta) -
rules_checked=0
for file in "$CLAUDE_DIR"/rules/*.md; do
    [ -f "$file" ] || continue
    name="$(basename "$file")"
    if ! has_frontmatter "$file"; then
        warn "rule '$name': sem frontmatter YAML (recomendado para escopo por 'paths')"
        rules_checked=$((rules_checked + 1)); continue
    fi
    has_key "$file" "paths" || warn "rule '$name': sem 'paths' no frontmatter (recomendado)"
    rules_checked=$((rules_checked + 1))
done
ok "rules: $rules_checked verificadas"

# ---- 4. settings.json (ausência é warn, não falha) ------------------------
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
    if jq empty "$SETTINGS" >/dev/null 2>&1; then ok "settings.json: JSON válido"
    else fail "settings.json: JSON inválido"; fi
else
    warn "settings.json: ausente (ok se o projeto não usa hooks/permissões locais)"
fi

# ---- 5. Hook commands existem & executáveis -------------------------------
if [ -f "$SETTINGS" ] && jq empty "$SETTINGS" >/dev/null 2>&1; then
    hook_refs=0; hook_bad=0
    while IFS= read -r cmd; do
        [ -n "$cmd" ] || continue
        hook_refs=$((hook_refs + 1))
        cleaned="${cmd#cat | }"; script_path="${cleaned%% *}"
        # Comando "nu" (sem '/', ex.: bash/echo/python): é binário do PATH, não arquivo.
        if [ "${script_path#*/}" = "$script_path" ]; then
            command -v "$script_path" >/dev/null 2>&1 || { fail "comando de hook não está no PATH: $script_path"; hook_bad=$((hook_bad + 1)); }
            continue
        fi
        # Path de script: 1ª tentativa literal; 2ª remapeia pelo nome do repo p/ o checkout atual.
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then continue; fi
        suffix="${script_path##*/$REPO/}"
        if [ "$suffix" != "$script_path" ] && [ -f "$ROOT/$suffix" ] && [ -x "$ROOT/$suffix" ]; then continue; fi
        if [ ! -f "$script_path" ]; then fail "hook não encontrado: $script_path"; hook_bad=$((hook_bad + 1))
        elif [ ! -x "$script_path" ]; then fail "hook não executável: $script_path"; hook_bad=$((hook_bad + 1)); fi
    done < <(jq -r '.hooks // {} | to_entries[] | .value[]? | .hooks[]? | .command // empty' "$SETTINGS")
    [ "$hook_bad" -eq 0 ] && ok "hooks: $hook_refs referências resolvidas e executáveis"
fi

# ---- 6. ADRs (Nygard) — warning -------------------------------------------
adrs_checked=0
for file in "$ROOT"/docs/adr/*.md; do
    [ -f "$file" ] || continue
    name="$(basename "$file")"
    case "$name" in README.md|template.md|*.template.md) continue ;; esac
    for section in "Status" "Contexto" "Decisão" "Consequências"; do
        grep -Fq "## $section" "$file" || grep -Fq "**$section" "$file" || warn "ADR '$name': sem seção '$section'"
    done
    adrs_checked=$((adrs_checked + 1))
done
[ "$adrs_checked" -gt 0 ] && ok "ADRs: $adrs_checked verificados"

echo
if [ "$EXIT_CODE" -eq 0 ]; then ok "integridade do harness: OK"; else fail "integridade do harness: FALHOU — ver achados acima"; fi
exit "$EXIT_CODE"
