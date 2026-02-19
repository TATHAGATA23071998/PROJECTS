USE [PRACTICE_DB];
-- ==============================
-- (A) Cleaning the track table
-- ==============================
-- Set missing composer to default
UPDATE track
SET composer = 'Not available'
WHERE composer IS NULL;

-- Ensure unit_price has proper decimal format
ALTER TABLE track
ALTER COLUMN unit_price DECIMAL(10,2);

-- Verify cleaned track table
SELECT * FROM track;


-- ==============================
-- (B) Cleaning the customer table
-- ==============================
UPDATE customer

    -- Remove corrupted characters
SET first_name = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(first_name, '¿', ''), '½', ''), 'ï', ''))),'Not available'),
    last_name  = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(last_name, '¿', ''), '½', ''), 'ï', ''))),'Not available'),
    address    = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(address, '¿', ''), '½', ''), 'ï', ''))),'Not available'),
    city       = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(city, '¿', ''), '½', ''), 'ï', ''))),'Not available'),
    company    = ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(company, '¿', ''), '½', ''), 'ï', ''))),'Not available'),
    state       = ISNULL(state, 'Not available'),
    fax         = ISNULL(fax, '0'),
    phone       = ISNULL(phone, '0'),
    postal_code = ISNULL(postal_code, 'O');

-- Verify cleaned customer table
SELECT * FROM customer;


-- ==============================
-- (C) Cleaning the employee table
-- ==============================
-- Change reports_to to VARCHAR for storing titles
ALTER TABLE employee
ALTER COLUMN reports_to VARCHAR(50);

-- Update NULL or 0 reports_to
UPDATE employee
SET reports_to = 'Not available'
WHERE reports_to IS NULL OR reports_to = '0';

-- Replace numeric reports_to with manager's title
UPDATE e
SET e.reports_to = m.title
FROM employee e
INNER JOIN employee m
    ON e.reports_to = CAST(m.employee_id AS VARCHAR(50))
WHERE e.reports_to <> 'Not available';

-- Verify employee table
SELECT * FROM employee;


-- ==============================
-- (D) Cleaning the invoice table
-- ==============================
-- Step 1: Add new date-only column
ALTER TABLE invoice
ADD invoice_date_only DATE;

-- Step 2: Copy data into new column
UPDATE invoice
SET invoice_date_only = CAST(invoice_date AS DATE);

-- Step 3: Verify data
SELECT invoice_date, invoice_date_only
FROM invoice;

-- Step 4: Drop old column after verification
ALTER TABLE invoice
DROP COLUMN invoice_date;

-- Step 5: Add formatted computed column
ALTER TABLE invoice
ADD formatted_invoice_date AS FORMAT(invoice_date_only, 'dd-MM-yyyy');

-- Verify invoice table
SELECT * FROM invoice;


-- ==============================
-- (E) Verify all 11 tables
-- ==============================
SELECT * FROM album;
SELECT * FROM artist;
SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM genre;
SELECT * FROM invoice;
SELECT * FROM invoice_line;
SELECT * FROM media_type;
SELECT * FROM playlist;
SELECT * FROM playlist_track;
SELECT * FROM track;

    
-- JOINING THE TABLES TOGETHER TO GET A COMPLETE VIEW OF THE DATA
SELECT 
    -- Customer Details
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.company,
    c.city AS customer_city,
    c.country AS customer_country,
    c.email,

    -- Employee (Support Rep)
    e.employee_id AS support_rep_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.title AS support_rep_title,

    -- Invoice Details
    i.invoice_id,
    i.formatted_invoice_date,
    i.billing_city,
    i.billing_country,
    i.total AS invoice_total,

    -- Invoice Line
    il.invoice_line_id,
    il.unit_price,
    il.quantity,

    -- Track Details
    t.track_id,
    t.name AS track_name,
    t.milliseconds,
    t.unit_price AS track_price,

    -- Album
    a.album_id,
    a.title AS album_title,

    -- Artist
    ar.artist_id,
    ar.name AS artist_name,

    -- Genre
    g.genre_id,
    g.name AS genre_name,

    -- Media Type
    m.media_type_id,
    m.name AS media_type_name,

    -- Playlist
    p.playlist_id,
    p.name AS playlist_name

FROM Customer c
LEFT JOIN Employee e 
    ON c.support_rep_id = e.employee_id

LEFT JOIN Invoice i 
    ON c.customer_id = i.customer_id

LEFT JOIN Invoice_line il 
    ON i.invoice_id = il.invoice_id

LEFT JOIN Track t 
    ON il.track_id = t.track_id

LEFT JOIN Album a 
    ON t.album_id = a.album_id

LEFT JOIN Artist ar 
    ON a.artist_id = ar.artist_id

LEFT JOIN Genre g 
    ON t.genre_id = g.genre_id

LEFT JOIN Media_type m 
    ON t.media_type_id = m.media_type_id

LEFT JOIN Playlist_Track pt 
    ON t.track_id = pt.track_id

LEFT JOIN Playlist p 
    ON pt.playlist_id = p.playlist_id

ORDER BY c.customer_id ASC

-- Puttng the joined data into a new table called 'MUSIC_DATA' for easier access
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.company,
    c.city AS customer_city,
    c.country AS customer_country,
    c.email,

    e.employee_id AS support_rep_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.title AS support_rep_title,

    i.invoice_id,
    i.formatted_invoice_date,
    i.billing_city,
    i.billing_country,
    i.total AS invoice_total,

    il.invoice_line_id,
    il.unit_price,
    il.quantity,

    t.track_id,
    t.name AS track_name,
    t.milliseconds,
    t.unit_price AS track_price,

    a.album_id,
    a.title AS album_title,

    ar.artist_id,
    ar.name AS artist_name,

    g.genre_id,
    g.name AS genre_name,

    m.media_type_id,
    m.name AS media_type_name,

    p.playlist_id,
    p.name AS playlist_name

INTO MUSIC_DATA

FROM Customer c
LEFT JOIN Employee e ON c.support_rep_id = e.employee_id
LEFT JOIN Invoice i ON c.customer_id = i.customer_id
LEFT JOIN Invoice_line il ON i.invoice_id = il.invoice_id
LEFT JOIN Track t ON il.track_id = t.track_id
LEFT JOIN Album a ON t.album_id = a.album_id
LEFT JOIN Artist ar ON a.artist_id = ar.artist_id
LEFT JOIN Genre g ON t.genre_id = g.genre_id
LEFT JOIN Media_type m ON t.media_type_id = m.media_type_id
LEFT JOIN Playlist_Track pt ON t.track_id = pt.track_id
LEFT JOIN Playlist p ON pt.playlist_id = p.playlist_id
ORDER BY c.customer_id ASC;

SELECT * FROM MUSIC_DATA
ORDER BY customer_id ASC;