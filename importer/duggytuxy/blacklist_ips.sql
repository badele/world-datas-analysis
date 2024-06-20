BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Blacklist IPs
--------------------------------------
CREATE OR REPLACE TABLE duggytuxy_blacklist_ips(
  ip_number BIGINT,
  ip TEXT
);

INSERT INTO duggytuxy_blacklist_ips
    SELECT ip_to_int(ip),ip
    FROM read_csv('./downloaded/duggytuxy/blacklist_ips_for_fortinet_firewall_*.txt',columns={'ip':'TEXT'})
    WHERE ip NOT LIKE '%:%';


-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------
COPY duggytuxy_blacklist_ips TO './dataset/duggytuxy/blacklist_ips.csv' (DELIMITER '|', HEADER);

COMMIT;
