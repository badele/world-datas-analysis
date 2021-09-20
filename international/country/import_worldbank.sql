.head on
.nullvalue NULL

BEGIN TRANSACTION;

--------------------------------------
-- Import indicator
--------------------------------------

DROP TABLE IF EXISTS "worldbank_indicator";
CREATE TABLE "worldbank_indicator" (
  "INDICATOR_CODE" TEXT,
  "INDICATOR_NAME" TEXT,
  "SOURCE_NOTE" TEXT,
  "SOURCE_ORGANIZATION" TEXT,

  PRIMARY KEY (INDICATOR_CODE)
);

INSERT INTO worldbank_indicator
SELECT * FROM x_downloaded_worldbank_indicator;


--------------------------------------
-- Import country
--------------------------------------

DROP TABLE IF EXISTS "worldbank_country";
CREATE TABLE "worldbank_country" (
  CountryCode TEXT,
  IndicatorCode TEXT,
  "year" INTEGER,
  "value" REAL,

  PRIMARY KEY (CountryCode,IndicatorCode, year)
);

INSERT INTO worldbank_country
SELECT * FROM x_downloaded_worldbank_country where value is not NULL;

--------------------------------------
-- Import country
--------------------------------------

DROP TABLE IF EXISTS "worldbank_country_indicators_summary";
CREATE TABLE "worldbank_country_indicators_summary" (
  CountryCode TEXT,
  IndicatorCode TEXT,
  "nb_years" INTEGER,
  "data_quality" REAL,
  "year_first" INTEGER,
  "year_last" INTEGER,
  "value_first" REAL,
  "value_min" REAL,
  "value_avg" REAL,
  "value_max" REAL,
  "value_last" REAL,
  "trend" REAL,
  "slope" REAL,

  PRIMARY KEY (CountryCode,IndicatorCode)
);


INSERT INTO worldbank_country_indicators_summary
SELECT CountryCode, 
IndicatorCode,
COUNT(year) - 1, 
ROUND(100.0*COUNT(year)/(CAST(strftime('%Y') AS decimal) - 1960.0),4) as nbyears, 
MIN(year) year_first, 
MAX(year) yaer_last, 
NULL value_first,
MIN(value) value_min, 
AVG(value) value_avg, 
MAX(value) value_max, 
NULL value_last,
NULL trend,
ROUND((COUNT(value) * SUM(year * value) - (SUM(year) * SUM(value))) / ((COUNT(value) * SUM(year * year)) - (SUM(year) * SUM(year))),4) slope
FROM worldbank_country wc
GROUP BY CountryCode, IndicatorCode;


-- First
UPDATE worldbank_country_indicators_summary as wu set value_first = (SELECT value
FROM worldbank_country wc where (wu.CountryCode = wc.CountryCode AND wu.IndicatorCode = wc.IndicatorCode AND wu.year_first = wc.year));  

-- Last
UPDATE worldbank_country_indicators_summary as wu set value_last = (SELECT value
FROM worldbank_country wc where (wu.CountryCode = wc.CountryCode AND wu.IndicatorCode = wc.IndicatorCode AND wu.year_last = wc.year));  

-- Trend
UPDATE worldbank_country_indicators_summary set trend = ROUND((value_last/value_first - 1) * 100,4);


--------------------------------------
-- all  period summaries
--------------------------------------

DROP TABLE IF EXISTS "worldbank_country_indicators_summary";
CREATE TABLE "worldbank_country_indicators_summary" (
  CountryCode TEXT,
  IndicatorCode TEXT,
  range TEXT,
  period TEXT,
  summary TEXT,
  value REAL,
  
  PRIMARY KEY (CountryCode,IndicatorCode,range,period,summary)
);

-- nb years
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'all' as range,
'all' as period,
'nb_years' as summary,
COUNT(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode
ORDER BY value DESC;

-- quality
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'quality' as sumary,
ROUND(100.0*COUNT(year)/(CAST(strftime('%Y') AS decimal) - 1960.0),4) as value
FROM worldbank_country wc
CROSS JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='nb_years'
GROUP BY wc.CountryCode,wc.IndicatorCode
ORDER BY value DESC;

-- min
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'all' as range,
'all' as period,
'year_first' as sumary,
min(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode
ORDER BY value DESC;

-- max
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'all' as range,
'all' as period,
'year_last' as sumary,
max(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode
ORDER BY value DESC;

-- value_first
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'value_first' as sumary,
wc.value as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='year_first'
WHERE wc.year = cs.value
GROUP BY wc.CountryCode,wc.IndicatorCode
ORDER BY value DESC;

-- value_last
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'value_last' as sumary,
wc.value as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='year_last'
WHERE wc.year = cs.value
GROUP BY wc.CountryCode,wc.IndicatorCode
ORDER BY value DESC;

-- linear regression a
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'all' as range,
'all' as period,
'linearregression_a' as summary,
ROUND((COUNT(value) * SUM(year * value) - (SUM(year) * SUM(value))) / ((COUNT(value) * SUM(year * year)) - (SUM(year) * SUM(year))),4) value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode
ORDER BY value DESC;

-- linear regression b
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'linearregression_b' as sumary,
(SUM(wc.value) / COUNT(wc.value)) - cs.value * (SUM(wc.year) / COUNT(wc.year)) as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='linearregression_a'
GROUP BY wc.CountryCode,wc.IndicatorCode
ORDER BY value DESC;

-- linear regression b
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'coef' as sumary,
(SUM(wc.value) / COUNT(wc.value)) - cs.value * (SUM(wc.year) / COUNT(wc.year)) as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='linearregression_a'
GROUP BY wc.CountryCode,wc.IndicatorCode
ORDER BY value DESC;

-- coef
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'all' as range,
'all' as period,
'corr' as summary,
SUM((wc.year-agg.avg_year)*(wc.value-agg.avg_value)) /
(SQRT(SUM(POW(wc.year,2))) * SQRT(SUM(POW(wc.value,2)))) as value
FROM worldbank_country wc,
 (SELECT
*, 
AVG(value) as avg_value,
AVG(year) as avg_year
FROM worldbank_country wc
GROUP BY CountryCode,IndicatorCode) as agg
WHERE  wc.CountryCode = agg.CountryCode AND
wc.IndicatorCode = agg.IndicatorCode
GROUP BY wc.CountryCode,wc.IndicatorCode;

--------------------------------------
-- decade summaries
--------------------------------------

-- nb years
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'nb_years' as summary,
COUNT(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode,year - (year % 10)
ORDER BY value DESC;

-- quality
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'quality' as sumary,
ROUND(100.0*COUNT(year)/(CAST(strftime('%Y') AS decimal) - 1960.0),4) as value
FROM worldbank_country wc
CROSS JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='nb_years'
GROUP BY wc.CountryCode,wc.IndicatorCode,year - (year % 10)
ORDER BY value DESC;

-- min
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'year_first' as sumary,
min(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode,year - (year % 10)
ORDER BY value DESC;

-- max
INSERT INTO worldbank_country_indicators_summary
SELECT 
CountryCode, 
IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'year_last' as sumary,
max(year) as value
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode,year - (year % 10)
ORDER BY value DESC;

-- value_first
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'value_first' as sumary,
wc.value as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='year_first'
WHERE wc.year = cs.value
GROUP BY wc.CountryCode,wc.IndicatorCode,year - (year % 10)
ORDER BY value DESC;

-- value_last
INSERT INTO worldbank_country_indicators_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
'decade' as range,
year - (year % 10) as period,
'value_last' as sumary,
wc.value as value
FROM worldbank_country wc
INNER JOIN worldbank_country_indicators_summary cs ON 
  wc.CountryCode = cs.CountryCode AND
  wc.IndicatorCode = cs.IndicatorCode AND
  cs.range='all' AND
  cs.period='all' AND
  cs.summary='year_last'
WHERE wc.year = cs.value
GROUP BY wc.CountryCode,wc.IndicatorCode,year - (year % 10)
ORDER BY value DESC;

DROP TABLE IF EXISTS "worldbank_country_category_summary";
CREATE TABLE "worldbank_country_category_summary" (
  CountryCode TEXT,
  IndicatorCode TEXT,
  "year_min" INTEGER,
  "value_min" REAL,
  "year_max" INTEGER,
  "value_max" REAL,

  PRIMARY KEY (CountryCode,IndicatorCode)
);

--------------------------------------
-- city view
--------------------------------------

DROP VIEW IF EXISTS v_worldbank_country;
CREATE VIEW IF NOT EXISTS v_geonames_city
AS
SELECT
  *
FROM geonames_allcuntries
WHERE geolevel='city';

COMMIT;

-- SELECT 
-- 'allperiods' as summary_type,
-- 'all' as period,
-- 'min' as sumary,
-- CountryCode, 
-- IndicatorCode, 
-- min(value) 
-- FROM worldbank_country
-- GROUP BY CountryCode,IndicatorCode; 

-- SELECT 
-- 'allperiods' as summary_type,
-- 'all' as period,
-- 'max' as sumary,
-- CountryCode, 
-- IndicatorCode, 
-- max(value) 
-- FROM worldbank_country
-- GROUP BY CountryCode,IndicatorCode; 

-- SELECT 
-- 'decades' as summary_type,
-- year - (year % 10),
-- 'min' as sumary,
-- CountryCode, 
-- IndicatorCode, 
-- min(value) 
-- FROM worldbank_country
-- GROUP BY CountryCode,IndicatorCode,year - (year % 10) 
-- ORDER by CountryCode,IndicatorCode,year;

-- SELECT wc.CountryCode, wc.IndicatorCode, MIN(wc.year) year_min, wcmin.value value_min, MAX(wc.year) yaer_max, wcmin.value value_max from worldbank_country wc 
-- INNER JOIN worldbank_country wcmin ON (wc.CountryCode = wcmin.CountryCode AND wc.IndicatorCode = wcmin.IndicatorCode AND wcmin.year = MIN(wc.year))
-- INNER JOIN worldbank_country wcmax ON (wc.CountryCode = wcmax.CountryCode AND wc.IndicatorCode = wcmax.IndicatorCode AND wcmax.year = MAX(wc.year))
-- GROUP BY wc.CountryCode,wc.IndicatorCode;


----
-- SELECT *,min(year),max(year),min(value),max(value) 
-- FROM worldbank_country
-- GROUP BY CountryCode,IndicatorCode,category,year_decade  LIMIT 10;

