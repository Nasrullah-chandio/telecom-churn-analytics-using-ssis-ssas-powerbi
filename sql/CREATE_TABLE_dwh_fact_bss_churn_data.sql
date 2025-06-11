IF OBJECT_ID('dwh.fact_bss_churn_data') IS NULL
BEGIN
    CREATE TABLE dwh.fact_bss_churn_data (
        customerID VARCHAR(50),
        SeniorCitizen INT,
        Partner VARCHAR(10),
        Dependents VARCHAR(10),
        tenure INT,
        MonthlyCharges DECIMAL(10,2),
        TotalCharges DECIMAL(10,2),
        churn_status VARCHAR(10),
        dim_customer_id VARCHAR(50),
        FOREIGN KEY (dim_customer_id) REFERENCES dwh.dim_customer(customerID)
    );
END



MERGE dwh.fact_bss_churn_data AS target
USING (
    SELECT
        DISTINCT customerID,
        SeniorCitizen,
        Partner,
        Dependents,
        tenure,
        TRY_CAST(MonthlyCharges AS DECIMAL(10,2)) AS MonthlyCharges,
        TRY_CAST(TotalCharges AS DECIMAL(10,2)) AS TotalCharges,
        CASE 
            WHEN is_churned = 1 THEN 'Churned'
            ELSE 'Active'
        END AS churn_status,
        customerID AS dim_customer_id  -- FK match
    FROM staging.bss_data
) AS source
ON target.customerID = source.customerID

-- Update existing records
WHEN MATCHED THEN
    UPDATE SET
        target.SeniorCitizen = source.SeniorCitizen,
        target.Partner = source.Partner,
        target.Dependents = source.Dependents,
        target.tenure = source.tenure,
        target.MonthlyCharges = source.MonthlyCharges,
        target.TotalCharges = source.TotalCharges,
        target.churn_status = source.churn_status,
        target.dim_customer_id = source.dim_customer_id

-- Insert new records
WHEN NOT MATCHED THEN
    INSERT (
        customerID, SeniorCitizen, Partner, Dependents, tenure,
        MonthlyCharges, TotalCharges, churn_status, dim_customer_id
    )
    VALUES (
        source.customerID, source.SeniorCitizen, source.Partner, source.Dependents, source.tenure,
        source.MonthlyCharges, source.TotalCharges, source.churn_status, source.dim_customer_id
    );
