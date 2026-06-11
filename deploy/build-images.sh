#!/usr/bin/env bash
# Build app images one service at a time — avoids OOM on small VPS / self-hosted runners.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE=()
if [ -f .env.deploy ]; then
  ENV_FILE=(--env-file .env.deploy)
fi

PROFILE=()
if grep -q '^DOMAIN=' .env.deploy 2>/dev/null; then
  PROFILE=(--profile https)
fi

compose() {
  docker compose "${PROFILE[@]}" -f docker-compose.dev.yml "${ENV_FILE[@]}" "$@"
}

export DOCKER_BUILDKIT=1
export COMPOSE_PARALLEL_LIMIT=1
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=768}"

for svc in api backoffice player-shell; do
  echo ""
  echo "=== Building ${svc} ==="
  compose build "$svc"
done

echo ""
echo "All images built."
