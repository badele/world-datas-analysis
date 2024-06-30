--------------------------------------
-- Index
--------------------------------------

CREATE UNIQUE INDEX dr5hn_regions_idx ON dr5hn_regions (id);
CREATE UNIQUE INDEX dr5hn_subregions_idx ON dr5hn_subregions (id);
CREATE UNIQUE INDEX dr5hn_countries_idx ON dr5hn_countries (id);
CREATE UNIQUE INDEX dr5hn_cities_idx ON dr5hn_cities (id,country_id,state_id,latitude,longitude);
CREATE UNIQUE INDEX dr5hn_states_idx ON dr5hn_states (state_code,country_id,type);

-- Regions
DROP VIEW IF EXISTS v_wda_dr5hn_regions;
CREATE VIEW v_wda_dr5hn_regions AS
    SELECT
        name AS region,
        wikiDataId AS wikidata_id
        FROM dr5hn_regions;

-- Subregions
DROP VIEW IF EXISTS v_wda_dr5hn_subregions;
CREATE VIEW v_wda_dr5hn_subregions AS
    SELECT
        sr.name AS subregion,
        r.name AS region,
        sr.wikiDataId AS wikidata_id
        FROM dr5hn_subregions sr
        LEFT JOIN dr5hn_regions r ON sr.region_id = r.id;

-- -- Countries
DROP VIEW IF EXISTS v_wda_dr5hn_countries;
CREATE VIEW v_wda_dr5hn_countries AS
SELECT
        co.emoji flag,
        co.name AS country,
        subregion,
        region,
        capital,
        iso2,
        iso3,
        numeric_code AS numcode
    FROM dr5hn_countries co
    LEFT JOIN dr5hn_regions re ON re.id=co.region_id
    LEFT JOIN dr5hn_subregions sr ON sr.id=co.subregion_id;

-- Cities
CREATE OR REPLACE VIEW v_wda_dr5hn_cities AS
  SELECT
        ci.name AS city,
        ci.latitude AS lat,
        ci.longitude AS lon,
        st.name AS state,
        st.state_code,
        st.latitude AS state_lat,
        st.longitude AS state_lon,
        type,
        iso2,
        co.emoji flag,
        co.name AS country,
        sr.name AS subregion,
        re.name AS region,
        ci.wikiDataId AS wikidata_id
    FROM dr5hn_cities ci
    LEFT JOIN dr5hn_states st ON ci.state_id=st.id
    LEFT JOIN dr5hn_countries co ON ci.country_id=co.id
    LEFT JOIN dr5hn_regions re ON re.id=co.region_id
    LEFT JOIN dr5hn_subregions sr ON sr.id=co.subregion_id;
--
-- state
CREATE OR REPLACE VIEW v_wda_dr5hn_states AS
    SELECT

        st.name AS state,
        co.emoji flag,
        co.name AS country,
        type,
        st.latitude AS lat,
        st.longitude AS lon,
        state_code
    FROM dr5hn_states st
    LEFT JOIN dr5hn_countries co ON co.id=st.country_id;
