BEGIN TRANSACTION;
--------------------------------------
-- Index
--------------------------------------

CREATE UNIQUE INDEX geonames_allentries_idx ON geonames_allentries (id);

--------------------------------------
-- Country
--------------------------------------
CREATE OR REPLACE VIEW wda_geonames_countries AS
  SELECT  ga.id AS countryid,
          ga.feature_class,
          ga.feature_code,
          gc.iso,
          gc.iso3,
          gc.country,
          ga.name,
          gc.capital,
          ga.population,
          ga.elevation,
          ga.dem,
          gc.currency_name,
          gc.phone_prefix,
          gc.languages,
          gc.tld,
          gc.neighbours,
          ga.longitude,
          ga.latitude,
          ga.timezone,
          ga.modification
  FROM geonames_countries gc
  LEFT JOIN geonames_allentries ga ON geonameid = ga.id;

--------------------------------------
-- Admin1
--------------------------------------
CREATE OR REPLACE VIEW wda_geonames_admin1codes AS
  SELECT code,
  ga.*
  FROM geonames_admin1codes
  LEFT JOIN geonames_allentries ga ON ga.id = geonames_admin1codes.geonameid
  WHERE code like 'FR.%';

--------------------------------------
-- Admin2
--------------------------------------
CREATE OR REPLACE VIEW wda_geonames_admin2codes AS
  SELECT code,
  ga.*
  FROM geonames_admin1codes
  LEFT JOIN geonames_allentries ga ON ga.id = geonames_admin1codes.geonameid
  WHERE code like 'FR.%';


--------------------------------------
-- Cities
--------------------------------------
CREATE OR REPLACE VIEW wda_geonames_cities AS
  SELECT
          -- City
          ga.id AS cityid,
          ga.feature_class,
          ga.feature_code,
          ga.admin1_code,
          ga.admin2_code,
          ga.admin3_code,
          ga.admin4_code,
          ga.name,
          ga.population,
          ga.longitude,
          ga.latitude,
          ga.elevation,
          ga.dem,
          ga.timezone,
          ga.modification,
          -- admin1
          ga1.id AS admin1id,
          ga1.feature_class AS admin1_feature_class,
          ga1.feature_code AS admin1_feature_code,
          ga1.name AS admin1_name,
          ga1.population AS admin1_population,
          ga1.longitude AS admin1_longitude,
          ga1.latitude AS admin1_latitude,
          ga1.elevation AS admin1_elevation,
          ga1.dem AS admin1_dem,
          ga1.timezone AS admin1_timezone,
          ga1.modification AS admin1_modification,
          -- admin2
          ga2.id AS admin2id,
          ga2.feature_class AS admin2_feature_class,
          ga2.feature_code AS admin2_feature_code,
          ga2.name AS admin2_name,
          ga2.population AS admin2_population,
          ga2.longitude AS admin2_longitude,
          ga2.latitude AS admin2_latitude,
          ga2.elevation AS admin2_elevation,
          ga2.dem AS admin2_dem,
          ga2.timezone AS admin2_timezone,
          ga2.modification AS admin2_modification,
          -- admin3
          ga3.id AS admin3id,
          ga3.feature_class AS admin3_feature_class,
          ga3.feature_code AS admin3_feature_code,
          ga3.name AS admin3_name,
          ga3.population AS admin3_population,
          ga3.longitude AS admin3_longitude,
          ga3.latitude AS admin3_latitude,
          ga3.elevation AS admin3_elevation,
          ga3.dem AS admin3_dem,
          ga3.timezone AS admin3_timezone,
          ga3.modification AS admin3_modification,
          -- admin4
          ga4.id AS admin4id,
          ga4.feature_class AS admin4_feature_class,
          ga4.feature_code AS admin4_feature_code,
          ga4.name AS admin4_name,
          ga4.population AS admin4_population,
          ga4.longitude AS admin4_longitude,
          ga4.latitude AS admin4_latitude,
          ga4.elevation AS admin4_elevation,
          ga4.dem AS admin4_dem,
          ga4.timezone AS admin4_timezone,
          ga4.modification AS admin4_modification,
          -- Country
          gc.countryid,
          gc.feature_class AS country_feature_class,
          gc.feature_code AS country_feature_code,
          gc.iso AS country_iso,
          gc.iso3 AS country_iso3,
          gc.country AS country_country,
          gc.name AS country_name,
          gc.capital AS country_capital,
          gc.population AS country_population,
          gc.currency_name AS country_currency_name,
          gc.phone_prefix AS country_phone_prefix,
          gc.languages AS country_languages,
          gc.tld AS country_tld,
          gc.neighbours AS country_neighbours,
          gc.longitude AS country_longitude,
          gc.latitude AS country_latitude,
          gc.elevation AS country_elevation,
          gc.dem AS country_dem,
          gc.timezone AS country_timezone,
          gc.modification AS country_modification,
  FROM geonames_allentries ga
  LEFT JOIN wda_geonames_countries gc ON ga.country_code = gc.iso
  LEFT JOIN geonames_allentries ga1 ON ga.country_code = ga1.country_code AND ga.admin1_code = ga1.admin1_code AND ga1.feature_code = 'ADM1'
  LEFT JOIN geonames_allentries ga2 ON ga.country_code = ga2.country_code AND ga.admin2_code = ga2.admin2_code AND ga2.feature_code = 'ADM2'
  LEFT JOIN geonames_allentries ga3 ON ga.country_code = ga3.country_code AND ga.admin3_code = ga3.admin3_code AND ga3.feature_code = 'ADM3'
  LEFT JOIN geonames_allentries ga4 ON ga.country_code = ga4.country_code AND ga.admin4_code = ga4.admin4_code AND ga4.feature_code = 'ADM4'
;

DELETE FROM wda_scopes_reference WHERE provider='geonames' AND dataset='wda_geonames_cities';
DELETE FROM wda_scopes_reference WHERE provider='geonames' AND dataset='wda_geonames_countries';

COMMIT;

BEGIN TRANSACTION;


INSERT INTO wda_scopes_reference
    SELECT 'geonames','wda_geonames_cities', 'city', (SELECT column_count FROM duckdb_views WHERE view_name='wda_geonames_cities') as nb_vars, (select count(*) from wda_geonames_cities) as nb_entries
;

INSERT INTO wda_scopes_reference
    SELECT 'geonames','wda_geonames_countries', 'country', (SELECT column_count FROM duckdb_views WHERE view_name='wda_geonames_countries') as nb_vars, (select count(*) from wda_geonames_countries) as nb_entries
;

COMMIT;
