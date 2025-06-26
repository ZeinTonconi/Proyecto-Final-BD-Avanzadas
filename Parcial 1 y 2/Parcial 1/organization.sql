-- Vistas
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

CREATE VIEW equipment_costs_by_type AS
SELECT 
    et.equipment_type,
    COUNT(*) AS total_units,
    AVG(ce.purchase_price) AS avg_price,
    SUM(ce.purchase_price) AS total_spent
FROM cooking_equipment ce
inner JOIN equipment_type et ON ce.equipment_type = et.type_id
GROUP BY et.equipment_type;

-- SP


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

-- Funciones

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

-- Triggers
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

-- Particiones
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