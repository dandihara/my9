#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d_%H%M%S)

docker exec seungyo-postgres pg_dump -U seungyo seungyo > "$BACKUP_DIR/seungyo_$TS.sql"
echo "backup created: $BACKUP_DIR/seungyo_$TS.sql"
