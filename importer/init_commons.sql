--------------------------------------
-- Dataset
--------------------------------------

CREATE TABLE IF NOT EXISTS geonames_latlon_cache(
    id INTEGER,
    latlon TEXT
)
;
CREATE INDEX IF NOT EXISTS idx_geonames_latlon_cache_latlon ON geonames_latlon_cache (latlon);



-- CREATE TABLE IF NOT EXISTS wda_blacklist_ips(
--   ip_number BIGINT,
--   ip TEXT,
--   duggytuxy INTEGER,
--   ipsum INTEGER
-- );
-- CREATE INDEX IF NOT EXISTS wda_blacklist_ips_idx ON wda_blacklist_ips(ip_number);
