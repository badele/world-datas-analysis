BEGIN TRANSACTION;

CREATE OR REPLACE TABLE wda_blacklist_ips AS
    SELECT * FROM read_csv('./dataset/wda/blacklist_ips.csv');

--------------------------------------
-- wda summaries
--------------------------------------
-- INSERT OR REPLACE INTO wda_scopes
-- SELECT 'wda', 'wda_wda_cities', city, COUNT(*)
-- FROM wda_wda_cities ci
-- GROUP BY 'wda', 'wda_wda_cities', city;


-- .read './importer/wda/_commons.sql'

COMMIT;
