-- Vistas
CREATE VIEW business_type_and_users as
select u.business_name, bt.type_name, u.first_name, u.last_name, u.email
from users u
inner join business_type bt
on u.business_type = bt.type_id;

CREATE VIEW station address as
select e.estacion_name, d.city, s.sucursal_name, d.street_name, e.description
from estaciones e
inner join sucursales s
on e.sucursal_id = s.sucursal_id
inner join directions d
on s.id_direction = d.directions_id;

-- SP
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

-- Funciones
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
-- Triggers
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

-- Particiones
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


-- Indices
explain analyze
    SELECT
        u.business_name,
        bt.type_name,
        s.sucursal_name,
        d.city,
        count(r.reserva_id)::INTEGER
    FROM sucursales s
    INNER JOIN estaciones e ON s.sucursal_id = e.sucursal_id
    INNER JOIN reservas r ON e.estacion_id = r.estacion_id
    INNER JOIN users u ON r.user_id = u.user_id
    INNER JOIN business_type bt ON u.business_type = bt.type_id
    inner join directions d on s.id_direction = d.directions_id
    where bt.type_name like 'Postres' and city like 'Madrid'
    GROUP BY s.sucursal_name, u.business_name, bt.type_name, d.city;

create index idx_type_name on business_type(type_name);
create index idx_city on directions(city);
create index idx_estaciones_sucursal_id on estaciones(sucursal_id);
create index idx_reservas_estacion_id on reservas(estacion_id);
create index idx_reservas_user_id on reservas(user_id);
create index idx_users_business_type on users(business_type);
create index idx_sucursales_id_direction on sucursales(id_direction);
