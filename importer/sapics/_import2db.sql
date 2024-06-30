BEGIN TRANSACTION;

CREATE OR REPLACE TABLE sapics_asn_ipv4 AS
    SELECT * FROM read_csv('./dataset/sapics/asn_ipv4.csv');

CREATE OR REPLACE TABLE sapics_cities_ipv4 AS
    SELECT * FROM read_csv('./dataset/sapics/cities_ipv4.csv');

CREATE OR REPLACE TABLE sapics_countries_ipv4 AS
    SELECT * FROM read_parquet('./dataset/sapics/countries_ipv4.parquet');

--------------------------------------
-- wda summaries
--------------------------------------
-- INSERT OR REPLACE INTO scopes
-- SELECT 'sapics', 'sapics_cities', city, COUNT(*)
-- FROM sapics_cities ci
-- GROUP BY 'sapics', 'sapics_cities', city;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','sapics_asn_ipv4', 'ASN', 'sapics ASN list', 'https://raw.githubusercontent.com/sapics/ip-location-db/main/geolite2-asn/geolite2-asn-ipv4.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='sapics_asn_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT as_organization)
    FROM sapics_asn_ipv4;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','sapics_cities_ipv4', 'city', 'sapics cities list', 'https://github.com/sapics/ip-location-db/raw/main/geolite2-city/geolite2-city-ipv4.csv.gz', (SELECT column_count FROM duckdb_tables WHERE table_name='sapics_cities_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT city)
    FROM sapics_cities_ipv4;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','sapics_countries_ipv4', 'country', 'sapics countries list', 'https://github.com/sapics/ip-location-db/blob/main/geolite2-country/geolite2-country-ipv4.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='sapics_countries_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT country)
    FROM sapics_countries_ipv4;


INSERT OR REPLACE INTO wda_providers
SELECT 'sapics',  'IP to location database', 'https://github.com/sapics/ip-location-db', count(*), sum(nb_observations)
FROM wda_datasets wd
WHERE provider='sapics';


.read './importer/sapics/_commons.sql'

COMMIT;
