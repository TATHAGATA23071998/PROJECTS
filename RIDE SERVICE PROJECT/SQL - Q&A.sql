USE [PRACTICE_DB]
GO

-- ==============================================================================
-- 1. Retrieve all successful bookings
-- Business Value: The foundational dataset for calculating actual realized revenue.
-- ==============================================================================
SELECT 
    f.Booking_ID, 
    f.Date, 
    f.Vehicle_Type, 
    f.Booking_Value
FROM Fact_Bookings f
JOIN Dim_Ride_Status s ON f.Status_ID = s.Status_ID
WHERE s.Booking_Status = 'Success'
ORDER BY Booking_Value DESC;


-- ==============================================================================
-- 2. Find the average ride distance for each vehicle type
-- Business Value: Identifies operational wear-and-tear and vehicle utilization metrics.
-- ==============================================================================
SELECT 
    Vehicle_Type, 
    ROUND(AVG(Ride_Distance), 2) AS Avg_Ride_Distance_KM
FROM Fact_Bookings
GROUP BY Vehicle_Type
ORDER BY Avg_Ride_Distance_KM DESC;


-- ==============================================================================
-- 3. Get the total number of cancelled rides by customers
-- Business Value: Tracks demand-side churn to investigate if pricing or wait times are too high.
-- ==============================================================================
SELECT 
    COUNT(f.Booking_ID) AS Total_Customer_Cancellations
FROM Fact_Bookings f
JOIN Dim_Ride_Status s ON f.Status_ID = s.Status_ID
WHERE s.Booking_Status = 'Canceled by Customer';


-- ==============================================================================
-- 4. List the top 5 customers who booked the highest number of rides
-- Business Value: Identifies "Power Users" for targeted loyalty/reward programs (DAU Retention).
-- ==============================================================================
SELECT TOP 5 
    Customer_ID, 
    COUNT(Booking_ID) AS Total_Lifetime_Rides
FROM Fact_Bookings
GROUP BY Customer_ID
ORDER BY Total_Lifetime_Rides DESC;


-- ==============================================================================
-- 5. Get the number of rides cancelled by drivers due to personal and car-related issues
-- Business Value: Identifies the root cause of the 38% supply-side operational bottleneck.
-- ==============================================================================
SELECT 
    COUNT(f.Booking_ID) AS Canceled_By_Driver_Issues
FROM Fact_Bookings f
JOIN Dim_Ride_Status s ON f.Status_ID = s.Status_ID
WHERE s.Canceled_Rides_by_Driver LIKE '%Personal & Car related issue%';


-- ==============================================================================
-- 6. Find the maximum and minimum driver ratings for Prime Sedan bookings
-- Business Value: Quality assurance check for premium fleet offerings.
-- ==============================================================================
SELECT 
    MAX(Driver_Ratings) AS Max_Rating, 
    MIN(Driver_Ratings) AS Min_Rating
FROM Fact_Bookings
WHERE Vehicle_Type = 'Prime Sedan';


-- ==============================================================================
-- 7. Retrieve all rides where payment was made using UPI
-- Business Value: Validates your executive recommendation to push digital payments.
-- ==============================================================================
SELECT 
    Booking_ID, 
    Date, 
    Vehicle_Type, 
    Booking_Value
FROM Fact_Bookings
WHERE Payment_Method = 'UPI';


-- ==============================================================================
-- 8. Find the average customer rating per vehicle type
-- Business Value: Highlights which vehicle categories are damaging the brand reputation.
-- ==============================================================================
SELECT 
    Vehicle_Type, 
    ROUND(AVG(Customer_Rating), 2) AS Avg_Customer_Rating
FROM Fact_Bookings
GROUP BY Vehicle_Type
ORDER BY Avg_Customer_Rating DESC;


-- ==============================================================================
-- 9. Calculate the total booking value of rides completed successfully
-- Business Value: The ultimate Top-Line Realized Revenue KPI.
-- ==============================================================================
SELECT 
    SUM(f.Booking_Value) AS Total_Realized_Revenue
FROM Fact_Bookings f
JOIN Dim_Ride_Status s ON f.Status_ID = s.Status_ID
WHERE s.Booking_Status = 'Success';


-- ==============================================================================
-- 10. List all incomplete rides along with the reason
-- Business Value: Captures the "Incomplete_Rides" metric to calculate mid-trip revenue leakage.
-- ==============================================================================
SELECT 
    f.Booking_ID, 
    f.Vehicle_Type,
    s.Incomplete_Rides_Reason
FROM Fact_Bookings f
JOIN Dim_Ride_Status s ON f.Status_ID = s.Status_ID
WHERE s.Incomplete_Rides = 'Yes' 
   OR s.Booking_Status = 'Incomplete';