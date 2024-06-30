BEGIN TRANSACTION;

.mode table
SELECT 'dr5hn' AS 'Importing';

-------------------------------------------------------------------------------
-- Import downloaded data
-------------------------------------------------------------------------------

-- cities
CREATE OR REPLACE TABLE dr5hn_cities AS
-- city_id INTEGER,
-- "city" TEXT,
-- lat DOUBLE,
-- lon DOUBLE,
-- wikidata_id TEXT,
-- state_id INTEGER,
-- country_id TEXT
-- );
--
-- INSERT INTO dr5hn_cities
  -- SELECT id, "name",latitude,longitude,wikiDataId,state_id, country_id
  SELECT *
  FROM read_json_auto('./downloaded/dr5hn/cities.json');
DELETE FROM dr5hn_cities WHERE id=149236;
-- CREATE UNIQUE INDEX dr5hn_cities_idx ON dr5hn_cities (id);

--countries
CREATE OR REPLACE TABLE dr5hn_countries AS
--   country_id INTEGER,
--   numcode INTEGER,
--   iso3 TEXT,
--   iso2 TEXT,
--   "country" TEXT,
--   capital TEXT,
--   nationality TEXT,
--   phone TEXT,
--   tld TEXT,
--   region_id INTEGER,
--   subregion_id INTEGER
-- );

-- INSERT INTO dr5hn_countries
  -- SELECT id, numeric_code, iso3, iso2, name, capital, nationality, phone_code, tld,region_id, subregion_id
  SELECT *
  FROM read_json_auto('./downloaded/dr5hn/countries.json');
-- CREATE UNIQUE INDEX dr5hn_countries_idx ON dr5hn_countries (iso2);

-- regions
CREATE OR REPLACE TABLE dr5hn_regions AS
--   region_id INTEGER,
--   "region" TEXT,
--   wikidata_id TEXT
-- );
-- INSERT INTO dr5hn_regions
  -- SELECT id, name, wikiDataId
  SELECT *
  FROM read_json_auto('./downloaded/dr5hn/regions.json');
-- CREATE UNIQUE INDEX dr5hn_regions_idx ON dr5hn_regions (id);

-- states
CREATE OR REPLACE TABLE dr5hn_states AS
--   state_id INTEGER,
--   "state" TEXT,
--   state_code TEXT,
--   "type" TEXT,
--   lat DOUBLE,
--   lon DOUBLE,
--   country_id INTEGER
--
-- );
-- INSERT INTO dr5hn_states
  -- SELECT id, name, state_code, type, latitude, longitude, country_id
  SELECT *
  FROM read_json_auto('./downloaded/dr5hn/states.json');
-- CREATE UNIQUE INDEX dr5hn_states_idx ON dr5hn_states (id);

-- subregions
CREATE OR REPLACE TABLE dr5hn_subregions AS
--   subregion_id INTEGER,
--   "subregion" TEXT,
--   region_id INTEGER,
--   wikidata_id TEXT
-- );
-- INSERT INTO dr5hn_subregions
  -- SELECT id, name, region_id, wikiDataId
  SELECT *
  FROM read_json_auto('./downloaded/dr5hn/subregions.json');
-- CREATE UNIQUE INDEX dr5hn_subregions_idx ON dr5hn_subregions (id);

-------------------------------------------------------------------------------
-- Convert
-------------------------------------------------------------------------------

-- -- Regions
-- CREATE OR REPLACE TABLE wda_dr5hn_regions AS
--     SELECT
--         region,
--         wikidata_id
--         FROM dr5hn_regions;
--
-- -- Subregions
-- CREATE OR REPLACE TABLE wda_dr5hn_subregions AS
--     SELECT
--         subregion,
--         region,
--         sr.wikidata_id
--         FROM dr5hn_subregions sr
--         LEFT JOIN dr5hn_regions r ON sr.region_id = r.region_id;
--
-- -- Countries
-- CREATE OR REPLACE TABLE wda_dr5hn_countries AS
-- SELECT
--         country,
--         subregion,
--         region,
--         capital,
--         iso2,
--         iso3,
--         numcode
--     FROM dr5hn_countries co
--     LEFT JOIN dr5hn_regions re ON re.region_id=co.region_id
--     LEFT JOIN dr5hn_subregions sr ON sr.subregion_id=co.subregion_id;
--
-- -- Cities
-- CREATE OR REPLACE TABLE wda_dr5hn_cities AS
-- SELECT
--         ci.city,
--         ci.lat,
--         ci.lon,
--         st.state,
--         st.state_code,
--         st.lat AS state_lat,
--         st.lon AS state_lon,
--         type,
--         iso2,
--         country,
--         subregion,
--         region,
--         ci.wikidata_id
--     FROM dr5hn_cities ci
--     LEFT JOIN dr5hn_states st ON ci.state_id=st.state_id
--     LEFT JOIN dr5hn_countries co ON ci.country_id=co.country_id
--     LEFT JOIN dr5hn_regions re ON re.region_id=co.region_id
--     LEFT JOIN dr5hn_subregions sr ON sr.subregion_id=co.subregion_id;
--
-- -- state
-- CREATE OR REPLACE TABLE wda_dr5hn_states AS
--     SELECT
--         state,
--         country,
--         type,
--         lat,
--         lon,
--         state_code
--     FROM dr5hn_states
--     LEFT JOIN dr5hn_countries co ON dr5hn_states.country_id=co.country_id;
--
--
-- -------------------------------------------------------------------------------
-- -- export to ./dataset
-- -------------------------------------------------------------------------------
--
-- COPY wda_dr5hn_regions TO './dataset/dr5hn/regions.csv' (DELIMITER '|', HEADER);
-- COPY wda_dr5hn_subregions TO './dataset/dr5hn/subregions.csv' (DELIMITER '|', HEADER);
-- COPY wda_dr5hn_countries TO './dataset/dr5hn/countries.csv' (DELIMITER '|', HEADER);
-- COPY wda_dr5hn_states TO './dataset/dr5hn/states.csv' (DELIMITER '|', HEADER);
-- COPY wda_dr5hn_cities TO './dataset/dr5hn/cities.csv' (DELIMITER '|', HEADER);

-------------------------------------------------------------------------------
-- Drop unused table
-------------------------------------------------------------------------------

-- DROP TABLE dr5hn_regions;
-- DROP TABLE dr5hn_subregions;
-- DROP TABLE dr5hn_countries;
-- DROP TABLE dr5hn_states;
-- DROP TABLE dr5hn_cities;

.read './importer/dr5hn/_commons.sql'

COMMIT;
