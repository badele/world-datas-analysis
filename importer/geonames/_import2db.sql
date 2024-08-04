BEGIN TRANSACTION;

CREATE OR REPLACE TABLE geonames_countries AS
    SELECT * FROM read_csv('./dataset/geonames/countries.csv');

CREATE OR REPLACE TABLE geonames_allentries AS
    SELECT * FROM read_csv('./dataset/geonames/allentries.csv');

.read './importer/geonames/_commons.sql'

COMMIT;
