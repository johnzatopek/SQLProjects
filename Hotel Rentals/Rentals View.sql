/*
We are creating a view to be used in future queries since the original table needs to be 
reformated with additional columns before being used.
This VIEW is used to create columns to label each input, convert rent to USD, and 
easily identify and categorize the Unit Floor level and Total number of floors in the rental.  
Currently, the Floor column lists every entry as xx out of xx.
*/
CREATE VIEW Rentals_Updated AS

--ROW_NUMBER() is used to assign a unique id to each rental
SELECT ROW_NUMBER() OVER (ORDER BY Posted_On) AS Rental_ID
, *
/*
REPLACE is used to create consistency in first floors.  Some inputs were coded as "Ground" and others as "1".
Our REPLACE functions gives consistency to the Unit_Floor column.
*/
, REPLACE(TRIM(SUBSTRING(Floor, 1, CHARINDEX(' out of ', Floor))),'Ground','1') AS Unit_Floor
/*
NULLIF is used in the Total_Floors column because there were input errors that did not include the total floors.
The table was UPDATEd to include " out of " so Unit_Floor is reflected correctly, but the remainder was left blank because we 
were not given the total number of floors.
*/
, NULLIF(TRIM(SUBSTRING(Floor, CHARINDEX(' out of ', Floor)+7, LEN(Floor))),'') AS Total_Floors
/*
The value of a rupee as of 2023-02-20 is .012 USD.  This value is used to create the USD column.
We use CAST and ROUND to display USD to an accuracy of 2 decimal places.
*/
, CAST(ROUND(Rent*.012,2) AS DECIMAL(20,2)) AS US_Dollar_Cost
--A column is created where month is extracted from the date.
, DATENAME(month, Posted_On) AS Month_Posted

FROM House_Rent_Dataset

