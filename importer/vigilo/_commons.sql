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

-- Categories
-- DROP VIEW IF EXISTS wda_vigilo_categories;
-- CREATE VIEW wda_vigilo_categories AS
--     SELECT
--         id,
--         name,
--         color
--         FROM vigilo_categories;
--
-- -- Scopes
-- DROP VIEW IF EXISTS wda_vigilo_scopes;
-- CREATE VIEW wda_vigilo_scopes AS
--     SELECT
--         id,
--         display_name AS name,
--         department,
--         country,
--         FROM vigilo_scopes;
--
-- -- Instances
-- DROP VIEW IF EXISTS wda_vigilo_instances;
-- CREATE VIEW wda_vigilo_instances AS
--     SELECT
--         scopeid,
--         id,
--         name,
--         postcode,
--         website
--     FROM vigilo_instances;

-- Observations
CREATE OR REPLACE VIEW wda_vigilo_observations AS SELECT
        token,
        ts,
        coordinates_lat,
        coordinates_lon,
        address,
        "comment",
        explanation,
        catid,
        approved,
        cityname
    FROM vigilo_observations;


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
    SELECT 'vigilo', 'wda_vigilo_observations', 'city', cityname, COUNT(*)
    FROM wda_vigilo_observations ci
    WHERE cityname IS NOT NULL
        AND cityname NOT like '%undefined%'
    GROUP BY 'vigilo', 'vigilo_cities', cityname;

INSERT INTO wda_datasets
    SELECT 'vigilo','vigilo','wda_vigilo_observations', 'city', 'vigilo citizen observations', 'https://vigilo.city', (SELECT column_count FROM duckdb_tables WHERE table_name='vigilo_observations') as nb_vars, COUNT(*), COUNT(DISTINCT cityname)
    FROM vigilo_observations;

INSERT INTO wda_providers
    SELECT 'vigilo',  'Observations of the collaborative citizen application', 'https://vigilo.city', count(*), sum(nb_observations)
    FROM wda_datasets wd
    WHERE provider='vigilo';

COMMIT;
