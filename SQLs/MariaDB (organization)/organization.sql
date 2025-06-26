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


-- Vistas
-- equipment_cost_by_type
create definer = admin@`%` view equipment_costs_by_type as
select `et`.`equipment_type`      AS `equipment_type`,
       count(0)                   AS `total_units`,
       avg(`ce`.`purchase_price`) AS `avg_price`,
       sum(`ce`.`purchase_price`) AS `total_spent`
from (`organization`.`cooking_equipment` `ce` join `organization`.`equipment_type` `et`
      on (`ce`.`equipment_type` = `et`.`type_id`))
group by `et`.`equipment_type`;
-- equipment_maintenance_summary
create definer = admin@`%` view equipment_maintenance_summary as
select `ce`.`equipment_id`   AS `equipment_id`,
       `et`.`equipment_type` AS `equipment_type`,
       `ce`.`purchase_date`  AS `purchase_date`,
       `ce`.`purchase_price` AS `purchase_price`,
       `ce`.`in_use`         AS `in_use`,
       `ce`.`sucursal_id`    AS `sucursal_id`,
       `s`.`supplier_name`   AS `supplier_name`,
       `s`.`contact_name`    AS `contact_name`,
       `s`.`contact_phone`   AS `contact_phone`,
       `s`.`contact_email`   AS `contact_email`
from ((`organization`.`cooking_equipment` `ce` join `organization`.`suppliers` `s`
       on (`ce`.`supplier_id` = `s`.`supplier_id`)) join `organization`.`equipment_type` `et`
      on (`ce`.`equipment_type` = `et`.`type_id`))
where `ce`.`needs_repair` = 1;

-- Funciones
-- fn_equipment_cost_efficiency
create
definer = admin@`%` function fn_equipment_cost_efficiency(p_equipment_id int) returns decimal(10, 2)
    deterministic
    reads sql data
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
-- fn_equipment_utilization_score
create
definer = admin@`%` function fn_equipment_utilization_score(p_equipment_id int) returns decimal(5, 2)
    deterministic
    reads sql data
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

-- SP
-- createsp_mark_high_usage_equipment_for_maintenance
create
definer = admin@`%` procedure sp_mark_high_usage_equipment_for_maintenance(IN p_min_hours int)
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
END;
-- sp_transfer_equipment
create
definer = admin@`%` procedure sp_transfer_equipment(IN p_equipment_id int, IN p_new_sucursal_id int,
                                                        IN p_employee_id int, IN p_notes text)
BEGIN
    DECLARE v_old_sucursal     INT;
    DECLARE v_exists_equipment INT;


SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

SELECT COUNT(*), sucursal_id
INTO v_exists_equipment, v_old_sucursal
FROM cooking_equipment
WHERE equipment_id = p_equipment_id;

IF v_exists_equipment = 0 THEN
        Rollback;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: The equipment does not exist.';
END IF;

    IF v_old_sucursal = p_new_sucursal_id THEN
        rollback ;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Destination branch is the same as the current one.';
END IF;


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

-- Triggers
-- tr_log_repair_flag
CREATE DEFINER=`admin`@`%` TRIGGER tr_log_repair_flag
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
END

-- tr_set_repair
CREATE DEFINER=`admin`@`%` TRIGGER tr_set_repair
    before UPDATE ON cooking_equipment
                      FOR EACH ROW
BEGIN
    if old.last_maintenance_date != new.last_maintenance_date then
        set new.needs_repair = false;
END IF;
END


