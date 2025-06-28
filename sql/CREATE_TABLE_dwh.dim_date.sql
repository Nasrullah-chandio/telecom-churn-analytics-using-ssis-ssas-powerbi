CREATE TABLE dwh.dim_date (
    date_key        DATE PRIMARY KEY,
    year            INT,
    quarter         INT,
    month           INT,
    month_name      VARCHAR(10),
    day             INT,
    day_of_week     INT,
    day_name        VARCHAR(10),
    is_weekend      BIT
);



WITH distinct_dates AS (
    SELECT DISTINCT CAST(date AS DATE) AS date_key
    FROM staging.stg_network_data
)
INSERT INTO dwh.dim_date (
    date_key, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend
)
SELECT
    date_key,
    YEAR(date_key) AS year,
    DATEPART(QUARTER, date_key) AS quarter,
    MONTH(date_key) AS month,
    DATENAME(MONTH, date_key) AS month_name,
    DAY(date_key) AS day,
    DATEPART(WEEKDAY, date_key) AS day_of_week,
    DATENAME(WEEKDAY, date_key) AS day_name,
    CASE WHEN DATEPART(WEEKDAY, date_key) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM distinct_dates;
