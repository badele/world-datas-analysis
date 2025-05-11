ATTACH 'db/wda.sqlite' AS sqlite (TYPE SQLITE);
USE sqlite;

DROP TABLE IF EXISTS dr5hn_cities;
CREATE TABLE dr5hn_cities AS
    SELECT * FROM wda.dr5hn_cities;

DROP TABLE IF EXISTS dr5hn_countries;
CREATE TABLE dr5hn_countries AS
    SELECT * FROM wda.dr5hn_countries;

DROP TABLE IF EXISTS dr5hn_regions;
CREATE TABLE dr5hn_regions AS
    SELECT * FROM wda.dr5hn_regions;

DROP TABLE IF EXISTS dr5hn_subregions;
CREATE TABLE dr5hn_subregions AS
    SELECT * FROM wda.dr5hn_subregions;

DROP TABLE IF EXISTS dr5hn_states;
CREATE TABLE dr5hn_states AS
    SELECT * FROM wda.dr5hn_states;

.read './importer/dr5hn/_commons.sql'
