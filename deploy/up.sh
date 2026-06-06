#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env.deploy ]; then
  cp .env.deploy.example .env.deploy
  echo "Created .env.deploy from .env.deploy.example"
fi

docker compose -f docker-compose.dev.yml --env-file .env.deploy up --build -d "$@"

echo ""
echo "Dev stack starting. URLs:"
echo "  Player shell:  http://localhost:5002"
echo "  Back office:   http://localhost:5001"
echo "  API / Swagger: http://localhost:5003/api/docs"
echo ""
echo "Logs: docker compose -f docker-compose.dev.yml logs -f"
