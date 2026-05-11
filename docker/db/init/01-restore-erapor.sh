#!/bin/bash
set -e

DB_NAME="${POSTGRES_DB:-db_neweraporsma}"
DUMP_FILE="/docker-entrypoint-initdb.d/backup-erapor.dump"

if [ -f "$DUMP_FILE" ]; then
  echo "Restoring e-Rapor database dump into ${DB_NAME}..."
  pg_restore --username "${POSTGRES_USER:-postgres}" --dbname "$DB_NAME" --no-owner --role "${POSTGRES_USER:-postgres}" --verbose "$DUMP_FILE"
  echo "Restore completed."
else
  echo "Dump file not found: ${DUMP_FILE}; skipping restore."
fi
