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

/*This CTE is necessary to find the median date. We assign a row number to each date based on when the rocket launch occured so we can
accurately create the next CTE to find the median.*/

achieve_med_date AS(
SELECT Date, ROW_NUMBER() OVER (ORDER BY DATE) AS DateLocation, COUNT(*) OVER () AS TotalRows
FROM space_missions_complete),

/*This CTE uses the previous one to identify the median. To do this we must SELECT the AVG date of (TotalRows+1)/2 and (TotalRows+2)/2.
Since these calculations in the WHERE clause are found as integers we will be averaging a row with itself in the case of an odd number of TotalRows.
If an even total number of rows, we will be finding the average of the two dates in the middle of our data.
Since SQL does not allow calculating averages on dates we must conduct multiple CAST functions to accurately calculate the average date.
*/
median_date AS (
SELECT CAST(CAST(AVG(CAST(CAST(Date AS DATETIME) AS INT)) AS DATETIME) AS DATE) AS MedianDate
FROM achieve_med_date
WHERE DateLocation IN ((TotalRows+1)/2, (TotalRows+2)/2)),

/*The following CTE identifies the date of the first rocket launch, the median date of rocket launches, 
the average date of launches, and the most recent rocket launch. A query was not created based on median date, but this
column could be used to return only the first 50% or last 50% of all rocket launches if desired.*/
summary_dates AS (
SELECT MIN(Date) as FirstLaunch 
, (SELECT * FROM median_date) AS MedianDate
, MAX(Date) as MostRecentLaunch
FROM space_missions_complete),

--Following CTE Objectives: Discover the success and failure rate of each decade.
--Total number of rocket launches by decade
num_rocket_launches_by_decade AS (
SELECT Decade, COUNT(*) AS NumberofLaunches
FROM space_missions_complete
GROUP BY Decade),

--Total number of succesful rocket launches by decade
successful_launches AS (
SELECT Decade, COUNT(*) AS NumberofSuccess
FROM space_missions_complete
WHERE MissionStatus LIKE '%Success%'
GROUP BY Decade),

--Total number of failed rocket launches by decade
failed_launches AS (
SELECT Decade, COUNT(*) AS NumberofFailure
FROM space_missions_complete
WHERE MissionStatus LIKE '%Failure%'
GROUP BY Decade),

--All launches joined into one table
joined_launches AS (
SELECT n.Decade, NumberofLaunches, ISNULL(NumberofSuccess,0) AS NumberofSuccess, ISNULL(NumberofFailure,0) AS NumberofFailure
FROM num_rocket_launches_by_decade AS n
LEFT JOIN successful_launches AS s
ON n.Decade = s.Decade
LEFT JOIN failed_launches AS f
ON n.Decade = f.Decade)

/*Query to return the total number of launches per decade and comparison of success/failure rates.
Unsurprisingly, the decade with the largest percentage of failed rocket launches is the 1950s with the next largest percentage of failed
launches being the 1960s.  From the 1970s and on the percentage of failed launches decreases dramatically with no decade going higher than 8.5%.
More optimistically, from the 1970s-2020s the percentage of success is greater than 91% for every decade.
Interestingly, the percentage of successful rocket launches dropped from the 2010s to the 2020s.  I suspect that this is because of a smaller 
number of launches taking place and new technologies being tested.
*/
SELECT Decade
, NumberofLaunches
, CAST(NumberofSuccess AS decimal)/NumberofLaunches*100 AS PercentSuccess
, CAST(NumberofFailure AS decimal)/NumberofLaunches*100 AS PercentFailure
, NumberofSuccess
, NumberofFailure
FROM joined_launches
ORDER BY Decade

/*The following query returns a table of the Country where the first rocket launch occured and the most recent rocket launch.
From this table we can conclude that the first rocket launch occured in Kazakhstan and the most recent was in China.
*/
SELECT Country, Date, 'FirstLaunch' AS HowRecent
FROM space_missions_complete 
WHERE Date IN (SELECT FirstLaunch FROM summary_dates)
UNION
SELECT Country, Date, 'MostRecentLaunch' AS HowRecent
FROM space_missions_complete 
WHERE Date IN (SELECT MostRecentLaunch FROM summary_dates)
ORDER BY Date ASC

/*The following query returns a table that examines the total number of rocket launches in each country for each decade 
that they launched rockets. The most interesting information to be gleaned from this query is the distribution of the top 3 locations
of rocket launches (USA, Russia, and Kazakhstan).
USA has the most consistent number of rocket launches each decde with over 115 launches in every decade from the 1960s and on.
Russia's most active decade was the 1970s with almost half (604) of their total rocket launches (1416) taking place in this decade.
The number of rocket launches drops off significantly for the next 3 decades stabalizing around 20-55 launches in the 2000s-2020s.
Kazakhstan launches most of their rockets in the 1960s (269) and 1970s (211). Their number of rocket launches tapered off significantly
beginning in the 1980s with only 2 decades above 50 launches and none over 100.
*/

SELECT Country, Decade, COUNT(*) AS NumberofLaunches
FROM space_missions_complete
GROUP BY Country, Decade
ORDER BY Country, Decade;

