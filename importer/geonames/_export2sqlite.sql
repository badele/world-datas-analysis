ATTACH 'db/wda.sqlite' AS sqlite (TYPE SQLITE);
USE sqlite;

DROP TABLE IF EXISTS geonames_countries;
CREATE TABLE geonames_countries AS
    SELECT * FROM wda_imported.geonames_countries;

DROP TABLE IF EXISTS geonames_allentries;
CREATE TABLE geonames_allentries AS
    SELECT * FROM wda_imported.geonames_allentries;

.read './importer/geonames/_commons.sql'
