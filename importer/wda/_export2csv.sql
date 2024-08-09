BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Clean old Blacklist IPs
-------------------------------------------------------------------------------
-- DELETE FROM wda_blacklist_ips
-- WHERE ipsum = 0 AND duggytuxy = 0;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
COPY wda_scopes TO './dataset/wda/scopes.csv' (DELIMITER '|', HEADER);
COPY wda_scopes_reference TO './dataset/wda/scopes_reference.csv' (DELIMITER '|', HEADER);
COPY wda_datasets TO './dataset/wda/datasets.csv' (DELIMITER '|', HEADER);
COPY wda_providers TO './dataset/wda/providers.csv' (DELIMITER '|', HEADER);

-- COPY wda_blacklist_ips TO './dataset/wda/blacklist_ips.csv' (DELIMITER '|', HEADER);

.read './importer/wda/_commons.sql'

COMMIT;
