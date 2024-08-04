BEGIN TRANSACTION;

-- Admin1 code
CREATE OR REPLACE TABLE geonames_admin1codes (
  code TEXT,
  name TEXT,
  name_ascii TEXT,
  geonameid INTEGER
);

INSERT INTO geonames_admin1codes
    SELECT *
    FROM read_csv('./downloaded/geonames/admin1CodesASCII.txt');

-- Admin2 code
CREATE OR REPLACE TABLE geonames_admin2codes (
  code TEXT,
  name TEXT,
  name_ascii TEXT,
  geonameid INTEGER
);

INSERT INTO geonames_admin2codes
    SELECT *
    FROM read_csv('./downloaded/geonames/admin2Codes.txt');

-- Countries
CREATE OR REPLACE TABLE geonames_countries (
  iso TEXT,
  iso3 TEXT,
  iso_numeric INTEGER,
  fips TEXT,
  country TEXT,
  capital TEXT,
  area_km2 DOUBLE,
  population INTEGER,
  continent TEXT,
  tld TEXT,
  currency_code TEXT,
  currency_name TEXT,
  phone_prefix TEXT,
  languages TEXT,
  geonameid INTEGER,
  neighbours TEXT,
  equivalent_fips_code TEXT
);

INSERT INTO geonames_countries
    SELECT  column00,
            column01,
            column02,
            column03,
            column04,
            column05,
            column06,
            column07,
            column08,
            column09,
            column10,
            column11,
            column12,
            column15,
            column16,
            column17,
            column18
    FROM read_csv('./downloaded/geonames/countryInfo.txt',skip=50);

-- entries
CREATE OR REPLACE TABLE geonames_allentries (
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
  modification DATE
);

INSERT INTO geonames_allentries
    SELECT *
    FROM read_csv('./downloaded/geonames/allCountries.txt')
    WHERE column06 = 'A';
;
    --WHERE column06 = 'A' OR column06 = 'P';



COMMIT;

COPY geonames_countries TO './dataset/geonames/countries.csv' (DELIMITER '|', HEADER);
COPY geonames_allentries TO './dataset/geonames/allentries.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');

.read './importer/geonames/_commons.sql'
