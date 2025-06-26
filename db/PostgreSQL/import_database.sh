# Borramos todo para evitar conflictos
docker exec -u postgres cowork dropdb -U admin cowork

# Copiamos el backup al contenedor
docker cp cowork_backup.dump cowork:/tmp/

# Restauramos la base de datos desde el backup
docker exec -u postgres cowork createdb -U admin cowork

# Importamos el backup a la base de datos
docker exec -u postgres cowork pg_restore -U admin -d cowork /tmp/cowork_backup.dump -O
