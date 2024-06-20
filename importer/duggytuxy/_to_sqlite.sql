ATTACH 'db/world-datas-analysis.db' AS sqlite (TYPE SQLITE);
USE sqlite;

.mode table
SELECT 'duggytuxy' AS 'Exporting';

DROP TABLE IF EXISTS duggytuxy_blacklist_ips;
CREATE TABLE duggytuxy_blacklist_ips AS
    SELECT * FROM duckdb.duggytuxy_blacklist_ips;

.read './importer/duggytuxy/_commons.sql'
