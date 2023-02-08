--Create CTEs necessary to separate Location into parts
--First CTE creates a column to label each individual Launch
WITH labeled_missions AS (
SELECT ROW_NUMBER() OVER (ORDER BY Date) AS LaunchID, *
FROM space_missions),

--Second CTE creates value column where Location has been split by comma
location_to_column AS(
SELECT *, ROW_NUMBER() OVER (PARTITION BY LaunchID ORDER BY LaunchID) AS RowNumber
FROM labeled_missions
CROSS APPLY  
string_split(Location, ',')),

--Third CTE pivots the table so each value that was separated from Location is now in its own column
space_missions_split AS(
SELECT  *
FROM location_to_column
PIVOT (MAX(value)
FOR RowNumber IN ([1], [2], [3], [4], [5])) AS Pvt),

--Fourth CTE places each of our new columns into the correct category of location
locations_labeled AS(
/*Creating CASE WHEN Statements to correctly place each value in Site, Station, City, State, Country
It is necessary to work our way from right to left in each of these CASE WHEN Statements because 
the right most value in Location is Country, but not every location has a State, City, or Site.*/
SELECT *, 
/*The first CASE WHEN Statement takes the right most value that IS NOT NULL as the Country
Note: Only Alaska has values in [5] since it was the only location to include a city
Note: Barents Sea, Yellow Sea, and Gran Canaria are listed as a Country. Gran Canaria is an island in Spain. */
	TRIM(CASE WHEN [5] IS NOT NULL THEN [5]
		 WHEN [4] IS NOT NULL THEN [4]
		 WHEN [3] IS NOT NULL THEN [3]
		 WHEN [2] IS NOT NULL THEN [2]
		 ELSE [1] 
	 END) AS Country,
--The second CASE WHEN Statement takes only locations in USA and places the states values in the correct location
--Note: Marshall Islands are listed as a state for USA
	TRIM(CASE WHEN Location LIKE '%USA%' AND [5] IS NOT NULL THEN [4]
		 WHEN Location LIKE '%USA%' AND [5] IS NULL THEN [3]
	ELSE NULL
	END) AS State,
--The third CASE WHEN Statement takes the city location and places is correctly in the city column
	TRIM(CASE WHEN [5] IS NOT NULL THEN [3]
	ELSE NULL END) AS City,
--The fourth CASE WHEN Statement takes the Station value and places it in the correct position
	TRIM(CASE WHEN [3] IS NOT NULL THEN [2]
		 WHEN [2] IS NOT NULL THEN [1] 
		ELSE NULL 
	END) AS Station,
/*The fifth CASE WHEN Statement takes the Site Value and places it in the correct position
There is no need to check other columns for IS NOT NULL because if any of our locations only have [1] and [2] then there is no site*/
	TRIM(CASE WHEN [3] IS NOT NULL THEN [1]
	ELSE NULL
	END) AS Site

FROM space_missions_split),

--Fifth CTE Objective: Reorder and columns into easy-to-read locations
space_missions_complete AS(
SELECT LaunchID, Company, Location, Site, Station, City, State, Country, Date, Time, Rocket, Mission, RocketStatus, Price, MissionStatus
FROM locations_labeled),

--Following CTE Objectives: Discover which country has conducted the most rocket launches and what the success rates are.
--Total number of rocket launches by country
num_rocket_launches_by_country AS (
SELECT Country, COUNT(*) AS NumberofLaunches
FROM space_missions_complete
GROUP BY Country),

--Total number of succesful rocket launches by country
successful_launches AS (
SELECT Country, COUNT(*) AS NumberofSuccess
FROM space_missions_complete
WHERE MissionStatus LIKE '%Success%'
GROUP BY Country),

--Total number of failed rocket launches by country
failed_launches AS (
SELECT Country, COUNT(*) AS NumberofFailure
FROM space_missions_complete
WHERE MissionStatus LIKE '%Failure%'
GROUP BY Country),

--All launches joined into one table
joined_launches AS (
SELECT n.Country, NumberofLaunches, ISNULL(NumberofSuccess,0) AS NumberofSuccess, ISNULL(NumberofFailure,0) AS NumberofFailure
FROM num_rocket_launches_by_country AS n
LEFT JOIN successful_launches AS s
ON n.Country = s.Country
LEFT JOIN failed_launches AS f
ON n.Country = f.Country)

--Query to return the total number of launches and comparison of success/failure rates
SELECT RANK() OVER (ORDER BY NumberofLaunches DESC) AS LaunchNumRank
, Country
, NumberofLaunches
, CAST(NumberofSuccess AS decimal)/NumberofLaunches*100 AS PercentSuccess
, CAST(NumberofFailure AS decimal)/NumberofLaunches*100 AS PercentFailure
, NumberofSuccess
, NumberofFailure
FROM joined_launches
ORDER BY LaunchNumRank;

/* From this query I can see that USA has the most rocket launches with a total of 1472 and Russia is second with 1416.
While Russia has had a smaller number of rocket launches, it has had a higher total number (and percentage) of succesful missions.
Brazil is the only country to have zero succesfull rocket launches.
There are three locations that have a 100% success rate.  Those locations are: Kenya, Yellow Sea, and Gran Canaria.
It should be taken into consideration that each of these locations have a very low number of launches compared to other locations, like Russia.
Accounting for the number of launches I am confident in stating that the most successful rocket launch locations are Russia and France.
France is one of the most successful because while it has almost 900 fewer rocket launches than Russia, the success rate is higher and I do not 
expect a dramatic increase in failed rocket launches if France were to conduct more launches.
*/

