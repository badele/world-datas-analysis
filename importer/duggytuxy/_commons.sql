CREATE UNIQUE INDEX duggytuxy_blacklist_ips_idx ON duggytuxy_blacklist_ips (ip_number);

DROP TABLE IF EXISTS wda_duggytuxy_blacklist_ips;
CREATE TABLE wda_duggytuxy_blacklist_ips AS
  SELECT
    bi.*,
    sc.country AS iso2,
    dc.country,
    dc.capital,
    dc.region,
    dc.subregion,
    ci.lat,
    ci.lon
    FROM duggytuxy_blacklist_ips bi
    LEFT JOIN sapics_countries_ipv4 sc ON bi.ip_number>=sc.range_start AND ip_number<=sc.range_end
    LEFT JOIN v_dr5hn_countries dc ON sc.country=dc.iso2
    LEFT JOIN dr5hn_cities ci ON dc.country_id dc.capital=ci.city;
CREATE UNIQUE INDEX wda_duggytuxy_blacklist_ips_idx ON wda_duggytuxy_blacklist_ips (ip_number);

-- DROP TABLE IF EXISTS wda_duggytuxy_blacklist_countries_stats;
-- CREATE TABLE wda_duggytuxy_blacklist_countries_stats AS
-- SELECT
--   iso2,
--   country,
--   capital,
--   region,
--   subregion,
--   lat,
--   lon,
--   count(*) AS nb
--   FROM wda_duggytuxy_blacklist_ips bi
--   GROUP BY iso2,country, capital, region,subregion,lat,lon
--   ORDER BY nb DESC;
