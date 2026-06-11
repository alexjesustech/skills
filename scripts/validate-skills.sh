#!/usr/bin/env bash
# Valida a estrutura de todas as skills do repositório (espelha a convenção do AGENTS.md):
#   1. SKILL.md existe em <categoria>/<skill>/
#   2. frontmatter YAML com `name` e `description`
#   3. `name` do frontmatter == nome da pasta (kebab-case)
#   4. cabeçalho TOOL · vX.Y.Z no corpo
#   5. seções "Quando NÃO usar" e "Adaptação" presentes
# Exit 0 = tudo OK; exit 1 = lista de achados.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
count=0

while IFS= read -r skill_md; do
  count=$((count + 1))
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  rel="${skill_md#"$root"/}"

  if ! head -1 "$skill_md" | grep -q '^---$'; then
    echo "FAIL $rel: sem frontmatter YAML"; fails=$((fails + 1)); continue
  fi
  fm="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_md")"
  if ! printf '%s\n' "$fm" | grep -q '^name:'; then
    echo "FAIL $rel: frontmatter sem 'name'"; fails=$((fails + 1))
  fi
  if ! printf '%s\n' "$fm" | grep -q '^description:'; then
    echo "FAIL $rel: frontmatter sem 'description'"; fails=$((fails + 1))
  fi
  fm_name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  if [ -n "$fm_name" ] && [ "$fm_name" != "$name" ]; then
    echo "FAIL $rel: name '$fm_name' difere da pasta '$name'"; fails=$((fails + 1))
  fi
  if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    echo "FAIL $rel: pasta '$name' não é kebab-case"; fails=$((fails + 1))
  fi
  if ! grep -Eq 'TOOL · v[0-9]+\.[0-9]+\.[0-9]+' "$skill_md"; then
    echo "FAIL $rel: sem cabeçalho 'TOOL · vX.Y.Z'"; fails=$((fails + 1))
  fi
  if ! grep -q '## Quando NÃO usar' "$skill_md"; then
    echo "FAIL $rel: sem seção 'Quando NÃO usar'"; fails=$((fails + 1))
  fi
  if ! grep -q '## Adaptação' "$skill_md"; then
    echo "FAIL $rel: sem seção 'Adaptação'"; fails=$((fails + 1))
  fi
done < <(find "$root" -mindepth 3 -maxdepth 3 -name SKILL.md -not -path '*/.git/*' | sort)

if [ "$count" -eq 0 ]; then
  echo "FAIL: nenhuma SKILL.md encontrada"; exit 1
fi
if [ "$fails" -gt 0 ]; then
  echo "—— $fails problema(s) em $count skill(s)"; exit 1
fi
echo "OK — $count skill(s) válidas"
