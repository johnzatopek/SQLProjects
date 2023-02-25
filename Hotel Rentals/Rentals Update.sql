/* When creating the original CTEs, I noticed there were several input errors that needed to be addressed.
Inconsistencies consisted of: "Ground" being used instead of 1 for floor level and four entries did not include the total number of levels.
I will use UPDATE to correct the four entries with improper formatting. The inconsistencies between "Ground" and 1 will be corrected within the CTEs.

To identify the errors, the following codes were used:
*/

--This CTE is used to assign a unique id to each rental
--WITH Rent_Label AS (
--SELECT ROW_NUMBER() OVER (ORDER BY Posted_On) AS Rental_ID, *
--FROM House_Rent_Dataset),

--This CTE is used to create columns that separates Floor into Unit_Floor and Total_Floors
--Split_Floor AS (
--SELECT *
--, TRIM(SUBSTRING(Floor, 1, CHARINDEX(' out of ', Floor))) AS Unit_Floor
--, TRIM(SUBSTRING(Floor, CHARINDEX(' out of ', Floor)+7, LEN(Floor))) AS Total_Floors
--FROM Rent_Label)

--Before using UPDATE this code was used to identify the rows that gave blank values for Unit_Floor and Total_Floors
--SELECT *
--FROM Split_Floor
--WHERE Unit_Floor = ''

--It was identified that one input error was "Ground", two others were "1", and the fourth was "3"

--To correct this, I will include " out of " on each of these entries.  Within the CTEs I will replace the blanks with NULL.
--UPDATE House_Rent_Dataset
--SET Floor = 'Ground out of '
--WHERE Floor = 'Ground'

--UPDATE House_Rent_Dataset
--SET Floor = '1 out of '
--WHERE Floor = '1'

--UPDATE House_Rent_Dataset
--SET Floor = '3 out of '
--WHERE Floor = '3'

--The following query is used to confirm that the table was updated correctly.
SELECT *
FROM House_Rent_Dataset
WHERE Floor = '3'