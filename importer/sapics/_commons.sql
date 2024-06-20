CREATE UNIQUE INDEX wda_sapics_asn_ipv4_idx ON wda_sapics_asn_ipv4 (range_start,range_end);
CREATE UNIQUE INDEX wda_sapics_countries_ipv4_idx ON wda_sapics_countries_ipv4 (range_start,range_end);
CREATE UNIQUE INDEX wda_sapics_cities_ipv4_idx ON wda_sapics_cities_ipv4 (range_start,range_end);
