BEGIN TRANSACTION;

CREATE OR REPLACE TABLE dr5hn_cities AS
    SELECT * FROM read_csv('./dataset/dr5hn/cities.csv');

CREATE OR REPLACE TABLE dr5hn_countries AS
    SELECT * FROM read_csv('./dataset/dr5hn/countries.csv');

CREATE OR REPLACE TABLE dr5hn_regions AS
    SELECT * FROM read_csv('./dataset/dr5hn/regions.csv');

CREATE OR REPLACE TABLE dr5hn_subregions AS
    SELECT * FROM read_csv('./dataset/dr5hn/subregions.csv');

CREATE OR REPLACE TABLE dr5hn_states AS
    SELECT * FROM read_csv('./dataset/dr5hn/states.csv');

--------------------------------------
-- wda summaries
--------------------------------------
-- INSERT OR REPLACE INTO scopes
-- SELECT 'dr5hn', 'dr5hn_cities', city, COUNT(*)
-- FROM dr5hn_cities ci
-- GROUP BY 'dr5hn', 'dr5hn_cities', city;

-- INSERT OR REPLACE INTO datasets
--     SELECT 'dr5hn','dr5hn','dr5hn cities', 'city', 'dr5hn cities list', 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/cities.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='dr5hn_cities') as nb_vars, COUNT(*), COUNT(DISTINCT city)
--     FROM dr5hn_cities;
--
-- INSERT OR REPLACE INTO datasets
--     SELECT 'dr5hn','dr5hn','dr5hn countries', 'country', 'dr5hn countries list', 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/countries.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='dr5hn_countries') as nb_vars, COUNT(*), COUNT(DISTINCT country)
--     FROM dr5hn_countries;
--
-- INSERT OR REPLACE INTO datasets
--     SELECT 'dr5hn','dr5hn','dr5hn regions', 'region', 'dr5hn regions list', 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/regions.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='dr5hn_regions') as nb_vars, COUNT(*), COUNT(DISTINCT region)
--     FROM dr5hn_regions;
--
-- INSERT OR REPLACE INTO datasets
--     SELECT 'dr5hn','dr5hn','dr5hn states', 'state', 'dr5hn states list', 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/states.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='dr5hn_states') as nb_vars, COUNT(*), COUNT(DISTINCT state)
--     FROM dr5hn_states;
--
-- INSERT OR REPLACE INTO datasets
--     SELECT 'dr5hn','dr5hn','dr5hn subregions', 'subregion', 'dr5hn subregions list', 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/subregions.csv', (SELECT column_count FROM duckdb_tables WHERE table_name='dr5hn_subregions') as nb_vars, COUNT(*), COUNT(DISTINCT subregion)
--     FROM dr5hn_subregions;
--
-- INSERT OR REPLACE INTO providers
-- SELECT 'dr5hn',  'Countries States Cities Database', 'https://github.com/dr5hn/countries-states-cities-database', count(*), sum(nb_observations)
-- FROM datasets wd
-- WHERE provider='dr5hn';


.read './importer/dr5hn/_commons.sql'

COMMIT;
