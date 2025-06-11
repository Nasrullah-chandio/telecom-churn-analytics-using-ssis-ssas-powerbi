CREATE TABLE dwh.fact_network_usage (
    usage_id INT IDENTITY(1,1) PRIMARY KEY,           -- Surrogate key
    customer_id VARCHAR(50),                          -- FK to dim_customer
    usage_date DATE,                                  -- Granularity
    total_calls INT,
    dropped_calls INT,
    call_drop_rate DECIMAL(5,2),                      -- Derived
    has_drop BIT,                                     -- Derived flag
    FOREIGN KEY (customer_id) REFERENCES dwh.dim_customer(customerID)
);


MERGE dwh.fact_network_usage AS target
USING (
    SELECT 
        customerID AS customer_id,
        [date] AS usage_date,
        CAST(CAST(dropped_calls AS FLOAT) AS INT) AS dropped_calls,
        CAST(CAST(total_calls AS FLOAT) AS INT) AS total_calls,
        CAST(
            CAST(dropped_calls AS FLOAT) * 100.0 / 
            NULLIF(CAST(total_calls AS FLOAT), 0)
            AS DECIMAL(5,2)
        ) AS call_drop_rate,
        CASE 
            WHEN CAST(dropped_calls AS FLOAT) > 0 THEN 1 
            ELSE 0 
        END AS has_drop
    FROM staging.stg_network_data
) AS source
ON target.customer_id = source.customer_id 
   AND target.usage_date = source.usage_date

-- Update existing
WHEN MATCHED THEN
UPDATE SET 
    target.total_calls = source.total_calls,
    target.dropped_calls = source.dropped_calls,
    target.call_drop_rate = source.call_drop_rate,
    target.has_drop = source.has_drop

-- Insert new
WHEN NOT MATCHED THEN
INSERT (
    customer_id,
    usage_date,
    total_calls,
    dropped_calls,
    call_drop_rate,
    has_drop
)
VALUES (
    source.customer_id,
    source.usage_date,
    source.total_calls,
    source.dropped_calls,
    source.call_drop_rate,
    source.has_drop
);
