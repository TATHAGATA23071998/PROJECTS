USE [PRACTICE_DB]
GO

-- ==============================================================================
-- STEP 1: CREATE DIMENSION TABLES (The "Nouns")
-- Using SELECT DISTINCT to isolate unique entities and remove duplicate data
-- ==============================================================================

-- A. Entity Dimension: Customer
SELECT DISTINCT Customer_ID 
INTO Dim_Customer 
FROM OLA_cleaned
WHERE Customer_ID IS NOT NULL;

-- B. Entity Dimension: Vehicle
SELECT DISTINCT Vehicle_Type 
INTO Dim_Vehicle 
FROM OLA_cleaned
WHERE Vehicle_Type IS NOT NULL;

-- C. Temporal Dimension: Date
SELECT DISTINCT TRY_CAST(Date AS DATE) AS Date 
INTO Dim_Date 
FROM OLA_cleaned
WHERE TRY_CAST(Date AS DATE) IS NOT NULL;

-- D. Root-Cause Dimension (The "Junk Dimension")
-- Grouping all heavy text-based cancellation and status logic into one table with a Surrogate Key
SELECT 
    IDENTITY(INT, 1, 1) AS Status_ID, 
    Booking_Status, 
    Canceled_Rides_by_Customer, 
    Canceled_Rides_by_Driver, 
    Incomplete_Rides, 
    Incomplete_Rides_Reason
INTO Dim_Ride_Status
FROM (
    SELECT DISTINCT 
        Booking_Status, 
        Canceled_Rides_by_Customer, 
        Canceled_Rides_by_Driver, 
        Incomplete_Rides, 
        Incomplete_Rides_Reason
    FROM OLA_cleaned
) AS DistinctStatuses;

-- ==============================================================================
-- STEP 2: CREATE THE FACT TABLE (The "Verbs" & Numerical KPIs)
-- Joining back to the new Status_ID to keep the fact table purely numerical/keys
-- ==============================================================================

SELECT 
    o.Booking_ID,
    TRY_CAST(o.Date AS DATE) AS Date,
    o.Customer_ID,
    o.Vehicle_Type,
    o.Pickup_Location,
    o.Drop_Location,
    o.Payment_Method,
    
    -- Surrogate Key for the qualitative text
    s.Status_ID, 

    -- Core Operational & Revenue KPIs
    o.V_TAT,
    o.C_TAT,
    o.Driver_Ratings,
    o.Customer_Rating,
    o.Booking_Value,
    o.Ride_Distance

INTO Fact_Bookings
FROM OLA_cleaned o
JOIN Dim_Ride_Status s
    ON o.Booking_Status = s.Booking_Status
    AND o.Canceled_Rides_by_Customer = s.Canceled_Rides_by_Customer
    AND o.Canceled_Rides_by_Driver = s.Canceled_Rides_by_Driver
    AND o.Incomplete_Rides = s.Incomplete_Rides
    AND o.Incomplete_Rides_Reason = s.Incomplete_Rides_Reason
WHERE o.Booking_ID IS NOT NULL;

-- ==============================================================================
-- STEP 3: ENFORCE ARCHITECTURE (Data Types, Primary & Foreign Keys)
-- Locking in the Star Schema relationships for BI tools like Tableau
-- ==============================================================================

-- 3A. Standardize Data Types & enforce NOT NULL on Dimension Keys
ALTER TABLE Dim_Customer ALTER COLUMN Customer_ID NVARCHAR(100) NOT NULL;
ALTER TABLE Dim_Vehicle ALTER COLUMN Vehicle_Type NVARCHAR(100) NOT NULL;
ALTER TABLE Dim_Date ALTER COLUMN Date DATE NOT NULL;
-- (Status_ID is already INT NOT NULL due to the IDENTITY function)

-- 3B. Standardize Data Types & enforce NOT NULL on Fact Table Keys 
-- (This ensures the Foreign Keys perfectly match the Dimension Primary Keys)
ALTER TABLE Fact_Bookings ALTER COLUMN Booking_ID NVARCHAR(100) NOT NULL;
ALTER TABLE Fact_Bookings ALTER COLUMN Customer_ID NVARCHAR(100) NOT NULL;
ALTER TABLE Fact_Bookings ALTER COLUMN Vehicle_Type NVARCHAR(100) NOT NULL;
ALTER TABLE Fact_Bookings ALTER COLUMN Date DATE NOT NULL;

-- 3C. Add Primary Keys
ALTER TABLE Dim_Customer ADD CONSTRAINT PK_Customer PRIMARY KEY (Customer_ID);
ALTER TABLE Dim_Vehicle ADD CONSTRAINT PK_Vehicle PRIMARY KEY (Vehicle_Type);
ALTER TABLE Dim_Date ADD CONSTRAINT PK_Date PRIMARY KEY (Date);
ALTER TABLE Dim_Ride_Status ADD CONSTRAINT PK_Status PRIMARY KEY (Status_ID);
ALTER TABLE Fact_Bookings ADD CONSTRAINT PK_Booking PRIMARY KEY (Booking_ID);

-- 3D. Add Foreign Keys
ALTER TABLE Fact_Bookings ADD CONSTRAINT FK_Fact_Customer FOREIGN KEY (Customer_ID) REFERENCES Dim_Customer(Customer_ID);
ALTER TABLE Fact_Bookings ADD CONSTRAINT FK_Fact_Vehicle FOREIGN KEY (Vehicle_Type) REFERENCES Dim_Vehicle(Vehicle_Type);
ALTER TABLE Fact_Bookings ADD CONSTRAINT FK_Fact_Date FOREIGN KEY (Date) REFERENCES Dim_Date(Date);
ALTER TABLE Fact_Bookings ADD CONSTRAINT FK_Fact_Status FOREIGN KEY (Status_ID) REFERENCES Dim_Ride_Status(Status_ID);
GO

PRINT 'Star Schema successfully deployed and constraints locked!'