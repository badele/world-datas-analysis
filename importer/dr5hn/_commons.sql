--------------------------------------
-- Index
--------------------------------------
--
--
CREATE UNIQUE INDEX wda_dr5hn_regions_idx ON wda_dr5hn_regions (region);
CREATE UNIQUE INDEX wda_dr5hn_subregions_idx ON wda_dr5hn_subregions (subregion);
CREATE UNIQUE INDEX wda_dr5hn_countries_idx ON wda_dr5hn_countries (country);
CREATE UNIQUE INDEX wda_dr5hn_cities_idx ON wda_dr5hn_cities (city,iso2,state,lat,lon);
CREATE UNIQUE INDEX wda_dr5hn_states_idx ON wda_dr5hn_states (state_code,country,type);
