.head on
.nullvalue NULL

BEGIN TRANSACTION;

-- Drop Dependencies ressources
DROP VIEW IF EXISTS v_geonames_continent;


--------------------------------------
-- Import continent
--------------------------------------

DROP TABLE IF EXISTS "geonames_continent";
CREATE TABLE "geonames_continent" (
  "code" TEXT,
  "continent" TEXT,
  "GEOID" INTEGER,
  PRIMARY KEY (code)
);
CREATE INDEX idx_geonames_continent_geoid ON geonames_allcuntries(GEOID);

INSERT INTO geonames_continent
SELECT DISTINCT * FROM x_downloaded_geonames_continent AS c;

-- DROP TABLE IF EXISTS "geonames_continent_downloaded";

-- --------------------------------------
-- -- featureclass
-- --------------------------------------

-- DROP TABLE IF EXISTS "geonames_featureclass";
-- CREATE TABLE "geonames_featureclass" (
--   "code" TEXT,
--   "class_description" TEXT
-- )

-- INSERT INTO geonames_featureclass
-- SELECT DISTINCT * FROM geonames_featureclass_downloaded;

-- --------------------------------------
-- -- featurecode
-- --------------------------------------

-- DROP TABLE IF EXISTS "geonames_featurecode";
-- CREATE TABLE "geonames_featurecode" (
--   "code" TEXT,
--   "class_description" TEXT
-- )

-- INSERT INTO geonames_featurecode
-- SELECT DISTINCT * FROM geonames_featurecode_downloaded;




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
  "countrypopulation" INTEGER,
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

INSERT INTO geonames_country
SELECT * FROM x_downloaded_geonames_country;


--------------------------------------
-- Import all countries
--------------------------------------

DROP TABLE IF EXISTS "geonames_allcuntries";
CREATE TABLE "geonames_allcuntries" (
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
  "population" INTEGER,
  "elevation" TEXT,
  "dem" INTEGER,
  "timezone" TEXT,
  "lastupdate" TEXT,
  "geolevel" TEXT,
  "populationdate" DATE,
  "source" TEXT,

  PRIMARY KEY (GEOID)
);


INSERT INTO geonames_allcuntries
SELECT * FROM x_downloaded_geonames_allcuntries AS c;

CREATE INDEX idx_geonames_name ON geonames_allcuntries(name);
CREATE INDEX idx_geonames_namecountrylevel ON geonames_allcuntries(name,countrycode,geolevel);
CREATE INDEX idx_geonames_population ON geonames_allcuntries(population);

CREATE INDEX idx_geonames_countrycode ON geonames_allcuntries(countrycode);
CREATE INDEX idx_geonames_countrylevel ON geonames_allcuntries(countrycode,geolevel);

CREATE INDEX idx_geonames_geolevel ON geonames_allcuntries(geolevel);
CREATE INDEX idx_geonames_geolevel_name ON geonames_allcuntries(name,geolevel);
CREATE INDEX idx_geonames_featureclass ON geonames_allcuntries(featureclass);
CREATE INDEX idx_geonames_features ON geonames_allcuntries(featureclass,featurecode);


UPDATE geonames_allcuntries SET geolevel="continent" WHERE featureclass='L' and featurecode='CONT';
UPDATE geonames_allcuntries SET geolevel='country' where GEOID = (SELECT GEOID FROM x_downloaded_geonames_country WHERE geonames_allcuntries.GEOID = x_downloaded_geonames_country.GEOID);
UPDATE geonames_allcuntries SET geolevel="city" WHERE featureclass='P';

-- DROP TABLE IF EXISTS "geonames_allcuntries_downloaded";

--------------------------------------
-- Continent view
--------------------------------------

DROP VIEW IF EXISTS v_geonames_continent;
CREATE VIEW IF NOT EXISTS v_geonames_continent
AS
SELECT
  ct.GEOID,
  ct.code,
  ct.continent,

  ac.name,
  ac.asciiname,
--  ac.alternatenames,
  ac.latitude,
  ac.longitude,
  ac.featureclass,
  ac.featurecode,
  ac.countrycode,
  ac.cc2,
  ac.adm1,
  ac.adm2,
  ac.adm3,
  ac.adm4,
  ac.population,
  ac.elevation,
  ac.dem,
  ac.timezone,
  ac.lastupdate,
  ac.geolevel,
  ac.populationdate,
  ac.source


FROM geonames_continent ct
INNER JOIN geonames_allcuntries ac ON (ct.GEOID=ac.GEOID);

--------------------------------------
-- Country view
--------------------------------------


DROP VIEW IF EXISTS v_geonames_country;
CREATE VIEW IF NOT EXISTS v_geonames_country
AS
SELECT
  ct.continent as continentname,
  co.*,
  ac.name,
  ac.asciiname,
--  ac.alternatenames,
  ac.latitude,
  ac.longitude,
  ac.featureclass,
  ac.featurecode,
  ac.countrycode,
  ac.cc2,
  ac.adm1,
  ac.adm2,
  ac.adm3,
  ac.adm4,
  ac.population,
  ac.elevation,
  ac.dem,
  ac.timezone,
  ac.lastupdate,
  ac.geolevel,
  ac.populationdate,
  ac.source

FROM geonames_country co
INNER JOIN geonames_allcuntries ac ON co.GEOID = ac.GEOID
INNER JOIN geonames_continent ct ON ct.code = co.continent;

--------------------------------------
-- city view
--------------------------------------


DROP VIEW IF EXISTS v_geonames_city;
CREATE VIEW IF NOT EXISTS v_geonames_city
AS
SELECT
  *
FROM geonames_allcuntries
WHERE geolevel='city';

COMMIT;
