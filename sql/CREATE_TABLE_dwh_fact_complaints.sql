CREATE TABLE dwh.fact_complaints (
    complaint_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    complaint_date DATE NOT NULL,
    complaint_type VARCHAR(100),
    status VARCHAR(50),
    status_stage VARCHAR(50)
);

INSERT INTO dwh.fact_complaints (
    complaint_id,
    customer_id,
    complaint_date,
    complaint_type,
    status,
    status_stage
)
SELECT 
    complaint_id,
    TRIM(customerID),
    CAST([date] AS DATE),
    issue,
    status,
    status_stage
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY complaint_id ORDER BY [date] DESC) AS rn
    FROM staging.stg_complaint_data
) AS ranked
WHERE rn = 1;
