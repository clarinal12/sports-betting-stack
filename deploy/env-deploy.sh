#!/usr/bin/env bash
# Read a single key from .env.deploy without sourcing (avoids cron * glob errors).
env_deploy_get() {
  local key="$1"
  local line
  line=$(grep -m1 "^${key}=" "${ENV_DEPLOY_FILE:-.env.deploy}" 2>/dev/null || true)
  if [ -z "$line" ]; then
    return 1
  fi
  local value="${line#*=}"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}
