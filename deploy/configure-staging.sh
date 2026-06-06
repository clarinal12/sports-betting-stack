#!/usr/bin/env bash
# Set HTTPS domain variables in .env.deploy (staging).
# Usage: ./deploy/configure-staging.sh sports-staging.example.com you@example.com
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DOMAIN="${1:-}"
ACME_EMAIL="${2:-}"

if [ -z "$DOMAIN" ] || [ -z "$ACME_EMAIL" ]; then
  echo "Usage: $0 <domain> <acme-email>"
  echo "Example: $0 sports-staging.example.com ops@example.com"
  exit 1
fi

if [ ! -f .env.deploy ]; then
  cp .env.deploy.example .env.deploy
fi

API_DOMAIN="api.${DOMAIN}"
BACKOFFICE_DOMAIN="backoffice.${DOMAIN}"
PLAYER_DOMAIN="play.${DOMAIN}"

set_var() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" .env.deploy; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" .env.deploy
  else
    echo "${key}=${value}" >> .env.deploy
  fi
}

set_var DOMAIN "$DOMAIN"
set_var ACME_EMAIL "$ACME_EMAIL"
set_var API_DOMAIN "$API_DOMAIN"
set_var BACKOFFICE_DOMAIN "$BACKOFFICE_DOMAIN"
set_var PLAYER_DOMAIN "$PLAYER_DOMAIN"
set_var API_PUBLIC_URL "https://${API_DOMAIN}"
set_var BACKOFFICE_PUBLIC_URL "https://${BACKOFFICE_DOMAIN}"
set_var PLAYER_PUBLIC_URL "https://${PLAYER_DOMAIN}"
set_var CORS_ORIGINS "https://${BACKOFFICE_DOMAIN},https://${PLAYER_DOMAIN}"

rm -f .env.deploy.bak

echo "Configured .env.deploy for ${DOMAIN}"
echo ""
echo "DNS A records → this server's public IP:"
echo "  ${API_DOMAIN}"
echo "  ${BACKOFFICE_DOMAIN}"
echo "  ${PLAYER_DOMAIN}"
