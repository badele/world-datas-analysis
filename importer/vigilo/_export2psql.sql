BEGIN;

-- disable pager
\pset pager off

\i './importer/init_psql.sql';

DROP FOREIGN TABLE IF EXISTS duckdb_vigilo_categories CASCADE;
CREATE FOREIGN TABLE duckdb_vigilo_categories (
    id bigint,
    name text,
    name_en text,
    color text
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/vigilo/categories.parquet")'
)
;

DROP FOREIGN TABLE IF EXISTS duckdb_vigilo_scopes CASCADE;
CREATE FOREIGN TABLE duckdb_vigilo_scopes (
    id text,
    name text,
    display_name text,
    iso text,
    country text,
    department bigint,
    lat_min double precision,
    lat_max double precision,
    lon_min double precision,
    lon_max double precision,
    map_center_string text,
    map_zoom bigint,
    api_path text,
    map_url text,
    nominatim_urlbase text,
    contact_email text,
    tweet_content text,
    twitter text,
    backend_version text,
    geonames_admin_filter text,
    geonames_countryid bigint
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/vigilo/scopes.parquet")'
)
;

DROP FOREIGN TABLE IF EXISTS duckdb_vigilo_observations CASCADE;
CREATE FOREIGN TABLE duckdb_vigilo_observations (
    scopeid text,
    token text,
    ts bigint,
    latitude double precision,
    longitude double precision,
    address text,
    "comment" text,
    explanation text,
    catid bigint,
    approved bigint,
    cityname text,
    geonames_districtid bigint,
    geonames_district text,
    geonames_cityid bigint,
    geonames_city text
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/vigilo/observations.parquet/*/*.parquet")'
)
;
-------------------------------------------------------------------------------
-- Copy data from DuckDB to Postgres tables
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS vigilo_categories CASCADE;
DROP TABLE IF EXISTS vigilo_scopes CASCADE;
DROP TABLE IF EXISTS vigilo_observations CASCADE;

CREATE TABLE vigilo_categories AS TABLE duckdb_vigilo_categories;
CREATE TABLE vigilo_scopes AS TABLE duckdb_vigilo_scopes;
CREATE TABLE vigilo_observations AS TABLE duckdb_vigilo_observations;

-------------------------------------------------------------------------------
-- Create index
-------------------------------------------------------------------------------
CREATE UNIQUE INDEX idx_vigilo_categories_id ON vigilo_categories (id);
CREATE UNIQUE INDEX idx_vigilo_scopes_id ON vigilo_scopes (id);
CREATE UNIQUE INDEX idx_vigilo_observations_scopeid_token ON vigilo_observations (scopeid,token);
CREATE UNIQUE INDEX idx_vigilo_observations_token ON vigilo_observations (token);

CREATE INDEX idx_vigilo_observations_districtid ON vigilo_observations (geonames_districtid);

SELECT
    'Check vigilo_scopes';

SELECT * FROM vigilo_scopes WHERE geonames_countryid IS NULL;
-- DO $$
-- DECLARE
--     src_count int;
-- BEGIN
--     -- Compter les lignes dans chaque table
--     SELECT
--         count(*) INTO src_count
--     FROM
--         vigilo_scopes
--     WHERE
--         geonames_countryid IS NULL;
--
--     -- Comparer les résultats
--     IF src_count > 0 THEN
--         RAISE EXCEPTION 'Certains scopes n''ont pas de villes lié avec la reference geonames';
--     END IF;
-- END
-- $$;


SELECT
    'Check vigilo_observations';

SELECT '"' || cityname || '"' ,count(*) AS nb FROM vigilo_observations WHERE geonames_cityid IS NULL GROUP BY cityname ORDER BY nb DESC;
-- DO $$
-- DECLARE
--     src_count int;
-- BEGIN
--     -- Compter les lignes dans chaque table
--     SELECT
--         count(*) INTO src_count
--     FROM
--         vigilo_observations
--     WHERE
--         geonames_cityid IS NULL;
--
--     -- Comparer les résultats
--     IF src_count > 0 THEN
--         RAISE EXCEPTION 'Certaines observations n''ont pas de villes lié avec la reference geonames';
--     END IF;
-- END
-- $$;

-- DROP VIEW IF EXISTS wda_vigilo_observations;
-- CREATE VIEW wda_vigilo_observations AS
--     SELECT
--         token AS obs_token,
--         ts AS obs_ts,
--         vo.latitude AS obs_latitude,
--         vo.longitude AS obs_longitude,
--         address AS obs_address,
--         "comment" AS obs_comment,
--         explanation AS obs_explanation,
--         catid AS obs_catid,
--         vc.name AS cat_name ,
--         approved AS obs_approved,
--         cityname AS obs_cityname,
--         geonames_districtid AS obs_districtid,
--         geonames_district AS obs_district,
--         geonames_cityid AS obs_cityid,
--         geonames_city AS obs_city,
--         vo.scopeid AS obs_scopeid,
--         vs.display_name as scope_displayname,
--         --
--         gc.*
--     FROM vigilo_observations vo
--     LEFT JOIN vigilo_categories vc ON vo.catid=vc.id
--     LEFT JOIN vigilo_scopes vs ON vo.scopeid=vs.id
--     LEFT JOIN wda_geonames_cities gc ON vo.geonames_districtid=gc.geonames_id
--     WHERE vo.geonames_districtid IS NOT NULL
-- ;

DROP MATERIALIZED VIEW IF EXISTS wda_vigilo_observations;
CREATE MATERIALIZED VIEW wda_vigilo_observations AS
 SELECT vo.token AS obs_token,
    vo.ts AS obs_ts,
    vo.latitude AS obs_latitude,
    vo.longitude AS obs_longitude,
    vo.address AS obs_address,
    vo.comment AS obs_comment,
    vo.explanation AS obs_explanation,
    vo.catid AS obs_catid,
    vc.name AS cat_name,
    vo.approved AS obs_approved,
    vo.cityname AS obs_cityname,
    vo.geonames_districtid AS obs_districtid,
    vo.geonames_district AS obs_district,
    vo.geonames_cityid AS obs_cityid,
    vo.geonames_city AS obs_city,
    vo.scopeid AS obs_scopeid,
    vs.display_name AS scope_displayname,
    gc.*
   FROM vigilo_observations vo
     LEFT JOIN vigilo_categories vc ON vo.catid = vc.id
     LEFT JOIN vigilo_scopes vs ON vo.scopeid = vs.id
     LEFT JOIN wda_geonames_cities gc ON vo.geonames_districtid = gc.geonames_id
  WHERE vo.geonames_districtid IS NOT NULL
;


CREATE INDEX idx_geonames_name ON wda_vigilo_observations (geonames_name);
CREATE INDEX idx_geonames_admin4_name ON wda_vigilo_observations (geonames_admin4_name);
CREATE INDEX idx_geonames_admin3_name ON wda_vigilo_observations (geonames_admin3_name);
CREATE INDEX idx_geonames_admin2_name ON wda_vigilo_observations (geonames_admin2_name);
CREATE INDEX idx_geonames_admin1_name ON wda_vigilo_observations (geonames_admin1_name);

-------------------------------------------------------------------------------
-- wda informations
-------------------------------------------------------------------------------
DELETE FROM wda_scopes WHERE provider='vigilo' AND dataset='wda_vigilo_observations';
DELETE FROM wda_datasets WHERE provider='vigilo' AND dataset='wda_vigilo_observations';
DELETE FROM wda_providers WHERE provider='vigilo';

INSERT INTO wda_scopes
    SELECT 'vigilo' AS source, 'wda_vigilo_observations' AS tablename, 'city' AS scope, 'wda_geonames_cities' AS tablesource, obs_city, COUNT(*)
    FROM wda_vigilo_observations ci
    WHERE obs_districtid IS NOT NULL
    GROUP BY obs_city
;

INSERT INTO wda_datasets
    SELECT
        'vigilo',
        'vigilo',
        'wda_vigilo_observations',
        'city',
        'wda_geonames_cities',
        'vigilo citizen observations',
        'https://vigilo.city',
        (SELECT count(*)
FROM pg_attribute a
  JOIN pg_class t on a.attrelid = t.oid
  JOIN pg_namespace s on t.relnamespace = s.oid
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND t.relname = 'wda_vigilo_observations'),
        COUNT(*),
        COUNT(DISTINCT geonames_name)
    FROM wda_vigilo_observations
;

INSERT INTO wda_providers
    SELECT
        'vigilo',
        'Observations of the collaborative citizen application',
        'https://vigilo.city',
        COUNT(*),
        SUM(nb_observations)
    FROM wda_datasets wd
    WHERE provider = 'vigilo';

COMMIT;
