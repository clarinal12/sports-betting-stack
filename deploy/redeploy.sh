#!/usr/bin/env bash
# Pull latest from GitHub and rebuild the staging stack.
# Run on the VPS: ./deploy/redeploy.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pull_repo() {
  local dir="$1"
  if [ -d "$dir/.git" ]; then
    echo "Pulling $dir..."
    git -C "$dir" fetch origin
    git -C "$dir" pull --ff-only
  else
    echo "Missing $dir — clone it first (see deploy/bootstrap-vps.sh)."
    exit 1
  fi
}

echo "Updating stack repo..."
git fetch origin
git pull --ff-only

pull_repo sports-betting-service
pull_repo sports-betting-backoffice
pull_repo sportsbook-player-shell

if [ -f deploy/up-https.sh ] && grep -q '^DOMAIN=' .env.deploy 2>/dev/null; then
  ./deploy/up-https.sh
else
  ./deploy/up.sh
fi

echo ""
echo "Redeploy complete."
docker compose -f docker-compose.dev.yml ps
