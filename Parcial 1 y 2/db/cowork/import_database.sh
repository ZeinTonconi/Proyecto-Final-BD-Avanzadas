#!/bin/bash

set -e  # Exit immediately on error

echo "Copying dump into docker /tmp..."
docker cp cowork_backup.dump cowork:/tmp/cowork_backup.dump || {
  echo "Failed to copy dump"; exit 1;
}

echo "Dropping database..."
docker exec -u postgres cowork dropdb -U admin cowork || {
    echo "⚠️ Failed to drop database"; exit 1;
}

echo "Creating database..."
docker exec -u postgres cowork createdb -U admin cowork || {
    echo "⚠️ Failed to create database"; exit 1;
}

echo "Restoring database..."
docker exec -u postgres cowork pg_restore -U admin -d cowork /tmp/cowork_backup.dump -O || {
    echo "⚠️ Failed to restore database"; exit 1;
}

echo "✅ Done!"
