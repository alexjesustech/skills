#!/usr/bin/env bash
# CI local — espelho EXATO do .github/workflows/validate.yml.
# Verde aqui = verde no GitHub Actions (checks determinísticos, sem rede).
# Uso: bash scripts/ci-local.sh
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

echo "▶ validate-skills"
bash "$root/scripts/validate-skills.sh" || fail=1

echo "▶ check-public-hygiene"
bash "$root/scripts/check-public-hygiene.sh" || fail=1

if [ "$fail" -ne 0 ]; then
  echo "✗ CI local FALHOU"; exit 1
fi
echo "✓ CI local verde"
