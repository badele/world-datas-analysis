ATTACH 'db/world-datas-analysis.db' AS sqlite (TYPE SQLITE);
USE sqlite;

.mode table
SELECT 'sapics' AS 'Exporting to sqlite';

DROP TABLE IF EXISTS wda_sapics_asn_ipv4;
CREATE TABLE wda_sapics_asn_ipv4 AS
    SELECT * FROM duckdb.wda_sapics_asn_ipv4;

DROP TABLE IF EXISTS wda_sapics_cities_ipv4;
CREATE TABLE wda_sapics_cities_ipv4 AS
    SELECT * FROM duckdb.wda_sapics_cities_ipv4;

DROP TABLE IF EXISTS wda_sapics_countries_ipv4;
CREATE TABLE wda_sapics_countries_ipv4 AS
    SELECT * FROM duckdb.wda_sapics_regions;


.read './importer/sapics/_commons.sql'
