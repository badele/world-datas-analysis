.head on
.nullvalue NULL

-- PRAGMA cache_size = 400000; PRAGMA synchronous = OFF; PRAGMA journal_mode = OFF; PRAGMA locking_mode = EXCLUSIVE; PRAGMA count_changes = OFF; PRAGMA temp_store = MEMORY; PRAGMA auto_vacuum = NONE;

-- SOURCE_ID=200

BEGIN TRANSACTION;

.read './dataset/init.sql'

-- provider info
INSERT OR REPLACE INTO db_dataset VALUES(200, 'worldbank', 'https://data.worldbank.org','Creative Commons Attribution 4.0 (CC-BY 4.0)');


--------------------------------------
-- Indicator and Category
--------------------------------------

-- Load datas
DROP TABLE IF EXISTS x_worldbank_indicator_french;
DROP TABLE IF EXISTS x_worldbank_indicator_english;
.import --csv './downloaded/worldbank/french_indicator.csv' x_worldbank_indicator_french
.import --csv './downloaded/worldbank/WDISeries.csv' x_worldbank_indicator_english

-- Category
DELETE FROM db_category WHERE SOURCE_ID=200;
INSERT INTO db_category (SOURCE_ID,LANG,CategoryKey,Description) SELECT DISTINCT 200,"FR",Topic,Topic FROM x_worldbank_indicator_french;  
INSERT INTO db_category (SOURCE_ID,LANG,CategoryKey,Description) SELECT DISTINCT 200,"EN",topic,topic FROM x_worldbank_indicator_english;

-- Indicator
DELETE FROM db_indicator_description WHERE SOURCE_ID=200;
INSERT INTO db_indicator_description (SOURCE_ID,LANG,IndicatorKey,Description) SELECT DISTINCT 200, "FR", wi."Series Code",wi."Indicator Name" FROM x_worldbank_indicator_french wi;
INSERT INTO db_indicator_description (SOURCE_ID,LANG,IndicatorKey,Description) SELECT DISTINCT 200, "EN", wi."Series Code",wi."Indicator Name" FROM x_worldbank_indicator_english wi;

-- Indicator in category
DELETE FROM db_indicator_in_category WHERE IndicatorKey IN (SELECT IndicatorKey FROM db_indicator_description WHERE SOURCE_ID=200);

-- FR
INSERT INTO db_indicator_in_category SELECT CAT_ID,"Series Code" FROM x_worldbank_indicator_french xdi
INNER JOIN db_category dc ON dc.CategoryKey = xdi.Topic
INNER JOIN db_indicator_description di ON di.IndicatorKey = xdi."Series Code" AND dc.LANG= di.LANG
WHERE di.LANG="FR";
-- EN
INSERT INTO db_indicator_in_category SELECT CAT_ID,"Series Code" FROM x_worldbank_indicator_english xdi
INNER JOIN db_category dc ON dc.CategoryKey = xdi.Topic
INNER JOIN db_indicator_description di ON di.IndicatorKey = xdi."Series Code" AND dc.LANG= di.LANG
WHERE di.LANG="EN";

-- Drop CSV tables
DROP TABLE x_worldbank_indicator_french;
DROP TABLE x_worldbank_indicator_english;

--------------------------------------
-- English category
--------------------------------------

-- DROP TABLE IF EXISTS x_worldbank_indicator;
-- .import --csv './downloaded/worldbank/WDISeries.csv' x_worldbank_indicator

-- DELETE FROM db_category WHERE SOURCE_ID=200 AND LANG="FR";
-- INSERT INTO db_category (SOURCE_ID,LANG,CategoryKey,Category) SELECT DISTINCT 200,"FR",CategoryKey,CategoryKey FROM x_worldbank_indicator;  

-- INSERT INTO db_category (SOURCE_ID,LANG,CategoryKey,Category) SELECT DISTINCT 200,"EN",topic,topic FROM x_worldbank_indicator;

-- COMMIT;

-- DROP TABLE IF EXISTS x_worldbank_serie;


--------------------------------------
-- Indicator
--------------------------------------

-- DROP TABLE IF EXISTS x_db_indicator;
-- .import --csv './downloaded/worldbank/french_indicator.csv' x_db_indicator

-- COMMIT;


-- DELETE FROM db_indicator WHERE SOURCE_ID=200;
-- INSERT INTO db_indicator () 
-- INSERT INTO "main"."db_category" ("SOURCE_ID", "CategoryKey", "LANG", "Category") VALUES ('', '', '', '');

--DROP TABLE x_db_indicator;


-- import
-- DROP TABLE IF EXISTS x_worldbank_serie;
-- .mode csv x_worldbank_serie
-- .import './downloaded/worldbank/WDISeries.csv' x_worldbank_serie

-- -- convert
-- DROP TABLE IF EXISTS x_worldbank_serie;
-- CREATE TABLE x_worldbank_serie(
--   LANG TEXT,
--   IndicatorKey TEXT,
--   topic TEXT,
--   IndicatorName TEXT,
--   PRIMARY KEY (LANG,INDICATORNAME)
-- );

-- COMMIT;


-- INSERT INTO worldbank_indicator
-- SELECT 
-- 'EN',
-- "IndicatorKey",
-- "Topic",
-- "Indicator Name"
-- FROM x_worldbank_serie;

-- DROP TABLE x_worldbank_serie;


--------------------------------------
-- Import country
--------------------------------------

-- import
DROP TABLE IF EXISTS worldbank_country;
.import --csv './downloaded/worldbank/WDICountry.csv' worldbank_country
--DROP TABLE worldbank_country;

--------------------------------------
-- Import datas
--------------------------------------

DROP TABLE IF EXISTS x_worldbank_datas;
.import --csv './downloaded/worldbank/WDIData_Pivot.csv' x_worldbank_datas

DELETE FROM db_historical_country_value WHERE SOURCE_ID=200;

INSERT OR REPLACE INTO db_historical_country_value (SOURCE_ID, COUNTRYCODE,YEAR, IndicatorKey,value) SELECT 200,COUNTRYCODE,YEAR,IndicatorKey,value FROM x_worldbank_datas;

DROP TABLE x_worldbank_datas;



--------------------------------------
-- all  period summaries
--------------------------------------


DELETE FROM db_historical_country_summary WHERE SOURCE_ID=200;
INSERT INTO db_historical_country_summary
SELECT 
wd.SOURCE_ID,
wd.COUNTRYCODE, 
wd.IndicatorKey, 
MIN(wd.YEAR) AS first_year,
MAX(wd.YEAR) AS last_year,
COUNT(wd.YEAR) AS nbyears,
NULL AS first_value,
NULL AS last_value,
NULL AS growth_percent,
MIN(wd.value) AS min_value,
MAX(wd.value) AS max_value,
ROUND((COUNT(wd.value) * SUM(wd.YEAR * wd.value) - (SUM(wd.YEAR) * SUM(wd.value))) / ((COUNT(wd.value) * SUM(POW(wd.YEAR,2))) - (SUM(wd.YEAR) * SUM(wd.YEAR))),4) AS lr_a,
(SUM(wd.value) / COUNT(wd.value)) - (ROUND((COUNT(wd.value) * SUM(wd.YEAR * wd.value) - (SUM(wd.YEAR) * SUM(wd.value))) / ((COUNT(wd.value) * SUM(POW(wd.YEAR,2))) - (SUM(wd.YEAR) * SUM(wd.YEAR))),4)) * (SUM(wd.YEAR) / COUNT(wd.YEAR)) AS lr_b,
NULL AS lr_percent_slope,
ROUND(COUNT(wd.YEAR) / wd1.nb_years * 100,2) AS data_quality,
SUM((wd.YEAR-wd2.avg_year)*(wd.value-wd2.avg_value)) /
(SQRT(SUM(POW(wd.YEAR-wd2.avg_year,2))) * SQRT(SUM(POW(wd.value-wd2.avg_value,2)))) AS corr
FROM db_historical_country_value wd,
 (SELECT
MAX(YEAR) - MIN(YEAR) + 1.0 nb_years, 
MIN(YEAR) min_year,
MAX(YEAR) max_year
FROM db_historical_country_value
GROUP BY SOURCE_ID) wd1,
 (SELECT
 *,
AVG(value) AS avg_value,
AVG(YEAR) AS avg_year
FROM db_historical_country_value
GROUP BY SOURCE_ID, COUNTRYCODE,IndicatorKey) AS wd2
WHERE wd.SOURCE_ID = wd2.SOURCE_ID AND wd.COUNTRYCODE = wd2.COUNTRYCODE AND wd.IndicatorKey = wd2.IndicatorKey
GROUP BY wd.SOURCE_ID, wd.COUNTRYCODE,wd.IndicatorKey;



-- slope
UPDATE db_historical_country_summary AS wu SET lr_percent_slope=((2*lr_a+lr_b)-(lr_a+lr_b))/abs(lr_a+lr_b)*100;
-- UPDATE db_historical_country_summary AS wu SET lr_percent_slope=(
--   SELECT ((2*lr_a+lr_b)-(lr_a+lr_b))/abs(lr_a+lr_b)*100 FROM db_historical_country_summary ws 
--   WHERE wu.COUNTRYCODE = ws.COUNTRYCODE AND wu.IndicatorKey = ws.IndicatorKey
--   );

-- first value
UPDATE db_historical_country_summary AS wu SET first_value=(
  SELECT value FROM db_historical_country_value wd 
  WHERE wu.SOURCE_ID = wd.SOURCE_ID AND wu.COUNTRYCODE = wd.COUNTRYCODE AND wu.IndicatorKey = wd.IndicatorKey AND wu.first_year = wd.year
  );


-- last value
UPDATE db_historical_country_summary AS wu SET last_value=(
  SELECT value FROM db_historical_country_value wd 
  WHERE wu.SOURCE_ID = wd.SOURCE_ID AND wu.COUNTRYCODE = wd.COUNTRYCODE AND wu.IndicatorKey = wd.IndicatorKey AND wu.last_year = wd.year
  );

-- Percent range
UPDATE db_historical_country_summary AS wu SET growth_percent=(last_value - first_value) / ABS(first_value)*100;


--------------------------------------
-- view
--------------------------------------

-- DROP VIEW IF EXISTS v_db_historical_country_summary;
-- CREATE VIEW IF NOT EXISTS v_db_historical_country_summary
-- AS
-- SELECT wi.COUNTRYCODE,category,description,CountryCode,first_year,last_year,nbyears,first_value, last_value, growth_percent, min_value, max_value, lr_a, lr_b, lr_percent_slope,data_quality,corr 
-- FROM worldbank_indicator wi
-- INNER JOIN worldbank_category wc ON wc.CATID=wi.CATID
-- INNER JOIN db_historical_country_summary ws ON wi.COUNTRYCODE = ws.COUNTRYCODE
-- WHERE wi.lang='FR'
-- ORDER BY category,wi.COUNTRYCODE;

DROP VIEW IF EXISTS v_indicator_description;
CREATE VIEW IF NOT EXISTS v_indicator_description
AS
SELECT ds.provider, dc.LANG, dc.Description as Category, did.IndicatorKey, did.Description as Indicator FROM db_indicator_in_category dic 
INNER JOIN db_category dc ON dc.CAT_ID = dic.CAT_ID
INNER JOIN db_indicator_description did ON did.IndicatorKey = dic.IndicatorKey AND dc.lang = did.lang
INNER JOIN db_dataset ds ON ds.SOURCE_ID = dc.SOURCE_ID 
ORDER BY dc.description;



COMMIT;
