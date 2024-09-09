BEGIN TRANSACTION;
-------------------------------------------------------------------------------
-- Index
-------------------------------------------------------------------------------
CREATE UNIQUE INDEX opendata3m_ecocompteur_observations_idx ON opendata3m_ecocompteur_observations (serie,ts);

-------------------------------------------------------------------------------
-- Create view
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW wda_opendata3m_ecocompteur_observations AS
    SELECT
    eo.serie,
    el.city,
    el.name,
    el.lat,
    el.lon,
    el.democraty_district,
    el.district,
    eo.ts,
    eo.nb_observations,
    gc.*
    FROM opendata3m_ecocompteur_observations eo
    LEFT JOIN opendata3m_ecocompteur_list el ON eo.serie=el.serie
    LEFT JOIN wda_geonames_cities gc ON el.city=gc.geonames_city_name
;

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
-- delete before next transaction
DELETE FROM wda_scopes WHERE provider='opendata3m' AND dataset='wda_opendata3m_ecocompteur_observations';
DELETE FROM wda_datasets WHERE provider='opendata3m' AND dataset='wda_opendata3m_ecocompteur_observations';
DELETE FROM wda_providers WHERE provider='opendata3m';

COMMIT;

BEGIN TRANSACTION;

INSERT OR REPLACE INTO wda_scopes
    SELECT 'opendata3m', 'wda_opendata3m_ecocompteur_observations', 'city', 'wda_geonames_cities', city, count(*)
    FROM wda_opendata3m_ecocompteur_observations
    GROUP BY city
;

INSERT INTO wda_datasets
    SELECT 'opendata3m','opendata3m','wda_opendata3m_ecocompteur_observations', 'city', 'wda_geonames_cities', 'ecocompteur observations', 'https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-eco-compteurs/resource/edf3e04f-9409-40fe-be66', (SELECT column_count FROM duckdb_views WHERE view_name='wda_opendata3m_ecocompteur_observations') as nb_vars, COUNT(*), COUNT(DISTINCT city)
    FROM wda_opendata3m_ecocompteur_observations
;

INSERT INTO wda_providers
SELECT 'opendata3m',  'OpenData Montpellier Méditerranée Métropole', 'https://data.montpellier3m.fr/', count(*), sum(nb_observations)
FROM wda_datasets wd
WHERE provider='opendata3m'
;

COMMIT;
