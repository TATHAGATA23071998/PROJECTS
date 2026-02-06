USE [MyDatabase]

SELECT *
FROM [dbo].[games_final_for_ssms]

SELECT *
FROM [dbo].[vgsales_perfectly_cleaned]

SELECT *
FROM vgsales_perfectly_cleaned V
INNER JOIN games_final_for_ssms G 
    ON (V.Name) = (G.Title)
WHERE V.Year IS NOT NULL AND G.Rating IS NOT NULL;