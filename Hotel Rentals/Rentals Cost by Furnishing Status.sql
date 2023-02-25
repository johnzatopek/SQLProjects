SELECT Furnishing_Status
, COUNT(*) AS Rentals_per_Furnishing_Status
, MIN(US_Dollar_Cost)  AS Min_Cost
, CAST(ROUND(AVG(US_Dollar_Cost),2) AS DECIMAL(20,2))  AS Avg_Cost
, MAX(US_Dollar_Cost)  AS Max_Cost
FROM Rentals_Updated
GROUP BY Furnishing_Status
ORDER BY Furnishing_Status
/*
From this query we can see that the furnishing status with the most available rentals is Semi-Furnished.
Units with the least availability are Furnished.
Unsurprisingly, the furnishing status with the highest avg cost is Furnished.  The lowest avg cost is Unfurnished.
Interestingly, the furnishing with with the highest cost is Semi-Furnished. It should be noted
that the value of 42000 is an outlier to the data with the next highest rental price of Semi-Furnished is 14400.
It seems that the most cost-effective rental to lease is unfurnished and furnished is the least cost-effective.
If the tennat desires to save money, they should search for unfurnished housing.
*/