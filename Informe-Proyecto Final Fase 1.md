# Gestores de BD

## **Relacionales**:

- Postgres
    - Tablas:
        1. Usuarios
            1. user_id **int pk**
            2. first_name **varchar(25)**
            3. last_name **varchar(25)**
            4. business_name **varchar(50)**
            5. business_type **int fk**
            6. creation_date **date**
            7. email **varchar(25)**
            8. phone_number **int**
        2. Tipo de emprendimiento
            1. type_name **varchar(25)**
            2. id **int pk**
        3. Sucursal
            1. sucursal_id **int pk**
            2. sucursal_name **varchar(50)**
            3. direction_id **int fk**
        4. Estación
            1. name **varchar(25)**
            2. description **text**
            3. sucursal_id **int fk**
            4. id **int pk**
        5. Reservas
            1. user_id **int fk**
            2. estacion_id **int fk**
            3. start_date **date**
            4. finish_date **date**
            5. state **varchar(25)**
            6. type **varchar(25)**
            7. id **int pk**
        6. Pagos
            1. user_id **int fk**
            2. id **int pk**
            3. reserva_id **int fk**
            4. date **date**
            5. amount **int**
            6. method **varchar(25)**
        7. Direcciones de sucursales
            1. number **int**
            2. street_name **varchar(50)**
            3. city **varchar(25)**
            4. directions_id **int pk**
        8. Reservas de salón de talleres
            1. user_id **int fk**
            2. sucursal_id **int fk**
            3. start_date **timestamp**
            4. finish_date **timestamp**
            5. description **text**
        
        ![image.png](attachment:0f546278-0c99-40a1-a056-26f1fc2d80ed:image.png)
        
- MariaDB
    - Tablas:
        1. Personal (Employee)
            1. employee_id **int pk**
            2. first_name **varchar(50)**
            3. middle_name **varchar(50)**
            4. last_names **varchar(100)**
            5. ci **varchar(10)**
            6. sucursal_id **int fk**
            7. phone **varchar(10)**
            8. contract_date **date**
            9. charge_id **int fk**
        2. Inventario (Cooking_equipment)
            1. equipment_id **int pk**
            2. equipment_type  **int fk**
            3. suppliers_id **int fk**
            4. purchase_date **date**
            5. purchase_price **int**
            6. in_use **bool**
            7. needs_repair **bool**
            8. sucursal_id **int fk**
            9. hours_in_use **int**
            10. last_maintenance_date **date**
        3. Categoría de equipamiento (equipment_type)
            1. type_id **int pk**
            2. equipment_type **varchar(50)**
        4. Proveedores
            1. supplier_id **int pk**
            2. supplier_name **varchar(50)**
            3. contract_date **date**
            4. contact_name **varchar(50)**
            5. contact_phone **varchar(50)**
            6. contact_email **varchar(50)**
            
            ![Captura de pantalla 2025-06-03 153537.png](attachment:9aeb3e6e-8e8a-46ad-ada4-fbc6ea616255:Captura_de_pantalla_2025-06-03_153537.png)
            

## **No relacionales**:

- Mongo
- Neo4j

# Vistas

1. (Postgres) Vista que tenga el nombre del negocio y el tipo al que pertenece, además de la información de contacto:
    - business_type_and_users
    
    ```sql
    CREATE VIEW business_type_and_users as
    select u.business_name, bt.type_name, u.first_name, u.last_name, u.email
    from users u
    inner join business_type bt
    on u.business_type = bt.type_id;
    ```
    
2. (Postgres) Vista que tenga la dirección de cada estación, como la ciudad, la calle y su descripción
    - direccion_estacion
    
    ```sql
    CREATE VIEW station address as
    select e.estacion_name, d.city, s.sucursal_name, d.street_name, e.description
    from estaciones e
    inner join sucursales s
    on e.sucursal_id = s.sucursal_id
    inner join directions d
    on s.id_direction = d.directions_id;
    ```
    
3. (MariaDB) Vista donde se pueda ver todos los equipos de cocinas que necesiten mantenimiento además del contacto del proveedor 
    
    ```sql
    CREATE VIEW equipment_maintenance_summary AS
    SELECT 
        ce.equipment_id,
        et.equipment_type,
        ce.purchase_date,
        ce.purchase_price,
        ce.in_use,
        ce.sucursal_id,
        s.supplier_name,
        s.contact_name,
        s.contact_phone,
        s.contact_email
    FROM cooking_equipment ce
    inner JOIN suppliers s ON ce.supplier_id = s.supplier_id
    inner JOIN equipment_type et ON ce.equipment_type = et.type_id
    WHERE ce.needs_repair = TRUE
    ```
    
4. (MariaDB) Vista que muestre el gasto que se realizo por tipo de equipo y además la cantidad que se tiene.
    
    ```sql
    CREATE VIEW equipment_costs_by_type AS
    SELECT 
        et.equipment_type,
        COUNT(*) AS total_units,
        AVG(ce.purchase_price) AS avg_price,
        SUM(ce.purchase_price) AS total_spent
    FROM cooking_equipment ce
    inner JOIN equipment_type et ON ce.equipment_type = et.type_id
    GROUP BY et.equipment_type;
    ```
    

# SP

1. (Postgres) Agregar usuario para ahorrar tiempo en la inserción de usuarios
    
    ```sql
    CREATE OR REPLACE PROCEDURE add_user(
        p_first_name VARCHAR,
        p_last_name VARCHAR,
        p_business_name VARCHAR,
        p_creation_date DATE,
        p_email VARCHAR,
        p_phone VARCHAR,
        p_business_type INT,
        p_user_id INT
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO users(first_name, last_name, business_name, creation_date, email, phone_number, business_type, user_id)
        VALUES (p_first_name, p_last_name, p_business_name,
                p_creation_date, p_email, p_phone, p_business_type, p_user_id);
    END;
    $$;
    
    CALL agregar_usuario('Rebeca', 'Navarro', 'Gluglugluten',
                         current_date, 'beca@gmail.com', '+591 78810003', 1,32634);
    
    SELECT *
    FROM users
    WHERE user_id=32634;
    ```
    
2. (Postgres) Registrar pagos y que verifique si ya había pago y si es un monto mayor a 0
    
    ```sql
    CREATE OR REPLACE PROCEDURE payment_register(
        userId INT,
        reservaId INT,
        pr_payment_date TIMESTAMP,
        pr_amount NUMERIC,
        pr_payment_method VARCHAR
    )
    LANGUAGE plpgsql
    AS $$
    DECLARE
        paid INT;
    BEGIN
        SELECT amount INTO paid 
        FROM payments
        WHERE reserva_id = reservaId
        LIMIT 1;
    
        IF paid > 0 THEN
            RAISE EXCEPTION 'La reserva % ya tiene un pago registrado de %', reservaId, montopagado;
        ELSIF pr_amount < 0 THEN
            RAISE EXCEPTION 'El monto no puede ser negativo';
        ELSE
            UPDATE payments
            SET amount = pr_amount,
                payment_date = pr_payment_date,
                payment_method = pr_payment_method
            WHERE reserva_id = reservaId AND user_id = userId;
    
        END IF;
    END;
    $$;
    
    CALL payment_register(123, 456, current_date, 500.00, 'tarjeta');
    CALL payment_register(12148, 1, current_date, 500.00, 'tarjeta');
    ```
    
3. (MariaDB) Transferir un equipo a otro sucursal además de realizar el log de dicha acción. En caso de que se intente transferir el mismo equipo a dos diferentes sucursales se utilizara manejo de excepciones ademas de utilizar la transaccion de serializable.
    
    ```sql
    
    CREATE or replace PROCEDURE organization.sp_transfer_equipment (
        IN p_equipment_id     INT,
        IN p_new_sucursal_id  INT,
        IN p_employee_id      INT,
        IN p_notes            TEXT
    )
    BEGIN
        DECLARE v_old_sucursal     INT;
        DECLARE v_exists_equipment INT;
    	DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    
        SELECT COUNT(*), sucursal_id
          INTO v_exists_equipment, v_old_sucursal
          FROM cooking_equipment
         WHERE equipment_id = p_equipment_id;
    
        IF v_exists_equipment = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: The equipment does not exist.';
        END IF;
    
        IF v_old_sucursal = p_new_sucursal_id THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Destination branch is the same as the current one.';
        END IF;
    
    	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
        START TRANSACTION;
    
        UPDATE cooking_equipment
           SET sucursal_id = p_new_sucursal_id
         WHERE equipment_id = p_equipment_id;
    
        INSERT INTO log_equipment_transfer (
            equipment_id,
            from_sucursal,
            to_sucursal,
            employee_id,
            notes
        ) VALUES (
            p_equipment_id,
            v_old_sucursal,
            p_new_sucursal_id,
            p_employee_id,
            p_notes
        );
    
        COMMIT;
    END;
    
    ```
    
4. (MariaDB) Marcar todos los equipos que tengan un tiempo minimo de uso como que necesitan mantenimiento needs_repair = true
    
    ```sql
    
    CREATE PROCEDURE sp_mark_high_usage_equipment_for_maintenance (
        IN p_min_hours INT
    )
    BEGIN
        DECLARE v_equipment_id  INT;
        DECLARE v_hours         INT;
        DECLARE done            BOOLEAN DEFAULT FALSE;
    
        DECLARE cur CURSOR FOR
            SELECT equipment_id, hours_in_use
              FROM cooking_equipment
             WHERE needs_repair = 0
               AND hours_in_use >= p_min_hours;
    
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
        START TRANSACTION;
    
        OPEN cur;
        read_loop: LOOP
            FETCH cur INTO v_equipment_id, v_hours;
            IF done THEN
                LEAVE read_loop;
            END IF;
    
            UPDATE cooking_equipment
               SET needs_repair = 1
             WHERE equipment_id = v_equipment_id;
        END LOOP;
    
        CLOSE cur;
        COMMIT;
    END
    ```
    

# Funciones

1. (Postgres) Una función que devuelva el historial de rentas hechas por un emprendimiento, en qué sucursal y cuantas veces para poder realizar estadísticas sobre las preferencias de los usuarios
    
    ```sql
    CREATE OR REPLACE FUNCTION rental_history(business varchar(50))
    RETURNS TABLE(
        Nombre_Empresa varchar(50),
        Tipo_Empresa varchar(25),
        Sucursal varchar(50),
        Cantidad_ReservasEstaciones INTEGER
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT
            u.business_name,
            bt.type_name,
            s.sucursal_name,
            count(r.reserva_id)::INTEGER
        FROM sucursales s
        INNER JOIN estaciones e ON s.sucursal_id = e.sucursal_id
        INNER JOIN reservas r ON e.estacion_id = r.estacion_id
        INNER JOIN users u ON r.user_id = u.user_id
        INNER JOIN business_type bt ON u.business_type = bt.type_id
        WHERE u.business_name = business
        GROUP BY s.sucursal_name, u.business_name, bt.type_name;
    END;
    $$ LANGUAGE plpgsql;
    
    SELECT historial_de_renta('Comida Peruana Gourmet');
    ```
    
2. (Postgres) Resumen por cliente, tanto del total de lo que pagó y la cantidad de reservas que hizo

```sql
CREATE OR REPLACE FUNCTION user_general_summary(userId INT)
RETURNS TABLE(
    User_name VARCHAR(25),
    User_last_name VARCHAR(25),
    Number_reservations INT,
    Number_reservations_salons INT,
    Amount_paid NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.first_name, u.last_name,
        (SELECT COUNT(*)::INT
         FROM reservations r
         WHERE r.user_id = userId),
        (SELECT COUNT(*)::INT
         FROM salons_reservations s
         WHERE s.user_id = userId),
        (SELECT SUM(p.amount)::NUMERIC
         FROM payments p
         WHERE p.user_id = userId)
    FROM users u
    WHERE u.user_id = userId
    group by u.first_name, u.last_name;
END;
$$ LANGUAGE plpgsql;

SELECT user_general_summary(216);
```

1. (MariaDB) Se creara una función para darle un puntaje al equipo que nos dira cuanto tiempo se uso desde la ultima vez que se realizo mantenimiento. Con el puntaje de tiempo podemos conseguir cuales son los equipos que estan mas nuevos o mas usados, para tomar decisiones. Por ejemplo, utilizar los mas usados para llevarlos a mantenimiento lo mas pronto posible.
    
    ```sql
    CREATE or replace FUNCTION fn_equipment_utilization_score(p_equipment_id INT)
    RETURNS DECIMAL(5,2)
    DETERMINISTIC
    READS SQL DATA
    BEGIN
        DECLARE v_hours_in_use INT;
        DECLARE v_maintenance_date DATE;
        DECLARE v_days_owned INT;
        DECLARE v_max_hours_possible INT;
        DECLARE v_score DECIMAL(5,2);
    
        SELECT hours_in_use, last_maintenance_date
          INTO v_hours_in_use, v_maintenance_date
          FROM cooking_equipment
         WHERE equipment_id = p_equipment_id;
    
        SET v_days_owned = DATEDIFF(CURDATE(), v_maintenance_date);
        SET v_max_hours_possible = v_days_owned * 8;
    
        IF v_max_hours_possible = 0 THEN
            RETURN 0;
        END IF;
    
        SET v_score = LEAST((v_hours_in_use / v_max_hours_possible) * 100, 100);
    
        RETURN ROUND(v_score, 2);
    END;
    
    update cooking_equipment set hours_in_use = hours_in_use + 10 where equipment_id = 20001;
    update cooking_equipment set last_maintenance_date = purchase_date where equipment_id = 20001;
    
    select * from cooking_equipment where equipment_id = 20001;
    select min(equipment_id), max(equipment_id) from cooking_equipment;
    
    SELECT fn_equipment_utilization_score(20001) AS utilization_score;
    ```
    
2. (MariaDB) De igual manera, se puede calcular la relacion costo eficiencia con el tiempo de uso del equipo
    
    ```sql
    CREATE FUNCTION fn_equipment_cost_efficiency(p_equipment_id INT)
    RETURNS DECIMAL(10,2)
    DETERMINISTIC
    READS SQL DATA
    BEGIN
        DECLARE v_price DECIMAL(10,2);
        DECLARE v_hours INT;
    
        SELECT purchase_price, hours_in_use
          INTO v_price, v_hours
          FROM cooking_equipment
         WHERE equipment_id = p_equipment_id;
    
        IF v_hours = 0 THEN
            RETURN 0;
        END IF;
    
        RETURN ROUND(v_price / v_hours, 2);
    END;
    SELECT fn_equipment_cost_efficiency(20001);
    ```
    

# Triggers

1. (Postgres) Validar que un mismo usuario no esté con más de 3 reservas activas
    
    ```sql
    CREATE OR REPLACE FUNCTION maximum_active_reservations()
    RETURNS TRIGGER AS $$
    DECLARE
        actives INT;
    BEGIN
        SELECT COUNT(*) INTO actives
        FROM reservations
        WHERE user_id = NEW.user_id AND state = 'activa';
    
        IF NEW.state = 'activa' AND actives >= 3 THEN
            RAISE EXCEPTION 'El usuario % ya tiene 3 reservas activas.', NEW.user_id;
        END IF;
    
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    CREATE TRIGGER max_active_reservations
    BEFORE INSERT OR UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION maximum_active_reservations();
    
    SELECT user_id
    FROM reservations
    WHERE state = 'activa'
    GROUP BY user_id
    HAVING COUNT(*) = 3
    LIMIT 1; --10792 con 3 activas
    
    INSERT INTO reservations(user_id, estacion_id, start_date, finish_date, state, reservation_type)
    VALUES (
        10792,5,current_date,current_date + INTERVAL '2 hours','activa', 'hora');
    ```
    
2. (Postgres) Cada que se actualice una reserva buscará en la tabla para ver si no hay reservas que ya acabaron pero aparecen como activas (error de insertado de datos por ejemplo)
    
    ```sql
    CREATE OR REPLACE FUNCTION update_expired_reservations()
    RETURNS TRIGGER AS $$
    BEGIN
        IF NEW.finish_date < CURRENT_TIMESTAMP AND NEW.state = 'activa' THEN
            NEW.state := 'vencida';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    CREATE TRIGGER update_reservations
    BEFORE INSERT OR UPDATE ON reservarions
    FOR EACH ROW
    EXECUTE FUNCTION update_expired_reservations();
    
    UPDATE reservations SET state = 'active' WHERE user_id= 532;
    ```
    
3. (MariaDB) Cada vez que se marca que un equipo necesita reparación se guardara en una tabla de logs
    
    ```sql
    CREATE TABLE equipment_repair_log (
        repair_id INT AUTO_INCREMENT PRIMARY KEY,
        equipment_id INT,
        flagged_on DATETIME
    );
    CREATE TRIGGER tr_log_repair_flag
    AFTER UPDATE ON cooking_equipment
    FOR EACH ROW
    BEGIN
        IF OLD.needs_repair = FALSE AND NEW.needs_repair = TRUE THEN
            INSERT INTO equipment_repair_log (
                equipment_id,
                flagged_on
            ) VALUES (
                NEW.equipment_id,
                NOW()
            );
        END IF;
    END;
    
    select min(equipment_id) from cooking_equipment where needs_repair = false;
    select * from equipment_maintenance_summary where equipment_id=20001;
    
    update cooking_equipment set needs_repair = true where equipment_id=20001;
    select * from equipment_repair_log;
    ```
    
4. (MariaDB) Cuando se realice mantenimiento a un equipo, este ya no requiere reparaciones por lo que cada vez que se actualice la fecha de mantenimiento la columna needs_repair ira a false
    
    ```sql
    CREATE or replace TRIGGER tr_set_repair
    before UPDATE ON cooking_equipment
    FOR EACH ROW
    BEGIN
    	if old.last_maintenance_date != new.last_maintenance_date then
    		set new.needs_repair = false;
        END IF;
    END;
    
    select min(equipment_id) from cooking_equipment where needs_repair=true;
    
    update cooking_equipment set last_maintenance_date='2025-12-12' WHERE equipment_id = 20001;
    select min(equipment_id) from cooking_equipment where needs_repair=true;
    
    ```
    

# Particiones

- (MariaDB) Se creo una partición en la tabla de logs de transferencia de equipos entre sucursales segun el año.
    
    ```sql
    CREATE TABLE IF NOT EXISTS log_equipment_transfer (
        log_id INT AUTO_INCREMENT,
        equipment_id INT NOT NULL,
        from_sucursal INT NOT NULL,
        to_sucursal INT NOT NULL,
        transfer_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        employee_id int NULL,
        notes TEXT NULL,
        primary key (log_id, transfer_date)
    ) PARTITION BY RANGE COLUMNS(transfer_date) (
        PARTITION p2018 VALUES LESS THAN ('2019-01-01'),
        PARTITION p2019 VALUES LESS THAN ('2020-01-01'),
        PARTITION p2020 VALUES LESS THAN ('2021-01-01'),
        PARTITION p2021 VALUES LESS THAN ('2022-01-01'),
        PARTITION p2022 VALUES LESS THAN ('2023-01-01'),
        PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
        PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
        PARTITION p2025 VALUES LESS THAN ('2026-01-01'),
        PARTITION pFuture VALUES LESS THAN (MAXVALUE)
    );
    
    ALTER TABLE log_equipment_transfer
        REORGANIZE PARTITION pFuture INTO (
            PARTITION p2026 VALUES LESS THAN ('2027-01-01'),
            PARTITION pFuture VALUES LESS THAN (MAXVALUE)
        );
    
    select partition_name, table_rows from
    information_schema.partitions where table_name = 'log_equipment_transfer';
    
    SELECT *
      FROM log_equipment_transfer
      PARTITION (p2025);
    ```
    
- (Postgres) Particiones según la ciudad de las sucursales
    
    ```sql
    CREATE TABLE direction_part (
        direccion_id INT NOT NULL,
        number VARCHAR(20),
        street_name VARCHAR(100),
        city VARCHAR(50)
    ) PARTITION BY LIST (city);
    
    CREATE TABLE directions_madrid PARTITION OF direction_part
        FOR VALUES IN ('Madrid');
    
    CREATE TABLE directions_barcelona PARTITION OF direction_part
        FOR VALUES IN ('Barcelona');
    
    CREATE TABLE directions_valencia PARTITION OF direction_part
        FOR VALUES IN ('Valencia');
    
    CREATE TABLE directions_bilbao PARTITION OF direction_part
        FOR VALUES IN ('Bilbao');
    
    ```
    

# Backups y Restauración

## MariaDB

```sql
docker exec mariadb-container \
  sh -c 'exec mysqldump -u root -p"admin123" \
    --single-transaction --quick --lock-tables=false organization' \
  > organization_backup.sql
```

```sql
docker exec -i organization   sh -c 'exec mysql -u root -p"admin123" organization'   < organization_bakcup.sql
```

## Postgres

```sql
docker exec -u postgres cowork   pg_dump -U admin -F c   -f /tmp/cowork_backup.dump -d  cowork
```

```sql
docker exec -u postgres cowork pg_restore -U admin -d cowork_hashed /tmp/cowork_backup.dump -O
```

# Ofuscamiento

## Ofuscar MariaDB

1. Crear el dump
    
    ```sql
    docker exec mariadb-container \
      sh -c 'exec mysqldump -u root -p"admin123" \
        --single-transaction --quick --lock-tables=false organization' \
      > organization_backup.sql
    ```
    
2. Crear la nueva base de datos
    
    ```sql
    docker exec organization   sh -c 'exec mysql -u root -p"admin123" 
    -e "CREATE DATABASE IF NOT EXISTS \`organization_hashed\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"'
    ```
    
3. Importar la base de datos
    
    ```sql
    docker exec -i organization   sh -c 'exec mysql -u root -p"admin123" organization_hashed'   < organization_bakcup.sql
    ```
    
4. Ofuscamos los valores de las tablas employees y suppliers
    
    ```sql
    select * from suppliers;
    
    update suppliers set 
    contact_name = 'contact_name', 
    contact_phone = 'contact_phone', 
    contact_email = 'contact_email';
    
    select * from employees;
    
    update employees set
    first_name = 'first_name',
    middle_name = 'middle_name',
    last_names = 'last_name',
    ci = 'ci',
    phone = 'phone';
    
    ```
    

## Ofuscar Postgres

1. Crear el backup de la base de datos cowork
    
    ```sql
    docker exec -u postgres cowork   pg_dump -U admin -F c   -f /tmp/cowork_backup.dump -d  cowork
    ```
    
2. Crear una nueva base de datos
    
    ```sql
    docker exec -u postgres cowork createdb -U admin cowork_hashed
    ```
    
3. Importar la base de datos
    
    ```sql
    docker exec -u postgres cowork pg_restore -U admin -d cowork_hashed /tmp/cowork_backup.sql
    ```
    
4. Ofuscamos la información sensible
    
    ```sql
    select * from users;
    
    update users set 
    	first_name = 'first_name',
    	last_name = 'last_name',
    	email = 'email',
    	phone_number = 'phone_number'
    ;
    ```
    

# Consultas optimizadas

## Postgres

- Como primer paso realizamos consultas que use a nuestras tablas de users, reservas y payments para ver cuánto tiempo nos toma realizar cada consulta

![image.png](attachment:6daa9380-e205-44ba-bdb0-b882bef4decf:image.png)

![image.png](attachment:dd12be99-7ec4-460e-9843-6d540724dc0c:image.png)

![Captura de pantalla 2025-06-04 112744.png](attachment:ec0d2a8a-9745-4285-9e98-f6d6b79a6d88:Captura_de_pantalla_2025-06-04_112744.png)

- Query original:
    - Planning Time: 3.547 ms
    - Execution Time: 10.932 ms
- Primero se creara los indices para s.sucursal_name y d.city

```sql
create index idx_type_name on business_type(type_name);
create index idx_city on directions(city);
```

![Captura de pantalla 2025-06-04 113622.png](attachment:354b0508-b43a-41fe-8c2d-0f1acf0a93fa:Captura_de_pantalla_2025-06-04_113622.png)

- Query con indices en los parametros del where
    - Planning Time: 1.774 ms
    - Execution Time: 13.899 ms
- Se creara indices en los foreign keys

```sql
create index idx_stations_sucursal_id on stations(sucursal_id);
create index idx_reservation_station_id on reservation(station_id);
create index idx_reservation_user_id on reservation(user_id);
create index idx_users_business_type on users(business_type);
create index idx_sucursals_direction_id on sucursals(direction_id);
```

![Captura de pantalla 2025-06-04 114838.png](attachment:77ea9bfd-dad7-4256-9853-a283c80166a8:Captura_de_pantalla_2025-06-04_114838.png)

- Optimizacion con indices en los foreign keys
    - Planning Time: 1.026 ms
    - Execution Time: 8.797 ms
