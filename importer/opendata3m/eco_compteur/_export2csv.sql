BEGIN TRANSACTION;

.mode table
SELECT 'opendata3m_eco_compteur' AS 'Importing';

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
-- counters list
CREATE OR REPLACE TABLE opendata3m_eco_compteur_list (
  name TEXT,
  serie TEXT,
  lat DOUBLE,
  lon DOUBLE,
  osm_id BIGINT,
  city TEXT,
  democraty_district TEXT,
  district TEXT
);

INSERT INTO opendata3m_eco_compteur_list
    SELECT *
    FROM read_csv('./downloaded/opendata3m/eco_compteur/counters_list.csv',delim='|');

-- counters observations
CREATE OR REPLACE TABLE opendata3m_ecocompteurs_observations(
  serie             TEXT,
  ts                DATETIME,
  nb_observations   INTEGER
);
-- CREATE UNIQUE INDEX opendata3m_ecocompteurs_observations_idx ON opendata3m_ecocompteurs_observations (serie,ts);

INSERT INTO opendata3m_ecocompteurs_observations
    SELECT filename, regexp_extract(dateObserved,'(.*)/.*',1), intensity
    FROM read_json('./downloaded/opendata3m/eco_compteur/*.json',filename=true);

-- -------------------------------------------------------------------------------
-- -- WDA Blacklist IPs
-- -------------------------------------------------------------------------------
--
-- -- init ipsum counter
-- UPDATE wda_blacklist_ips
--     SET ipsum = 0;
--
-- -- Insert to commons wda_blacklist_ips
-- INSERT INTO wda_blacklist_ips
--     SELECT ip_number,ip,0,0 FROM ipsum_blacklist_ips
--         WHERE ip_number NOT IN (SELECT ip_number FROM wda_blacklist_ips);
--
-- -- Update nb of blacklisted ips
-- UPDATE wda_blacklist_ips bi
--     SET ipsum = ii.nb
--     FROM ipsum_blacklist_ips ii
--     WHERE bi.ip_number=ii.ip_number;
--
-- .read './importer/ipsum/_commons.sql'
--
COMMIT;
