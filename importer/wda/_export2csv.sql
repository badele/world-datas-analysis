BEGIN TRANSACTION;

.mode table
SELECT 'wda' AS 'Importing';

-------------------------------------------------------------------------------
-- Clean old Blacklist IPs
-------------------------------------------------------------------------------
DELETE FROM wda_blacklist_ips
WHERE ipsum = 0 AND duggytuxy = 0;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------

COPY wda_blacklist_ips TO './dataset/wda/blacklist_ips.csv' (DELIMITER '|', HEADER);

.read './importer/wda/_commons.sql'

COMMIT;
