BEGIN TRANSACTION;

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
    FROM read_csv('./downloaded/geonames/countryInfo.txt',skip=50);

DROP TABLE IF EXISTS geonames_allentries;
CREATE TABLE geonames_allentries (
    geonames_fullcode TEXT,
    id INTEGER,
    name TEXT,
    asciiname TEXT,
    alternatenames TEXT,
    latitude DOUBLE,
    longitude DOUBLE,
    feature_class TEXT,
    feature_code TEXT,
    country_code TEXT,
    cc2 TEXT,
    admin1_code TEXT,
    admin2_code TEXT,
    admin3_code TEXT,
    admin4_code TEXT,
    population BIGINT,
    elevation INTEGER,
    dem INTEGER,
    timezone TEXT,
    modification TEXT,
    admin1_fullcode TEXT,
    admin2_fullcode TEXT,
    admin3_fullcode TEXT,
    admin4_fullcode TEXT,
    admin1_id INTEGER,
    admin2_id INTEGER,
    admin3_id INTEGER,
    admin4_id INTEGER,
    admin1_name TEXT,
    admin2_name TEXT,
    admin3_name TEXT,
    admin4_name TEXT,
    city_id BIGINT,
    city_name TEXT
);

INSERT INTO geonames_allentries
    SELECT NULL,*,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM read_csv('./downloaded/geonames/allCountries.txt')
    WHERE column06 = 'A' or column06 = 'P'
;

-- Encoding problem in this field
ALTER TABLE geonames_allentries DROP COLUMN alternatenames;
CREATE INDEX idx_geonames_allentries_lat_lon ON geonames_allentries (latitude,longitude);

-------------------------------------------------------------------------------
-- Compute admin fullcodes
-------------------------------------------------------------------------------

UPDATE geonames_allentries
SET admin1_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '')
WHERE admin1_code IS NOT NULL
;

UPDATE geonames_allentries
SET admin2_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '')
WHERE admin2_code IS NOT NULL
;

UPDATE geonames_allentries
SET admin3_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '') || '-' ||
                 COALESCE(admin3_code, '')
WHERE admin3_code IS NOT NULL
;

UPDATE geonames_allentries
SET admin4_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '') || '-' ||
                 COALESCE(admin3_code, '') || '-' ||
                 COALESCE(admin4_code, '')
WHERE admin4_code IS NOT NULL
;

-------------------------------------------------------------------------------
-- Compute geonames fullcodes
-------------------------------------------------------------------------------
UPDATE geonames_allentries
SET geonames_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '')
WHERE feature_code='ADM1'
;

UPDATE geonames_allentries
SET geonames_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '')
WHERE feature_code='ADM2'
;

UPDATE geonames_allentries
SET geonames_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '') || '-' ||
                 COALESCE(admin3_code, '')
WHERE feature_code='ADM3'
;

UPDATE geonames_allentries
SET geonames_fullcode = COALESCE(country_code, '') || '-' ||
                 COALESCE(admin1_code, '') || '-' ||
                 COALESCE(admin2_code, '') || '-' ||
                 COALESCE(admin3_code, '') || '-' ||
                 COALESCE(admin4_code, '')
WHERE feature_code='ADM4'
;

UPDATE geonames_allentries ga set admin1_id=(SELECT id FROM geonames_allentries gsearch WHERE ga.admin1_fullcode = gsearch.geonames_fullcode ) WHERE ga.admin1_fullcode IS NOT NULL;
UPDATE geonames_allentries ga set admin2_id=(SELECT id FROM geonames_allentries gsearch WHERE ga.admin2_fullcode = gsearch.geonames_fullcode ) WHERE ga.admin2_fullcode IS NOT NULL;
UPDATE geonames_allentries ga set admin3_id=(SELECT id FROM geonames_allentries gsearch WHERE ga.admin3_fullcode = gsearch.geonames_fullcode ) WHERE ga.admin3_fullcode IS NOT NULL;
UPDATE geonames_allentries ga set admin4_id=(SELECT id FROM geonames_allentries gsearch WHERE ga.admin4_fullcode = gsearch.geonames_fullcode ) WHERE ga.admin4_fullcode IS NOT NULL;

UPDATE geonames_allentries ga set admin1_name=(SELECT name FROM geonames_allentries gsearch WHERE gsearch.id=ga.admin1_id);
UPDATE geonames_allentries ga set admin2_name=(SELECT name FROM geonames_allentries gsearch WHERE gsearch.id=ga.admin2_id);
UPDATE geonames_allentries ga set admin3_name=(SELECT name FROM geonames_allentries gsearch WHERE gsearch.id=ga.admin3_id);
UPDATE geonames_allentries ga set admin4_name=(SELECT name FROM geonames_allentries gsearch WHERE gsearch.id=ga.admin4_id);

UPDATE geonames_allentries ga set city_id=admin4_id  WHERE admin4_name IS NOT NULL AND city_id IS NULL;
UPDATE geonames_allentries ga set city_id=admin3_id  WHERE admin3_name IS NOT NULL AND city_id IS NULL;
UPDATE geonames_allentries ga set city_id=admin2_id  WHERE admin2_name IS NOT NULL AND city_id IS NULL;
UPDATE geonames_allentries ga set city_id=admin1_id  WHERE admin1_name IS NOT NULL AND city_id IS NULL;

UPDATE geonames_allentries ga set city_name=admin4_name  WHERE admin4_name IS NOT NULL AND city_name IS NULL;
UPDATE geonames_allentries ga set city_name=admin3_name  WHERE admin3_name IS NOT NULL AND city_name IS NULL;
UPDATE geonames_allentries ga set city_name=admin2_name  WHERE admin2_name IS NOT NULL AND city_name IS NULL;
UPDATE geonames_allentries ga set city_name=admin1_name  WHERE admin1_name IS NOT NULL AND city_name IS NULL;

COMMIT;

COPY geonames_countries TO './dataset/geonames/countries.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY geonames_allentries TO './dataset/geonames/allentries.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', PARTITION_BY (country_code));
