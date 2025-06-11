IF OBJECT_ID('dwh.dim_complaint', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.dim_complaint (
        complaint_id   VARCHAR(50) PRIMARY KEY,
        customerID     VARCHAR(50),
        complaint_date DATE,
        issue          VARCHAR(255),
        status         VARCHAR(50),
        status_stage   VARCHAR(50)
    );
END;

WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY complaint_id ORDER BY (SELECT NULL)) AS rn
    FROM staging.stg_complaint_data
)
MERGE dwh.dim_complaint AS target
USING (
    SELECT * FROM ranked WHERE rn = 1
) AS source
ON target.complaint_id = source.complaint_id

WHEN NOT MATCHED THEN
    INSERT (
        complaint_id, customerID, complaint_date, issue, status, status_stage
    )
    VALUES (
        source.complaint_id, source.customerID, source.date, source.issue, source.status, source.status_stage
    );
