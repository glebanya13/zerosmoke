#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/opt/antismoke}"
COMPOSE_FILE="$ROOT/deploy/compose.yml"
ENV_FILE="$ROOT/deploy/.env"

cd "$ROOT"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — create it from backend/.env.example first." >&2
  exit 1
fi

echo "==> Pull latest code"
if [[ -d .git ]]; then
  git pull --ff-only origin main || git pull --ff-only origin master
else
  echo "No git repo — assuming code was synced by CI (SCP)."
fi

echo "==> Sync admin overlay (if present)"
if [[ -f "$ROOT/deploy/admin-overlay/app/page.tsx" ]]; then
  cp "$ROOT/deploy/admin-overlay/app/page.tsx" "$ROOT/admin/app/page.tsx"
fi
if [[ -f "$ROOT/deploy/admin-overlay/app/globals.css" ]]; then
  cp "$ROOT/deploy/admin-overlay/app/globals.css" "$ROOT/admin/app/globals.css"
fi

echo "==> Rebuild and restart stack"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" run --rm migrate
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" build backend admin
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d backend admin

echo "==> Wait for API health"
for i in $(seq 1 30); do
  if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T backend \
    node -e "fetch('http://127.0.0.1:3000/admin/dashboard',{headers:{'x-admin-key':process.env.ADMIN_API_KEY}}).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" 2>/dev/null; then
    echo "API is healthy"
    exit 0
  fi
  sleep 2
done

echo "API health check timed out — check logs: docker compose logs backend" >&2
exit 1
