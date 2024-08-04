BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
-- counters list
CREATE OR REPLACE TABLE opendata3m_ecocompteur_list (
  name TEXT,
  serie TEXT,
  lat DOUBLE,
  lon DOUBLE,
  osm_id BIGINT,
  city TEXT,
  democraty_district TEXT,
  district TEXT,
  first_date DATETIME,
  last_date DATETIME,
  nb_observations INTEGER,
  wda_id INTEGER
)
;

INSERT INTO opendata3m_ecocompteur_list
    SELECT *,NULL,NULL,NULL,NULL
    FROM read_csv('./downloaded/opendata3m/ecocompteur/list.csv',delim='|')
;

-- counters observations
CREATE OR REPLACE TEMP TABLE tmp_opendata3m_ecocompteur_observations(
  serie             TEXT,
  ts                DATETIME,
  nb_observations   INTEGER
)
;

CREATE OR REPLACE TABLE opendata3m_ecocompteur_observations(
  serie             TEXT,
  ts                DATETIME,
  nb_observations   INTEGER
)
;

INSERT INTO tmp_opendata3m_ecocompteur_observations
    SELECT regexp_extract(filename,'.*/([A-Z0-9]+)\..*',1), regexp_extract(dateObserved,'(.*)/.*',1), intensity
    FROM read_json('./downloaded/opendata3m/ecocompteur/*.json',filename=true)
;

-- deduplicate
INSERT INTO opendata3m_ecocompteur_observations
    SELECT serie,ts,max(nb_observations) AS nb_observations FROM tmp_opendata3m_ecocompteur_observations
    GROUP BY serie,ts
;
DROP TABLE tmp_opendata3m_ecocompteur_observations;

-- Compute summary
CREATE OR REPLACE TEMP TABLE opendata3m_summary_counter AS
    SELECT serie,MIN(ts) AS first_date,MAX(ts) AS last_date,SUM(nb_observations) AS nb_observations
    FROM opendata3m_ecocompteur_observations
    GROUP BY serie
;

UPDATE opendata3m_ecocompteur_list AS el
SET
    first_date = sc.first_date,
    last_date = sc.last_date,
    nb_observations = sc.nb_observations
FROM (
    SELECT
        serie,
        first_date,
        last_date,
        nb_observations
    FROM opendata3m_summary_counter
) AS sc
WHERE el.serie = sc.serie
;


UPDATE opendata3m_ecocompteur_list ol
    SET wda_id = (
        SELECT id
        FROM geonames_allentries gc
        WHERE ol.city = gc.name AND gc.country_code='FR'
    )
;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
COPY opendata3m_ecocompteur_list TO './dataset/opendata3m/ecocompteur/list.csv' (DELIMITER '|', HEADER);
COPY opendata3m_ecocompteur_observations TO './dataset/opendata3m/ecocompteur/observations.csv' (DELIMITER '|', HEADER);
COMMIT;

.read './importer/opendata3m/ecocompteur/_commons.sql'
