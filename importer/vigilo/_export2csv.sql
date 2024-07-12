BEGIN TRANSACTION;

.mode table
SELECT 'vigilo' AS 'Exporting';

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
-- categories
CREATE OR REPLACE TABLE vigilo_categories (
    id INTEGER,
    name TEXT,
    name_en TEXT,
    color TEXT
);

INSERT INTO vigilo_categories
    SELECT catid,catname,catname_en_US,catcolor
    FROM read_json('./downloaded/vigilo/categories.json');

-- scopes
CREATE OR REPLACE TABLE vigilo_scopes (
    id TEXT,
    name TEXT,
    display_name TEXT,
    country TEXT,
    department INTEGER,
    lat_min DOUBLE,
    lat_max DOUBLE,
    lon_min DOUBLE,
    lon_max DOUBLE,
    map_center_string TEXT,
    map_zoom INTEGER,
    api_path TEXT,
    map_url TEXT,
    nominatim_urlbase TEXT,
    contact_email TEXT,
    tweet_content TEXT,
    twitter TEXT,
    backend_version TEXT
);

INSERT INTO vigilo_scopes
    SELECT scope,
    name,
    display_name,
    country,
    department,
    coordinate_lat_min,
    coordinate_lat_max,
    coordinate_lon_min,
    coordinate_lon_max,
    map_center_string,
    map_zoom,api_path,
    map_url,
    nominatim_urlbase,
    contact_email,
    tweet_content,
    twitter,
    backend_version
    FROM read_json('./downloaded/vigilo/scopes.json');
--
--instances
CREATE OR REPLACE TABLE vigilo_instances (
    scopeid TEXT,
    id INTEGER,
    name TEXT,
    postcode INTEGER,
    website TEXT
);

INSERT INTO vigilo_instances
    SELECT scope,id,name,postcode,website
    FROM read_json('./downloaded/vigilo/instances.json');

-- observations
CREATE OR REPLACE TABLE vigilo_observations (
    scopeid TEXT,
    token TEXT,
    ts INTEGER,
    coordinates_lat DOUBLE,
    coordinates_lon DOUBLE,
    address TEXT,
    "comment" TEXT,
    explanation TEXT,
    catid INTEGER,
    approved INTEGER,
    cityname TEXT
);

INSERT INTO vigilo_observations
    SELECT regexp_extract(filename,'.*([0-9][0-9]_.*)\..*',1),
        token,
        "time",
        coordinates_lat,
        coordinates_lon,
        address,
        "comment",
        explanation,
        categorie,
        approved,
        cityname
    FROM read_json('./downloaded/vigilo/observations_*.json',filename = true)
    WHERE approved = 1;
;

-------------------------------------------------------------------------------
-- Fix
-------------------------------------------------------------------------------
UPDATE vigilo_observations set cityname=ltrim(cityname);

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
COPY vigilo_categories TO './dataset/vigilo/categories.csv' (DELIMITER '|', HEADER);
COPY vigilo_scopes TO './dataset/vigilo/scopes.csv' (DELIMITER '|', HEADER);
COPY vigilo_instances TO './dataset/vigilo/instances.csv' (DELIMITER '|', HEADER);
COPY vigilo_observations TO './dataset/vigilo/observations.csv' (DELIMITER '|', HEADER);

.read './importer/vigilo/_commons.sql'

COMMIT;
