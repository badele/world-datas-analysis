ATTACH 'db/wda.sqlite' AS sqlite (TYPE SQLITE);
USE sqlite;

DROP TABLE IF EXISTS sapics_asn_ipv4;
CREATE TABLE sapics_asn_ipv4 AS
    SELECT * FROM wda.sapics_asn_ipv4;

DROP TABLE IF EXISTS sapics_cities_ipv4;
CREATE TABLE sapics_cities_ipv4 AS
    SELECT * FROM wda.sapics_cities_ipv4;

DROP TABLE IF EXISTS sapics_countries_ipv4;
CREATE TABLE sapics_countries_ipv4 AS
    SELECT * FROM wda.sapics_countries_ipv4;

.read './importer/sapics/_commons.sql'
