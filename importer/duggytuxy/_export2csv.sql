BEGIN TRANSACTION;

.mode table
SELECT 'duggytuxy' AS 'Importing';

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE duggytuxy_blacklist_ips(
  ip_number BIGINT,
  ip TEXT
);

INSERT INTO duggytuxy_blacklist_ips
    SELECT 0,ip
    FROM read_csv('./downloaded/duggytuxy/blacklist_ips_for_fortinet_firewall_*.txt',columns={'ip':'TEXT'},ignore_errors=true)
    WHERE ip NOT LIKE '%:%';

-- fix
DELETE FROM duggytuxy_blacklist_ips WHERE ip like '36.91.21.49%';
DELETE FROM duggytuxy_blacklist_ips WHERE ip like '193.32.162.79%';
DELETE FROM duggytuxy_blacklist_ips WHERE ip like '38.180.41.251%';
DELETE FROM duggytuxy_blacklist_ips WHERE ip like '99.99.68.189%';

UPDATE duggytuxy_blacklist_ips
    SET ip_number = CAST(split_part(ip,'.',1) AS BIGINT)*16777216+CAST(split_part(ip,'.',2) AS BIGINT)*65536+CAST(split_part(ip,'.',3) AS BIGINT)*256+CAST(split_part(ip,'.',4) AS BIGINT);

-------------------------------------------------------------------------------
-- WDA Blacklist IPs
-------------------------------------------------------------------------------

-- init ipsum counter
UPDATE wda_blacklist_ips
    SET duggytuxy = 0;

-- Insert to commons wda_blacklist_ips
INSERT INTO wda_blacklist_ips
    SELECT ip_number,ip,0,0 FROM duggytuxy_blacklist_ips
        WHERE ip_number NOT IN (SELECT ip_number FROM wda_blacklist_ips);

-- Update nb of blacklisted ips
UPDATE wda_blacklist_ips bi
    SET duggytuxy = 1
    FROM duggytuxy_blacklist_ips di
    WHERE bi.ip_number=di.ip_number;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------

.read './importer/duggytuxy/_commons.sql'

COMMIT;
