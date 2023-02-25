SELECT Month_Posted
, COUNT(*) AS Rentals_per_Month_Posted
, MIN(US_Dollar_Cost)  AS Min_Cost
, CAST(ROUND(AVG(US_Dollar_Cost),2) AS DECIMAL(20,2))  AS Avg_Cost
, MAX(US_Dollar_Cost)  AS Max_Cost
FROM Rentals_Updated
GROUP BY Month_Posted
ORDER BY Month_Posted
/*
Note: This database only contains rentals from 2022-04-13 to 2022-07-11.
We can say definitively that June had more new rentals made available for rent than May did and (more than likely) April.
I would conjecture that July would have the largest number of new rentals since the data available only represent approximately 1/3 of 
the month of July and it is already over half the number of rentals of June.
The average cost of rentals increased as each month progressed.
*/