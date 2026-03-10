USE [PRACTICEDB]

-- Optional: Drop the old corrupted table so we can start fresh
IF OBJECT_ID('OLA_cleaned', 'U') IS NOT NULL 
    DROP TABLE OLA_cleaned;
GO

-- ==========================================
-- 1. PRE-CALCULATE MEDIANS & MODES 
-- ==========================================
DECLARE @Med_VTAT FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(V_TAT AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE V_TAT IS NOT NULL);
DECLARE @Med_CTAT FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(C_TAT AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE C_TAT IS NOT NULL);
DECLARE @Med_DRat FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(Driver_Ratings AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE Driver_Ratings IS NOT NULL);
DECLARE @Med_CRat FLOAT = (SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TRY_CAST(Customer_Rating AS FLOAT)) OVER () FROM [OLA_DataSet.xlsx - July] WHERE Customer_Rating IS NOT NULL);

DECLARE @Mode_Pay NVARCHAR(100)     = (SELECT TOP 1 Payment_Method FROM [OLA_DataSet.xlsx - July] WHERE NULLIF(Payment_Method, 'null') IS NOT NULL GROUP BY Payment_Method ORDER BY COUNT(*) DESC);
DECLARE @Mode_CCust NVARCHAR(100)   = (SELECT TOP 1 Canceled_Rides_by_Customer FROM [OLA_DataSet.xlsx - July] WHERE NULLIF(Canceled_Rides_by_Customer, 'null') IS NOT NULL GROUP BY Canceled_Rides_by_Customer ORDER BY COUNT(*) DESC);
DECLARE @Mode_CDrv NVARCHAR(100)    = (SELECT TOP 1 Canceled_Rides_by_Driver FROM [OLA_DataSet.xlsx - July] WHERE NULLIF(Canceled_Rides_by_Driver, 'null') IS NOT NULL GROUP BY Canceled_Rides_by_Driver ORDER BY COUNT(*) DESC);
DECLARE @Mode_IncReas NVARCHAR(100) = (SELECT TOP 1 Incomplete_Rides_Reason FROM [OLA_DataSet.xlsx - July] WHERE NULLIF(Incomplete_Rides_Reason, 'null') IS NOT NULL GROUP BY Incomplete_Rides_Reason ORDER BY COUNT(*) DESC);


-- ==========================================
-- 2. CREATE BULLETPROOF CLEANED TABLE
-- ==========================================
SELECT 
    TRY_CAST(Date AS DATE) AS Date,
    Booking_ID,
    Booking_Status,
    Customer_ID,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,

    -- IMPUTATION: Continuous metrics still get medians
    COALESCE(TRY_CAST(V_TAT AS FLOAT), @Med_VTAT) AS V_TAT,
    COALESCE(TRY_CAST(C_TAT AS FLOAT), @Med_CTAT) AS C_TAT,
    COALESCE(TRY_CAST(Driver_Ratings AS FLOAT), @Med_DRat) AS Driver_Ratings,
    COALESCE(TRY_CAST(Customer_Rating AS FLOAT), @Med_CRat) AS Customer_Rating,
    COALESCE(NULLIF(Payment_Method, 'null'), @Mode_Pay) AS Payment_Method,

    --  THE FIX: CONDITIONAL CATEGORICAL IMPUTATION
    
    -- Fix 1: Customer Cancellations
    CASE 
        WHEN Booking_Status = 'Success' THEN 'N/A - Completed Ride'
        WHEN Booking_Status = 'Canceled by Customer' THEN COALESCE(NULLIF(Canceled_Rides_by_Customer, 'null'), @Mode_CCust)
        ELSE 'N/A' 
    END AS Canceled_Rides_by_Customer,

    -- Fix 2: Driver Cancellations
    CASE 
        WHEN Booking_Status = 'Success' THEN 'N/A - Completed Ride'
        WHEN Booking_Status = 'Canceled by Driver' THEN COALESCE(NULLIF(Canceled_Rides_by_Driver, 'null'), @Mode_CDrv)
        ELSE 'N/A' 
    END AS Canceled_Rides_by_Driver,

    -- Fix 3: Incomplete Rides & Reasons
    CASE 
        WHEN Booking_Status = 'Success' THEN 'No'
        WHEN NULLIF(Incomplete_Rides, 'null') IS NULL THEN 'Unknown'
        ELSE Incomplete_Rides 
    END AS Incomplete_Rides,

    CASE 
        WHEN Booking_Status = 'Success' THEN 'N/A - Completed Ride'
        WHEN Incomplete_Rides = 'Yes' THEN COALESCE(NULLIF(Incomplete_Rides_Reason, 'null'), @Mode_IncReas)
        ELSE 'N/A' 
    END AS Incomplete_Rides_Reason,
    
    TRY_CAST(Booking_Value AS FLOAT) AS Booking_Value,
    TRY_CAST(Ride_Distance AS FLOAT) AS Ride_Distance,
    [Vehicle_Images] 

INTO OLA_cleaned
FROM [OLA_DataSet.xlsx - July];
GO

PRINT 'Bulletproof Data Cleaning Complete. Proceed to Star Schema creation.'



SELECT TOP 10 * 
FROM [dbo].[OLA_cleaned];
