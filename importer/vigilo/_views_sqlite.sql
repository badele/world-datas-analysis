BEGIN TRANSACTION;

--------------------------------------
-- Emulate Views (Too slow on SQLite)
--------------------------------------

.database

-- Observations
DROP TABLE IF EXISTS wda_vigilo_observations;
CREATE TABLE wda_vigilo_observations AS
    SELECT * FROM wda_imported.wda_vigilo_observations
;

COMMIT;
