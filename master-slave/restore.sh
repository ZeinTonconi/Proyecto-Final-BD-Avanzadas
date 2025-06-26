#!/bin/bash
set -e

# 1. Wait for Postgres to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until pg_isready -h localhost -p 5432 -U "$POSTGRESQL_USERNAME" > /dev/null 2>&1; do
  sleep 1
done
echo "✅ PostgreSQL is ready."

# 2. Export password so pg commands don’t prompt
export PGPASSWORD="$POSTGRESQL_PASSWORD"

# 3. Drop & recreate the public schema (i.e. clear all tables, views, sequences, etc.)
echo "🧹 Clearing existing public schema..."
psql -h localhost -p 5432 -U "$POSTGRESQL_USERNAME" -d "$POSTGRESQL_DATABASE" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# 4. Restore the dump
echo "📦 Restoring database from dump..."
pg_restore \
  --no-owner \
  -h localhost -p 5432 \
  -U "$POSTGRESQL_USERNAME" \
  -d "$POSTGRESQL_DATABASE" \
  /docker-entrypoint-initdb.d/cowork_backup.dump \
    && echo "✅ Restore completed." \
    || echo "❌ Restore failed."

# 5. Unset the password for safety
unset PGPASSWORD
