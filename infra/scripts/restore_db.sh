#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: ./restore_db.sh backup.sql"
  exit 1
fi

cat "$1" | docker exec -i seungyo-postgres psql -U seungyo -d seungyo
