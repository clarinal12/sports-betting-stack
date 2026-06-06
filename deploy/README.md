# Sports Betting — Dev Environment Deployment

Docker Compose stack for the three projects plus Postgres and Redis.

GitHub: [clarinal12/sports-betting-stack](https://github.com/clarinal12/sports-betting-stack) (orchestration only — clones the three app repos on the VPS).

## Quick start: HTTPS staging on a VPS

### Prerequisites

- Ubuntu/Debian VPS with Docker (2 vCPU / 4 GB RAM is enough)
- A domain you control
- Ports **80** and **443** open; do **not** expose 5001–5003 publicly

### 1. DNS

Create **A records** pointing at the VPS public IP:

| Host | Example |
|------|---------|
| `api` | `api.sports-staging.example.com` |
| `backoffice` | `backoffice.sports-staging.example.com` |
| `play` | `play.sports-staging.example.com` |

### 2. Bootstrap the server

SSH into the VPS, then:

```bash
export ACME_EMAIL=you@example.com
git clone https://github.com/clarinal12/sports-betting-stack.git ~/casino
cd ~/casino
./deploy/bootstrap-vps.sh sports-staging.example.com
```

This installs Docker (if needed), clones the three app repos, and creates `.env.deploy`.

### 3. Rotate secrets (required before public access)

On the VPS:

```bash
cd ~/casino
./deploy/generate-secrets.sh
```

Paste the three output lines into `.env.deploy`, replacing the dev defaults.

Keep `FIXTURE_PROVIDER=mock` for staging unless you have a stable `ODDS_API_KEY`.

### 4. Deploy

```bash
./deploy/configure-staging.sh sports-staging.example.com you@example.com   # if not done by bootstrap
./deploy/up-https.sh
```

First HTTPS request may take 1–2 minutes while Caddy obtains Let's Encrypt certificates.

### 5. Smoke test

```bash
./deploy/smoke-staging.sh
```

| App | URL |
|-----|-----|
| Player shell | `https://play.<domain>` |
| Back office | `https://backoffice.<domain>` |
| API health | `https://api.<domain>/ready` |

Demo logins (when `SEED_ON_START=true`): `super@example.com` / `Super123!`

Player launch token:

```bash
docker compose -f docker-compose.dev.yml exec api npm run dev:token -- \
  --merchant acme-merchant --user player-1 --username alice
```

---

## Modes

| Mode | Command | URLs |
|------|---------|------|
| **Local** (direct ports) | `./deploy/up.sh` | `http://localhost:5001` … `5003` |
| **Public HTTPS** (VPS) | `./deploy/up-https.sh` | `https://play.*`, `https://backoffice.*`, `https://api.*` |

Postgres and Redis are internal to the stack in both modes.

---

## Public HTTPS (recommended for shared dev)

### What you need

- A VPS with Docker (2 vCPU / 4 GB RAM is enough)
- A domain you control (e.g. `sports-dev.example.com`)
- Ports **80** and **443** open on the firewall

### 1. DNS

Create **A records** pointing at the server IP:

| Host | Example |
|------|---------|
| `api` | `api.sports-dev.example.com` |
| `backoffice` | `backoffice.sports-dev.example.com` |
| `play` | `play.sports-dev.example.com` |

All three can point to the same IP — Caddy routes by hostname.

### 2. Configure `.env.deploy`

```bash
cp .env.deploy.example .env.deploy
```

Uncomment and set the HTTPS block (Mode B):

```bash
DOMAIN=sports-dev.example.com
ACME_EMAIL=you@example.com
API_DOMAIN=api.sports-dev.example.com
BACKOFFICE_DOMAIN=backoffice.sports-dev.example.com
PLAYER_DOMAIN=play.sports-dev.example.com
API_PUBLIC_URL=https://api.sports-dev.example.com
BACKOFFICE_PUBLIC_URL=https://backoffice.sports-dev.example.com
PLAYER_PUBLIC_URL=https://play.sports-dev.example.com
CORS_ORIGINS=https://backoffice.sports-dev.example.com,https://play.sports-dev.example.com
```

`API_PUBLIC_URL` is baked into the Next.js images at build time — **rebuild** after changing it.

### 3. Deploy

From the `casino/` directory (sibling to all three repos):

```bash
chmod +x deploy/up-https.sh
./deploy/up-https.sh
```

Caddy obtains Let's Encrypt certificates automatically on first request (may take 1–2 minutes).

### 4. Open the apps

| App | URL |
|-----|-----|
| Player shell | `https://play.sports-dev.example.com` |
| Back office | `https://backoffice.sports-dev.example.com` |
| API health | `https://api.sports-dev.example.com/ready` |
| Swagger | `https://api.sports-dev.example.com/api/docs` |

### Firewall

- **Allow:** 80, 443 (and 22 for SSH)
- **Block on public interface:** 5001, 5002, 5003 (apps are still reachable via Caddy)

### Seed & logins

On first boot, `SEED_ON_START=true` loads mock fixtures and demo tenants.

| Account | Password | Role |
|---------|----------|------|
| `super@example.com` | `Super123!` | SUPER_ADMIN |
| `platform@example.com` | `Platform123!` | PLATFORM_ADMIN (Acme only) |
| `admin@acme.example.com` | `Acme123!` | OPERATOR_ADMIN (Acme) |

Player launch token:

```bash
docker compose -f docker-compose.dev.yml exec api npm run dev:token -- \
  --merchant acme-merchant --user player-1 --username alice
```

Paste at `https://play.<your-domain>/login`.

---

## Local Docker (no TLS)

```bash
cp .env.deploy.example .env.deploy
./deploy/up.sh
```

Stop local `npm run start:dev` / `pnpm dev` first if ports 5001–5003 are in use.

- Player shell: http://localhost:5002
- Back office: http://localhost:5001
- API: http://localhost:5003/api/docs

---

## Operations

```bash
# All logs
docker compose -f docker-compose.dev.yml logs -f

# Caddy / TLS issues
docker compose -f docker-compose.dev.yml logs -f caddy

# Restart API
docker compose -f docker-compose.dev.yml restart api

# Stop (keeps database)
docker compose --profile https -f docker-compose.dev.yml down

# Wipe database
docker compose --profile https -f docker-compose.dev.yml down -v

# Re-seed
docker compose -f docker-compose.dev.yml exec api npm run db:seed
```

## Architecture (HTTPS mode)

```text
Internet :443
    │
    ▼
 Caddy (TLS termination)
    ├── api.<domain>        → api:5003
    ├── backoffice.<domain> → backoffice:5001
    └── play.<domain>       → player-shell:5002
                                    │
                                    └── HTTP/WS → api:5003
api ──→ postgres, redis
```

## Configuration notes

- **`NODE_ENV=development`** — browser CORS works for the Next.js apps. Dev environment only.
- **`FIXTURE_PROVIDER=mock`** — no Odds API key required. Switch to `odds-api` when needed.
- **Secrets** — override JWT/encryption keys if the host is on the public internet.
- **Let's Encrypt** — requires valid public DNS. `localhost` will not work for HTTPS.

## Local processes vs Docker

| | `npm run start:dev` | Docker stack |
|--|---------------------|--------------|
| Hot reload | Yes | No — rebuild images |
| Shared URL | No | Yes (HTTPS mode) |
| Postgres/Redis | Host docker-compose | In stack |

Use local processes for daily coding; use the HTTPS stack for a stable URL the team can share.
