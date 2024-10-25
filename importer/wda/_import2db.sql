BEGIN TRANSACTION;

-- CREATE OR REPLACE TABLE wda_blacklist_ips AS
--     SELECT * FROM read_csv('./dataset/wda/blacklist_ips.csv');

CREATE OR REPLACE TABLE wda_scopes AS
    SELECT * FROM read_csv('./dataset/wda/scopes.csv');

CREATE OR REPLACE TABLE wda_scopes_reference AS
    SELECT * FROM read_csv('./dataset/wda/scopes_reference.csv');

CREATE OR REPLACE TABLE wda_datasets AS
    SELECT * FROM read_csv('./dataset/wda/datasets.csv');

CREATE OR REPLACE TABLE wda_providers AS
    SELECT * FROM read_csv('./dataset/wda/providers.csv');

--------------------------------------
-- wda summaries
--------------------------------------
-- INSERT OR REPLACE INTO wda_scopes
-- SELECT 'wda', 'wda_wda_cities', city, COUNT(*)
-- FROM wda_wda_cities ci
-- GROUP BY 'wda', 'wda_wda_cities', city;


-- .read './importer/wda/_commons.sql'

COMMIT;
