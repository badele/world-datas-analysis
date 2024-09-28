BEGIN;

\i './importer/init_psql.sql';

DROP FOREIGN TABLE IF EXISTS public.duckdb_vigilo_categories CASCADE;
CREATE FOREIGN TABLE public.duckdb_vigilo_categories (
    id bigint,
    name text,
    name_en text,
    color text
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("./dataset/vigilo/categories.parquet")'
)
;

DROP FOREIGN TABLE IF EXISTS public.duckdb_vigilo_scopes CASCADE;
CREATE FOREIGN TABLE public.duckdb_vigilo_scopes (
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
    TABLE 'read_parquet("./dataset/vigilo/scopes.parquet")'
)
;

DROP FOREIGN TABLE IF EXISTS public.duckdb_vigilo_observations CASCADE;
CREATE FOREIGN TABLE public.duckdb_vigilo_observations (
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
    geonames_city_id bigint
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("./dataset/vigilo/observations.parquet")'
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

SELECT
    'Check vigilo_observations';

SELECT count(*) AS nb FROM vigilo_observations WHERE geonames_city_id IS NULL;
SELECT '"' || cityname || '"' ,count(*) AS nb FROM vigilo_observations WHERE geonames_city_id IS NULL GROUP BY cityname ORDER BY nb DESC;

DO $$
DECLARE
    src_count int;
BEGIN
    -- Compter les lignes dans chaque table
    SELECT
        count(*) INTO src_count
    FROM
        vigilo_observations
    WHERE
        geonames_city_id IS NULL;

    -- Comparer les résultats
    IF src_count > 0 THEN
        -- RAISE NOTICE 'City: %, Nb: % r.city, r.nb
        -- FROM (SELECT '"' || cityname || '"' AS city,count(*) AS nb FROM vigilo_observations WHERE geonames_city_id IS NULL GROUP BY cityname ORDER BY nb DESC) AS r;
        -- RAISE EXCEPTION 'Certaines villes ne sont pas lié avec la reference geonames';
    END IF;
END
$$;


COMMIT;
