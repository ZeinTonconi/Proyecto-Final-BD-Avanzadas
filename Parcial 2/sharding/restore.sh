#!/bin/bash
set -e

echo "Waiting for PostgreSQL to be ready..."

until pg_isready -U "$POSTGRES_USER" > /dev/null 2>&1; do
  sleep 1
done

echo "PostgreSQL is ready. Checking if restore is needed..."

# Only restore if no user-defined tables
if [ -z "$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT tablename FROM pg_tables WHERE schemaname = 'public' LIMIT 1")" ]; then
  echo "Restoring database from dump..."
  pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" -O /dump/cowork_backup.dump \
    && echo "✅ Restore completed successfully." \
    || echo "❌ Restore failed."
else
  echo "⚠️ Database already initialized. Skipping restore."
fi
