BEGIN TRANSACTION;

.mode table
SELECT 'sapics' AS 'Importing to database';

.read './importer/init.sql'

-- ASN
CREATE OR REPLACE TABLE wda_sapics_asn_ipv4(
    ip_range_start TEXT,
    ip_range_end TEXT,
    as_number TEXT,
    as_organization TEXT,
    range_start BIGINT,
    range_end BIGINT,
    nb_ips BIGINT
);

INSERT INTO wda_sapics_asn_ipv4
    SELECT column0,column1,column2,column3,ip_to_int(column0),ip_to_int(column1),-1
    FROM read_csv_auto('./downloaded/sapics/geolite2-asn/geolite2-asn-ipv4.csv',header=false);
UPDATE wda_sapics_asn_ipv4 SET as_number = 'AS' || as_number;
UPDATE wda_sapics_asn_ipv4 SET nb_ips = range_end - range_start+1;

-- Cities
CREATE OR REPLACE TABLE wda_sapics_cities_ipv4(
    ip_range_start TEXT,
    ip_range_end TEXT,
    country_code TEXT,
    state1 TEXT,
    state2 TEXT,
    city TEXT,
    postcode TEXT,
    latitude DOUBLE,
    longitude DOUBLE,
    timezone TEXT,
    range_start BIGINT,
    range_end BIGINT,
    nb_ips BIGINT
);

INSERT INTO wda_sapics_cities_ipv4
    SELECT column0,column1,column2,column3,column4,column5,column6,column7,column8,column9,ip_to_int(column0),ip_to_int(column1),-1
    FROM read_csv_auto('./downloaded/sapics/geolite2-city/geolite2-city-ipv4.csv.gz',header=false);
UPDATE wda_sapics_cities_ipv4 SET nb_ips = range_end - range_start+1;

-- Countries
CREATE OR REPLACE TABLE wda_sapics_countries_ipv4(
    ip_range_start TEXT,
    ip_range_end TEXT,
    country TEXT,
    range_start BIGINT,
    range_end BIGINT,
    nb_ips BIGINT
);
INSERT INTO wda_sapics_countries_ipv4
    SELECT column0,column1,column2,ip_to_int(column0),ip_to_int(column1),-1
    FROM read_csv_auto('./downloaded/sapics/geolite2-country/geolite2-country-ipv4.csv',header=false);
UPDATE wda_sapics_countries_ipv4 SET nb_ips = range_end - range_start+1;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------

COPY wda_sapics_asn_ipv4 TO './dataset/sapics/asn_ipv4.csv' (DELIMITER '|', HEADER);
COPY wda_sapics_cities_ipv4 TO './dataset/sapics/cities_ipv4.csv' (DELIMITER '|', HEADER);
COPY wda_sapics_countries_ipv4 TO './dataset/sapics/countries_ipv4.csv' (DELIMITER '|', HEADER);

.read './importer/sapics/_commons.sql'

COMMIT;
