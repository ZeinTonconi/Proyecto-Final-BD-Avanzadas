SELECT
    b.branch_name,
    bt.type_name      AS business_type,
    t.hour_of_day     AS hour_of_day,
    COUNT(*)          AS reservation_count,
    SUM(rf.duration_hours) AS total_reserved_hours
FROM reservation_fact rf
         JOIN dim_branch b     USING (branch_id)
         JOIN dim_user u       USING (user_id)
         JOIN dim_business_type bt USING (business_type_id)
         JOIN dim_time t       USING (time_id)
GROUP BY b.branch_name, bt.type_name, hour_of_day
ORDER BY b.branch_name,
         bt.type_name,
         total_reserved_hours DESC;


SELECT
    bt.type_name     AS business_type,
    SUM(rf.duration_hours) AS total_hours_reserved
FROM reservation_fact rf
         JOIN dim_user u       USING (user_id)
         JOIN dim_business_type bt USING (business_type_id)
GROUP BY bt.type_name
ORDER BY total_hours_reserved DESC;


SELECT
    bt.type_name     AS user_segment,
    p.method         AS payment_method,
    SUM(rf.payment_amount) AS total_revenue
FROM reservation_fact rf
         JOIN dim_user u       USING (user_id)
         JOIN dim_business_type bt USING (business_type_id)
         JOIN dim_payment p     USING (payment_id)
GROUP BY bt.type_name, p.method
ORDER BY total_revenue DESC;

SELECT
    p.method         AS payment_method,
    SUM(rf.payment_amount) AS total_revenue
FROM reservation_fact rf
         JOIN dim_user u       USING (user_id)
         JOIN dim_payment p     USING (payment_id)
GROUP BY p.method
ORDER BY total_revenue DESC;


SELECT
    bt.type_name     AS business_type,
    t.hour_of_day     AS hour_of_day,
    COUNT(*)          AS reservation_count
FROM reservation_fact rf
         JOIN dim_user u       USING (user_id)
         JOIN dim_business_type bt USING (business_type_id)
         JOIN dim_time t       USING (time_id)
GROUP BY bt.type_name, hour_of_day
ORDER BY reservation_count DESC;

SELECT
    bt.type_name       AS business_type,
    hr.hour_of_day,
    hr.reservation_count
FROM (
         SELECT
             u.business_type_id,
             t.hour_of_day     AS hour_of_day,
             COUNT(*)               AS reservation_count,
             ROW_NUMBER() OVER (
                 PARTITION BY u.business_type_id
                 ORDER BY COUNT(*) DESC
                 ) AS rn
         FROM reservation_fact rf
                  JOIN dim_user u
                       ON rf.user_id = u.user_id
                  JOIN dim_time t
                       ON rf.time_id = t.time_id
         GROUP BY u.business_type_id, hour_of_day
     ) hr
         JOIN dim_business_type bt
              ON hr.business_type_id = bt.business_type_id
WHERE hr.rn = 1
ORDER BY hr.reservation_count DESC;
