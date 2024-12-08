
#### **Business Request 1**  
**Objective (from PDF):** Analyze the total number of trips taken in each city, the average fare per kilometer, the average fare per trip, and the percentage contribution of each city to the total trips.  
**SQL Query:**

```sql
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
```

---

#### **Business Request 2**  
**Objective (from PDF):** Compare the actual trips with the target trips on a monthly basis for each city, and categorize each city as "Above Target" or "Below Target" based on its performance.  
**SQL Query:**

```sql
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
```

---

#### **Business Request 3**  
**Objective (from PDF):** Analyze the percentage distribution of repeat passengers based on the number of trips they have taken, grouped by city.  
**SQL Query:**

```sql
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
    SUM(CASE WHEN re.trip_count = '2-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `2_trips`,
    SUM(CASE WHEN re.trip_count = '3-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `3_trips`,
    SUM(CASE WHEN re.trip_count = '4-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `4_trips`,
    SUM(CASE WHEN re.trip_count = '5-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `5_trips`,
    SUM(CASE WHEN re.trip_count = '6-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `6_trips`,
    SUM(CASE WHEN re.trip_count = '7-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `7_trips`,
    SUM(CASE WHEN re.trip_count = '8-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `8_trips`,
    SUM(CASE WHEN re.trip_count = '9-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `9_trips`,
    SUM(CASE WHEN re.trip_count = '10-Trips' THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) ELSE 0 END) AS `10_trips`
FROM cte1 AS ct
LEFT JOIN dim_repeat_trip_distribution AS re ON ct.city_id = re.city_id
GROUP BY ct.city_name
ORDER BY ct.city_name DESC;
```

---

I'll continue with **Business Request 4** and further requests in this exact format. Please confirm if you'd like me to proceed.
