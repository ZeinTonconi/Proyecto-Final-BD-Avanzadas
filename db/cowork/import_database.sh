
docker exec -u postgres cowork dropdb -U admin cowork

docker exec -u postgres cowork createdb -U admin cowork

docker exec -u postgres cowork pg_restore -U admin -d cowork /tmp/cowork_backup.dump -O
