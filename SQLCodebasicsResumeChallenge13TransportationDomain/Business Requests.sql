-- Business Request-1
SELECT 
    dc.city_name AS city_name,
    COUNT(ft.trip_id) AS total_trips,
    AVG(fare_amount / distance_travelled_km) AS avg_fare_per_km,
    AVG(fare_amount) AS avg_fare_per_trip,
    (COUNT(ft.trip_id) * 100.0) / SUM(COUNT(ft.trip_id)) OVER () AS percent_contribution_to_total_trips
FROM 
    fact_trips AS ft
LEFT JOIN 
    dim_city AS dc ON ft.city_id = dc.city_id
GROUP BY 
    city_name
ORDER BY 
    total_trips DESC;


-- Business Request 2

WITH cte1 AS (
    SELECT 
        ft.city_id AS city_id,
        MONTHNAME(ft.date) AS month_name,
        dc.city_name AS city_name,
        COUNT(ft.trip_id) AS actual_trips
    FROM fact_trips AS ft 
    LEFT JOIN dim_city AS dc
        ON ft.city_id = dc.city_id
    GROUP BY city_id, city_name, MONTHNAME(ft.date)
)

SELECT 
    ct.city_name,
    ct.month_name,
    ct.actual_trips,
    mt.total_target_trips AS target_trips,
    ROUND((((ct.actual_trips - mt.total_target_trips) / mt.total_target_trips) * 100), 2) AS percent_difference,
    CASE 
        WHEN ct.actual_trips > mt.total_target_trips THEN 'Above Target' 
        ELSE 'Below Target' 
    END AS Target_Status
FROM cte1 AS ct 
LEFT JOIN targets_db.monthly_target_trips AS mt
    ON ct.city_id = mt.city_id 
    AND ct.month_name = MONTHNAME(mt.month)
GROUP BY 
    ct.city_name, 
    ct.month_name, 
    ct.actual_trips, 
    mt.total_target_trips
ORDER BY 
    ct.city_name DESC;

-- Business Request 3
WITH cte1 AS (
    SELECT 
        ft.city_id AS city_id, 
        dt.city_name AS city_name,
        COUNT(ft.trip_id) AS total_trip_count
    FROM fact_trips AS ft 
    LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
    GROUP BY city_id
)
SELECT 
    ct.city_name AS city_name,
    SUM(CASE WHEN re.trip_count = '2-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `2_trips`,
    SUM(CASE WHEN re.trip_count = '3-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `3_trips`,
    SUM(CASE WHEN re.trip_count = '4-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `4_trips`,
    SUM(CASE WHEN re.trip_count = '5-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `5_trips`,
    SUM(CASE WHEN re.trip_count = '6-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2)ELSE 0 END) AS `6_trips`,
    SUM(CASE WHEN re.trip_count = '7-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `7_trips`,
    SUM(CASE WHEN re.trip_count = '8-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2) ELSE 0 END) AS `8_trips`,
    SUM(CASE WHEN re.trip_count = '9-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2)ELSE 0 END) AS `9_trips`,
    SUM(CASE WHEN re.trip_count = '10-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100,2)ELSE 0 END) AS `10_trips`
FROM cte1 AS ct
LEFT JOIN dim_repeat_trip_distribution AS re ON ct.city_id = re.city_id
GROUP BY ct.city_name
order by ct.city_name desc;

-- Business Request 4

(SELECT 
        dt.city_name AS city_name,
        COUNT(ft.passenger_type) AS total_new_passengers,
        'Top 3' as City_Category
    FROM fact_trips AS ft 
    LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
    where passenger_type="new" and city_name in('Chandigarh','Kochi','Jaipur')
    GROUP BY city_name
    order by total_new_passengers asc)
UNION
(SELECT 
        dt.city_name AS city_name,
        COUNT(ft.passenger_type) AS total_new_passengers,
        'Bottom 3' as City_Category
    FROM fact_trips AS ft 
    LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
    where passenger_type="new" and city_name in('Surat','Vadodara','Coimbatore')
    GROUP BY city_name
    order by total_new_passengers desc);

-- Business Request 5
WITH cte1 AS (
    SELECT dt.city_name, monthname(ft.date) AS month,
	SUM(ft.fare_amount) AS total_revenue
    FROM fact_trips AS ft
    LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
    GROUP BY dt.city_name, month
),
cte2 as(SELECT 
    city_name,month,total_revenue,
    row_number()over(partition by city_name order by total_revenue desc) as serial
FROM cte1
),
cte3 as(select city_name,sum(total_revenue) as city_total_revenues
from cte1
group by city_name)

select c2.city_name as CITY_NAME, c2.month AS MONTH, c2.total_revenue AS TOTAL_REVENUE,
Round(((c2.total_revenue / c3.city_total_revenues)) * 100,2) AS PERCENTAGE_CONTRIBUTION
from cte2 as c2 join cte3 as c3
on c2.city_name =c3.city_name
where serial=1
order by TOTAL_REVENUE desc;


-- Business Request 6

with cte1 as
(select dc.city_name,monthname(fp.month), total_passengers, repeat_passengers,
((fp.repeat_passengers/fp.total_passengers)*100) as monthly_repeat_passenger_rate
from fact_passenger_summary as fp join dim_city as dc
on fp.city_id=dc.city_id)
select * from cte1;


-- Business Request 6
WITH cte1 AS (
    SELECT 
        dc.city_name,
        MONTHNAME(fp.month) AS month_name,
        fp.total_passengers,
        fp.repeat_passengers,
        round(((fp.repeat_passengers / fp.total_passengers) * 100),2) AS monthly_repeat_passenger_rate
    FROM fact_passenger_summary AS fp
    JOIN dim_city AS dc
        ON fp.city_id = dc.city_id
        order by dc.city_name
),
cte2 AS (
    SELECT 
        city_name,
        SUM(total_passengers) AS total_passengers_all_months,
        SUM(repeat_passengers) AS repeat_passengers_all_months
    FROM cte1
    GROUP BY city_name
)
SELECT 
    cte1.city_name,
    cte1.month_name,
    cte1.total_passengers,
    cte1.repeat_passengers,
    cte1.monthly_repeat_passenger_rate,
    round(((cte2.repeat_passengers_all_months / cte2.total_passengers_all_months) * 100),2) AS overall_repeat_passenger_rate
FROM cte1
JOIN cte2
    ON cte1.city_name = cte2.city_name
    ORDER BY cte1.city_name, cte1.month_name;












