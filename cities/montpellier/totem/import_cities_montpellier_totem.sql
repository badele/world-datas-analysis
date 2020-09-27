--------------------------------------
-- Import countries
--------------------------------------

.head on
.nullvalue NULL

BEGIN TRANSACTION;

-- Drop Dependencies ressources
DROP VIEW IF EXISTS v_cities_montpellier_totem;

-- Create totem table
DROP TABLE IF EXISTS cities_montpellier_totem_downloaded;
CREATE TABLE IF NOT EXISTS 'cities_montpellier_totem_downloaded' (
  DATETIME TEXT,
  annee INTEGER NULL,
  mois INTEGER NULL,
  jours INTEGER NULL,
  heure INTEGER NULL,
  minute INTEGER NULL,
  jour_année INTEGER NULL,
  jour_semaine INTEGER NULL,
  tranche_horaire TEXT NULL,
  saison TEXT NULL,
  comptage_cumul INTEGER NULL,
  comptage_quotidien INTEGER NULL,
  methode INTEGER NULL,
  PRIMARY KEY (DATETIME)
);



-- import csv file
.mode csv cities_montpellier_totem_downloaded
.separator ","
.import '| tail -n +2 cities/montpellier/totem/datas/albert_1er_downloaded.csv' cities_montpellier_totem_downloaded

-- -- Add zone fields
-- ALTER TABLE cities_montpellier_totem_downloaded ADD COLUMN zone TEXT;
-- UPDATE cities_montpellier_totem_downloaded SET zone = "country" WHERE Province_State = '';
-- UPDATE cities_montpellier_totem_downloaded SET zone = "state" WHERE Province_State != '';

-- -- Rename table and create index
-- DROP TABLE IF EXISTS global_covid19_JHU_locations;
-- ALTER TABLE cities_montpellier_totem_downloaded RENAME TO global_covid19_JHU_locations;
-- DROP INDEX IF EXISTS loc_country_province;
-- CREATE INDEX loc_country_province ON global_covid19_JHU_locations(country_region,province_state);


-- --------------------------------------
-- -- Import JHU cases,recovered,deaths
-- --------------------------------------

-- CREATE TEMPORARY TABLE IF NOT EXISTS 'global_covid19_JHU_downloaded' (
--     date TEXT,
--     country_region TEXT,
--     province_state TEXT,
--     field TEXT,
--     value INTEGER,
--     PRIMARY KEY (date,country_region,province_state,field)
-- );

-- -- import csv file
-- .mode csv global_covid19_JHU_downloaded
-- .separator ","
-- .import '| tail -n +2 international/covid-19/datas/global_covid19_JHU_cases_downloaded.csv' global_covid19_JHU_downloaded
-- .import '| tail -n +2 international/covid-19/datas/global_covid19_JHU_recovered_downloaded.csv' global_covid19_JHU_downloaded
-- .import '| tail -n +2 international/covid-19/datas/global_covid19_JHU_deaths_downloaded.csv' global_covid19_JHU_downloaded


-- -- Init global_covid19_JHU table
-- CREATE TEMPORARY TABLE IF NOT EXISTS global_covid19_JHU_tmp (
--     date TEXT,
--     LOC_ID INTEGER NULL,
--     country_region TEXT,
--     province_state TEXT,
--     cases INTEGER NULL,
--     recovered INTEGER NULL,
--     deaths INTEGER NULL
-- );
-- DROP INDEX IF EXISTS JHU_country_province;
-- CREATE INDEX JHU_country_province ON global_covid19_JHU_tmp(country_region,province_state);

-- -- Insert all countries and provinces
-- INSERT INTO global_covid19_JHU_tmp
-- SELECT DISTINCT c.date,NULL,c.country_region,c.province_state,NULL,NULL,NULL FROM global_covid19_JHU_downloaded AS c ORDER by date,country_region,province_state;

-- -- Import cases countries
-- UPDATE global_covid19_JHU_tmp AS a
-- SET cases = (
-- SELECT value FROM global_covid19_JHU_downloaded AS c
-- WHERE c.field='cases' AND a.country_region=c.country_region and c.province_state=a.province_state AND a.date = c.date
-- );

-- -- Import recovered
-- UPDATE global_covid19_JHU_tmp AS a
-- SET recovered = (
-- SELECT value FROM global_covid19_JHU_downloaded AS c
-- WHERE c.field='recovered' AND a.country_region=c.country_region and c.province_state=a.province_state AND a.date = c.date
-- );

-- -- Import deaths
-- UPDATE global_covid19_JHU_tmp AS a
-- SET deaths = (
-- SELECT value FROM global_covid19_JHU_downloaded AS c
-- WHERE c.field='deaths' AND a.country_region=c.country_region and c.province_state=a.province_state AND a.date = c.date
-- );

-- -- Update LOC_ID
-- UPDATE global_covid19_JHU_tmp AS c
-- SET LOC_ID = (
-- select LOC_ID from global_covid19_JHU_locations AS l
-- WHERE l.country_region=c.country_region AND l.province_state=c.province_state
-- );

-- -- Create finaly global_covid19_JHU table
-- DROP TABLE IF EXISTS global_covid19_JHU;
-- CREATE TABLE IF NOT EXISTS 'global_covid19_JHU' (
--     date TEXT,
--     LOC_ID INTEGER,
--     cases INTEGER,
--     recovered INTEGER,
--     deaths INTEGER
--     --PRIMARY KEY (date,LOC_ID)
-- );

-- INSERT INTO global_covid19_JHU
-- SELECT
--     date,
--     co.LOC_ID,
--     cases,
--     recovered,
--     deaths
-- FROM global_covid19_JHU_tmp AS ca
-- LEFT JOIN global_covid19_JHU_locations AS co ON (ca.country_region=co.country_region and ca.province_state=co.province_state);

-- -- Replace some rows content
-- UPDATE global_covid19_JHU_locations SET country_region = "Korea South" WHERE country_region = "Korea, South";

-- -- Create views
-- DROP VIEW IF EXISTS v_cities_montpellier_totem;
-- CREATE VIEW IF NOT EXISTS v_cities_montpellier_totem
-- AS
-- SELECT
--     date(date) as date,
--     cases,
--     recovered,
--     deaths,
--     round(cases*1.0/co.population,6) as ratio_cases,
--     round(recovered*1.0/co.population,6) as ratio_recovered,
--     round(deaths*1.0/co.population,6) as ratio_deaths,
--     co.LOC_ID,
--     co.country_region,
--     co.province_state,
--     co.lat,
--     co.long,
--     co.zone,
--     co.population
-- FROM global_covid19_JHU ca
-- INNER JOIN global_covid19_JHU_locations co ON (ca.LOC_ID=co.LOC_ID);

COMMIT;
