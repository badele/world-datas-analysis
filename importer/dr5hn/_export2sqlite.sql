ATTACH 'db/world-datas-analysis.db' AS sqlite (TYPE SQLITE);
USE sqlite;

.mode table
SELECT 'dr5hn' AS 'Exporting to sqlite';

DROP TABLE IF EXISTS wda_dr5hn_cities;
CREATE TABLE wda_dr5hn_cities AS
    SELECT * FROM duckdb.wda_dr5hn_cities;

DROP TABLE IF EXISTS wda_dr5hn_countries;
CREATE TABLE wda_dr5hn_countries AS
    SELECT * FROM duckdb.wda_dr5hn_countries;

DROP TABLE IF EXISTS wda_dr5hn_regions;
CREATE TABLE wda_dr5hn_regions AS
    SELECT * FROM duckdb.wda_dr5hn_regions;

DROP TABLE IF EXISTS wda_dr5hn_subregions;
CREATE TABLE wda_dr5hn_subregions AS
    SELECT * FROM duckdb.wda_dr5hn_subregions;

DROP TABLE IF EXISTS wda_dr5hn_states;
CREATE TABLE wda_dr5hn_states AS
    SELECT * FROM duckdb.wda_dr5hn_states;

.read './importer/dr5hn/_commons.sql'
