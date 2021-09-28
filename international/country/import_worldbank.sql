--------------------------------------
-- Indicator
--------------------------------------
.head on
.nullvalue NULL

BEGIN TRANSACTION;

-- import
DROP TABLE IF EXISTS x_worldbank_serie;
.mode csv x_worldbank_serie
.import '/tmp/worldbank/WDISeries.csv' x_worldbank_serie

-- convert
DROP TABLE IF EXISTS worldbank_serie;
CREATE TABLE worldbank_indicator(
  LANG TEXT,
  INDICATORCODE TEXT,
  topic TEXT,
  IndicatorName TEXT,
  PRIMARY KEY (LANG,INDICATORNAME)
);

INSERT INTO worldbank_indicator
SELECT 
'EN',
"IndicatorCode",
"Topic",
"Indicator Name"
FROM x_worldbank_serie;

DROP TABLE x_worldbank_serie;


--------------------------------------
-- Import country
--------------------------------------

-- import
DROP TABLE IF EXISTS worldbank_country;
.mode csv worldbank_country
.import '/tmp/worldbank/WDICountry.csv' worldbank_country

--------------------------------------
-- Import datas
--------------------------------------

-- import
DROP TABLE IF EXISTS x_worldbank_datas;
.mode csv x_worldbank_datas
.import '/tmp/worldbank/WDIData_Pivot.csv' x_worldbank_datas

-- convert
DROP TABLE IF EXISTS worldbank_datas;
CREATE TABLE worldbank_datas(
  COUNTRYCODE TEXT,
  INDICATORCODE TEXT,
  YEAR INTEGER,
  value REAL,
  PRIMARY KEY (COUNTRYCODE,INDICATORCODE,YEAR)
);

INSERT INTO worldbank_datas
SELECT * FROM x_worldbank_datas;

DROP TABLE IF EXISTS x_worldbank_datas;


-- DROP TABLE IF EXISTS worldbank_country;
-- CREATE TABLE worldbank_country (
--   CountryCode TEXT,
--   IndicatorCode TEXT,
--   "year" INTEGER,
--   "value" REAL,

--   PRIMARY KEY (CountryCode,IndicatorCode, year)
-- );

-- INSERT INTO worldbank_country
-- SELECT * FROM x_downloaded_worldbank_country where value is not NULL;


--------------------------------------
-- all  period summaries
--------------------------------------

DROP TABLE IF EXISTS worldbank_datas_summary;
CREATE TABLE worldbank_datas_summary (
  COUNTRYCODE TEXT,
  INDICATORCODE TEXT,
  first_year INTEGER,
  last_year INTEGER,
  nbyears INTEGER,
  first_value REAL,
  last_value REAL,
  growth_percent REAL,
  min_value REAL,
  max_value REAL,
  lr_a REAL,
  lr_b REAL,
  lr_percent_slope REAL,
  data_quality REAL,
  corr REAL,
  
  PRIMARY KEY (COUNTRYCODE,INDICATORCODE)
);

INSERT INTO worldbank_datas_summary
SELECT 
wd.COUNTRYCODE, 
wd.INDICATORCODE, 
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
FROM worldbank_datas wd,
 (SELECT
MAX(YEAR) - MIN(YEAR) + 1.0 nb_years, 
MIN(YEAR) min_year,
MAX(YEAR) max_year
FROM worldbank_datas) wd1,
 (SELECT
 *,
AVG(value) AS avg_value,
AVG(YEAR) AS avg_year
FROM worldbank_datas
GROUP BY COUNTRYCODE,INDICATORCODE) AS wd2
WHERE wd.COUNTRYCODE = wd2.COUNTRYCODE AND wd.INDICATORCODE = wd2.INDICATORCODE
GROUP BY wd.COUNTRYCODE,wd.INDICATORCODE;

-- slope
UPDATE worldbank_datas_summary AS wu SET lr_percent_slope=(
  SELECT ((2*lr_a+lr_b)-(lr_a+lr_b))/abs(lr_a+lr_b)*100 FROM worldbank_datas_summary ws 
  WHERE wu.COUNTRYCODE = ws.COUNTRYCODE AND wu.INDICATORCODE = ws.INDICATORCODE
  );

-- first value
UPDATE worldbank_datas_summary AS wu SET first_value=(
  SELECT value FROM worldbank_datas wd 
  WHERE wu.COUNTRYCODE = wd.COUNTRYCODE AND wu.COUNTRYCODE = wd.COUNTRYCODE and wu.first_year = wd.year
  );

-- last value
UPDATE worldbank_datas_summary AS wu SET last_value=(
  SELECT value FROM worldbank_datas wd 
  WHERE wu.COUNTRYCODE = wd.COUNTRYCODE AND wu.COUNTRYCODE = wd.COUNTRYCODE and wu.last_year = wd.year
  );

-- Percent range
UPDATE worldbank_datas_summary AS wu SET growth_percent=(
  SELECT (last_value - first_value) / ABS(first_value)*100 FROM worldbank_datas wd 
  WHERE wu.COUNTRYCODE = wd.COUNTRYCODE AND wu.COUNTRYCODE = wd.COUNTRYCODE and wu.last_year = wd.year
  );




--------------------------------------
-- view
--------------------------------------

DROP VIEW IF EXISTS v_worldbank_datas_summary;
CREATE VIEW IF NOT EXISTS v_worldbank_datas_summary
AS
SELECT wi.COUNTRYCODE,category,description,CountryCode,first_year,last_year,nbyears,first_value, last_value, growth_percent, min_value, max_value, lr_a, lr_b, lr_percent_slope,data_quality,corr 
FROM worldbank_indicator wi
INNER JOIN worldbank_category wc ON wc.CATID=wi.CATID
INNER JOIN worldbank_datas_summary ws ON wi.COUNTRYCODE = ws.COUNTRYCODE
WHERE wi.lang='FR'
ORDER BY category,wi.COUNTRYCODE;

COMMIT;
