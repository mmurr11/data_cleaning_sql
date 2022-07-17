-- Check table
SELECT *
FROM nashville_housing
LIMIT 100;





-- Standardize date format

-- update format of sale_date (yyyy-mm-dd)
UPDATE nashville_housing 
SET sale_date = TO_DATE(sale_date, 'Month DD, YYYY');

-- confirm column change
SELECT sale_date
FROM nashville_housing
LIMIT 100;





-- Populate property address data

-- Some property addresses are null, let's check if the null's parcel_id 
-- has been used before, with a valid property_address.
SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcel_id = b.parcel_id
	AND a.unique_id != b.unique_id
WHERE a.property_address is null -- no results = no nulls
    
-- Fill null addresses by matching parcel_id with a non-null property address in another row
UPDATE nashville_housing
SET property_address = (
  SELECT b.property_address
  FROM nashville_housing b
  WHERE b.parcel_id = nashville_housing.parcel_id AND b.property_address IS NOT NULL
  LIMIT 1
)
WHERE property_address is null; -- run top query to confirm





-- Format property address into columns "address", "city", "state"

-- check property_address formatting
SELECT property_address, property_city
FROM nashville_housing;
                        
-- create city column
ALTER TABLE nashville_housing
ADD property_city VARCHAR(100);

-- update city & address with property_address substrings
UPDATE nashville_housing
SET property_city = SPLIT_PART(property_address, ',', 2);

UPDATE nashville_housing
SET property_address = SPLIT_PART(property_address, ',', 1); -- run top query for confirmation





-- Fill owner_address nulls and make columns for owner's address, city, & state

-- What do these columns look like & how many nulls
SELECT owner_address, owner_city, owner_split_address, owner_state
FROM nashville_housing;

-- create city, state, & split_address columns
ALTER TABLE nashville_housing
ADD owner_city VARCHAR(100);

ALTER TABLE nashville_housing
ADD owner_state VARCHAR(100);

ALTER TABLE nashville_housing
ADD owner_split_address VARCHAR(100);

-- update owner's city, state, & address columns
UPDATE nashville_housing
SET owner_city = SPLIT_PART(owner_address, ',', 2);

UPDATE nashville_housing
SET owner_state = SPLIT_PART(owner_address, ',', 3);

UPDATE nashville_housing
SET owner_split_address = SPLIT_PART(owner_address, ',', 1); -- run top query for confirmation





-- Change Y & N to Yes & No in sold_as_vacant

-- check unique values
SELECT DISTINCT(sold_as_vacant), COUNT(sold_as_vacant)
FROM nashville_housing
GROUP BY sold_as_vacant
ORDER BY 2;

-- change Y & N
UPDATE nashville_housing 
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
    WHEN sold_as_vacant = 'N' THEN 'No'
	ELSE sold_as_vacant
    END; -- run top query for confirmation





-- Remove duplicates

-- query the number of rows that share values in specified columns
-- anything over 1 is a duplicate
WITH row_num_cte AS (
	SELECT 
		*,
    	ROW_NUMBER() OVER (
        PARTITION BY parcel_id,
      				property_address,
      				sale_price,
      				sale_date,
      				legal_reference
      ) row_num
	FROM nashville_housing
)
SELECT DISTINCT(row_num) 
FROM row_num_cte;

-- delete duplicates
DELETE FROM nashville_housing
WHERE parcel_id IN
    (SELECT parcel_id
    FROM 
        (SELECT 
		*,
    	ROW_NUMBER() OVER (
        PARTITION BY parcel_id,
      				property_address,
      				sale_price,
      				sale_date,
      				legal_reference
      ) row_num
	FROM nashville_housing) row_num_subq
    WHERE row_num_subq.row_num > 1 ); -- run top query for confirmation





-- Remove unused columns
SELECT *
FROM nashville_housing
LIMIT 100;

ALTER TABLE nashville_housing
DROP COLUMN tax_district;



