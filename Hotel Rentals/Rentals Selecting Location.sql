SELECT *
FROM Rentals_Updated
--Note: Avg Size is 967
WHERE Size >= (SELECT AVG(Size)
				FROM Rentals_Updated)
--Note: Avg US Dollar Cost is 419.92
AND US_Dollar_Cost <= (SELECT AVG(US_Dollar_Cost)
						FROM Rentals_Updated)
--Note: Avg BHK is 2
AND BHK >= (SELECT AVG(BHK) 
			FROM Rentals_Updated)
AND Bathroom >= 3
AND Tenant_Preferred LIKE '%Family%'
AND Point_of_Contact LIKE '%Agent%'
--Unit Floor's value must be in quotes because it is a string since some values are Basement types, which is a string.
AND Unit_Floor = '1'
AND Furnishing_Status = 'Furnished'
/*
Using the above query, we have found the single rental that is above average in size, above average in BHK (bedrooms, halls, and kitchens),
below average in cost, has 3 or more bathrooms, the preferred tenant is a family, is on the ground floor, is furnished, and point of contact is
an agent.  However, this rental is in the City of Kolkata and based on previous queries, it appears as though Kolkata is one of the less desirable
locations to rent.  By removing any of these restrictions (such as point of contact) the number of options increase tremendously.
*/


