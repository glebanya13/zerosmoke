#!/bin/sh
set -eu

umask 077
backup_dir=/opt/antismoke/backups
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$backup_dir"

docker compose --env-file /opt/antismoke/deploy/.env \
  -f /opt/antismoke/deploy/compose.yml exec -T postgres \
  pg_dump -U smokefree -d smokefree | gzip -9 > "$backup_dir/postgres-$timestamp.sql.gz"

find "$backup_dir" -type f -name 'postgres-*.sql.gz' -mtime +14 -delete
