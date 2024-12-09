### **Transportation Domain Project Documentation**

#### **Introduction**
This project involves creating SQL-based solutions to address six critical business requests from the transportation domain. Each request focuses on deriving actionable insights from city-level transportation data, including trip performance, revenue analysis, passenger trends, and repeat passenger behavior. The detailed SQL queries provided below align with the objectives of the business requests.

---

### **Business Requests and Solutions**

#### **Business Request 1: City-Level Fare and Trip Summary Report**

**Objective:**  
Provide a city-level summary of trips, average fare metrics, and each city's contribution to total trips.

**Key Metrics:**  
- `city_name`: Name of the city.  
- `total_trips`: Total trips in each city.  
- `avg_fare_per_km`: Average fare per kilometer.  
- `avg_fare_per_trip`: Average fare per trip.  
- `percent_contribution_to_total_trips`: City's contribution to total trips (%).  

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

#### **Business Request 2: Monthly City-Level Trips Target Performance Report**

**Objective:**  
Analyze monthly city-level trip performance by comparing actual trips against targets and categorizing performance status.

**Key Metrics:**  
- `city_name`: City name.  
- `month_name`: Month of analysis.  
- `actual_trips`: Actual trips for the month.  
- `target_trips`: Target trips for the month.  
- `percent_difference`: Percent difference between actual and target trips.  
- `target_status`: "Above Target" or "Below Target."  

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

#### **Business Request 3: Repeat Passenger Trip Frequency Report**

**Objective:**  
Calculate the percentage distribution of repeat passenger trips in each city, grouped by trip count categories (e.g., 2 trips, 3 trips, etc.).

**Key Metrics:**  
- `city_name`: City name.  
- Trip frequency categories (`2-Trips`, `3-Trips`, ..., `10-Trips`): Percentage distribution of passengers.  

**SQL Query:**  
```sql
-- Step 1: Calculate total trips for each city
WITH cte1 AS (
    SELECT 
        ft.city_id AS city_id, 
        dt.city_name AS city_name,
        COUNT(ft.trip_id) AS total_trip_count
    FROM 
        fact_trips AS ft 
    LEFT JOIN 
        dim_city AS dt ON ft.city_id = dt.city_id
    GROUP BY 
        ft.city_id, dt.city_name
)

-- Step 2: Calculate the percentage distribution of repeat trips for each city
SELECT 
    ct.city_name AS city_name,
    SUM(CASE 
            WHEN re.trip_count = '2-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `2_trips`,
    SUM(CASE 
            WHEN re.trip_count = '3-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `3_trips`,
    SUM(CASE 
            WHEN re.trip_count = '4-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `4_trips`,
    SUM(CASE 
            WHEN re.trip_count = '5-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `5_trips`,
    SUM(CASE 
            WHEN re.trip_count = '6-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `6_trips`,
    SUM(CASE 
            WHEN re.trip_count = '7-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `7_trips`,
    SUM(CASE 
            WHEN re.trip_count = '8-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `8_trips`,
    SUM(CASE 
            WHEN re.trip_count = '9-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `9_trips`,
    SUM(CASE 
            WHEN re.trip_count = '10-Trips' 
            THEN ROUND((re.repeat_passenger_count / ct.total_trip_count) * 100, 2) 
            ELSE 0 
        END) AS `10_trips`
FROM 
    cte1 AS ct
LEFT JOIN 
    dim_repeat_trip_distribution AS re ON ct.city_id = re.city_id
GROUP BY 
    ct.city_name
ORDER BY 
    ct.city_name DESC;

```

---

#### **Business Request 4: Top and Bottom Cities for New Passengers**

**Objective:**  
Identify cities with the highest (Top 3) and lowest (Bottom 3) numbers of new passengers.

**Key Metrics:**  
- `city_name`: City name.  
- `total_new_passengers`: Total new passengers.  
- `city_category`: "Top 3" or "Bottom 3."  

**SQL Query:**  
```sql
(SELECT 
    dt.city_name AS city_name,
    SUM(ft.new_passengers) AS total_new_passengers,
    'Top 3' AS City_Category
FROM fact_passenger_summary AS ft 
LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
WHERE city_name IN ('Chandigarh', 'Kochi', 'Jaipur')
GROUP BY city_name
ORDER BY total_new_passengers ASC)
UNION
(SELECT 
    dt.city_name AS city_name,
    SUM(ft.new_passengers) AS total_new_passengers,
    'Bottom 3' AS City_Category
FROM fact_passenger_summary AS ft 
LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
WHERE city_name IN ('Surat', 'Vadodara', 'Coimbatore')
GROUP BY city_name
ORDER BY total_new_passengers DESC);
```

---

#### **Business Request 5: Month with Highest Revenue per City**

**Objective:**  
Identify the month with the highest revenue for each city and its percentage contribution to the city's total revenue.

**Key Metrics:**  
- `city_name`: City name.  
- `month`: Month with the highest revenue.  
- `total_revenue`: Revenue for the month.  
- `percent_contribution`: Contribution of the month's revenue to the city's total revenue (%).  

**SQL Query:**  
```sql
WITH cte1 AS (
    SELECT dt.city_name, MONTHNAME(ft.date) AS month,
        SUM(ft.fare_amount) AS total_revenue
    FROM fact_trips AS ft
    LEFT JOIN dim_city AS dt ON ft.city_id = dt.city_id
    GROUP BY dt.city_name, month
),
cte2 AS (
    SELECT 
        city_name, month, total_revenue,
        ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY total_revenue DESC) AS serial
    FROM cte1
),
cte3 AS (
    SELECT city_name, SUM(total_revenue) AS city_total_revenues
    FROM cte1
    GROUP BY city_name
)
SELECT 
    c2.city_name AS city_name, 
    c2.month AS month, 
    c2.total_revenue AS total_revenue,
    ROUND(((c2.total_revenue / c3.city_total_revenues)) * 100, 2) AS percentage_contribution
FROM cte2 AS c2 
JOIN cte3 AS c3 ON c2.city_name = c3.city_name
WHERE serial = 1
ORDER BY total_revenue DESC;
```

---

#### **Business Request 6: Repeat Passenger Rate Analysis**

**Objective:**  
Calculate monthly and overall repeat passenger rates for each city.

**Key Metrics:**  
- `city_name`: City name.  
- `month_name`: Month of analysis.  
- `total_passengers`: Total passengers for the month.  
- `repeat_passengers`: Repeat passengers for the month.  
- `monthly_repeat_passenger_rate`: Monthly repeat passenger rate (%).  
- `overall_repeat_passenger_rate`: Overall repeat passenger rate for the city (%).  

**SQL Query:**  
```sql
WITH cte1 AS (
    SELECT 
        dc.city_name,
        MONTHNAME(fp.month) AS month_name,
        fp.total_passengers,
        fp.repeat_passengers,
        ROUND(((fp.repeat_passengers / fp.total_passengers) * 100), 2) AS monthly_repeat_passenger_rate
    FROM fact_passenger_summary AS fp
    JOIN dim_city AS dc ON fp.city_id = dc.city_id
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
    ROUND(((cte2.repeat_passengers_all_months / cte2.total_passengers_all_months) * 100), 2) AS overall_repeat_passenger_rate
FROM cte1
JOIN cte2 ON cte1.city_name = cte2.city_name
ORDER BY cte1.city_name, cte1.month_name;
```

---

### **Conclusion**
These SQL queries address the six business requests effectively, extracting key insights to improve decision-making in transportation operations. Let me know if further refinements or additional details are needed!
