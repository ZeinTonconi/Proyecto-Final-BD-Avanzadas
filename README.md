# Proyecto Final BD Avanzadas

## Para ejecutar:

### 1. Configuración inicial
1. Clonar el repositorio 
2. Ir a la carpeta `db` y crear el archivo `.env` .
3. Colocar la siguiente información

```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=cowork

MARIADB_USER=admin
MARIADB_PASSWORD=admin
MARIADB_DB=organization
MARIADB_ROOT_PASSWORD=admin123

MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=secret
```

4. Ejecutar el comando "docker compose up -d" para levantar los contenedores

### 2. PostgreSQL

![alt text](/Imagenes/docker.png)

5. Ir a la carpeta de PostgreSQL
6. Ejecutar el siguiente comando para otorgar permisos, si es necesario.
```chmod +x import_database.sh```

7. Luego ejecutar el siguiente comando para importar la base de datos.
```./import_database.sh```

8. En Data Grip realizar la conexión con el usuario y contraseña del env

### 2. MariaDB

9. Ir a la carpeta de MariaDB
10. Ejecutar el siguiente comando en la terminal según el sistema operativo de su preferencia:
    -Linux: 
    ```docker exec -i organization   sh -c 'exec mysql -u root -p"admin123" organization'   < organization_bakcup.sql ```
    -Windows: 
    ```type organization_bakcup.sql | docker exec -i organization mysql -u root -p"admin123" organization```
11. En Data Grip hacer la conexión con los datos del env

### 3. MongoDB:

12. Muy parecido a Postgres, vamos a la carpeta Mongo
13. Ejecutar el siguiente comando para otorgar permisos, si es necesario.
```chmod +x import_mongo.sh```
14. Luego ejecutar el siguiente comando en git bash para ejecutar y no powershell.
```./import_mongo.sh```



