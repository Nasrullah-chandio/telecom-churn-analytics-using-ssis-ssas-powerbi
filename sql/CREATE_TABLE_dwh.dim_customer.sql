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
