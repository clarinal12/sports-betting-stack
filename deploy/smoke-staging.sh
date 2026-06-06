#!/usr/bin/env bash
# Quick HTTPS staging checks. Run from casino/ after ./deploy/up-https.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env.deploy ]; then
  echo "Missing .env.deploy"
  exit 1
fi

# shellcheck disable=SC1091
source .env.deploy

API="${API_PUBLIC_URL:-https://${API_DOMAIN}}"
BACKOFFICE="${BACKOFFICE_PUBLIC_URL:-https://${BACKOFFICE_DOMAIN}}"
PLAYER="${PLAYER_PUBLIC_URL:-https://${PLAYER_DOMAIN}}"

fail=0
check() {
  local name="$1"
  local url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "$url" || echo "000")
  if [ "$code" = "200" ] || [ "$code" = "302" ] || [ "$code" = "307" ]; then
    echo "OK   $name ($code) $url"
  else
    echo "FAIL $name ($code) $url"
    fail=1
  fi
}

echo "Staging smoke — ${DOMAIN:-unknown domain}"
echo ""

check "API ready" "${API}/ready"
check "API docs" "${API}/api/docs"
check "Back office" "${BACKOFFICE}/"
check "Player shell" "${PLAYER}/"

if [ "$fail" -eq 0 ]; then
  echo ""
  echo "All checks passed."
  echo "Back office login: super@example.com / Super123! (if SEED_ON_START=true)"
  echo "Player token:"
  echo "  docker compose -f docker-compose.dev.yml exec api npm run dev:token -- --merchant acme-merchant"
else
  echo ""
  echo "Some checks failed. Try: docker compose -f docker-compose.dev.yml logs -f caddy api"
  exit 1
fi
