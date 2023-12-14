DELIMITER $$
DROP PROCEDURE IF EXISTS copy_and_clean_data;
CREATE PROCEDURE copy_and_clean_data()
BEGIN
	CREATE TABLE IF NOT EXISTS `us_household_income_cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    
-- copy data to new table
	INSERT INTO us_household_income_cleaned
    SELECT *, CURRENT_TIMESTAMP 
	FROM bakery.us_household_income;
    
-- data cleaning
	-- Removing duplicates
	DELETE FROM us_household_income_cleaned
	WHERE row_id IN
	( 
		SELECT row_id
		FROM 
		( -- start of subquery
			SELECT 
				row_id, 
				id, 
				ROW_NUMBER() OVER (PARTITION BY id, `TimeStamp` ORDER BY id, `TimeStamp`) AS row_num
			FROM us_household_income_cleaned
		) duplicates -- end of subquery
		WHERE row_num > 1
	);
	-- Fixing some data quality issues by fixing typos and general standardization
	UPDATE us_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';
END $$
DELIMITER ;

CALL copy_and_clean_data();

-- creating the event
CREATE EVENT run_clean_data
	ON SCHEDULE EVERY 30 DAY
    DO CALL copy_and_clean_data();