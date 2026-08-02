#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker is not installed or is not in PATH."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERROR] Docker Compose v2 is required."
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "[ERROR] .env is missing. Copy infra/oracle-cloud/oracle.env.example to .env and fill in secrets."
  exit 1
fi

echo "[1/3] Building and starting MY9 services..."
docker compose --env-file .env -f docker-compose.oracle.yml up -d --build

echo "[2/3] Service status"
docker compose --env-file .env -f docker-compose.oracle.yml ps

echo "[3/3] API health check"
if curl --fail --silent --show-error --max-time 15 http://127.0.0.1/health; then
  echo
  echo "MY9 API is reachable through Caddy."
else
  echo
  echo "[WARN] Local health check failed. Review logs with:"
  echo "docker compose --env-file .env -f docker-compose.oracle.yml logs --tail=100 api-server caddy data-worker"
  exit 1
fi
