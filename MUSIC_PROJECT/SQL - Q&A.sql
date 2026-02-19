USE [PRACTICE_DB]
-- Business Inisghts

-- 1. Customer Analytics
--1.1 Top 10 customers by total spending
SELECT TOP 10
    customer_id,
    customer_name,
    ROUND(SUM(invoice_total),2) AS total_spent
FROM MUSIC_DATA
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC;

-- 1.2 Average Customer Lifetime Value (CLV)
SELECT 
    ROUND(AVG(customer_total),2) AS avg_customer_lifetime_value_in_USD
FROM (
    SELECT customer_id, SUM(invoice_total) AS customer_total
    FROM MUSIC_DATA
    GROUP BY customer_id
)t;


--1.3 Repeat vs One-Time Customers
WITH customer_purchases AS (
    SELECT 
        customer_id, 
        COUNT(DISTINCT invoice_id) AS purchase_count
    FROM MUSIC_DATA
    GROUP BY customer_id
)

SELECT 
    CASE 
        WHEN purchase_count > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_purchases
GROUP BY 
    CASE 
        WHEN purchase_count > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END;

--1.4 Top 10 countries Generating Most Revenue Per Customer
SELECT Top 10
    customer_country,
    ROUND(SUM(invoice_total) / COUNT(DISTINCT customer_id),2) AS revenue_per_customer
FROM MUSIC_DATA
GROUP BY customer_country
ORDER BY revenue_per_customer DESC;

-- 1.5 Customers Inactive in Last 6 Months
SELECT
    customer_id,
    customer_name,
    CONVERT(VARCHAR(10),
            MAX(TRY_CONVERT(DATETIME, formatted_invoice_date)),
            103) AS last_purchase_date
FROM MUSIC_DATA
GROUP BY customer_id, customer_name
HAVING MAX(TRY_CONVERT(DATETIME, formatted_invoice_date)) 
       < DATEADD(MONTH, -6, GETDATE())
ORDER BY MAX(TRY_CONVERT(DATETIME, formatted_invoice_date)) ASC;

-- 2. Sales & Revenue Analysis
--2.1 Monthly Revenue Trends (Last 2 Years)
SELECT
    YEAR(invoice_date) AS sales_year,
    DATENAME(MONTH,invoice_date) AS sales_month,
    ROUND(SUM(unit_price * quantity),2) AS monthly_revenue
FROM (
    SELECT 
        TRY_CONVERT(DATE, formatted_invoice_date) AS invoice_date,
        unit_price,
        quantity
    FROM MUSIC_DATA
) t
WHERE invoice_date >= (
        SELECT DATEADD(YEAR, -2, MAX(TRY_CONVERT(DATE, formatted_invoice_date)))
        FROM MUSIC_DATA
)
GROUP BY YEAR(invoice_date), MONTH(invoice_date), DATENAME(MONTH,invoice_date)
ORDER BY monthly_revenue DESC;

--2.2 Average Invoice Value (AOV)
SELECT 
    ROUND(AVG(invoice_value),2) AS avg_invoice_value
FROM (
    SELECT 
        invoice_id,
        SUM(unit_price * quantity) AS invoice_value
    FROM MUSIC_DATA
    GROUP BY invoice_id
) t;

-- 2.3 Revenue by billing country, billing city
SELECT
    billing_country,
    billing_city,
    ROUND(SUM(invoice_total),2) AS total_revenue
    FROM MUSIC_DATA
    GROUP BY billing_country, billing_city
    ORDER BY total_revenue DESC;

-- 2.4 How much revenue does each sales representative contribute?
SELECT
    support_rep_id,
    employee_name,
    ROUND(SUM(unit_price * quantity),2) AS total_revenue
FROM MUSIC_DATA
GROUP BY 
    support_rep_id,
    employee_name
ORDER BY total_revenue DESC;


--2.5 Which months or quarters have peak music sales?
SELECT TOP 1
    YEAR(invoice_date) AS sales_year,
    DATENAME(MONTH, invoice_date) AS month_name,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM (
    SELECT 
        TRY_CONVERT(DATE, formatted_invoice_date, 103) AS invoice_date,
        unit_price,
        quantity
    FROM MUSIC_DATA
) t
WHERE invoice_date IS NOT NULL
GROUP BY 
    YEAR(invoice_date),
    MONTH(invoice_date),
    DATENAME(MONTH, invoice_date)
ORDER BY total_revenue DESC;

-- 3. Product & Content Analysis
--3.1 Which tracks generated the most revenue?
SELECT TOP 10
    track_id,
    track_name,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY track_id, track_name
ORDER BY total_revenue DESC;

--3.2 Which Albums Are Most Frequently Purchased?
SELECT TOP 10
    album_id,
    album_title,
    COUNT(DISTINCT invoice_id) AS purchase_frequency
FROM MUSIC_DATA
GROUP BY album_id, album_title
ORDER BY purchase_frequency DESC;

--3.3 Tracks Never Purchased
SELECT
    t.track_id,
    t.track_name
FROM MUSIC_DATA t
WHERE NOT EXISTS (
    SELECT 1
    FROM MUSIC_DATA md
    WHERE md.track_id = t.track_id
);

-- 3.4 Average Price Per Track by Genre
SELECT
    genre_name,
    ROUND(AVG(track_price),2) AS avg_track_price
FROM MUSIC_DATA t
GROUP BY genre_name
ORDER BY avg_track_price DESC;

-- 3.5 Track Count per Genre + Sales Correlation
SELECT
    genre_name,
    COUNT(DISTINCT track_id) AS total_tracks_sold,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue,
    ROUND(
        SUM(unit_price * quantity) * 1.0 
        / COUNT(DISTINCT track_id),
    2) AS revenue_per_track
FROM MUSIC_DATA
GROUP BY genre_name
ORDER BY total_revenue DESC;

--4. Artist & Genre Performance
--4.1 Who are the top 5 highest-grossing artists?
SELECT TOP 5
    artist_id,
    artist_name,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY artist_id, artist_name
ORDER BY total_revenue DESC;

--4.2 Most Popular Genres by Number of Tracks Sold
    SELECT
    genre_name,
    COUNT(DISTINCT track_id) AS tracks_sold
FROM MUSIC_DATA
GROUP BY genre_name
ORDER BY tracks_sold DESC;

--4.3 Most Popular Genres by Total Revenue
SELECT
    genre_name,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY genre_name
ORDER BY total_revenue DESC;


--4.4 Genre Popularity by Country
SELECT
    billing_country,
    genre_name,
    COUNT(DISTINCT track_id) AS tracks_sold,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY billing_country, genre_name
ORDER BY total_revenue DESC;

-- 5. Employee & Operational Efficiency
-- 5.1 Which employees (support representatives) are managing the highest-spending customers?
SELECT TOP 10
    support_rep_id AS employee_id,
    employee_name,
    customer_id,
    customer_name,
    ROUND(SUM(unit_price * quantity), 2) AS customer_total_spent
FROM MUSIC_DATA
GROUP BY support_rep_id, employee_name, customer_id, customer_name
ORDER BY customer_total_spent DESC;

--5.2 Average Number of Customers per Employee
SELECT
    support_rep_id,
    employee_name,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(COUNT(DISTINCT customer_id) * 1.0 / COUNT(DISTINCT support_rep_id), 2) AS avg_customers_per_employee
FROM MUSIC_DATA
GROUP BY support_rep_id, employee_name
ORDER BY total_customers DESC;

--5.3 Employee Regions Bringing the Most Revenue
SELECT
    support_rep_id AS employee_id,
    employee_name,
    billing_country,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY support_rep_id, employee_name, billing_country
ORDER BY total_revenue DESC;

-- 6. Geographic Trends
-- 6.1 Which countries or cities have the highest number of customers?
SELECT
    billing_country,
    COUNT(DISTINCT customer_id) AS total_customers
FROM MUSIC_DATA
GROUP BY billing_country
ORDER BY total_customers DESC;

SELECT
    billing_country,
    billing_city,
    COUNT(DISTINCT customer_id) AS total_customers
FROM MUSIC_DATA
GROUP BY billing_country, billing_city
ORDER BY total_customers DESC;

--6.2 Revenue Variation by Region
SELECT
    billing_country,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY billing_country
ORDER BY total_revenue DESC;

SELECT
    billing_country,
    billing_city,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue
FROM MUSIC_DATA
GROUP BY billing_country, billing_city
ORDER BY total_revenue DESC;


--6.3 Identify Underserved Regions (High Users, Low Sales)
SELECT
    billing_country,
    billing_city,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(unit_price * quantity), 2) AS total_revenue,
    ROUND(SUM(unit_price * quantity) * 1.0 / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM MUSIC_DATA
GROUP BY billing_country, billing_city
ORDER BY revenue_per_customer ASC, total_customers DESC;

--7 Customer Retention & Purchase Patterns
--7.1 What is the distribution of purchase frequency per customer?
SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT invoice_id) AS purchase_count
FROM MUSIC_DATA
GROUP BY customer_id, customer_name
ORDER BY purchase_count DESC;

--7.2 How long is the average time between customer purchases?
WITH customer_invoices AS (
    SELECT
        customer_id,
        TRY_CONVERT(DATE, formatted_invoice_date, 103) AS invoice_date
    FROM MUSIC_DATA
    WHERE formatted_invoice_date IS NOT NULL
),
invoice_diff AS (
    SELECT
        customer_id,
        invoice_date,
        LAG(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS prev_invoice_date
    FROM customer_invoices
)
SELECT
    ROUND(AVG(DATEDIFF(DAY, prev_invoice_date, invoice_date) * 1.0),2) AS avg_days_between_purchases
FROM invoice_diff
WHERE prev_invoice_date IS NOT NULL;

-- 7.3 What percentage of customers purchase tracks from more than one genre?
-- 7.3 Percentage of Customers Purchasing Tracks from More Than One Genre
WITH invoice_genres AS (
    SELECT
        customer_id,
        invoice_id,
        COUNT(DISTINCT LTRIM(RTRIM(genre_name))) AS genres_per_invoice
    FROM MUSIC_DATA
    GROUP BY customer_id, invoice_id
)
SELECT
    COUNT(*) AS total_invoices,
    SUM(CASE WHEN genres_per_invoice = 1 THEN 1 ELSE 0 END) AS single_genre_invoices,
    SUM(CASE WHEN genres_per_invoice > 1 THEN 1 ELSE 0 END) AS multi_genre_invoices,
    ROUND(
        100.0 * SUM(CASE WHEN genres_per_invoice > 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_multi_genre_invoices
FROM invoice_genres;

--8. Operational Optimization
-- 8.1 What are the most common combinations of tracks purchased together?
SELECT
    t1.track_name AS track_1,
    t2.track_name AS track_2,
    COUNT(DISTINCT md.invoice_id) AS times_purchased_together
    FROM MUSIC_DATA md
    JOIN MUSIC_DATA t1 ON md.track_id = t1.track_id
    JOIN MUSIC_DATA t2 ON md.invoice_id = t2.invoice_id AND t1.track_id < t2.track_id
    GROUP BY t1.track_name, t2.track_name
    ORDER BY times_purchased_together DESC;

-- 8.2 Are there pricing patterns that lead to higher or lower sales?
SELECT
    ROUND(unit_price, 2) AS price,
    SUM(quantity) AS total_quantity_sold,
    COUNT(DISTINCT invoice_id) AS invoice_count,
    SUM(quantity * unit_price) AS total_revenue
FROM MUSIC_DATA
GROUP BY ROUND(unit_price, 2)
ORDER BY total_revenue DESC;

-- 8.3 Which media types (e.g., MPEG, AAC) are declining or increasing in usage?
SELECT
    media_type_name,
    YEAR(invoice_date) AS sales_year,
    COUNT(DISTINCT invoice_id) AS invoices_sold,
    SUM(quantity) AS tracks_sold,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM (
    -- Step 1: Convert formatted_invoice_date to DATE and filter invalid rows
    SELECT
        *,
        TRY_CONVERT(DATE, formatted_invoice_date, 103) AS invoice_date
    FROM MUSIC_DATA
) md
WHERE invoice_date IS NOT NULL  -- exclude invalid dates
GROUP BY media_type_name, YEAR(invoice_date)
ORDER BY revenue DESC;
