SELECT City
, COUNT(*) AS Rentals_per_City
, MIN(US_Dollar_Cost)  AS Min_Cost
, CAST(ROUND(AVG(US_Dollar_Cost),2) AS DECIMAL(20,2))  AS Avg_Cost
, MAX(US_Dollar_Cost)  AS Max_Cost
FROM Rentals_Updated
GROUP BY City
ORDER BY City
/*
From this query we can see that the city with the most rentals availble is Mumbai.
The city with the least rentals available is Kolkata.
The city with the lowest min cost is Hyderabad.
The city with the lowest avg and max cost is Kolkata.
The city with the largest min and avg cost is Mumbai.
The city with the largest max cost is Bangalore (but this is a significant outlier, if removed, the max cost would be Mumbai).
Without knowing more information, it is difficult to determine the exact reason for the difference in rental prices.
I would conjecture that Kolkata is one of the least desireable places to rent because there are a low number available and the prices remain low.
If Kolkata were more desirable, I would expect the lower number of rentals availabe would encourage a higher avg cost.
Another conjecture is that Mumbai is undesireable to live for a correlated reason.  There are many rentals available, but prices are high.
Since prices are high, there are less people that choose to rent creating a larger supply than demand.  
To increase the number of rents in Mumbai, I suggest lowering the price of living spaces to better reflect the demand.
*/