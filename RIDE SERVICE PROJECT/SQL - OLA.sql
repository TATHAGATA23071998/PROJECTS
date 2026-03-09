USE [PRACTICE_DB]
GO

-- 1. Pre-calculate Medians
-- Using TRY_CAST ensures we handle any unexpected 'null' strings or empty values safely
DECLARE @Med_VTAT FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(V_TAT AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE TRY_CAST(V_TAT AS FLOAT) IS NOT NULL);
DECLARE @Med_CTAT FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(C_TAT AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE TRY_CAST(C_TAT AS FLOAT) IS NOT NULL);
DECLARE @Med_DRat FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(Driver_Ratings AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE TRY_CAST(Driver_Ratings AS FLOAT) IS NOT NULL);
DECLARE @Med_CRat FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(Customer_Rating AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE TRY_CAST(Customer_Rating AS FLOAT) IS NOT NULL);

-- 2. Pre-calculate Modes
-- We use CAST(column AS NVARCHAR(MAX)) to prevent comparison errors between numeric types and the string 'null'
DECLARE @Mode_Pay     NVARCHAR(MAX) = (SELECT TOP 1 Payment_Method FROM [OLA_DataSet.xlsx - July] WHERE Payment_Method IS NOT NULL AND CAST(Payment_Method AS NVARCHAR(MAX)) <> 'null' GROUP BY Payment_Method ORDER BY COUNT(*) DESC);
DECLARE @Mode_CCust   NVARCHAR(MAX) = (SELECT TOP 1 Canceled_Rides_by_Customer FROM [OLA_DataSet.xlsx - July] WHERE Canceled_Rides_by_Customer IS NOT NULL AND CAST(Canceled_Rides_by_Customer AS NVARCHAR(MAX)) <> 'null' GROUP BY Canceled_Rides_by_Customer ORDER BY COUNT(*) DESC);
DECLARE @Mode_CDrv    NVARCHAR(MAX) = (SELECT TOP 1 Canceled_Rides_by_Driver FROM [OLA_DataSet.xlsx - July] WHERE Canceled_Rides_by_Driver IS NOT NULL AND CAST(Canceled_Rides_by_Driver AS NVARCHAR(MAX)) <> 'null' GROUP BY Canceled_Rides_by_Driver ORDER BY COUNT(*) DESC);
DECLARE @Mode_Inc     NVARCHAR(MAX) = (SELECT TOP 1 Incomplete_Rides FROM [OLA_DataSet.xlsx - July] WHERE Incomplete_Rides IS NOT NULL AND CAST(Incomplete_Rides AS NVARCHAR(MAX)) <> 'null' GROUP BY Incomplete_Rides ORDER BY COUNT(*) DESC);
DECLARE @Mode_IncReas NVARCHAR(MAX) = (SELECT TOP 1 Incomplete_Rides_Reason FROM [OLA_DataSet.xlsx - July] WHERE Incomplete_Rides_Reason IS NOT NULL AND CAST(Incomplete_Rides_Reason AS NVARCHAR(MAX)) <> 'null' GROUP BY Incomplete_Rides_Reason ORDER BY COUNT(*) DESC);

-- 3. Create OLA_cleaned with the Fixed Date Logic

SELECT 
    -- FIX: Since Date is already a datetime type, use TRY_CAST or CAST to get just the Date part.
    -- This avoids the Msg 8116 error.
    TRY_CAST(Date AS DATE) AS Date,
    
    Booking_ID,
    Booking_Status,
    Customer_ID,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,

    -- Numerical Imputation
    ISNULL(TRY_CAST(V_TAT AS FLOAT), @Med_VTAT) AS V_TAT,
    ISNULL(TRY_CAST(C_TAT AS FLOAT), @Med_CTAT) AS C_TAT,
    ISNULL(TRY_CAST(Driver_Ratings AS FLOAT), @Med_DRat) AS Driver_Ratings,
    ISNULL(TRY_CAST(Customer_Rating AS FLOAT), @Med_CRat) AS Customer_Rating,

    -- Categorical Imputation
    ISNULL(NULLIF(CAST(Canceled_Rides_by_Customer AS NVARCHAR(MAX)), 'null'), @Mode_CCust) AS Canceled_Rides_by_Customer,
    ISNULL(NULLIF(CAST(Canceled_Rides_by_Driver AS NVARCHAR(MAX)), 'null'), @Mode_CDrv) AS Canceled_Rides_by_Driver,
    ISNULL(NULLIF(CAST(Incomplete_Rides AS NVARCHAR(MAX)), 'null'), @Mode_Inc) AS Incomplete_Rides,
    ISNULL(NULLIF(CAST(Incomplete_Rides_Reason AS NVARCHAR(MAX)), 'null'), @Mode_IncReas) AS Incomplete_Rides_Reason,
    ISNULL(NULLIF(CAST(Payment_Method AS NVARCHAR(MAX)), 'null'), @Mode_Pay) AS Payment_Method,
    
    TRY_CAST(Booking_Value AS FLOAT) AS Booking_Value,
    TRY_CAST(Ride_Distance AS FLOAT) AS Ride_Distance,
    
    -- Images Column
    [Vehicle_Images] 

INTO OLA_cleaned
FROM [OLA_DataSet.xlsx - July];
GO

-- Verification Query
SELECT TOP 10 Date, Booking_ID, Vehicle_Type FROM OLA_cleaned;

SELECT * FROM OLA_cleaned;