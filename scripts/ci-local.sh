#!/usr/bin/env bash
# CI local — espelho EXATO do .github/workflows/validate.yml.
# Verde aqui = verde no GitHub Actions (checks determinísticos, sem rede).
# Uso: bash scripts/ci-local.sh
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

echo "▶ validate-skills"
if ! bash "$root/scripts/validate-skills.sh"; then
  echo "✗ CI local FALHOU"; exit 1
fi
echo "✓ CI local verde"
