SELECT Unit_Floor
, COUNT(*) AS Rentals_per_Unit_Floor
, MIN(US_Dollar_Cost)  AS Min_Cost
, CAST(ROUND(AVG(US_Dollar_Cost),2) AS DECIMAL(20,2))  AS Avg_Cost
, MAX(US_Dollar_Cost)  AS Max_Cost
FROM Rentals_Updated
GROUP BY Unit_Floor
ORDER BY Unit_Floor
/*
From this query we can see that the unit floor with the most available rentals is floor 1.
Floors with the least availability are those at double-digit levels.
Both of these facts make sense because every building has a 1st floor, but not every building even has double-digit levels.
The unit floors with the cheapest costs are floors 1, 2, and 3.  I believe this is because these floors have the most availability
and double-digit floors that are likely in large apartment complexes within the city.  Living in the city is typically more expensive than rural areas.
*/