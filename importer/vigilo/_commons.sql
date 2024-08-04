BEGIN TRANSACTION;
--------------------------------------
-- Index
--------------------------------------

CREATE UNIQUE INDEX vigilo_categories_idx ON vigilo_categories (id);
CREATE UNIQUE INDEX vigilo_scopes_idx ON vigilo_scopes (id);
CREATE UNIQUE INDEX vigilo_instances_idx ON vigilo_instances (scopeid,id);
CREATE UNIQUE INDEX vigilo_observations_idx ON vigilo_observations (scopeid,token);

--------------------------------------
-- Views
--------------------------------------

-- Observations
CREATE OR REPLACE VIEW wda_vigilo_observations AS
    SELECT
        token,
        ts,
        vo.latitude,
        vo.longitude,
        address,
        "comment",
        explanation,
        catid,
        approved,
        cityname,
        gc.*
    FROM vigilo_observations vo
    LEFT JOIN vigilo_scopes vs ON vo.scopeid=vs.id
    LEFT JOIN wda_geonames_cities gc ON vo.wda_id=gc.cityid
    ;

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
    SELECT 'vigilo', 'wda_vigilo_observations', 'city', 'wda_geonames_cities', cityname, COUNT(*)
    FROM wda_vigilo_observations ci
    WHERE cityid IS NOT NULL
    GROUP BY 'vigilo', 'vigilo_cities', cityname
;

INSERT INTO wda_datasets
    SELECT 'vigilo','vigilo','wda_vigilo_observations', 'city', 'wda_geonames_cities', 'vigilo citizen observations', 'https://vigilo.city', (SELECT column_count FROM duckdb_views WHERE view_name='wda_vigilo_observations') as nb_vars, COUNT(*), COUNT(DISTINCT cityname)
    FROM wda_vigilo_observations
;

INSERT INTO wda_providers
    SELECT 'vigilo',  'Observations of the collaborative citizen application', 'https://vigilo.city', count(*), sum(nb_observations)
    FROM wda_datasets wd
    WHERE provider='vigilo'
;

COMMIT;
