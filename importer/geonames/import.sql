.head on
.nullvalue NULL

PRAGMA synchronous = OFF;

BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Import continent
--------------------------------------

DROP TABLE IF EXISTS "geonames_continent";
CREATE TABLE "geonames_continent" (
  "Continent_Key" TEXT,
  "Continent" TEXT,
  "GEOID" INTEGER,
  PRIMARY KEY (Continent_Key)
);

.import --csv './downloaded/geonames/continent.csv' geonames_continent

--------------------------------------
-- Import country
--------------------------------------

DROP TABLE IF EXISTS "geonames_country";
CREATE TABLE "geonames_country" (
  "GEOID" INTEGER,
  "iso2" TEXT,
  "iso3" TEXT,
  "isonum" INTEGER,
  "fips" TEXT,
  "country" TEXT,
  "capital" TEXT,
  "area" REAL,
  "continent" TEXT,
  "tld" TEXT,
  "currencycode" TEXT,
  "currencyname" TEXT,
  "phone" TEXT,
  "postalcodeformat" TEXT,
  "postalcoderegex" TEXT,
  "language" TEXT,
  "neighbours" TEXT,
  "equivfipscode" TEXT,
  PRIMARY KEY (GEOID)
);

.import --csv --skip 1 './downloaded/geonames/country.csv' geonames_country

--------------------------------------
-- Import geoloc
--------------------------------------

DROP TABLE IF EXISTS "geonames_allentries";
CREATE TABLE "geonames_allentries" (
  "GEOID" INTEGER,
  "name" TEXT,
  "asciiname" TEXT,
--  "alternatenames" TEXT,
  "latitude" REAL,
  "longitude" REAL,
  "featureclass" TEXT,
  "featurecode" TEXT,
  "countrycode" TEXT,
  "cc2" TEXT,
  "adm1" TEXT,
  "adm2" TEXT,
  "adm3" TEXT,
  "adm4" TEXT,
  "elevation" TEXT,
  "dem" INTEGER,
  "timezone" TEXT,
  "lastupdate" TEXT,
  "scope" TEXT,

  PRIMARY KEY (GEOID)
);

.import --csv --skip 1 './downloaded/geonames/allcountries.csv' geonames_allentries

CREATE INDEX IF NOT EXISTS idx_geonames_name ON geonames_allentries(name);
CREATE INDEX IF NOT EXISTS idx_geonames_namecountrylevel ON geonames_allentries(name,countrycode,scope);
CREATE INDEX IF NOT EXISTS idx_geonames_countrycode ON geonames_allentries(countrycode);
CREATE INDEX IF NOT EXISTS idx_geonames_countrylevel ON geonames_allentries(countrycode,scope);
CREATE INDEX IF NOT EXISTS idx_geonames_scope ON geonames_allentries(scope);
CREATE INDEX IF NOT EXISTS idx_geonames_scope_name ON geonames_allentries(name,scope);
CREATE INDEX IF NOT EXISTS idx_geonames_featureclass ON geonames_allentries(featureclass);
CREATE INDEX IF NOT EXISTS idx_geonames_features ON geonames_allentries(featureclass,featurecode);

UPDATE geonames_allentries SET scope="continent" WHERE featureclass='L' and featurecode='CONT';
UPDATE geonames_allentries SET scope='country' where GEOID = (SELECT GEOID FROM geonames_country WHERE geonames_allentries.GEOID = geonames_country.GEOID);
UPDATE geonames_allentries SET scope="city" WHERE featureclass='P';

--------------------------------------
-- dataset summaries
--------------------------------------

INSERT OR REPLACE INTO wda_variable 
SELECT "geonames", "geonames", "Geonames database", trim(scope || " informations"), scope, "Geonames website", COUNT(*),15, COUNT(*) FROM  geonames_allentries gae
GROUP BY scope;

INSERT OR REPLACE INTO wda_dataset
SELECT provider,real_provider,dataset, max(nb_variables), sum(nb_observations),max(nb_scope) FROM wda_variable wv
WHERE provider="geonames"
GROUP BY provider,real_provider,dataset;

-- Summarize provider
INSERT OR REPLACE INTO wda_provider 
SELECT provider,  "Geonames entries", "https://download.geonames.org/export/dump", 0, max(nb_variables),sum(nb_observations),max(nb_scope)
FROM wda_variable wv
WHERE provider="geonames"
GROUP BY provider;

UPDATE wda_provider SET nb_datasets = (SELECT count() FROM wda_dataset WHERE provider='geonames')
WHERE provider='geonames';


-- UPDATE wda_dataset 
-- SET nb_scopes=(
--   SELECT COUNT() FROM geonames_allentries ga
--   WHERE ga.scope = wda_dataset.scope  
-- )
-- WHERE provider='geonames';

-- select featurecode,COUNT() from geonames_allentries 
-- where featureclass='A' AND  featurecode like 'ADM%' and featurecode not like '%H' and featurecode not like '%D'
-- GROUP by featurecode


-- UPDATE wda_dataset SET nb_variables=(SELECT count() FROM PRAGMA_TABLE_INFO('geonames_allentries'))
-- WHERE provider='geonames';

COMMIT;

