**Proyecto**

**Gestores de BD**

**Relacionales:** 

- Postgres 
  - Tablas:

     Usuar ios

a user\_id **int pk**

b first\_name **varchar(25)**

c last\_name **varchar(25)**

d business\_name **varchar(50)** e business\_type **int fk**

f creation\_date **date**

g email **varchar(25)**

h phone\_number **int**

 Tipo de empr endimiento

a type\_name **varchar(25)**

b id **int pk**

 Sucursal

a sucursal\_id **int pk**

b sucursal\_name **varchar(50)** c direction\_id **int fk**

 Estación

a name **varchar(25)**

b description **text**

c sucursal\_id **int fk** d id **int pk**

 Reservas

a user\_id **int fk** b estacion\_id **int fk** c start\_date **date** d finish\_date **date** e state **varchar(25)**

f type **varchar(25)** g id **int pk**

 Pagos

a user\_id **int fk** b id **int pk**

c reserva\_id **int fk** d date **date**

e amount **int**

f method  **varchar(25)**  Direcciones de sucursales

a number **int**

b street\_name **varchar(50)** c city **varchar(25)**

d directions\_id **int pk**

 Reservas de salón de talleres

a user\_id **int fk**

b sucursal\_id **int fk**

c start\_date **timestamp** d finish\_date **timestamp**

e description **text**

![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.001.jpeg)

- MariaDB
  - Tablas:

     Personal Employee)

a employee\_id **int pk**

b first\_name **varchar(50)**

c middle\_name **varchar(50)** d last\_names **varchar(100)**

e ci **varchar(10)**

f sucursal\_ id **int fk**

g phone **varchar(10)**

h contract\_date **date**

i char ge\_id **int fk**

 Inventario Cooking\_equipment)

a equipment\_id **int pk**

b equipment\_type  **int fk**

c suppliers\_id **int fk**

d purchase\_date **date**

e purchase\_price **int**

f in\_use  **bool**

g needs\_repair **bool**

h sucursal\_id **int fk**

i hours\_ in\_use **int**

j last\_ maintenance\_date **date**

 Cat egoría de equipamiento (equipment\_type)

a type\_id **int pk**

b equipment\_type **varchar(50)**

 Proveedores

a supplier\_id **int pk**

b supplier\_name **varchar(50)**

c contract\_date **date**

d contact\_name **varchar(50)**

e contact\_phone **varchar(50)**

f cont act\_email **varchar(50)**

![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.002.jpeg)

**No relacionales:** 

- Mongo 
- Neo4j

**Vistas**

 Postgres) Vista que tenga el nombre del negocio y el tipo al que

pertenece, además de la información de contacto:

- business\_type\_and\_users 

CREATE VIEW business\_type\_and\_users as![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.003.png)

select u.business\_name, bt.type\_name, u.first\_name, u.last\_name, u.email from users u

inner join business\_type bt

on u.business\_type = bt.type\_id;

 Postgres) Vista que tenga la dirección de cada estación, como la ciudad, la

calle y su descripción

- direccion\_estacion 

CREATE VIEW station address as![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.004.png)

select e.estacion\_name, d.city, s.sucursal\_name, d.street\_name, e.descrip from estaciones e

inner join sucursales s

on e.sucursal\_id = s.sucursal\_id

inner join directions d

on s.id\_direction = d.directions\_id;

 MariaDB Vista donde se pueda ver todos los equipos de cocinas que

necesiten mantenimiento además del contacto del proveedor 

CREATE VIEW equipment\_maintenance\_summary AS![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.005.png)

SELECT 

`    `ce.equipment\_id,

`    `et.equipment\_type,

`    `ce.purchase\_date,

`    `ce.purchase\_price,

`    `ce.in\_use,

`    `ce.sucursal\_id,

`    `s.supplier\_name,

`    `s.contact\_name,

`    `s.contact\_phone,

`    `s.contact\_email

FROM cooking\_equipment ce

inner JOIN suppliers s ON ce.supplier\_id = s.supplier\_id inner JOIN equipment\_type et ON ce.equipment\_type = et.type\_id WHERE ce.needs\_repair  TRUE

 MariaDB Vista que muestre el gasto que se realizo por tipo de equipo y

además la cantidad que se tiene.

CREATE VIEW equipment\_costs\_by\_type AS![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.006.png)

SELECT 

`    `et.equipment\_type,

`    `COUNT\* AS total\_units,

`    `AVG(ce.purchase\_price) AS avg\_price,

`    `SUM(ce.purchase\_price) AS total\_spent

FROM cooking\_equipment ce![ref1]

inner JOIN equipment\_type et ON ce.equipment\_type = et.type\_id GROUP BY et.equipment\_type;

**SP**

 Postgres) Agregar usuario para ahorrar tiempo en la inserción de usuarios

CREATE OR REPLACE PROCEDURE add\_user(![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.008.png)

`    `p\_first\_name VARCHAR,

`    `p\_last\_name VARCHAR,

`    `p\_business\_name VARCHAR,

`    `p\_creation\_date DATE,

`    `p\_email VARCHAR,

`    `p\_phone VARCHAR,

`    `p\_business\_type INT,

`    `p\_user\_id INT

)

LANGUAGE plpgsql

AS $$

BEGIN

`    `INSERT INTO users(first\_name, last\_name, business\_name, creation\_dat     VALUES (p\_first\_name, p\_last\_name, p\_business\_name,

`            `p\_creation\_date, p\_email, p\_phone, p\_business\_type, p\_user\_id); END;

$$;

CALL agregar\_usuario('Rebeca', 'Navarro', 'Gluglugluten',                      current\_date, 'beca@gmail.com', '591 78810003', 1,32634;

SELECT \*

FROM users

WHERE user\_id=32634;

 Postgres) Registrar pagos y que verifique si ya había pago y si es un

monto mayor a 0

CREATE OR REPLACE PROCEDURE payment\_register(     userId ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.009.png)INT,

`    `reservaId INT,

`    `pr\_payment\_date TIMESTAMP,

`    `pr\_amount NUMERIC,

`    `pr\_payment\_method VARCHAR

)

LANGUAGE plpgsql

AS $$

DECLARE

`    `paid INT;

BEGIN

`    `SELECT amount INTO paid 

`    `FROM payments

`    `WHERE reserva\_id = reservaId

`    `LIMIT 1;

`    `IF paid  0 THEN

`        `RAISE EXCEPTION 'La reserva % ya tiene un pago registrado de %', r     ELSIF pr\_amount  0 THEN

`        `RAISE EXCEPTION 'El monto no puede ser negativo';

`    `ELSE

`        `UPDATE payments

`        `SET amount = pr\_amount,

`            `payment\_date = pr\_payment\_date,

`            `payment\_method = pr\_payment\_method

`        `WHERE reserva\_id = reservaId AND user\_id = userId;

`    `END IF; END;

$$;

CALL payment\_register(123, 456, current\_date, 500.00, 'tarjeta'); CALL payment\_register(12148, 1, current\_date, 500.00, 'tarjeta');

 MariaDB Transferir un equipo a otro sucursal además de realizar el log de 

dicha acción. En caso de que se intente transferir el mismo equipo a dos

diferentes sucursales se utilizara manejo de excepciones ademas de utilizar la transaccion de serializable.

CREATE or replace PROCEDURE organization.sp\_transfer\_equipment (     IN p\_equipment\_id     INT,![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.010.png)

`    `IN p\_new\_sucursal\_id  INT,

`    `IN p\_employee\_id      INT,

`    `IN p\_notes            TEXT

)

BEGIN

`    `DECLARE v\_old\_sucursal     INT;

`    `DECLARE v\_exists\_equipment INT;

DECLARE EXIT HANDLER FOR SQLEXCEPTION

`    `BEGIN

`        `ROLLBACK;

`    `END;

`    `SELECT COUNT\*, sucursal\_id

`      `INTO v\_exists\_equipment, v\_old\_sucursal       FROM cooking\_equipment

`     `WHERE equipment\_id = p\_equipment\_id;

`    `IF v\_exists\_equipment  0 THEN

`        `SIGNAL SQLSTATE '45000'

`        `SET MESSAGE\_TEXT  'Error: The equipment does not exist.';     END IF;

`    `IF v\_old\_sucursal = p\_new\_sucursal\_id THEN

`        `SIGNAL SQLSTATE '45000'

`        `SET MESSAGE\_TEXT  'Error: Destination branch is the same as the c     END IF;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;     START TRANSACTION;

`    `UPDATE cooking\_equipment

`       `SET sucursal\_id = p\_new\_sucursal\_id![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.011.png)

`     `WHERE equipment\_id = p\_equipment\_id;

`    `INSERT INTO log\_equipment\_transfer (         equipment\_id,

`        `from\_sucursal,

`        `to\_sucursal,

`        `employee\_id,

`        `notes

- VALUES 

`        `p\_equipment\_id,

`        `v\_old\_sucursal,

`        `p\_new\_sucursal\_id,

`        `p\_employee\_id,

`        `p\_notes

`    `);

`    `COMMIT; END;

 MariaDB Marcar todos los equipos que tengan un tiempo minimo de uso como que necesitan mantenimiento needs\_repair = true

CREATE PROCEDURE sp\_mark\_high\_usage\_equipment\_for\_maintenance (     IN p\_min\_hours INT

)

BEGIN

`    `DECLARE v\_equipment\_id  INT;

`    `DECLARE v\_hours         INT;

`    `DECLARE done            BOOLEAN DEFAULT FALSE;

`    `DECLARE cur CURSOR FOR

`        `SELECT equipment\_id, hours\_in\_use           FROM cooking\_equipment

`         `WHERE needs\_repair  0

`           `AND hours\_in\_use >= p\_min\_hours;

`    `DECLARE CONTINUE HANDLER FOR NOT FOUND SET done  TRUE;     START TRANSACTION;![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.012.png)

`    `OPEN cur;

`    `read\_loop: LOOP

`        `FETCH cur INTO v\_equipment\_id, v\_hours;         IF done THEN

`            `LEAVE read\_loop;

`        `END IF;

`        `UPDATE cooking\_equipment

`           `SET needs\_repair  1

`         `WHERE equipment\_id = v\_equipment\_id;     END LOOP;

`    `CLOSE cur;     COMMIT; END

**Funciones**

 Postgres) Una función que devuelva el historial de rentas hechas por un

emprendimiento, en qué sucursal y cuantas veces para poder realizar estadísticas sobre las preferencias de los usuarios

CREATE OR REPLACE FUNCTION rental\_history(business varchar(50)) RETURNS TABLE

`    `Nombre\_Empresa varchar(50),

`    `Tipo\_Empresa varchar(25),

`    `Sucursal varchar(50),

`    `Cantidad\_ReservasEstaciones INTEGER

- AS $$

BEGIN

`    `RETURN QUERY

`    `SELECT

`        `u.business\_name,![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.013.png)

`        `bt.type\_name,

`        `s.sucursal\_name,

`        `count(r.reserva\_id)::INTEGER

`    `FROM sucursales s

`    `INNER JOIN estaciones e ON s.sucursal\_id = e.sucursal\_id     INNER JOIN reservas r ON e.estacion\_id = r.estacion\_id     INNER JOIN users u ON r.user\_id = u.user\_id

`    `INNER JOIN business\_type bt ON u.business\_type = bt.type\_id     WHERE u.business\_name = business

`    `GROUP BY s.sucursal\_name, u.business\_name, bt.type\_name; END;

$$ LANGUAGE plpgsql;

SELECT historial\_de\_renta('Comida Peruana Gourmet');

 Postgres) Resumen por cliente, tanto del total de lo que pagó y la cantidad 

de reservas que hizo

CREATE OR REPLACE FUNCTION user\_general\_summary(userId INT RETURNS ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.014.png)TABLE

`    `User\_name VARCHAR25,

`    `User\_last\_name VARCHAR25,

`    `Number\_reservations INT,

`    `Number\_reservations\_salons INT,

`    `Amount\_paid NUMERIC

- AS $$

BEGIN

`    `RETURN QUERY

`    `SELECT u.first\_name, u.last\_name,

`        `SELECT COUNT\*INT

`         `FROM reservations r

`         `WHERE r.user\_id = userId),

`        `SELECT COUNT\*INT

`         `FROM salons\_reservations s

`         `WHERE s.user\_id = userId),

`        `SELECT SUM(p.amount)::NUMERIC

`         `FROM payments p

`         `WHERE p.user\_id = userId)![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.015.png)

`    `FROM users u

`    `WHERE u.user\_id = userId

`    `group by u.first\_name, u.last\_name; END;

$$ LANGUAGE plpgsql;

SELECT user\_general\_summary(216);

 MariaDB Se creara una función para darle un puntaje al equipo que nos

dira cuanto tiempo se uso desde la ultima vez que se realizo mantenimiento. Con el puntaje de tiempo podemos conseguir cuales son los equipos que estan mas nuevos o mas usados, para tomar decisiones. Por ejemplo, utilizar los mas usados para llevarlos a mantenimiento lo mas pronto posible.

CREATE or replace FUNCTION fn\_equipment\_utilization\_score(p\_equipmen RETURNS DECIMAL5,2![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.016.png)

DETERMINISTIC

READS SQL DATA

BEGIN

`    `DECLARE v\_hours\_in\_use INT;

`    `DECLARE v\_maintenance\_date DATE;

`    `DECLARE v\_days\_owned INT;

`    `DECLARE v\_max\_hours\_possible INT;

`    `DECLARE v\_scor e DECIMAL5,2;

`    `SELECT hours\_in\_use, last\_maintenance\_date       INTO v\_hours\_in\_use, v\_maintenance\_date

`      `FROM cooking\_equipment

`     `WHERE equipment\_id = p\_equipment\_id;

`    `SET v\_days\_owned  DATEDIFFCURDATE, v\_maintenance\_date);     SET v\_max\_hours\_possible = v\_days\_owned \* 8;

`    `IF v\_max\_hours\_possible  0 THEN         RETURN 0;

`    `END IF;![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.017.png)

`    `SET v\_score  LEAST((v\_hours\_in\_use / v\_max\_hours\_possible) \* 100, 10

`    `RETURN ROUND(v\_score, 2; END;

update cooking\_equipment set hours\_in\_use = hours\_in\_use  10 where eq update cooking\_equipment set last\_maintenance\_date = purchase\_date w

select \* from cooking\_equipment where equipment\_id  20001; select min(equipment\_id), max(equipment\_id) from cooking\_equipment;

SELECT fn\_equipment\_utilization\_score(20001 AS utilization\_score;

 MariaDB De igual manera, se puede calcular la relacion costo eficiencia 

con el tiempo de uso del equipo

CREATE FUNCTION fn\_equipment\_cost\_efficiency(p\_equipment\_id INT RETURNS DECIMAL10,2

DETERMINISTIC

READS SQL DATA

BEGIN

`    `DECLARE v\_price DECIMAL10,2;

`    `DECLARE v\_hours INT;

`    `SELECT purchase\_price, hours\_in\_use

`      `INTO v\_price, v\_hours

`      `FROM cooking\_equipment

`     `WHERE equipment\_id = p\_equipment\_id;

`    `IF v\_hours  0 THEN         RETURN 0;

`    `END IF;

`    `RETURN ROUND(v\_price / v\_hours, 2; END;

SELECT fn\_equipment\_cost\_efficiency(20001;

**Triggers**

 Postgres) Validar que un mismo usuario no esté con más de 3 reservas 

activas

CREATE OR REPLACE FUNCTION maximum\_active\_reservations() RETURNS TRIGGER AS $$![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.018.png)

DECLARE

`    `actives INT;

BEGIN

`    `SELECT COUNT\* INTO actives

`    `FROM reservations

`    `WHERE user\_id  NEW.user\_id AND state = 'activa';

`    `IF NEW.state = 'activa' AND actives  3 THEN

`        `RAISE EXCEPTION 'El usuario % ya tiene 3 reservas activas.', NEW.us     END IF;

`    `RETURN NEW; END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER max\_active\_reservations

BEFORE INSERT OR UPDATE ON reservations

FOR EACH ROW

EXECUTE FUNCTION maximum\_active\_reservations();

SELECT user\_id

FROM reservations

WHERE state = 'activa'

GROUP BY user\_id

HAVING COUNT\*  3

LIMIT 1; 10792 con 3 activas

INSERT INTO reservations(user\_id, estacion\_id, start\_date, finish\_date, sta

VALUES ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.019.png)

`    `10792,5,current\_date,current\_date  INTERVAL '2 hours','activa', 'hora')

 Postgres) Cada que se actualice una reserva buscará en la tabla para ver 

si no hay reservas que ya acabaron pero aparecen como activas (error de insertado de datos por ejemplo)

CREATE OR REPLACE FUNCTION update\_expired\_reservations() RETURNS TRIGGER AS $$

BEGIN

`    `IF NEW.finish\_date  CURRENT\_TIMESTAMP AND NEW.state = 'activa' T         NEW.state := 'vencida';

`    `END IF;

`    `RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER update\_reservations

BEFORE INSERT OR UPDATE ON reservarions

FOR EACH ROW

EXECUTE FUNCTION update\_expired\_reservations();

UPDATE reservations SET state = 'active' WHERE user\_id= 532;

 MariaDB Cada vez que se marca que un equipo necesita reparación se 

guardara en una tabla de logs

CREATE TABLE equipment\_repair\_log (

`    `repair\_id INT AUTO\_INCREMENT PRIMARY KEY,

`    `equipment\_id INT,

`    `flagged\_on DATETIME

);

CREATE TRIGGER tr\_log\_repair\_flag

AFTER UPDATE ON cooking\_equipment

FOR EACH ROW

BEGIN

`    `IF OLD.needs\_repair  FALSE AND NEW.needs\_repair  TRUE THEN

`        `INSERT INTO equipment\_repair\_log (             equipment\_id,![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.020.png)

`            `flagged\_on

- VALUES 

`            `NEW.equipment\_id,

`            `NOW

`        `);

`    `END IF;

END;

select min(equipment\_id) from cooking\_equipment where needs\_repair = f select \* from equipment\_maintenance\_summary where equipment\_id=200

update cooking\_equipment set needs\_repair = true where equipment\_id=2 select \* from equipment\_repair\_log;

 MariaDB Cuando se realice mantenimiento a un equipo, este ya no 

requiere reparaciones por lo que cada vez que se actualice la fecha de mantenimiento la columna needs\_repair ira a false

CREATE or replace TRIGGER tr\_set\_repair

before UPDATE ON cooking\_equipment

FOR EACH ROW

BEGIN

if old.last\_maintenance\_date ! new.last\_maintenance\_date then

set new.needs\_repair = false;

`    `END IF;

END;

select min(equipment\_id) from cooking\_equipment where needs\_repair=tr

update cooking\_equipment set last\_maintenance\_date='20251212' WHE select min(equipment\_id) from cooking\_equipment where needs\_repair=tr

**Particiones**

- MariaDB Se creo una partición en la tabla de logs de transferencia de equipos entre sucursales segun el año.

CREATE TABLE IF NOT EXISTS log\_equipment\_transfer (![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.021.png)

`    `log\_id INT AUTO\_INCREMENT,

`    `equipment\_id INT NOT NULL,

`    `from\_sucursal INT NOT NULL,

`    `to\_sucursal INT NOT NULL,

`    `transfer\_date DATETIME NOT NULL DEFAULT CURRENT\_TIMESTAMP,     employee\_id int NULL,

`    `notes TEXT NULL,

`    `primary key (log\_id, transfer\_date)

- PARTITION BY RANGE COLUMNS(transfer\_date) (

`    `PARTITION p2018 VALUES LESS THAN '20190101'),

`    `PARTITION p2019 VALUES LESS THAN '20200101'),

`    `PARTITION p2020 VALUES LESS THAN '20210101'),

`    `PARTITION p2021 VALUES LESS THAN '20220101'),

`    `PARTITION p2022 VALUES LESS THAN '20230101'),

`    `PARTITION p2023 VALUES LESS THAN '20240101'),

`    `PARTITION p2024 VALUES LESS THAN '20250101'),

`    `PARTITION p2025 VALUES LESS THAN '20260101'),

`    `PARTITION pFutur e VALUES LESS THAN MAXVALUE

);

ALTER TABLE log\_equipment\_transfer

`    `REORGANIZE PARTITION pFuture INTO 

`        `PARTITION p2026 VALUES LESS THAN '20270101'),         PARTITION pFuture VALUES LESS THAN MAXVALUE     );

select partition\_name, table\_rows from

information\_schema.partitions where table\_name = 'log\_equipment\_transfe SELECT \*

`  `FROM log\_equipment\_transfer

`  `PARTITION (p2025;

- Postgres) Particiones según la ciudad de las sucursales

CREATE TABLE direction\_part (     direccion\_id INT NOT NULL,![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.022.png)

`    `number VARCHAR20,

`    `street\_name VARCHAR100,     cit y VARCHAR50

- PARTITION BY LIST (city);

CREATE TABLE directions\_madrid PARTITION OF direction\_part     FOR VALUES IN 'Madrid');

CREATE TABLE directions\_barcelona PARTITION OF direction\_part     FOR VALUES IN 'Barcelona');

CREATE TABLE directions\_valencia PARTITION OF direction\_part     FOR VALUES IN 'Valencia');

CREATE TABLE directions\_bilbao PARTITION OF direction\_part     FOR VALUES IN 'Bilbao');

**Backups y Restauración**

**MariaDB**

docker exec mariadb-container \![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.023.png)

`  `sh -c 'exec mysqldump -u root -p"admin123" \     --single-transaction --quick --lock-tables=false organization' \

- organization\_backup.sql

docker exec -i organization   sh -c 'exec mysql -u root -p"admin123" organiza![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.024.png)

**Postgres**

docker exec -u postgres cowork   pg\_dump U admin F c   -f /tmp/cowork\_ba![ref2]

docker exec -u postgres cowork pg\_restore U admin -d cowork\_hashed /tmp![ref2]

**Ofuscamiento**

**Ofuscar MariaDB**

 Crear el dump

docker exec mariadb-container \![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.026.png)

`  `sh -c 'exec mysqldump -u root -p"admin123" \     --single-transaction --quick --lock-tables=false organization' \

- organization\_backup.sql

 Crear la nueva base de datos

docker exec organization   sh -c 'exec mysql -u root -p"admin123" -e "CREATE DATABASE IF ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.027.png)NOT EXISTS \`organization\_hashed\` CHARACT

 Impor tar la base de datos

docker exec -i organization   sh -c 'exec mysql -u root -p"admin123" organ ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.028.png) Ofusc amos los valores de las tablas employees y suppliers

select \* from suppliers;![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.029.png)

update suppliers set contact\_name = 'contact\_name', contact\_phone = 'contact\_phone', contact\_email = 'contact\_email';

select \* from employees;

update employees set first\_name = 'first\_name', middle\_name = 'middle\_name', last\_names = 'last\_name', ![ref1]ci = 'ci',

phone = 'phone';

**Ofuscar Postgres**

 Crear el backup de la base de datos cowork

docker exec -u postgres cowork   pg\_dump U admin F c   -f /tmp/cowor ![ref3] Crear una nueva base de datos

docker exec -u postgres cowork createdb U admin cowork\_hashed![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.031.png)

 Impor tar la base de datos

docker exec -u postgres cowork pg\_restore U admin -d cowork\_hashed / ![ref3] Ofusc amos la información sensible

select \* from users;![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.032.png)

update users set 

first\_name = 'first\_name', last\_name = 'last\_name',

email = 'email',

phone\_number = 'phone\_number' ;

**Consultas optimizadas**

**Postgres**

- Como primer paso realizamos consultas que use a nuestras tablas de users, reservas y payments para ver cuánto tiempo nos toma realizar cada consulta

  ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.033.jpeg)

  ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.034.jpeg)

![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.035.jpeg)

- Query original: 
  - Planning Time: 3.547 ms
  - Execution Time: 10.932 ms
- Primero se creara los indices para s.sucursal\_name y d.city

create index idx\_type\_name on business\_type(type\_name); create index idx\_city on directions(city);![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.036.png)

![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.037.jpeg)

- Query con indices en los parametros del where
  - Planning Time: 1.774 ms
  - Execution Time: 13.899 ms
- Se creara indices en los foreign keys

create index idx\_stations\_sucursal\_id on stations(sucursal\_id); create index ![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.038.png)idx\_reservation\_station\_id on reservation(station\_id); create index idx\_reservation\_user\_id on reservation(user\_id); create index idx\_users\_business\_type on users(business\_type); create index idx\_sucursals\_direction\_id on sucursals(direction\_id);

![](Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.039.jpeg)

- Optimizacion con indices en los foreign keys
  - Planning Time: 1.026 ms
  - Execution Time: 8.797 ms
Proyect o 22

[ref1]: Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.007.png
[ref2]: Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.025.png
[ref3]: Aspose.Words.e466e088-34a1-4722-9a55-cf7a690d0110.030.png
