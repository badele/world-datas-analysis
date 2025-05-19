BEGIN;

-- disable pager
\pset pager off

\i './importer/init_psql.sql';

--------------------------------------------------------------------------------
-- nafrev2 Sections
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_nafrev2_sections CASCADE;
CREATE FOREIGN TABLE duckdb_nafrev2_sections (
    section_id TEXT,
    section TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/nafrev2/sections.parquet")'
);

DROP TABLE IF EXISTS nafrev2_sections CASCADE;
CREATE TABLE nafrev2_sections AS TABLE duckdb_nafrev2_sections;

--------------------------------------------------------------------------------
-- nafrev2 Divisions
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_nafrev2_divisions CASCADE;
CREATE FOREIGN TABLE duckdb_nafrev2_divisions (
    section_id TEXT,
    division_id TEXT,
    division TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/nafrev2/divisions.parquet")'
);

DROP TABLE IF EXISTS nafrev2_divisions CASCADE;
CREATE TABLE nafrev2_divisions AS TABLE duckdb_nafrev2_divisions;

--------------------------------------------------------------------------------
-- nafrev2 Groupes
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_nafrev2_groupes CASCADE;
CREATE FOREIGN TABLE duckdb_nafrev2_groupes (
    section_id TEXT,
    division_id TEXT,
    groupe_id TEXT,
    groupe TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/nafrev2/groupes.parquet")'
);

DROP TABLE IF EXISTS nafrev2_groupes CASCADE;
CREATE TABLE nafrev2_groupes AS TABLE duckdb_nafrev2_groupes;

--------------------------------------------------------------------------------
-- nafrev2 Classes
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_nafrev2_classes CASCADE;
CREATE FOREIGN TABLE duckdb_nafrev2_classes (
    section_id TEXT,
    division_id TEXT,
    groupe_id TEXT,
    classe_id TEXT,
    classe TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/nafrev2/classes.parquet")'
);

DROP TABLE IF EXISTS nafrev2_classes CASCADE;
CREATE TABLE nafrev2_classes AS TABLE duckdb_nafrev2_classes;

--------------------------------------------------------------------------------
-- nafrev2 Sous-classes
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_nafrev2_sous_classes CASCADE;
CREATE FOREIGN TABLE duckdb_nafrev2_sous_classes (
    section_id TEXT,
    division_id TEXT,
    groupe_id TEXT,
    classe_id TEXT,
    sous_classe_id TEXT,
    sous_classe TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/nafrev2/sous_classes.parquet")'
);

DROP TABLE IF EXISTS nafrev2_sous_classes CASCADE;
CREATE TABLE nafrev2_sous_classes AS TABLE duckdb_nafrev2_sous_classes;

--------------------------------------------------------------------------------
-- Create indexes for faster queries
--------------------------------------------------------------------------------
CREATE UNIQUE INDEX idx_nafrev2_sections_id ON nafrev2_sections (section_id);
CREATE UNIQUE INDEX idx_nafrev2_divisions_id ON nafrev2_divisions (division_id);
CREATE UNIQUE INDEX idx_nafrev2_groupes_id ON nafrev2_groupes (groupe_id);
CREATE UNIQUE INDEX idx_nafrev2_classes_id ON nafrev2_classes (classe_id);
CREATE UNIQUE INDEX idx_nafrev2_sous_classes_id ON nafrev2_sous_classes (sous_classe_id);

--------------------------------------------------------------------------------
-- wda informations
--------------------------------------------------------------------------------
DELETE FROM wda_scopes WHERE provider='nafrev2';
DELETE FROM wda_datasets WHERE provider='nafrev2';
DELETE FROM wda_providers WHERE provider='nafrev2';

INSERT INTO wda_scopes
    SELECT 'nafrev2' AS source, 'nafrev2_sections' AS tablename, 'section' AS scope, NULL AS tablesource, section_id, COUNT(*)
    FROM nafrev2_sections
    GROUP BY section_id;

INSERT INTO wda_datasets
    SELECT
        'nafrev2',
        'nafrev2',
        'nafrev2_sections',
        'section',
        NULL,
        'NAF Rev2 Classification - Sections',
        'https://nafrev2.fr',
        (SELECT count(*) FROM nafrev2_sections),
        COUNT(*),
        COUNT(DISTINCT section_id)
    FROM nafrev2_sections;

INSERT INTO wda_providers
    SELECT
        'nafrev2',
        'NAF Rev2 Classification Provider',
        'https://nafrev2.fr',
        COUNT(*),
        SUM(nb_observations)
    FROM wda_datasets wd
    WHERE provider = 'nafrev2';

COMMIT;
