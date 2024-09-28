BEGIN;

\i './importer/init_psql.sql';

-------------------------------------------------------------------------------
-- Load data from Parquet files
-------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS public.duckdb_geonames_countries CASCADE;
CREATE FOREIGN TABLE public.duckdb_geonames_countries (
    iso text,
    iso3 text,
    iso_numeric integer,
    fips text,
    country text,
    capital text,
    area_km2 double precision,
    population bigint,
    continent text,
    tld text,
    currency_code text,
    currency_name text,
    phone_prefix text,
    languages text,
    postal_code_format text,
    postal_code_regex text,
    geonameid integer,
    neighbours text,
    equivalent_fips_code text,
    city_admin_level integer)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("./dataset/geonames/countries.parquet")'
)
;

DROP FOREIGN TABLE IF EXISTS public.duckdb_geonames_allentries CASCADE;
CREATE FOREIGN TABLE public.duckdb_geonames_allentries (
    geonames_fullcode text,
    id integer,
    "name" text,
    asciiname text,
    alternatenames text,
    latitude double precision,
    longitude double precision,
    feature_class text,
    feature_code text,
    country_code text,
    cc2 text,
    admin1_code text,
    admin2_code text,
    admin3_code text,
    admin4_code text,
    population bigint,
    elevation integer,
    dem integer,
    timezone text,
    modification text,
    admin1_fullcode text,
    admin2_fullcode text,
    admin3_fullcode text,
    admin4_fullcode text,
    admin1_id integer,
    admin2_id integer,
    admin3_id integer,
    admin4_id integer,
    admin1_name text,
    admin2_name text,
    admin3_name text,
    admin4_name text,
    city_admin_level integer)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("./dataset/geonames/allentries.parquet")'
)
;

-------------------------------------------------------------------------------
-- Copy data from DuckDB to Postgres tables
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS geonames_countries CASCADE;
DROP TABLE IF EXISTS geonames_allentries CASCADE;

CREATE TABLE geonames_countries AS TABLE duckdb_geonames_countries;
CREATE TABLE geonames_allentries AS TABLE duckdb_geonames_allentries;

-------------------------------------------------------------------------------
-- Create index
-------------------------------------------------------------------------------
CREATE INDEX idx_geonames_allentries_admin1 ON geonames_allentries (country_code, admin1_code);
CREATE INDEX idx_geonames_allentries_admin2 ON geonames_allentries (country_code, admin2_code);
CREATE INDEX idx_geonames_allentries_admin3 ON geonames_allentries (country_code, admin3_code);
CREATE INDEX idx_geonames_allentries_admin4 ON geonames_allentries (country_code, admin4_code);

CREATE UNIQUE INDEX idx_geonames_country_iso ON geonames_countries (iso);
CREATE UNIQUE INDEX idx_geonames_allentries_id ON geonames_allentries (id);

-------------------------------------------------------------------------------
-- Create view
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.wda_geonames_countries AS
SELECT
    gc.geonameid AS geonames_country_id,
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
FROM
    geonames_countries gc
    LEFT JOIN geonames_allentries ga ON gc.geonameid = ga.id
;
ALTER TABLE public.wda_geonames_countries OWNER TO wda;

-- CHECK COUNT CONTENT
SELECT
    'Check geonames wda_geonames_countries';

DO $$
DECLARE
    src_count int;
    dst_count int;
BEGIN
    -- Compter les lignes dans chaque table
    SELECT
        COUNT(*) INTO src_count
    FROM
        geonames_countries;
    SELECT
        COUNT(*) INTO dst_count
    FROM
        wda_geonames_countries;
    -- Comparer les résultats
    IF src_count != dst_count THEN
        RAISE EXCEPTION 'Les tables ne contiennent pas le même nombre de lignes : geonames_countries = %, wda_geonames_countries = %', src_count, dst_count;
    ELSE
        RAISE NOTICE 'La table wda_geonames_countries contient le même nombre de lignes que l''origine : %', src_count;
    END IF;
END
$$;

--------------------------------------
-- Cities
--------------------------------------
CREATE OR REPLACE VIEW public.wda_geonames_cities AS
WITH admin1 AS (
    SELECT
        geonames_allentries.admin1_id,
        geonames_allentries.admin1_name,
        geonames_allentries.latitude AS admin1_latitude,
        geonames_allentries.longitude AS admin1_longitude,
        geonames_allentries.feature_class AS admin1_feature_class,
        geonames_allentries.feature_code AS admin1_feature_code,
        geonames_allentries.country_code AS admin1_country_code,
        geonames_allentries.cc2 AS admin1_cc2,
        geonames_allentries.population AS admin1_population,
        geonames_allentries.elevation AS admin1_elevation,
        geonames_allentries.dem AS admin1_dem,
        geonames_allentries.timezone AS admin1_timezone,
        geonames_allentries.modification AS admin1_modification
    FROM
        geonames_allentries
    WHERE
        geonames_allentries.feature_class = 'A'::text
        AND geonames_allentries.feature_code = 'ADM1'::text
),
admin2 AS (
    SELECT
        geonames_allentries.admin2_id,
        geonames_allentries.admin2_name,
        geonames_allentries.latitude AS admin2_latitude,
        geonames_allentries.longitude AS admin2_longitude,
        geonames_allentries.feature_class AS admin2_feature_class,
        geonames_allentries.feature_code AS admin2_feature_code,
        geonames_allentries.country_code AS admin2_country_code,
        geonames_allentries.cc2 AS admin2_cc2,
        geonames_allentries.population AS admin2_population,
        geonames_allentries.elevation AS admin2_elevation,
        geonames_allentries.dem AS admin2_dem,
        geonames_allentries.timezone AS admin2_timezone,
        geonames_allentries.modification AS admin2_modification
    FROM
        geonames_allentries
    WHERE
        geonames_allentries.feature_class = 'A'::text
        AND geonames_allentries.feature_code = 'ADM2'::text
),
admin3 AS (
    SELECT
        geonames_allentries.admin3_id,
        geonames_allentries.admin3_name,
        geonames_allentries.latitude AS admin3_latitude,
        geonames_allentries.longitude AS admin3_longitude,
        geonames_allentries.feature_class AS admin3_feature_class,
        geonames_allentries.feature_code AS admin3_feature_code,
        geonames_allentries.country_code AS admin3_country_code,
        geonames_allentries.cc2 AS admin3_cc2,
        geonames_allentries.population AS admin3_population,
        geonames_allentries.elevation AS admin3_elevation,
        geonames_allentries.dem AS admin3_dem,
        geonames_allentries.timezone AS admin3_timezone,
        geonames_allentries.modification AS admin3_modification
    FROM
        geonames_allentries
    WHERE
        geonames_allentries.feature_class = 'A'::text
        AND geonames_allentries.feature_code = 'ADM3'::text
),
admin4 AS (
    SELECT
        geonames_allentries.admin4_id,
        geonames_allentries.admin4_name,
        geonames_allentries.latitude AS admin4_latitude,
        geonames_allentries.longitude AS admin4_longitude,
        geonames_allentries.feature_class AS admin4_feature_class,
        geonames_allentries.feature_code AS admin4_feature_code,
        geonames_allentries.country_code AS admin4_country_code,
        geonames_allentries.cc2 AS admin4_cc2,
        geonames_allentries.admin1_code,
        geonames_allentries.admin2_code,
        geonames_allentries.admin3_code,
        geonames_allentries.admin4_code,
        geonames_allentries.population AS admin4_population,
        geonames_allentries.elevation AS admin4_elevation,
        geonames_allentries.dem AS admin4_dem,
        geonames_allentries.timezone AS admin4_timezone,
        geonames_allentries.modification AS admin4_modification
    FROM
        geonames_allentries
    WHERE
        geonames_allentries.feature_class = 'A'::text
        AND geonames_allentries.feature_code = 'ADM4'::text
)
SELECT
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
    ga1.admin1_id,
    ga1.admin1_name,
    ga1.admin1_latitude,
    ga1.admin1_longitude,
    ga1.admin1_feature_class,
    ga1.admin1_feature_code,
    ga1.admin1_country_code,
    ga1.admin1_cc2,
    ga1.admin1_population,
    ga1.admin1_elevation,
    ga1.admin1_dem,
    ga1.admin1_timezone,
    ga1.admin1_modification,
    ga2.admin2_id,
    ga2.admin2_name,
    ga2.admin2_latitude,
    ga2.admin2_longitude,
    ga2.admin2_feature_class,
    ga2.admin2_feature_code,
    ga2.admin2_country_code,
    ga2.admin2_cc2,
    ga2.admin2_population,
    ga2.admin2_elevation,
    ga2.admin2_dem,
    ga2.admin2_timezone,
    ga2.admin2_modification,
    ga3.admin3_id,
    ga3.admin3_name,
    ga3.admin3_latitude,
    ga3.admin3_longitude,
    ga3.admin3_feature_class,
    ga3.admin3_feature_code,
    ga3.admin3_country_code,
    ga3.admin3_cc2,
    ga3.admin3_population,
    ga3.admin3_elevation,
    ga3.admin3_dem,
    ga3.admin3_timezone,
    ga3.admin3_modification,
    ga4.admin4_id,
    ga4.admin4_name,
    ga4.admin4_latitude,
    ga4.admin4_longitude,
    ga4.admin4_feature_class,
    ga4.admin4_feature_code,
    ga4.admin4_country_code,
    ga4.admin4_cc2,
    ga4.admin1_code,
    ga4.admin2_code,
    ga4.admin3_code,
    ga4.admin4_code,
    ga4.admin4_population,
    ga4.admin4_elevation,
    ga4.admin4_dem,
    ga4.admin4_timezone,
    ga4.admin4_modification,
    gc.geonames_country_id,
    gc.geonames_country_feature_class,
    gc.geonames_country_feature_code,
    gc.geonames_country_iso,
    gc.geonames_country_iso3,
    gc.geonames_country_country,
    gc.geonames_country_name,
    gc.geonames_country_capital,
    gc.geonames_country_population,
    gc.geonames_country_elevation,
    gc.geomames_dem,
    gc.geomames_currency_name,
    gc.geonames_country_phone_prefix,
    gc.geonames_country_postal_code_format,
    gc.geonames_country_postal_code_regex,
    gc.geonames_country_languages,
    gc.geonames_country_tld,
    gc.geonames_country_neighbours,
    gc.geonames_country_longitude,
    gc.geonames_country_latitude,
    gc.geonames_country_timezone,
    gc.geonames_country_modification,
    gc.geonames_country_city_admin_level
FROM
    geonames_allentries ga
    LEFT JOIN wda_geonames_countries gc ON ga.country_code = gc.geonames_country_iso
    LEFT JOIN admin1 ga1 ON ga1.admin1_id = ga.id
    LEFT JOIN admin2 ga2 ON ga2.admin2_id = ga.id
    LEFT JOIN admin3 ga3 ON ga3.admin3_id = ga.id
    LEFT JOIN admin4 ga4 ON ga4.admin4_id = ga.id
WHERE
    ga.feature_code = ANY (ARRAY['ADM1'::text, 'ADM2'::text, 'ADM3'::text, 'ADM4'::text])
;
ALTER TABLE public.wda_geonames_cities OWNER TO wda;

-- CHECK COUNT CONTENT
DO $$
DECLARE
    src_count int;
    dst_count int;
BEGIN
    -- Compter les lignes dans chaque table
    SELECT
        COUNT(*) INTO src_count
    FROM
        geonames_allentries
    WHERE
        feature_class = 'A'
        AND feature_code IN ('ADM1', 'ADM2', 'ADM3', 'ADM4');
    SELECT
        COUNT(*) INTO dst_count
    FROM
        wda_geonames_cities;
    -- Comparer les résultats
    IF src_count != dst_count THEN
        RAISE EXCEPTION 'Les tables ne contiennent pas le même nombre de lignes : geonames_allentries = %, wda_geonames_cities = %', src_count, dst_count;
    ELSE
        RAISE NOTICE 'La table wda_geonames_cities contient le même nombre de lignes que l''origine : %', src_count;
    END IF;
END
$$;

DELETE FROM wda_scopes_reference
WHERE provider = 'geonames'
    AND dataset = 'wda_geonames_cities';
DELETE FROM wda_scopes_reference
WHERE provider = 'geonames'
    AND dataset = 'wda_geonames_countries';
COMMIT;

--------------------------------------
-- wda_scopes_reference
--------------------------------------
BEGIN;
INSERT INTO wda_scopes_reference
SELECT
    'geonames',
    'wda_geonames_cities',
    'city',
    'https://geonames.org',
    (
        SELECT
            COUNT(*)
        FROM
            information_schema.columns
        WHERE
            table_name = 'wda_geonames_cities') AS nb_vars,
    (
        SELECT
            COUNT(*)
        FROM
            wda_geonames_cities) AS nb_entries
;

INSERT INTO wda_scopes_reference
SELECT
    'geonames',
    'wda_geonames_countries',
    'country',
    'https://geonames.org',
    (
        SELECT
            COUNT(*)
        FROM
            information_schema.columns
        WHERE
            table_name = 'wda_geonames_countries') AS nb_vars,
    (
        SELECT
            COUNT(*)
        FROM
            wda_geonames_countries) AS nb_entries
;
COMMIT;
