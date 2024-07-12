BEGIN TRANSACTION;

CREATE OR REPLACE TABLE vigilo_categories AS
    SELECT * FROM read_csv('./dataset/vigilo/categories.csv');

CREATE OR REPLACE TABLE vigilo_scopes AS
    SELECT * FROM read_csv('./dataset/vigilo/scopes.csv');

CREATE OR REPLACE TABLE vigilo_instances AS
    SELECT * FROM read_csv('./dataset/vigilo/instances.csv');

CREATE OR REPLACE TABLE vigilo_observations AS
    SELECT * FROM read_csv('./dataset/vigilo/observations.csv');

.read './importer/vigilo/_commons.sql'

COMMIT;
