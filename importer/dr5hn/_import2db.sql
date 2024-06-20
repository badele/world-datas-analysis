BEGIN TRANSACTION;

.mode table
SELECT 'dr5hn' AS 'Importing to database';

.read './importer/init.sql'

CREATE TABLE wda_dr5hn_cities AS
    SELECT * FROM read_csv('./dataset/dr5hn/cities.csv');

CREATE TABLE wda_dr5hn_countries AS
    SELECT * FROM read_csv('./dataset/dr5hn/countries.csv');

CREATE TABLE wda_dr5hn_regions AS
    SELECT * FROM read_csv('./dataset/dr5hn/regions.csv');

CREATE TABLE wda_dr5hn_subregions AS
    SELECT * FROM read_csv('./dataset/dr5hn/subregions.csv');

CREATE TABLE wda_dr5hn_states AS
    SELECT * FROM read_csv('./dataset/dr5hn/states.csv');

.read './importer/dr5hn/_commons.sql'

COMMIT;
