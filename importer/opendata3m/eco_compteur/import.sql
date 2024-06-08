BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- EcoCompteurs list
--------------------------------------
CREATE OR REPLACE TABLE opendata3m_ecocompteurs_list(
  serie         TEXT,
  nom           TEXT,
  latitude      DOUBLE,
  longitude     DOUBLE,
  osm_line      INTEGER,
  city          TEXT,
  dem_district  TEXT,
  district      TEXT
);

INSERT INTO opendata3m_ecocompteurs_list
SELECT serie,name,lat,lon,osm_id,city,dem_district,district
FROM read_csv_auto('./downloaded/opendata3m/eco_compteur/compteurs.csv');
UPDATE opendata3m_ecocompteurs_list SET dem_district = NULL WHERE dem_district='null';
UPDATE opendata3m_ecocompteurs_list SET district = NULL WHERE district='null';

CREATE UNIQUE INDEX opendata3m_ecocompteurs_list_idx ON opendata3m_ecocompteurs_list (serie);

--------------------------------------
-- EcoCompteurs observations
--------------------------------------
CREATE OR REPLACE TABLE opendata3m_ecocompteurs_observations(
  serie             TEXT,
  ts                DATETIME,
  nb_observations   INTEGER
);
CREATE UNIQUE INDEX opendata3m_ecocompteurs_observations_idx ON opendata3m_ecocompteurs_observations (serie,ts);

INSERT OR REPLACE INTO opendata3m_ecocompteurs_observations
SELECT regexp_extract(id,'MMM_EcoCompt_(.*)_.*',1),regexp_extract(dateObserved,'(.*)/.*',1),intensity
FROM read_json_auto('./downloaded/opendata3m/eco_compteur/MMM_EcoCompt_*.json')
-- Remove duplicates
QUALIFY row_number() over (partition by id,dateObserved order by id,dateObserved) = 1;

--------------------------------------
-- view
--------------------------------------
DROP VIEW IF EXISTS v_opendata3m_ecocompteurs_observations;
CREATE VIEW IF NOT EXISTS v_opendata3m_ecocompteurs_observations
AS
SELECT vo.ts,vl.*,vo.nb_observations FROM opendata3m_ecocompteurs_observations vo
INNER JOIN opendata3m_ecocompteurs_list vl ON vo.serie = vl.serie
ORDER BY ts;

--------------------------------------
-- dataset summaries
--------------------------------------
INSERT OR REPLACE INTO wda_scopes
SELECT 'opendata3m', 'v_opendata3m_ecocompteurs_observations', city as cityname, COUNT(*)
FROM v_opendata3m_ecocompteurs_observations vo
GROUP BY 'opendata3m', 'v_opendata3m_ecocompteurs',city;
--
INSERT OR REPLACE INTO wda_datasets
SELECT 'opendata3m','opendata3m','v_opendata3m_ecocompteurs_observations', 'city', 'opendata3m bike ecocompteurs', 'https://opendata3m.city', (SELECT column_count FROM duckdb_views WHERE view_name='v_opendata3m_ecocompteurs_observations'), COUNT(*), COUNT(DISTINCT city)
FROM v_opendata3m_ecocompteurs_observations;
--
INSERT OR REPLACE INTO wda_providers
SELECT 'opendata3m',  'OpenData Méditerranée Métropole', 'https://data.montpellier3m.fr/', count(*), sum(nb_observations)
FROM wda_datasets wd
WHERE provider='opendata3m';

COMMIT;
