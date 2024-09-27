-- INSTALL sqlite; LOAD sqlite;
-- INSTALL postgres; LOAD postgres;

.read './importer/init_commons.sql'

--------------------------------------
-- macro
--------------------------------------
-- CREATE OR REPLACE MACRO ip_to_int(ip) AS CAST(split_part(ip,'.',1) AS BIGINT)*16777216+CAST(split_part(ip,'.',2) AS BIGINT)*65536+CAST(split_part(ip,'.',3) AS BIGINT)*256+CAST(split_part(ip,'.',4) AS BIGINT);
