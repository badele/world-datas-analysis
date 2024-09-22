BEGIN TRANSACTION;
--------------------------------------
-- Index
--------------------------------------

CREATE INDEX idx_geonames_allentries_admin1 ON geonames_allentries (country_code, admin1_code);
CREATE INDEX idx_geonames_allentries_admin2 ON geonames_allentries (country_code, admin2_code);
CREATE INDEX idx_geonames_allentries_admin3 ON geonames_allentries (country_code, admin3_code);
CREATE INDEX idx_geonames_allentries_admin4 ON geonames_allentries (country_code, admin4_code);

CREATE UNIQUE INDEX idx_geonames_country_iso ON geonames_countries (iso);
CREATE UNIQUE INDEX idx_geonames_allentries_id ON geonames_allentries (id);

-- CREATE INDEX idx_geonames_allentries_idx1 ON geonames_allentries (feature_code,admin1_code,country_code);

--------------------------------------
-- Country
--------------------------------------
DROP VIEW IF EXISTS wda_geonames_countries;
CREATE VIEW wda_geonames_countries AS
  SELECT  gc.geonameid AS geonames_country_id,
          ga.feature_class AS geonames_country_feature_class,
          ga.feature_code AS geonames_country_feature_code,
          gc.iso AS geonames_country_iso,
          gc.iso3 AS geonames_country_iso3,
          gc.country AS geonames_country_country,
          ga.name AS geonames_country_name,
          gc.capital AS geonames_country_capital,
          ga.population AS geonames_country_population,
          ga.elevation AS geonames_country_elevation,
          ga.dem AS geomames_dem,
          gc.currency_name AS geomames_currency_name,
          gc.phone_prefix AS geonames_country_phone_prefix,
          gc.postal_code_format AS geonames_country_postal_code_format,
          gc.postal_code_regex AS geonames_country_postal_code_regex,
          gc.languages AS geonames_country_languages,
          gc.tld AS geonames_country_tld,
          gc.neighbours AS geonames_country_neighbours,
          ga.longitude AS geonames_country_longitude,
          ga.latitude AS geonames_country_latitude,
          ga.timezone AS geonames_country_timezone,
          ga.modification AS geonames_country_modification,
          gc.city_admin_level AS geonames_country_city_admin_level

  FROM geonames_countries gc
  LEFT JOIN geonames_allentries ga ON gc.geonameid = ga.id
;
-- CHECK COUNT CONTENT
SELECT 'Check geonames wda_geonames_countries';
SELECT COUNT(*) FROM geonames_countries;
SELECT COUNT(*) FROM wda_geonames_countries;

--------------------------------------
-- Admin1
--------------------------------------
-- DROP VIEW IF EXISTS wda_geonames_admin1codes;
-- CREATE VIEW wda_geonames_admin1codes AS
--   SELECT code AS admin1_code,
--         ga.id AS admin1_id,
--         ga.name AS admin1_name,
--         ga.latitude AS admin1_latitude,
--         ga.longitude AS admin1_longitude,
--         ga.feature_class AS admin1_feature_class,
--         ga.feature_code AS admin1_feature_code,
--         ga.country_code AS admin1_country_code,
--         ga.cc2 AS admin1_cc2,
--         ga. admin1_code AS admin1_admin1_code,
--         ga.population AS admin1_population,
--         ga.elevation AS admin1_elevation,
--         ga.dem AS admin1_dem,
--         ga.timezone AS admin1_timezone,
--         ga.modification AS admin1_modification
--   FROM geonames_admin1codes
--   LEFT JOIN geonames_allentries ga ON ga.id = geonames_admin1codes.geonameid
-- ;

--------------------------------------
-- Admin2
--------------------------------------
-- DROP VIEW IF EXISTS wda_geonames_admin2codes;
-- CREATE VIEW wda_geonames_admin2codes AS
--   SELECT code AS admin2_code,
--         ga.id AS admin2_id,
--         ga.name AS admin2_name,
--         ga.latitude AS admin2_latitude,
--         ga.longitude AS admin2_longitude,
--         ga.feature_class AS admin2_feature_class,
--         ga.feature_code AS admin2_feature_code,
--         ga.country_code AS admin2_country_code,
--         ga.cc2 AS admin2_cc2,
--         ga. admin2_code AS admin2_admin2_code,
--         ga.population AS admin2_population,
--         ga.elevation AS admin2_elevation,
--         ga.dem AS admin2_dem,
--         ga.timezone AS admin2_timezone,
--         ga.modification AS admin2_modification
--   FROM geonames_admin2codes
--   LEFT JOIN geonames_allentries ga ON ga.id = geonames_admin2codes.geonameid
-- ;


--------------------------------------
-- Cities
--------------------------------------
DROP VIEW IF EXISTS wda_geonames_cities;
CREATE VIEW wda_geonames_cities AS
  WITH admin1 AS (
      SELECT
        admin1_id,
        admin1_name,
        latitude AS admin1_latitude,
        longitude AS admin1_longitude,
        feature_class AS admin1_feature_class,
        feature_code AS admin1_feature_code,
        country_code AS admin1_country_code,
        cc2 AS admin1_cc2,
        admin1_code AS admin1_code,
        population AS admin1_population,
        elevation AS admin1_elevation,
        dem AS admin1_dem,
        timezone AS admin1_timezone,
        modification AS admin1_modification
      FROM geonames_allentries
      WHERE feature_class='A' AND feature_code = 'ADM1'
  ),
  admin2 AS (
      SELECT
        admin2_id,
        admin2_name,
        latitude AS admin2_latitude,
        longitude AS admin2_longitude,
        feature_class AS admin2_feature_class,
        feature_code AS admin2_feature_code,
        country_code AS admin2_country_code,
        cc2 AS admin2_cc2,
        admin1_code AS admin1_code,
        admin2_code AS admin2_code,
        population AS admin2_population,
        elevation AS admin2_elevation,
        dem AS admin2_dem,
        timezone AS admin2_timezone,
        modification AS admin2_modification
      FROM geonames_allentries
      WHERE feature_class='A' AND feature_code = 'ADM2'
  ),
  admin3 AS (
      SELECT
        admin3_id,
        admin3_name,
        latitude AS admin3_latitude,
        longitude AS admin3_longitude,
        feature_class AS admin3_feature_class,
        feature_code AS admin3_feature_code,
        country_code AS admin3_country_code,
        cc2 AS admin3_cc2,
        admin1_code AS admin1_code,
        admin2_code AS admin2_code,
        admin3_code AS admin3_code,
        population AS admin3_population,
        elevation AS admin3_elevation,
        dem AS admin3_dem,
        timezone AS admin3_timezone,
        modification AS admin3_modification
      FROM geonames_allentries
      WHERE feature_class='A' AND feature_code = 'ADM3'
  ),
  admin4 AS (
      SELECT
        admin4_id,
        admin4_name,
        latitude AS admin4_latitude,
        longitude AS admin4_longitude,
        feature_class AS admin4_feature_class,
        feature_code AS admin4_feature_code,
        country_code AS admin4_country_code,
        cc2 AS admin4_cc2,
        admin1_code AS admin1_code,
        admin2_code AS admin2_code,
        admin3_code AS admin3_code,
        admin4_code AS admin4_code,
        population AS admin4_population,
        elevation AS admin4_elevation,
        dem AS admin4_dem,
        timezone AS admin4_timezone,
        modification AS admin4_modification
      FROM geonames_allentries
      WHERE feature_class='A' AND feature_code = 'ADM4'
  )
  SELECT
          -- City
          ga.geonames_fullcode AS geonames_geonames_fullcode,
          ga.id AS geonames_city_id,
          ga.name AS geonames_city_name,
          ga.country_code AS geonames_city_country_code,
          ga.feature_class AS geonames_city_feature_class,
          ga.feature_code AS geonames_city_feature_code,
          ga.admin1_code AS geonames_city_admin1_code,
          ga.admin2_code AS geonames_city_admin2_code,
          ga.admin3_code AS geonames_city_admin3_code,
          ga.admin4_code AS geonames_city_admin4_code,
          ga.population AS geonames_city_population,
          ga.longitude AS geonames_city_longitude,
          ga.latitude AS geonames_city_latitude,
          ga.elevation AS geonames_city_elevation,
          ga.dem AS geonames_city_dem,
          ga.timezone AS geonames_city_timezone,
          ga.modification AS geonames_city_modification,
          ga.city_admin_level AS geonames_city_city_admin_level,
          -- admin
          ga1.*,
          ga2.*,
          ga3.*,
          ga4.*,
          -- Country
          gc.*
  FROM geonames_allentries ga
  LEFT JOIN wda_geonames_countries gc ON ga.country_code = gc.geonames_country_iso
  LEFT JOIN admin1 ga1 ON ga1.admin1_id = ga.id
  LEFT JOIN admin2 ga2 ON ga2.admin2_id = ga.id
  LEFT JOIN admin3 ga3 ON ga3.admin3_id = ga.id
  LEFT JOIN admin4 ga4 ON ga4.admin4_id = ga.id
  WHERE ga.feature_code IN ('ADM1','ADM2','ADM3','ADM4')
;

-- CHECK COUNT CONTENT
SELECT 'Check geonames wda_geonames_cities';
SELECT COUNT() FROM geonames_allentries WHERE feature_class='A' AND feature_code IN ('ADM1','ADM2','ADM3','ADM4');
SELECT COUNT() FROM wda_geonames_cities;

DELETE FROM wda_scopes_reference WHERE provider='geonames' AND dataset='wda_geonames_cities';
DELETE FROM wda_scopes_reference WHERE provider='geonames' AND dataset='wda_geonames_countries';

COMMIT;

BEGIN TRANSACTION;


INSERT INTO wda_scopes_reference
  SELECT 'geonames','wda_geonames_cities', 'city', 'https://geonames.org', (SELECT column_count FROM duckdb_views WHERE view_name='wda_geonames_cities') as nb_vars, (select count(*) from wda_geonames_cities) as nb_entries
;

INSERT INTO wda_scopes_reference
  SELECT 'geonames','wda_geonames_countries', 'country', 'https://geonames.org', (SELECT column_count FROM duckdb_views WHERE view_name='wda_geonames_countries') as nb_vars, (select count(*) from wda_geonames_countries) as nb_entries
;

COMMIT;
