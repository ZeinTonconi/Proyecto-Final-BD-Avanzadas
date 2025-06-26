# Borramos todo para evitar conflictos
# Borramos la base de datos 'information' si existe, podemos cambiar el nombre de la base de datos si queremos
docker exec stationdb mongosh -u admin -p "secret" --authenticationDatabase admin --eval "db.getSiblingDB('cowork_central').dropDatabase()"

# Copiamos el backup al contenedor
docker cp ./cowork_central/ stationdb:/tmp/restore/

# Restaurar la base de datos desde el backup
docker exec stationdb bash -c '
  for file in /tmp/restore/cowork_central/*.bson; do
    if [[ -f "$file" ]]; then
      collection=$(basename "$file" .bson)
      echo "Restaurando colección: $collection"
      mongorestore \
        --authenticationDatabase admin \
        -u admin -p "secret" \
        --db cowork_central \
        --collection "$collection" \
        "$file"
    fi
  done
'

# Mostramos las colecciones restauradas para que se ejecutó bien
docker exec stationdb mongosh -u admin -p "secret" --authenticationDatabase admin --eval "db.getSiblingDB('cowork_central').getCollectionNames()"
