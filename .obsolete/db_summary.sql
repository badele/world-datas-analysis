.head on

--------------------------------------
-- Database summary 
--------------------------------------
BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS db_summary (
  description TEXT,
  value INTEGER,
  SOURCE_ID INTEGER,

  PRIMARY KEY (SOURCE_ID,description)
);


--------------------------------------
-- geonames 
--------------------------------------

REPLACE INTO db_summary SELECT SOURCE_ID, 'nb countries',count(GEOID) from geonames_country;
REPLACE INTO db_summary SELECT SOURCE_ID, 'nb entries', count(GEOID) from geonames_allentries;

--------------------------------------
-- commons 
--------------------------------------

REPLACE INTO db_summary SELECT SOURCE_ID,'nb distinct indicators',  count(DISTINCT IndicatorKey) from db_indicator_description;
REPLACE INTO db_summary SELECT SOURCE_ID,'nb distinct french indicators', count(*) FROM db_indicator_description WHERE lang='FR';
REPLACE INTO db_summary SELECT SOURCE_ID,'nb indicators values', count(*) FROM db_historical_country_value;


--------------------------------------
-- worldbank 
--------------------------------------




SELECT "=== DB SUMMARY ===";
SELECT * FROM db_summary ORDER BY sourcename, value DESC;
SELECT "";
SELECT "=== TABLES ===";

SELECT type,name FROM sqlite_master 
WHERE name NOT LIKE 'x_%' AND (type LIKE 'table' OR type LIKE 'view')
ORDER BY name; 

COMMIT;

