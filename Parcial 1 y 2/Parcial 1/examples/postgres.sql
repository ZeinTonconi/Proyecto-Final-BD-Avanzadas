
-- Postgres

-- Vistas
select * from business_type_and_users;

select * from direccion_estacion;

-- SP

CALL agregar_usuario('Rebeca', 'Navarro', 'Gluglugluten',
     current_date, 'beca@gmail.com', '+591 78810003', 1,32636);

update payments p set amount = 0 where user_id = 456;
select * from payments p where user_id = 456;
CALL registrar_pago(456, 13387, current_date, 500.00, 'tarjeta');

select * from payments p where user_id = 456;
CALL registrar_pago(456, 13387, current_date, 500.00, 'tarjeta');

-- Functions
SELECT historial_de_renta('Comida Peruana Gourmet');

SELECT resumen_general_usuario(216);

-- Triggers
INSERT INTO reservas(reserva_id, user_id, estacion_id, start_date, finish_date, state, reserva_type)
VALUES (20001, 10792,5,current_date,current_date + INTERVAL '2 hours','activa', 'hora');

-- Partitions
select * from directions_madrid;