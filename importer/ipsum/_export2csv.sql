BEGIN TRANSACTION;

.mode table
SELECT 'ipsum' AS 'Importing';

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE ipsum_blacklist_ips(
  ip_number BIGINT,
  ip TEXT,
  nb INTEGER
);

INSERT INTO ipsum_blacklist_ips
    SELECT CAST(split_part(ip,'.',1) AS BIGINT)*16777216+CAST(split_part(ip,'.',2) AS BIGINT)*65536+CAST(split_part(ip,'.',3) AS BIGINT)*256+CAST(split_part(ip,'.',4) AS BIGINT),ip,nb
    FROM read_csv('./downloaded/ipsum/ipsum.txt',delim='\t', skip=7, columns={'ip':'TEXT','nb':'INTEGER'});

-------------------------------------------------------------------------------
-- WDA Blacklist IPs
-------------------------------------------------------------------------------

-- init ipsum counter
UPDATE wda_blacklist_ips
    SET ipsum = 0;

-- Insert to commons wda_blacklist_ips
INSERT INTO wda_blacklist_ips
    SELECT ip_number,ip,0,0 FROM ipsum_blacklist_ips
        WHERE ip_number NOT IN (SELECT ip_number FROM wda_blacklist_ips);

-- Update nb of blacklisted ips
UPDATE wda_blacklist_ips bi
    SET ipsum = ii.nb
    FROM ipsum_blacklist_ips ii
    WHERE bi.ip_number=ii.ip_number;

.read './importer/ipsum/_commons.sql'

COMMIT;
