-- Vistas
select * from business_type_and_users;

select * from station_direction;

-- SP

CALL add_user('Rebeca', 'Navarro', 'Gluglugluten',
                     current_date, 'beca@gmail.com', '+591 78810003', 1,32636);

update payments p set amount = 0 where user_id = 456;
select * from payments p where user_id = 456;
CALL payment_register(456, 13387, current_date, 500.00, 'tarjeta');

select * from payments p where user_id = 456;
CALL payment_register(456, 13387, current_date, 500.00, 'tarjeta');

-- Functions
SELECT rental_history('Comida Peruana Gourmet');

SELECT user_general_summary(216);

-- Triggers
INSERT INTO reservations(reservation_id, user_id, station_id, start_date, finish_date, state, reservation_type)
VALUES (20001, 10792,5,current_date,current_date + INTERVAL '2 hours','activa', 'hora');

UPDATE reservations SET state = 'active' where user_id=532;

-- Partitions
select * from directions_lpz;