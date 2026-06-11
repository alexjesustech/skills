#!/usr/bin/env bash
# Higiene de repositório PÚBLICO — checks genéricos (rodam no CI, em todo PR/push):
#   1. caminhos pessoais absolutos (/home/<user>, /Users/<user>)
#   2. hostnames internos (*.lan, *.local, *.internal)
#   3. IPs de rede privada (192.168.x, 10.x, 172.16-31.x)
#   4. blocos de chave privada
#   5. e-mails que não sejam do autor público ou noreply
# A curadoria fina (nomes de projetos privados etc.) roda como hook LOCAL de
# pre-push com denylist privada — fora deste repositório, por definição.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 2
fails=0

scan() { # scan "<descrição>" "<padrão ERE>" [allowlist ERE]
  local desc="$1" pat="$2" allow="${3:-}"
  local hits
  hits="$(git grep -IEn "$pat" -- ':!scripts/check-public-hygiene.sh' 2>/dev/null || true)"
  if [ -n "$allow" ] && [ -n "$hits" ]; then
    hits="$(printf '%s\n' "$hits" | grep -Ev "$allow" || true)"
  fi
  if [ -n "$hits" ]; then
    echo "FAIL [$desc]:"
    printf '%s\n' "$hits" | head -10
    fails=$((fails + 1))
  fi
}

scan "caminho pessoal absoluto" '/home/[a-z_][a-z0-9_-]*/|/Users/[A-Za-z_][A-Za-z0-9_-]*/'
scan "hostname interno" '[a-z0-9-]+\.(lan|local|internal)([^a-z0-9.]|$)'
scan "IP de rede privada" '\b(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})\b'
scan "chave privada" 'BEGIN (RSA|EC|OPENSSH|DSA|PGP) PRIVATE KEY'
scan "e-mail não-público" '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' '(noreply|users\.noreply)@|alexjesus\.tech@gmail\.com|keepachangelog|semver|example\.(com|org)'

if [ "$fails" -gt 0 ]; then
  echo "—— higiene pública: $fails categoria(s) com achados"; exit 1
fi
echo "OK — higiene pública sem achados"
