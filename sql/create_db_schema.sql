Create DATABASE TelecomChurn;
GO
USE TelecomChurn;

CREATE SCHEMA landing;
GO
CREATE SCHEMA staging;
GO
CREATE SCHEMA dwh;
GO
CREATE SCHEMA datamart;


=============================================================================

DROP TABLE IF EXISTS dwh.dim_customer;

CREATE TABLE dwh.dim_customer (
    customerID        VARCHAR(50) PRIMARY KEY,
    gender            VARCHAR(10),
    SeniorCitizen     BIT,
    Partner           VARCHAR(3),
    Dependents        VARCHAR(3),
    tenure            INT,
    PhoneService      VARCHAR(30),
    MultipleLines     VARCHAR(30),
    InternetService   VARCHAR(30),
    OnlineSecurity    VARCHAR(30),
    OnlineBackup      VARCHAR(30),
    DeviceProtection  VARCHAR(30),
    TechSupport       VARCHAR(30),
    StreamingTV       VARCHAR(30),
    StreamingMovies   VARCHAR(30),
    Contract          VARCHAR(30),
    PaperlessBilling  VARCHAR(3),
    PaymentMethod     VARCHAR(50),
    MonthlyCharges    FLOAT,
    TotalCharges      FLOAT,
    is_churned        BIT
);


WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customerID ORDER BY (SELECT NULL)) AS rn
    FROM staging.bss_data
)

MERGE dwh.dim_customer AS target
USING (
    SELECT *
    FROM ranked
    WHERE rn = 1
) AS source
ON target.customerID = source.customerID

WHEN NOT MATCHED THEN
    INSERT (
        customerID, gender, SeniorCitizen, Partner, Dependents,
        tenure, PhoneService, MultipleLines, InternetService,
        OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport,
        StreamingTV, StreamingMovies, Contract, PaperlessBilling,
        PaymentMethod, MonthlyCharges, TotalCharges, is_churned
    )
    VALUES (
        source.customerID, source.gender, source.SeniorCitizen, source.Partner, source.Dependents,
        source.tenure, source.PhoneService, source.MultipleLines, source.InternetService,
        source.OnlineSecurity, source.OnlineBackup, source.DeviceProtection, source.TechSupport,
        source.StreamingTV, source.StreamingMovies, source.Contract, source.PaperlessBilling,
        source.PaymentMethod, source.MonthlyCharges, source.TotalCharges, source.is_churned
    );


===================================================================================================================================

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
===================================================================================================================================

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
