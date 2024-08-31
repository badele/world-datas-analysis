ATTACH 'db/wda.sqlite' AS sqlite (TYPE SQLITE);
USE sqlite;

DROP TABLE IF EXISTS vigilo_categories;
CREATE TABLE vigilo_categories AS
    SELECT * FROM wda_imported.vigilo_categories;

DROP TABLE IF EXISTS vigilo_scopes;
CREATE TABLE vigilo_scopes AS
    SELECT * FROM wda_imported.vigilo_scopes;

DROP TABLE IF EXISTS vigilo_instances;
CREATE TABLE vigilo_instances AS
    SELECT * FROM wda_imported.vigilo_instances;

DROP TABLE IF EXISTS vigilo_observations;
CREATE TABLE vigilo_observations AS
    SELECT * FROM wda_imported.vigilo_observations;

.read './importer/vigilo/_commons.sql'
