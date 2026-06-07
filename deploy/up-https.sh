#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env.deploy ]; then
  echo "Missing .env.deploy — copy .env.deploy.example and set DOMAIN / ACME_EMAIL first."
  exit 1
fi

# shellcheck source=deploy/env-deploy.sh
. "$(dirname "$0")/env-deploy.sh"

DOMAIN="$(env_deploy_get DOMAIN || true)"
ACME_EMAIL="$(env_deploy_get ACME_EMAIL || true)"
API_DOMAIN="$(env_deploy_get API_DOMAIN || true)"
BACKOFFICE_DOMAIN="$(env_deploy_get BACKOFFICE_DOMAIN || true)"
PLAYER_DOMAIN="$(env_deploy_get PLAYER_DOMAIN || true)"
API_PUBLIC_URL="$(env_deploy_get API_PUBLIC_URL || true)"
BACKOFFICE_PUBLIC_URL="$(env_deploy_get BACKOFFICE_PUBLIC_URL || true)"
PLAYER_PUBLIC_URL="$(env_deploy_get PLAYER_PUBLIC_URL || true)"

missing=()
[ -z "$DOMAIN" ] && missing+=("DOMAIN")
[ -z "$ACME_EMAIL" ] && missing+=("ACME_EMAIL")
[ -z "$API_DOMAIN" ] && missing+=("API_DOMAIN")
[ -z "$BACKOFFICE_DOMAIN" ] && missing+=("BACKOFFICE_DOMAIN")
[ -z "$PLAYER_DOMAIN" ] && missing+=("PLAYER_DOMAIN")

if [ ${#missing[@]} -gt 0 ]; then
  echo "Set these in .env.deploy before HTTPS deploy: ${missing[*]}"
  exit 1
fi

echo "HTTPS deploy for ${DOMAIN}"
echo "Ensure DNS A records point to this server:"
echo "  ${API_DOMAIN}"
echo "  ${BACKOFFICE_DOMAIN}"
echo "  ${PLAYER_DOMAIN}"
echo ""

docker compose --profile https -f docker-compose.dev.yml --env-file .env.deploy up --build -d "$@"

echo ""
echo "Stack starting. Public URLs (after Caddy obtains certificates):"
echo "  Player shell:  ${PLAYER_PUBLIC_URL:-https://$PLAYER_DOMAIN}"
echo "  Back office:   ${BACKOFFICE_PUBLIC_URL:-https://$BACKOFFICE_DOMAIN}"
echo "  API / Swagger: ${API_PUBLIC_URL:-https://$API_DOMAIN}/api/docs"
echo ""
echo "Logs: docker compose -f docker-compose.dev.yml logs -f caddy"
