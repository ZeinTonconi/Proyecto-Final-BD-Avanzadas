-- Particiones
create table direction_part
(
    direction_id integer not null,
    number       varchar(20),
    street_name  varchar(100),
    city         varchar(50)
)
    partition by LIST (city);

alter table direction_part
    owner to admin;

create table directions_cbb
    partition of direction_part
    FOR VALUES IN ('Cochabamba');

alter table directions_cbb
    owner to admin;

create table directions_lpz
    partition of direction_part
    FOR VALUES IN ('La Paz');

alter table directions_lpz
    owner to admin;

create table directions_scz
    partition of direction_part
    FOR VALUES IN ('Santa Cruz');

alter table directions_scz
    owner to admin;

create table directions_sucre
    partition of direction_part
    FOR VALUES IN ('Sucre');

alter table directions_sucre
    owner to admin;

-- Vistas
-- business_type_and_users
create view business_type_and_users(business_name, type_name, first_name, last_name, email) as
SELECT u.business_name,
       bt.type_name,
       u.first_name,
       u.last_name,
       u.email
FROM users u
         JOIN business_type bt ON u.business_type = bt.type_id;

alter table business_type_and_users
    owner to admin;

-- station_direction

create view station_direction(station_name, city, branch_name, street_name, description) as
SELECT st.station_name,
       d.city,
       b.branch_name,
       d.street_name,
       st.description
FROM stations st
         JOIN branches b ON st.branches_id = b.branch_id
         JOIN directions d ON b.id_direction = d.directions_id;

alter table station_direction
    owner to admin;

-- SP
-- add_user
create procedure add_user(IN p_first_name character varying, IN p_last_name character varying, IN p_business_name character varying, IN p_creation_date date, IN p_email character varying, IN p_phone character varying, IN p_business_type integer, IN p_user_id integer)
    language plpgsql
as
$$
BEGIN
INSERT INTO users(first_name, last_name, business_name, creation_date, email, phone_number, business_type, user_id)
VALUES (p_first_name, p_last_name, p_business_name,
        p_creation_date, p_email, p_phone, p_business_type, p_user_id);
END;
$$;

alter procedure add_user(varchar, varchar, varchar, date, varchar, varchar, integer, integer) owner to admin;

-- payment_register
create procedure payment_register(IN userid integer, IN reservationid integer, IN pr_payment_date timestamp without time zone, IN pr_amount numeric, IN pr_payment_method character varying)
    language plpgsql
as
$$
DECLARE
paid INT;
BEGIN
SELECT amount INTO paid
FROM payments
WHERE reservation_id = reservationId
    LIMIT 1;

IF paid > 0 THEN
        RAISE EXCEPTION 'La reserva % ya tiene un pago registrado de %', reservationId, paid;
    ELSIF pr_amount < 0 THEN
        RAISE EXCEPTION 'El monto no puede ser negativo';
ELSE
UPDATE payments
SET amount = pr_amount,
    payment_date = pr_payment_date,
    payment_method = pr_payment_method
WHERE reservation_id = reservationId AND user_id = userId;

END IF;
END;
$$;

alter procedure payment_register(integer, integer, timestamp, numeric, varchar) owner to admin;

-- Functions
-- rental_history
create function rental_history(business character varying)
    returns TABLE(business_name character varying, business_type character varying, branch character varying, reservationsstations integer)
    language plpgsql
as
$$
BEGIN
RETURN QUERY
SELECT
    u.business_name,
    bt.type_name,
    b.branch_name,
    count(r.reservation_id)::INTEGER
FROM branches b
         INNER JOIN stations s ON b.branch_id = s.branches_id
         INNER JOIN reservations r ON s.station_id = r.station_id
         INNER JOIN users u ON r.user_id = u.user_id
         INNER JOIN business_type bt ON u.business_type = bt.type_id
WHERE u.business_name = business
GROUP BY b.branch_name, u.business_name, bt.type_name;
END;
$$;

alter function rental_history(varchar) owner to admin;

-- user_general_summary
create function user_general_summary(userid integer)
    returns TABLE(user_name character varying, user_last_name character varying, number_reservations integer, number_reservations_salons integer, amount_paid numeric)
    language plpgsql
as
$$
BEGIN
RETURN QUERY
SELECT u.first_name, u.last_name,
       (SELECT COUNT(*)::INT
        FROM reservations r
        WHERE r.user_id = userId),
       (SELECT COUNT(*)::INT
        FROM reserve_workshops s
        WHERE s.user_id = userId),
       (SELECT SUM(p.amount)::NUMERIC
        FROM payments p
        WHERE p.user_id = userId)
FROM users u
WHERE u.user_id = userId
group by u.first_name, u.last_name;
END;
$$;

alter function user_general_summary(integer) owner to admin;

-- triggers
-- maximum_active_reservations

CREATE OR REPLACE FUNCTION public.maximum_active_reservations()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
actives INT;
BEGIN
SELECT COUNT(*) INTO actives
FROM reservations
WHERE user_id = NEW.user_id AND state = 'activa';

IF NEW.state != OLD.state AND NEW.state = 'activa' AND actives >= 3 THEN
        RAISE EXCEPTION 'El usuario % ya tiene 3 reservas activas.', NEW.user_id;
END IF;

RETURN NEW;
END;
$function$
;

CREATE TRIGGER max_active_reservations
    BEFORE INSERT OR UPDATE ON reservations
                         FOR EACH ROW
                         EXECUTE FUNCTION maximum_active_reservations();

-- update_expired_reservations

CREATE OR REPLACE FUNCTION public.update_expired_reservations()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (NEW.finish_date < CURRENT_TIMESTAMP AND NEW.state = 'active') OR NEW.state = 'activa' THEN
        NEW.state := 'vencida';
END IF;
RETURN NEW;
END;
$function$
;
CREATE TRIGGER update_reservations
    BEFORE INSERT OR UPDATE ON reservations
                         FOR EACH ROW
                         EXECUTE FUNCTION update_expired_reservations();