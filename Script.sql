
/* Script for cleaning data */


-- Creating a table from the raw listings table

CREATE TABLE airbnb.listings1 AS SELECT * FROM airbnb.listings;

SELECT * FROM airbnb.listings1;

-- Creating a new table 'hosts' which contains host information 

CREATE TABLE airbnb.hosts AS (SELECT host_id,
	host_since,
	host_location,
	host_response_time,
	host_response_rate,
	host_acceptance_rate,
	host_is_superhost,
	host_neighbourhood,
	host_listings_count,
	host_total_listings_count,
	calculated_host_listings_count
	host_verifications,
	host_has_profile_pic,
	host_identity_verified FROM airbnb.listings1);

SELECT * 
FROM airbnb.hosts;

-- Checking if there are any duplicate rows in our table

SELECT SUM(IF(host_id IS NULL,1,0))
FROM airbnb.listings1;

-- Checking columns now
-- Checking the amount of null values in square_feet column

SELECT SUM(IF(square_feet IS NULL,1,0)) / COUNT(*)
FROM airbnb.listings1;

-- Checking the amount of null values in has_availability

SELECT SUM(IF(has_availability IS NULL,1,0))
FROM airbnb.listings1;

-- Checking the amount of null values in weekly_price

SELECT SUM(IF(weekly_price IS NULL,1,0)) / COUNT(*)
FROM airbnb.listings1;

-- Checking the amount of null values in monthly_price

SELECT SUM(IF(monthly_price IS NULL,1,0)) / COUNT(*)
FROM airbnb.listings1;

-- Creating a new table with selected columns, removing extra review columns, and 
-- columns with a lot of missing values

CREATE TABLE airbnb.listings2 AS (
SELECT 
	id,
	host_id,
	city,
	state,
	zipcode,
	neighbourhood_cleansed,
	market,
	latitude,
	longitude,
	is_location_exact,
	property_type,
	accommodates,
	bathrooms,
	bedrooms,
	beds,
	bed_type,
	amenities,
	price,
	security_deposit,
	cleaning_fee,
	guests_included,
	extra_people,
	minimum_nights,
	maximum_nights,
	calendar_updated,
	availability_30, 
	availability_60,
	availability_90,
	number_of_reviews,
	review_scores_rating,
	instant_bookable,
	cancellation_policy,
	require_guest_profile_picture,
	require_guest_phone_verification,
	reviews_per_month
FROM airbnb.listings1);

SELECT * 
FROM airbnb.listings2;

-- Looking at city column

SELECT DISTINCT city
FROM airbnb.listings2;

-- Cleaning the city column 

UPDATE airbnb.listings2
SET city = LOWER(TRIM(city));

SELECT *
FROM airbnb.listings2 l 
WHERE city LIKE 'jamaica plain%';

UPDATE airbnb.listings2
SET city = 'jamaica plain'
WHERE city LIKE '%jamaica plain%';

UPDATE airbnb.listings2 
SET city = 'charlestown'
WHERE city LIKE '%charlestown%';

SELECT *
FROM airbnb.listings2
WHERE city LIKE '%, boston';

UPDATE airbnb.listings2 
SET city = REPLACE(city, ', boston', '')
WHERE city LIKE '%, boston';

UPDATE airbnb.listings2 
SET city = 'boston'
WHERE city = '波士顿' OR city = 'boston, massachusetts, us';

-- Looking at state column

SELECT DISTINCT state
FROM airbnb.listings2;

-- Looking at zipcode column

SELECT DISTINCT zipcode
FROM airbnb.listings;

-- Cleaning zipcode column

UPDATE airbnb.listings2 
SET zipcode = SUBSTRING(zipcode , 1, LOCATE(' ', zipcode) - 1)
WHERE zipcode LIKE '% %';

-- Looking at neighbourhood_cleansed column and cleaning

SELECT DISTINCT neighbourhood_cleansed
FROM airbnb.listings2;

UPDATE airbnb.listings2 
SET neighbourhood_cleansed = LOWER(neighbourhood_cleansed);

-- market column

SELECT DISTINCT market 
FROM airbnb.listings2;

UPDATE airbnb.listings2 
SET market = LOWER(market);

SELECT *
FROM airbnb.listings2
WHERE market IS NULL;

-- longitude and latitude columns

SELECT *
FROM airbnb.listings2
WHERE latitude IS NULL OR longitude IS NULL;

-- is_location_exact column

SELECT * 
FROM airbnb.listings2
WHERE is_location_exact IS NULL;

SELECT DISTINCT is_location_exact
FROM airbnb.listings2;

-- instant_bookable

SELECT DISTINCT instant_bookable
FROM airbnb.listings2;

-- require_guest_profile_picture column

SELECT DISTINCT require_guest_profile_picture
FROM airbnb.listings2;

-- require_guest_phone_verification column

SELECT DISTINCT require_guest_phone_verification 
FROM airbnb.listings2;

# Changing the data in T/F columns to True or False

UPDATE airbnb.listings2
SET 
	is_location_exact = CASE
		WHEN is_location_exact = 't' THEN TRUE
		ELSE FALSE
	END,
	instant_bookable = CASE
		WHEN instant_bookable = 't' THEN TRUE
		ELSE FALSE
	END,
	require_guest_profile_picture = CASE
		WHEN require_guest_profile_picture = 't' THEN TRUE
		ELSE FALSE 
	END,
	require_guest_phone_verification = CASE
		WHEN require_guest_phone_verification = 't' THEN TRUE
		ELSE FALSE
	END;

-- Changing column types too

ALTER TABLE airbnb.listings2
MODIFY COLUMN is_location_exact TINYINT(1),
MODIFY COLUMN instant_bookable TINYINT(1),
MODIFY COLUMN require_guest_profile_picture TINYINT(1),
MODIFY COLUMN require_guest_phone_verification TINYINT(1);

-- property_type

SELECT DISTINCT property_type
FROM airbnb.listings2;

UPDATE airbnb.listings2
SET property_type = 'other'
WHERE property_type IS NULL;

UPDATE airbnb.listings2
SET property_type = LOWER(property_type);

-- Looking at listing details columns

SELECT *
FROM airbnb.listings2
WHERE accommodates IS NULL OR bathrooms IS NULL OR bedrooms IS NULL OR beds IS NULL;

SELECT DISTINCT bed_type
FROM airbnb.listings2;

UPDATE airbnb.listings2
SET bed_type = LOWER(bed_type);

SELECT DISTINCT amenities
FROM airbnb.listings2;

-- Changing dollar columns from $XX.XX to decimal data type

UPDATE airbnb.listings2 
SET 
	price = REPLACE(price, '$', ''),
	security_deposit = REPLACE(security_deposit, '$', ''),
	cleaning_fee = REPLACE(cleaning_fee, '$', ''),
	extra_people = REPLACE(extra_people, '$', '');

ALTER TABLE airbnb.listings2
MODIFY COLUMN price DECIMAL(10,2),
MODIFY COLUMN security_deposit DECIMAL(10,2),
MODIFY COLUMN cleaning_fee DECIMAL(10,2),
MODIFY COLUMN extra_people DECIMAL(10,2);

SELECT * FROM airbnb.listings2;

-- Fill NA values in reviews_per_month with 0
-- Since it logically makes sense
UPDATE airbnb.listings2 
SET
	reviews_per_month = 0
WHERE reviews_per_month IS NULL;

-- Cleaning up calendar_updated column

SELECT DISTINCT calendar_updated
FROM airbnb.listings2
WHERE calendar_updated LIKE '%month%';

ALTER TABLE airbnb.listings2 ADD calendar_updated1 INT;

-- Changing calendar_updated column to number of days since last updated

UPDATE airbnb.listings2 
SET
	calendar_updated1 = CASE
		WHEN calendar_updated = 'today' THEN 0
		WHEN calendar_updated = 'yesterday' THEN 1
		WHEN calendar_updated LIKE '%days%' THEN CAST(SUBSTRING(calendar_updated, 1, 1) AS UNSIGNED)
		WHEN (calendar_updated = 'a week ago' OR calendar_updated = '1 week ago') THEN 7
		WHEN calendar_updated LIKE '%weeks%' THEN CAST(SUBSTRING(calendar_updated, 1, 1) AS UNSIGNED) * 7
		WHEN calendar_updated LIKE '%month%' THEN CAST(SUBSTRING(calendar_updated , 1, LOCATE(' ', calendar_updated) - 1) AS UNSIGNED) * 30
	END;

-- Comparing old and new columns

SELECT calendar_updated, calendar_updated1
FROM airbnb.listings2
WHERE calendar_updated1 IS NULL;

-- Creating new columns based on important amentites like
-- Has wifi/internet, air conditioning, kitchen, 
-- parking, heating, Washer/Dryer, pool

SELECT *
FROM airbnb.listings2
WHERE amenities NOT LIKE '%internet%';

ALTER TABLE airbnb.listings2 ADD has_internet TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_internet = CASE
		WHEN amenities LIKE '%internet%' THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_kitchen TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_kitchen = CASE
		WHEN amenities LIKE '%kitchen%' THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_ac TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_ac = CASE
		WHEN amenities LIKE '%air conditioning%' THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_parking TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_parking = CASE
		WHEN amenities LIKE '%free parking%' THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_heating TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_heating = CASE
		WHEN (amenities LIKE '%Heating%' OR amenities LIKE '%Fireplace%')THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_washer_dryer TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_washer_dryer = CASE
		WHEN (amenities LIKE '%washer%' AND amenities LIKE '%dryer%')THEN TRUE
		ELSE FALSE
	END;

ALTER TABLE airbnb.listings2 ADD has_pool TINYINT(1);

UPDATE airbnb.listings2
SET 
	has_pool = CASE
		WHEN (amenities LIKE '%pool%')THEN TRUE
		ELSE FALSE
	END;

SELECT *
FROM airbnb.listings2;


-- Creating new table with reordered columns and without 
-- amenities and calendar_updated columns
CREATE TABLE airbnb.listings3 AS (
SELECT 
	id,
	host_id,
	price,
	security_deposit,
	cleaning_fee,
	accommodates,
	guests_included,
	extra_people AS extra_people_price,
	bathrooms,
	bedrooms,
	beds,
	bed_type,
	has_internet,
	has_kitchen,
	has_ac,
	has_parking,
	has_heating,
	has_washer_dryer,
	has_pool,
	minimum_nights,
	maximum_nights,
	instant_bookable,
	cancellation_policy,
	calendar_updated1 AS days_since_calendar_updated,
	property_type,
	city,
	state,
	zipcode,
	neighbourhood_cleansed AS neighbourhood,
	market,
	latitude,
	longitude,
	is_location_exact,
	availability_30,
	availability_60,
	availability_90,
	review_scores_rating,
	number_of_reviews,
	reviews_per_month,
	require_guest_profile_picture,
	require_guest_phone_verification
	FROM airbnb.listings2
	);

SELECT *
FROM airbnb.listings3;

-- Checking date, data is from Sept 6th 2016 to Sept. 5th 2017, 365 days

SELECT MIN(date)
FROM airbnb.calendar;

SELECT MAX(date)
FROM airbnb.calendar;

SELECT COUNT(DISTINCT date)
FROM airbnb.calendar;

-- Joining our listings3 table with calendar table to get booked days for each listing for the past year

CREATE TABLE airbnb.calendar2 AS (SELECT 
	*,
	CASE
		WHEN available = 'f' THEN 1
		ELSE 0
	END AS booked_counter
FROM airbnb.calendar);

SELECT * FROM airbnb.calendar2;

SELECT
	listing_id,
	SUM(booked_counter)
FROM airbnb.calendar2 c
GROUP BY listing_id;

-- Checking to see if there are any problems with the join

WITH cte AS (SELECT
	listing_id,
	SUM(booked_counter) AS booked_days
FROM airbnb.calendar2 c
GROUP BY listing_id),
cte2 AS (
SELECT
	l.*,
	c.listing_id,
	c.booked_days
FROM airbnb.listings3 l
LEFT JOIN cte c
ON l.id = c.listing_id
)
SELECT *
FROM cte2
WHERE listing_id IS NULL;

-- Joined perfectly with no null values, so we'll create a new table with 
-- the joined booked_days column

CREATE TABLE airbnb.final_table AS (
WITH cte AS (SELECT
	listing_id,
	SUM(booked_counter) AS booked_days
FROM airbnb.calendar2 c
GROUP BY listing_id)
SELECT
	l.*,
	c.booked_days
FROM airbnb.listings3 l
LEFT JOIN cte c
ON l.id = c.listing_id
);

SELECT *
FROM airbnb.final_table;
	