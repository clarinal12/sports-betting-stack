#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu/Debian VPS for HTTPS staging.
# Usage: curl -fsSL <raw-url>/deploy/bootstrap-vps.sh | bash -s -- staging.example.com
set -euo pipefail

DOMAIN="${1:-}"
ACME_EMAIL="${ACME_EMAIL:-}"
STACK_REPO="${STACK_REPO:-https://github.com/clarinal12/sports-betting-stack.git}"
STACK_ROOT="${STACK_ROOT:-$HOME/casino}"

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain>   e.g. $0 sports-staging.example.com"
  echo "Optional env: ACME_EMAIL=you@example.com STACK_ROOT=/opt/casino"
  exit 1
fi

if [ -z "$ACME_EMAIL" ]; then
  echo "Set ACME_EMAIL for Let's Encrypt, e.g.:"
  echo "  ACME_EMAIL=you@example.com $0 $DOMAIN"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
  echo "Docker installed. If this is a new install, log out and back in, then re-run this script."
  if ! docker info >/dev/null 2>&1; then
    exit 0
  fi
fi

mkdir -p "$STACK_ROOT"
cd "$STACK_ROOT"

if [ ! -f docker-compose.dev.yml ]; then
  echo "Cloning stack repo into $STACK_ROOT..."
  git clone "$STACK_REPO" "$STACK_ROOT"
fi

clone_app() {
  local dir="$1"
  local url="$2"
  if [ ! -d "$dir/.git" ]; then
    echo "Cloning $dir..."
    git clone "$url" "$dir"
  else
    echo "Updating $dir..."
    git -C "$dir" pull --ff-only
  fi
}

clone_app sports-betting-service https://github.com/clarinal12/sports-betting-service.git
clone_app sports-betting-backoffice https://github.com/clarinal12/sports-betting-backoffice.git
clone_app sportsbook-player-shell https://github.com/clarinal12/sportsbook-player-shell.git

./deploy/configure-staging.sh "$DOMAIN" "$ACME_EMAIL"

if grep -q 'dev-staff-jwt-secret-change-me-please' .env.deploy; then
  echo ""
  echo "Rotate secrets before going public. On any machine run:"
  echo "  ./deploy/generate-secrets.sh"
  echo "Then paste the three lines into .env.deploy on this server."
  echo ""
fi

chmod +x deploy/up.sh deploy/up-https.sh deploy/generate-secrets.sh deploy/smoke-staging.sh 2>/dev/null || true

echo ""
echo "DNS: point these A records at this server's public IP:"
echo "  ${API_DOMAIN}"
echo "  ${BACKOFFICE_DOMAIN}"
echo "  ${PLAYER_DOMAIN}"
echo ""
echo "When DNS propagates, deploy:"
echo "  cd ${STACK_ROOT} && ./deploy/up-https.sh"
echo ""
echo "Smoke test:"
echo "  ./deploy/smoke-staging.sh"
