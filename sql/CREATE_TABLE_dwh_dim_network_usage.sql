IF OBJECT_ID('dwh.dim_network_usage') IS NULL
BEGIN
    CREATE TABLE dwh.dim_network_usage (
        date DATE,
        customer_id VARCHAR(50),
        total_calls INT,
        dropped_calls INT,
        data_volume_MB FLOAT,
        throughput_Mbps FLOAT,
        has_drop BIT,
        CONSTRAINT PK_dim_network_usage PRIMARY KEY (date, customer_id)
    );
END

MERGE dwh.dim_network_usage AS target
USING (
    SELECT *
    FROM (
        SELECT 
            date,
            customerID,
            CAST(CAST(total_calls AS FLOAT) AS INT) AS total_calls,
            CAST(CAST(dropped_calls AS FLOAT) AS INT) AS dropped_calls,
            CAST(data_volume_MB AS FLOAT) AS data_volume_MB,
            CAST(throughput_Mbps AS FLOAT) AS throughput_Mbps,
            CAST(has_drop AS BIT) AS has_drop,
            ROW_NUMBER() OVER (PARTITION BY date, customerID ORDER BY date DESC) AS rn
        FROM staging.stg_network_data
    ) t
    WHERE rn = 1
) AS source
ON target.date = source.date AND target.customer_id = source.customerID
WHEN MATCHED THEN
    UPDATE SET 
        total_calls = source.total_calls,
        dropped_calls = source.dropped_calls,
        data_volume_MB = source.data_volume_MB,
        throughput_Mbps = source.throughput_Mbps,
        has_drop = source.has_drop
WHEN NOT MATCHED THEN
    INSERT (date, customer_id, total_calls, dropped_calls, data_volume_MB, throughput_Mbps, has_drop)
    VALUES (
        source.date,
        source.customerID,
        source.total_calls,
        source.dropped_calls,
        source.data_volume_MB,
        source.throughput_Mbps,
        source.has_drop
    );
