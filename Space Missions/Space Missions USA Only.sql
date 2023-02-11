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

--Fifth CTE Objective: Reorder and columns into easy-to-read locations and included a decade column to aggregate on in future queries.
space_missions_complete AS(
SELECT LaunchID, Company, Location, Site, Station, City, State, Country, Date, Time, Rocket, Mission, RocketStatus, Price, MissionStatus,
CASE WHEN Date BETWEEN '1950-01-01' AND '1959-12-31' THEN '1950s'
	 WHEN Date BETWEEN '1960-01-01' AND '1969-12-31' THEN '1960s'
	 WHEN Date BETWEEN '1970-01-01' AND '1979-12-31' THEN '1970s'
	 WHEN Date BETWEEN '1980-01-01' AND '1989-12-31' THEN '1980s'
	 WHEN Date BETWEEN '1990-01-01' AND '1999-12-31' THEN '1990s'
	 WHEN Date BETWEEN '2000-01-01' AND '2009-12-31' THEN '2000s'
	 WHEN Date BETWEEN '2010-01-01' AND '2019-12-31' THEN '2010s'
	 WHEN Date BETWEEN '2020-01-01' AND '2029-12-31' THEN '2020s'
	 ELSE NULL END AS Decade
FROM locations_labeled),

USA_only AS(
SELECT *
FROM space_missions_complete
WHERE Country = 'USA'),

--The following three CTEs count the total number of launches, successfull launches, and failed launches per decade in USA
USA_launches_by_decade AS (
SELECT Decade, COUNT(*) AS NumberofLaunches
FROM USA_only
GROUP BY Decade),

USA_success AS(
SELECT Decade, COUNT(*) AS SuccessfulLaunches
FROM USA_only
WHERE MissionStatus = 'Success'
GROUP BY Decade),

USA_failure AS(
SELECT Decade, COUNT(*) AS FailedLaunches
FROM USA_only
WHERE MissionStatus LIKE '%Fail%'
GROUP BY Decade),

--The following CTE joins the previous 3 into one table
USA_joined_launches AS (
SELECT n.Decade, NumberofLaunches, ISNULL(SuccessfulLaunches,0) AS SuccessfulLaunches, ISNULL(FailedLaunches,0) AS FailedLaunches
FROM USA_launches_by_decade AS n
LEFT JOIN USA_success AS s
ON n.Decade = s.Decade
LEFT JOIN USA_failure AS f
ON n.Decade = f.Decade),

State_launches AS (
SELECT State, COUNT(*) AS LaunchesPerState, SUM(COUNT(*)) OVER () AS TotalLaunches
FROM USA_only
GROUP BY State)

/*This query outputs a table displaying the total number of successful and failed launches in each decade, 
along with the percentage of each in each decade. From this table we can see that the only decade the USA had a larger percentage of
failed launches was the 1950s.  The most successful decade is the 2000s with a 95.897% success rate. The year with the largest number of launches
is the 1960s, followed by the 1990s.*/
SELECT 
Decade
, NumberofLaunches
, CAST(SuccessfulLaunches AS decimal)/NumberofLaunches*100 AS PercentSuccess
, CAST(FailedLaunches AS decimal)/NumberofLaunches*100 AS PercentFailure
, SuccessfulLaunches
, FailedLaunches
FROM USA_joined_launches
ORDER BY Decade

/*The following query returns the total count of launches per state along with the percentage of launches in each state.
Florida has the most launches with 911 and a percentage of 61.889%.
Hawaii as the least with only 1 launch and a percentage of 0.068%.
It would be interesting to consider the statistics of launches from each state compared across the decades, but this type of analysis would be more
appropriate in a dashboard so we could filter data more easily.
*/
SELECT State, LaunchesPerState, CAST(LaunchesPerState AS decimal)/TotalLaunches*100 AS PercentofLaunches
FROM State_launches;
