SET memory_limit = '5GB';
SET threads = 4;

-- Countries
DROP TABLE IF EXISTS geonames_countries;
CREATE TABLE geonames_countries (
    iso TEXT,
    iso3 TEXT,
    iso_numeric INTEGER,
    fips TEXT,
    country TEXT,
    capital TEXT,
    area_km2 DOUBLE,
    population BIGINT,
    continent TEXT,
    tld TEXT,
    currency_code TEXT,
    currency_name TEXT,
    phone_prefix TEXT,
    languages TEXT,
    postal_code_format TEXT,
    postal_code_regex TEXT,
    geonameid INTEGER,
    neighbours TEXT,
    equivalent_fips_code TEXT,
);

INSERT INTO geonames_countries
    SELECT  *
    -- GeoNames files are tab-separated and may contain literal quotes.
    FROM read_csv(
        './downloaded/geonames/countryInfo.txt',
        delim='\t',
        header=false,
        skip=50,
        quote='',
        columns={
            'iso': 'VARCHAR',
            'iso3': 'VARCHAR',
            'iso_numeric': 'INTEGER',
            'fips': 'VARCHAR',
            'country': 'VARCHAR',
            'capital': 'VARCHAR',
            'area_km2': 'DOUBLE',
            'population': 'BIGINT',
            'continent': 'VARCHAR',
            'tld': 'VARCHAR',
            'currency_code': 'VARCHAR',
            'currency_name': 'VARCHAR',
            'phone_prefix': 'VARCHAR',
            'postal_code_format': 'VARCHAR',
            'postal_code_regex': 'VARCHAR',
            'languages': 'VARCHAR',
            'geonameid': 'INTEGER',
            'neighbours': 'VARCHAR',
            'equivalent_fips_code': 'VARCHAR'
        }
    );

-------------------------------------------------------------------------------
-- Load raw entries (feature_class A=admin, P=populated places)
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS geonames_raw;
CREATE TABLE geonames_raw AS
    SELECT *
    FROM read_csv(
        './downloaded/geonames/allCountries.txt',
        delim='\t',
        header=false,
        quote='',
        columns={
            'id': 'INTEGER',
            'name': 'VARCHAR',
            'asciiname': 'VARCHAR',
            'alternatenames': 'VARCHAR',
            'latitude': 'DOUBLE',
            'longitude': 'DOUBLE',
            'feature_class': 'VARCHAR',
            'feature_code': 'VARCHAR',
            'country_code': 'VARCHAR',
            'cc2': 'VARCHAR',
            'admin1_code': 'VARCHAR',
            'admin2_code': 'VARCHAR',
            'admin3_code': 'VARCHAR',
            'admin4_code': 'VARCHAR',
            'population': 'BIGINT',
            'elevation': 'INTEGER',
            'dem': 'INTEGER',
            'timezone': 'VARCHAR',
            'modification': 'DATE'
        }
    )
    WHERE feature_class IN ('A', 'P');

-------------------------------------------------------------------------------
-- Compute admin fullcodes in one pass
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS geonames_with_fullcodes;
CREATE TABLE geonames_with_fullcodes AS
SELECT
    -- geonames_fullcode: identifier for ADM1/ADM2/ADM3/ADM4 records used as JOIN keys
    CASE feature_code
        WHEN 'ADM1' THEN country_code || '-' || COALESCE(admin1_code, '')
        WHEN 'ADM2' THEN country_code || '-' || COALESCE(admin1_code, '') || '-' || COALESCE(admin2_code, '')
        WHEN 'ADM3' THEN country_code || '-' || COALESCE(admin1_code, '') || '-' || COALESCE(admin2_code, '') || '-' || COALESCE(admin3_code, '')
        WHEN 'ADM4' THEN country_code || '-' || COALESCE(admin1_code, '') || '-' || COALESCE(admin2_code, '') || '-' || COALESCE(admin3_code, '') || '-' || COALESCE(admin4_code, '')
        ELSE NULL
    END AS geonames_fullcode,
    id,
    name,
    asciiname,
    latitude,
    longitude,
    feature_class,
    feature_code,
    country_code,
    cc2,
    admin1_code,
    admin2_code,
    admin3_code,
    admin4_code,
    population,
    elevation,
    dem,
    timezone,
    modification,
    -- admin fullcodes for JOIN
    CASE WHEN admin1_code IS NOT NULL THEN country_code || '-' || admin1_code END AS admin1_fullcode,
    CASE WHEN admin2_code IS NOT NULL THEN country_code || '-' || admin1_code || '-' || admin2_code END AS admin2_fullcode,
    CASE WHEN admin3_code IS NOT NULL THEN country_code || '-' || admin1_code || '-' || admin2_code || '-' || admin3_code END AS admin3_fullcode,
    CASE WHEN admin4_code IS NOT NULL THEN country_code || '-' || admin1_code || '-' || admin2_code || '-' || admin3_code || '-' || admin4_code END AS admin4_fullcode,
FROM geonames_raw;

DROP TABLE geonames_raw;

-------------------------------------------------------------------------------
-- Build lookup tables for ADM1–ADM4 (small, indexed in memory by DuckDB)
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS geonames_adm1_lkp;
CREATE TABLE geonames_adm1_lkp AS
    SELECT id, name, geonames_fullcode FROM geonames_with_fullcodes WHERE feature_code = 'ADM1';

DROP TABLE IF EXISTS geonames_adm2_lkp;
CREATE TABLE geonames_adm2_lkp AS
    SELECT id, name, geonames_fullcode FROM geonames_with_fullcodes WHERE feature_code = 'ADM2';

DROP TABLE IF EXISTS geonames_adm3_lkp;
CREATE TABLE geonames_adm3_lkp AS
    SELECT id, name, geonames_fullcode FROM geonames_with_fullcodes WHERE feature_code = 'ADM3';

DROP TABLE IF EXISTS geonames_adm4_lkp;
CREATE TABLE geonames_adm4_lkp AS
    SELECT id, name, geonames_fullcode FROM geonames_with_fullcodes WHERE feature_code = 'ADM4';

-------------------------------------------------------------------------------
-- Final table: resolve admin IDs and names in one hash-join pass
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS geonames_allentries;
CREATE TABLE geonames_allentries AS
SELECT
    ga.geonames_fullcode,
    ga.id,
    ga.name,
    ga.asciiname,
    ga.latitude,
    ga.longitude,
    ga.feature_class,
    ga.feature_code,
    ga.country_code,
    ga.cc2,
    ga.admin1_code,
    ga.admin2_code,
    ga.admin3_code,
    ga.admin4_code,
    ga.population,
    ga.elevation,
    ga.dem,
    ga.timezone,
    ga.modification,
    ga.admin1_fullcode,
    ga.admin2_fullcode,
    ga.admin3_fullcode,
    ga.admin4_fullcode,
    a1.id   AS admin1_id,
    a2.id   AS admin2_id,
    a3.id   AS admin3_id,
    a4.id   AS admin4_id,
    a1.name AS admin1_name,
    a2.name AS admin2_name,
    a3.name AS admin3_name,
    a4.name AS admin4_name,
    COALESCE(a4.id,   a3.id,   a2.id,   a1.id)   AS city_id,
    COALESCE(a4.name, a3.name, a2.name, a1.name) AS city_name
FROM geonames_with_fullcodes ga
LEFT JOIN geonames_adm1_lkp a1 ON ga.admin1_fullcode = a1.geonames_fullcode
LEFT JOIN geonames_adm2_lkp a2 ON ga.admin2_fullcode = a2.geonames_fullcode
LEFT JOIN geonames_adm3_lkp a3 ON ga.admin3_fullcode = a3.geonames_fullcode
LEFT JOIN geonames_adm4_lkp a4 ON ga.admin4_fullcode = a4.geonames_fullcode;

DROP TABLE geonames_with_fullcodes;
DROP TABLE geonames_adm1_lkp;
DROP TABLE geonames_adm2_lkp;
DROP TABLE geonames_adm3_lkp;
DROP TABLE geonames_adm4_lkp;

CREATE INDEX idx_geonames_allentries_lat_lon ON geonames_allentries (latitude, longitude);

COPY geonames_countries TO './dataset/geonames/raw/countries.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY geonames_allentries TO './dataset/geonames/raw/allentries.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', PARTITION_BY (country_code));
