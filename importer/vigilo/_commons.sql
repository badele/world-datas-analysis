BEGIN TRANSACTION;
--------------------------------------
-- Index
--------------------------------------

CREATE UNIQUE INDEX idx_vigilo_categories_id ON vigilo_categories (id);
CREATE UNIQUE INDEX idx_vigilo_scopes_id ON vigilo_scopes (id);
-- CREATE UNIQUE INDEX idx_vigilo_instances_scopeid_id ON vigilo_instances (scopeid,id);
CREATE UNIQUE INDEX idx_vigilo_observations_scopeid_token ON vigilo_observations (scopeid,token);
CREATE UNIQUE INDEX idx_vigilo_observations_token ON vigilo_observations (token);

CREATE INDEX idx_vigilo_observations_wdaid ON vigilo_observations (geonames_city_id);

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
-- delete before next transaction
DELETE FROM wda_scopes WHERE provider='vigilo' AND dataset='wda_vigilo_observations';
DELETE FROM wda_datasets WHERE provider='vigilo' AND dataset='wda_vigilo_observations';
DELETE FROM wda_providers WHERE provider='vigilo';

COMMIT;

BEGIN TRANSACTION;

INSERT INTO wda_scopes
    SELECT 'vigilo', 'wda_vigilo_observations', 'city', 'wda_geonames_cities', geonames_city_name, COUNT(*)
    FROM wda_vigilo_observations ci
    WHERE geonames_city_id IS NOT NULL
    GROUP BY 'vigilo', 'vigilo_cities', geonames_city_name
;

INSERT INTO wda_datasets
    SELECT 'vigilo','vigilo','wda_vigilo_observations', 'city', 'wda_geonames_cities', 'vigilo citizen observations', 'https://vigilo.city', (SELECT column_count FROM duckdb_views WHERE view_name='wda_vigilo_observations') as nb_vars, COUNT(*), COUNT(DISTINCT geonames_city_name)
    FROM wda_vigilo_observations
;

INSERT INTO wda_providers
    SELECT 'vigilo',  'Observations of the collaborative citizen application', 'https://vigilo.city', count(*), sum(nb_observations)
    FROM wda_datasets wd
    WHERE provider='vigilo'
;

COMMIT;
