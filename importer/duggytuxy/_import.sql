BEGIN TRANSACTION;

.mode table
SELECT 'duggytuxy' AS 'Importing';

.read './importer/init.sql'

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE duggytuxy_blacklist_ips AS
    SELECT * FROM read_csv('dataset/duggytuxy/blacklist_ips.csv',delim = '|',header = true);

.read './importer/duggytuxy/_commons.sql'

COMMIT;
