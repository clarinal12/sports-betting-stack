#!/usr/bin/env bash
# Print random secrets for .env.deploy (staging). Paste into the JWT/encryption lines.
set -euo pipefail

echo "STAFF_JWT_SECRET=$(openssl rand -hex 32)"
echo "SESSION_JWT_SECRET=$(openssl rand -hex 32)"
echo "SECRET_ENCRYPTION_KEY=$(openssl rand -hex 32)"
