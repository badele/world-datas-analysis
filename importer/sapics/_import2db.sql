BEGIN TRANSACTION;

.mode table
SELECT 'sapics' AS 'Importing to database';

.read './importer/init.sql'

CREATE OR REPLACE TABLE wda_sapics_asn_ipv4 AS
    SELECT * FROM read_csv('./dataset/sapics/asn_ipv4.csv');

CREATE OR REPLACE TABLE wda_sapics_cities_ipv4 AS
    SELECT * FROM read_csv('./dataset/sapics/cities_ipv4.csv');

CREATE OR REPLACE TABLE wda_sapics_countries AS
    SELECT * FROM read_csv('./dataset/sapics/countries_ipv4.csv');

--------------------------------------
-- wda summaries
--------------------------------------
-- INSERT OR REPLACE INTO wda_scopes
-- SELECT 'sapics', 'wda_sapics_cities', city, COUNT(*)
-- FROM wda_sapics_cities ci
-- GROUP BY 'sapics', 'wda_sapics_cities', city;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','wda_sapics_asn_ipv4', 'ASN', 'sapics ASN list', 'https://raw.githubusercontent.com/sapics/ip-location-db/main/geolite2-asn/geolite2-asn-ipv4.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='wda_sapics_asn_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT as_organization)
    FROM wda_sapics_asn_ipv4;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','wda_sapics_cities_ipv4', 'city', 'sapics cities list', 'https://github.com/sapics/ip-location-db/raw/main/geolite2-city/geolite2-city-ipv4.csv.gz', (SELECT column_count FROM duckdb_tables WHERE table_name='wda_sapics_cities_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT city)
    FROM wda_sapics_cities_ipv4;

INSERT OR REPLACE INTO wda_datasets
    SELECT 'sapics','sapics','wda_sapics_countries_ipv4', 'country', 'sapics countries list', 'https://github.com/sapics/ip-location-db/blob/main/geolite2-country/geolite2-country-ipv4.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='wda_sapics_countries_ipv4') as nb_vars, COUNT(*), COUNT(DISTINCT country)
    FROM wda_sapics_countries_ipv4;


INSERT OR REPLACE INTO wda_providers
SELECT 'sapics',  'IP to location database', 'https://github.com/sapics/ip-location-db', count(*), sum(nb_observations)
FROM wda_datasets wd
WHERE provider='sapics';


.read './importer/sapics/_commons.sql'

COMMIT;
