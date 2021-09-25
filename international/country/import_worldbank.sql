.head on
.nullvalue NULL

BEGIN TRANSACTION;


--------------------------------------
-- Import country
--------------------------------------

DROP TABLE IF EXISTS worldbank_country;
CREATE TABLE worldbank_country (
  CountryCode TEXT,
  IndicatorCode TEXT,
  "year" INTEGER,
  "value" REAL,

  PRIMARY KEY (CountryCode,IndicatorCode, year)
);

INSERT INTO worldbank_country
SELECT * FROM x_downloaded_worldbank_country where value is not NULL;


--------------------------------------
-- all  period summaries
--------------------------------------

DROP TABLE IF EXISTS worldbank_country_summary;
CREATE TABLE worldbank_country_summary (
  CountryCode TEXT,
  IndicatorCode TEXT,
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
  
  PRIMARY KEY (CountryCode,IndicatorCode)
);

INSERT INTO worldbank_country_summary
SELECT 
wc.CountryCode, 
wc.IndicatorCode, 
MIN(wc.year) AS first_year,
MAX(wc.year) AS last_year,
COUNT(wc.year) AS nbyears,
NULL AS first_value,
NULL AS last_value,
NULL AS growth_percent,
MIN(wc.value) AS min_value,
MAX(wc.value) AS max_value,
ROUND((COUNT(wc.value) * SUM(wc.year * wc.value) - (SUM(wc.year) * SUM(wc.value))) / ((COUNT(wc.value) * SUM(POW(wc.year,2))) - (SUM(wc.year) * SUM(wc.year))),4) AS lr_a,
(SUM(wc.value) / COUNT(wc.value)) - (ROUND((COUNT(wc.value) * SUM(wc.year * wc.value) - (SUM(wc.year) * SUM(wc.value))) / ((COUNT(wc.value) * SUM(POW(wc.year,2))) - (SUM(wc.year) * SUM(wc.year))),4)) * (SUM(wc.year) / COUNT(wc.year)) AS lr_b,
NULL AS lr_percent_slope,
ROUND(COUNT(wc.year) / wc1.nb_years * 100,2) AS data_quality,
SUM((wc.year-wc2.avg_year)*(wc.value-wc2.avg_value)) /
(SQRT(SUM(POW(wc.year-wc2.avg_year,2))) * SQRT(SUM(POW(wc.value-wc2.avg_value,2)))) AS corr
FROM worldbank_country wc,
 (SELECT
MAX(year) - MIN(year) + 1.0 nb_years, 
MIN(year) min_year,
MAX(year) max_year
FROM worldbank_country) wc1,
 (SELECT
 *,
AVG(value) AS avg_value,
AVG(year) AS avg_year
FROM worldbank_country
GROUP BY CountryCode,IndicatorCode) AS wc2
WHERE wc.CountryCode = wc2.CountryCode AND wc.IndicatorCode = wc2.IndicatorCode
GROUP BY wc.CountryCode,wc.IndicatorCode;

-- slope
UPDATE worldbank_country_summary AS wu SET lr_percent_slope=(
  SELECT ((2*lr_a+lr_b)-(lr_a+lr_b))/abs(lr_a+lr_b)*100 FROM worldbank_country_summary ws 
  WHERE wu.CountryCode = ws.CountryCode AND wu.IndicatorCode = ws.IndicatorCode
  );

-- first value
UPDATE worldbank_country_summary AS wu SET first_value=(
  SELECT value FROM worldbank_country wc 
  WHERE wu.CountryCode = wc.CountryCode AND wu.IndicatorCode = wc.IndicatorCode and wu.first_year = wc.year
  );

-- last value
UPDATE worldbank_country_summary AS wu SET last_value=(
  SELECT value FROM worldbank_country wc 
  WHERE wu.CountryCode = wc.CountryCode AND wu.IndicatorCode = wc.IndicatorCode and wu.last_year = wc.year
  );

-- Percent range
UPDATE worldbank_country_summary AS wu SET growth_percent=(
  SELECT (last_value - first_value) / ABS(first_value)*100 FROM worldbank_country wc 
  WHERE wu.CountryCode = wc.CountryCode AND wu.IndicatorCode = wc.IndicatorCode and wu.last_year = wc.year
  );




--------------------------------------
-- view
--------------------------------------

DROP VIEW IF EXISTS v_worldbank_country_summary;
CREATE VIEW IF NOT EXISTS v_worldbank_country_summary
AS
SELECT wi.IndicatorCode,category,description,CountryCode,first_year,last_year,nbyears,first_value, last_value, growth_percent, min_value, max_value, lr_a, lr_b, lr_percent_slope,data_quality,corr 
FROM worldbank_indicator wi
INNER JOIN worldbank_category wc ON wc.CATID=wi.CATID
INNER JOIN worldbank_country_summary ws ON wi.IndicatorCode = ws.IndicatorCode
WHERE wi.lang='FR'
ORDER BY category,wi.IndicatorCode;

--------------------------------------
-- Database summary 
--------------------------------------

CREATE TABLE IF NOT EXISTS db_summary (
  sourcename TEXT,
  description TEXT,
  value INTEGER,

  PRIMARY KEY (sourcename,description)
);

REPLACE INTO db_summary VALUES('worldbank','nb distinct indicators',(select  count(DISTINCT IndicatorCode) from worldbank_country_summary));
REPLACE INTO db_summary VALUES('worldbank','nb distinct french indicators',(SELECT count(*) FROM worldbank_indicator));
REPLACE INTO db_summary VALUES('worldbank','nb indicators values',(SELECT count(*) FROM worldbank_country));
COMMIT;
