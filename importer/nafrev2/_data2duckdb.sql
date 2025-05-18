.mode box

BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- All levels
-------------------------------------------------------------------------------
SELECT 'import nafrev2 all levels' as mess;
CREATE OR REPLACE TABLE tmp_nafrev2_all_levels (
    section_id VARCHAR,
    section VARCHAR,
    division_id VARCHAR,
    division VARCHAR,
    groupe_id VARCHAR,
    groupe VARCHAR,
    classe_id VARCHAR,
    classe VARCHAR,
    sous_classe_id VARCHAR,
    sous_classe VARCHAR,
)
;

INSERT INTO tmp_nafrev2_all_levels
SELECT * FROM read_csv('./downloaded/nafrev2/naf2008-listes-completes-5-niveaux.csv')
;

-------------------------------------------------------------------------------
-- Sections
-------------------------------------------------------------------------------

CREATE OR REPLACE TABLE nafrev2_sections (
    section_id VARCHAR,
    section VARCHAR
)
;

INSERT INTO nafrev2_sections
    SELECT DISTINCT section_id, section FROM tmp_nafrev2_all_levels
;

-------------------------------------------------------------------------------
-- Divisions
-------------------------------------------------------------------------------

CREATE OR REPLACE TABLE nafrev2_divisions (
    section_id VARCHAR,
    division_id VARCHAR,
    division VARCHAR
)
;

INSERT INTO nafrev2_divisions
    SELECT DISTINCT section_id, division_id, division FROM tmp_nafrev2_all_levels
;

-------------------------------------------------------------------------------
-- Groupes
-------------------------------------------------------------------------------

CREATE OR REPLACE TABLE nafrev2_groupes (
    section_id VARCHAR,
    division_id VARCHAR,
    groupe_id VARCHAR,
    groupe VARCHAR
)
;

INSERT INTO nafrev2_groupes
    SELECT DISTINCT section_id, division_id,groupe_id, groupe FROM tmp_nafrev2_all_levels
;


-------------------------------------------------------------------------------
-- Classes
-------------------------------------------------------------------------------

CREATE OR REPLACE TABLE nafrev2_classes (
    section_id VARCHAR,
    division_id VARCHAR,
    groupe_id VARCHAR,
    classe_id VARCHAR,
    classe VARCHAR
)
;

INSERT INTO nafrev2_classes
    SELECT DISTINCT section_id, division_id,groupe_id,classe_id, classe FROM tmp_nafrev2_all_levels
;


-------------------------------------------------------------------------------
-- Sous classes
-------------------------------------------------------------------------------

CREATE OR REPLACE TABLE nafrev2_sous_classes (
    section_id VARCHAR,
    division_id VARCHAR,
    groupe_id VARCHAR,
    classe_id VARCHAR,
    sous_classe_id VARCHAR,
    sous_classe VARCHAR
)
;

INSERT INTO nafrev2_sous_classes
    SELECT DISTINCT section_id, division_id,groupe_id,classe_id,sous_classe_id, sous_classe FROM tmp_nafrev2_all_levels
;


-------------------------------------------------------------------------------
-- Fix
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_nafrev2_all_levels CASCADE;


-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
SELECT 'export nafrev2 to parquet' as mess;

COPY nafrev2_sections TO './dataset/nafrev2/sections.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY nafrev2_divisions TO './dataset/nafrev2/divisions.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY nafrev2_groupes TO './dataset/nafrev2/groupes.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY nafrev2_classes TO './dataset/nafrev2/classes.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY nafrev2_sous_classes TO './dataset/nafrev2/sous_classes.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');

SELECT 'COMMIT' as mess;
COMMIT;
