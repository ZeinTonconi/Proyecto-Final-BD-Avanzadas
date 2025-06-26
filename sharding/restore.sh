#!/bin/bash

set -e  # Exit immediately on error

echo "Copying dump into docker /tmp..."
docker cp cowork_backup.dump shard_lapaz:/tmp/cowork_backup.dump || {
  echo "Failed to copy dump"; exit 1;
}

echo "Dropping database..."
docker exec -u postgres shard_lapaz dropdb -U postgres cowork || {
    echo "⚠️ Failed to drop database"; exit 1;
}

echo "Creating database..."
docker exec -u postgres shard_lapaz createdb -U postgres cowork || {
    echo "⚠️ Failed to create database"; exit 1;
}

echo "Restoring database..."
docker exec -u postgres shard_lapaz pg_restore -U postgres -d cowork /tmp/cowork_backup.dump -O || {
    echo "⚠️ Failed to restore database"; exit 1;
}

echo "✅ Done!"

echo "Copying dump into docker /tmp..."
docker cp cowork_backup.dump shard_cbba:/tmp/cowork_backup.dump || {
  echo "Failed to copy dump"; exit 1;
}

echo "Dropping database..."
docker exec -u postgres shard_cbba dropdb -U postgres cowork || {
    echo "⚠️ Failed to drop database"; exit 1;
}

echo "Creating database..."
docker exec -u postgres shard_cbba createdb -U postgres cowork || {
    echo "⚠️ Failed to create database"; exit 1;
}

echo "Restoring database..."
docker exec -u postgres shard_cbba pg_restore -U postgres -d cowork /tmp/cowork_backup.dump -O || {
    echo "⚠️ Failed to restore database"; exit 1;
}

echo "✅ Done!"