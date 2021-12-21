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
  date TEXT,
  horaire TEXT,
  annee INTEGER NULL,
  mois INTEGER NULL,
  jours INTEGER NULL,
  heure INTEGER NULL,
  minute INTEGER NULL,
  jour_annee INTEGER NULL,
  idx_semaine INTEGER NULL,
  idx_jour INTEGER NULL,
  jour_semaine TEXT NULL,
  idx_tranche TEXT NULL,
  tranche_horaire TEXT NULL,
  idx_saison INTEGER NULL,
  saison TEXT NULL,
  comptage_cumul INTEGER NULL,
  comptage_quotidien INTEGER NULL,
  methode INTEGER NULL,
  PRIMARY KEY (date,horaire)
);

-- import csv file
.mode csv cities_montpellier_totem_downloaded
.separator ","
.import '| tail -n +2 cities/montpellier/totem/datas/albert_1er_downloaded.csv' cities_montpellier_totem_downloaded

COMMIT;
