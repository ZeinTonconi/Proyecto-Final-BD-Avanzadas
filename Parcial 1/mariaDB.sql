
-- MariaDB

-- Vistas

select * from equipment_maintenance_summary ems;

select * from equipment_costs_by_type ecbt;

-- SP

CALL sp_transfer_equipment(20002, 6, 27, 'Mantenimiento en Suc. 5');
select * from log_equipment_transfer;

CALL sp_transfer_equipment(20002, 2, 27, 'Mantenimiento en Suc. 5');
select * from log_equipment_transfer;

select ce.equipment_id, ce.needs_repair, max(ce.hours_in_use) from cooking_equipment ce;
call sp_mark_high_usage_equipment_for_maintenance(20);
select ce.equipment_id, ce.needs_repair, max(ce.hours_in_use) from cooking_equipment ce;

-- Functions
update cooking_equipment set last_maintenance_date = purchase_date where equipment_id = 20001;
SELECT fn_equipment_utilization_score(20001);

SELECT fn_equipment_cost_efficiency(20001);

-- Triggers
select min(equipment_id) from cooking_equipment where needs_repair = false;
begin;
update cooking_equipment ce set needs_repair = true where equipment_id = 20001;
select * from equipment_repair_log erl;
rollback;

begin;
update cooking_equipment set last_maintenance_date='2025-12-12' WHERE equipment_id = 20001;
select * from cooking_equipment where equipment_id = 20001;
select min(equipment_id) from cooking_equipment where needs_repair=true;
ROLLBACK;

-- Partitions
SELECT *
  FROM log_equipment_transfer
  PARTITION (p2025);
