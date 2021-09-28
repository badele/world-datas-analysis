.head on
.nullvalue NULL

PRAGMA synchronous = OFF;

-- SOURCE_ID=0022,

BEGIN TRANSACTION;

.read './dataset/init.sql'

-- provider info
INSERT OR REPLACE INTO db_dataset VALUES(100, 'geonames', 'http://download.geonames.org/export/dump','Creative Commons Attribution 4.0 (CC-BY 4.0)');

--------------------------------------
-- Import continent
--------------------------------------

DROP TABLE IF EXISTS "geonames_continent";
CREATE TABLE "geonames_continent" (
  "Continent_Key" TEXT,
  "Continent" TEXT,
  "GEOID" INTEGER,
  "SOURCE_ID" INTEGER,
  PRIMARY KEY (Continent_Key)
);

DROP TABLE IF EXISTS x_downloaded_geonames_continent;
.import --csv './downloaded/geonames/continent.csv' x_downloaded_geonames_continent

INSERT INTO geonames_continent
SELECT *,100 FROM x_downloaded_geonames_continent;

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
  "SOURCE_ID" INTEGER,
  PRIMARY KEY (GEOID)
);

DROP TABLE IF EXISTS x_downloaded_geonames_country;
.import --csv './downloaded/geonames/country.csv' x_downloaded_geonames_country

INSERT INTO geonames_country
SELECT *,100 FROM x_downloaded_geonames_country WHERE GEOID>0;

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
  "geolevel" TEXT,
  "SOURCE_ID" INTEGER,

  PRIMARY KEY (GEOID)
);

DROP TABLE IF EXISTS x_downloaded_geonames_allcuntries;
.import --csv './downloaded/geonames/allcuntries.csv' x_downloaded_geonames_allcuntries

-- drop indexes
DROP TABLE IF EXISTS geonames_allcuntries;

INSERT INTO geonames_allentries
SELECT *,100 FROM x_downloaded_geonames_allcuntries;

CREATE INDEX IF NOT EXISTS idx_geonames_name ON geonames_allentries(name);
CREATE INDEX IF NOT EXISTS idx_geonames_namecountrylevel ON geonames_allentries(name,countrycode,geolevel);
--CREATE INDEX idx_geonames_population ON geonames_allentries(population);

CREATE INDEX IF NOT EXISTS idx_geonames_countrycode ON geonames_allentries(countrycode);
CREATE INDEX IF NOT EXISTS idx_geonames_countrylevel ON geonames_allentries(countrycode,geolevel);
CREATE INDEX IF NOT EXISTS idx_geonames_geolevel ON geonames_allentries(geolevel);
CREATE INDEX IF NOT EXISTS idx_geonames_geolevel_name ON geonames_allentries(name,geolevel);
CREATE INDEX IF NOT EXISTS idx_geonames_featureclass ON geonames_allentries(featureclass);
CREATE INDEX IF NOT EXISTS idx_geonames_features ON geonames_allentries(featureclass,featurecode);

UPDATE geonames_allentries SET geolevel="continent" WHERE featureclass='L' and featurecode='CONT';
UPDATE geonames_allentries SET geolevel='country' where GEOID = (SELECT GEOID FROM x_downloaded_geonames_country WHERE geonames_allentries.GEOID = x_downloaded_geonames_country.GEOID);
UPDATE geonames_allentries SET geolevel="city" WHERE featureclass='P';

--------------------------------------
-- Drop downloaded tables
--------------------------------------

DROP TABLE IF EXISTS x_downloaded_geonames_continent;
DROP TABLE IF EXISTS x_downloaded_geonames_country;
DROP TABLE IF EXISTS x_downloaded_geonames_allcuntries;;

COMMIT;

