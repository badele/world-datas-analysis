BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
-- categories
CREATE OR REPLACE TABLE vigilo_categories (
    id BIGINT,
    name TEXT,
    name_en TEXT,
    color TEXT
)
;

INSERT INTO vigilo_categories
    SELECT catid,catname,catname_en_US,catcolor
    FROM read_json('./downloaded/vigilo/categories.json')
;

-- scopes
CREATE OR REPLACE TABLE vigilo_scopes (
    id TEXT,
    name TEXT,
    display_name TEXT,
    iso TEXT,
    country TEXT,
    department BIGINT,
    lat_min DOUBLE,
    lat_max DOUBLE,
    lon_min DOUBLE,
    lon_max DOUBLE,
    map_center_string TEXT,
    map_zoom BIGINT,
    api_path TEXT,
    map_url TEXT,
    nominatim_urlbase TEXT,
    contact_email TEXT,
    tweet_content TEXT,
    twitter TEXT,
    backend_version TEXT,
    geonames_admin_filter TEXT,
    geonames_countryid BIGINT
)
;

INSERT INTO vigilo_scopes
    SELECT scope,
    name,
    display_name,
    NULL,
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
    backend_version,
    NULL,
    NULL
    FROM read_json('./downloaded/vigilo/scopes.json')
;

-- observations
CREATE OR REPLACE TABLE vigilo_observations (
    scopeid TEXT,
    token TEXT,
    ts BIGINT,
    latitude DOUBLE,
    longitude DOUBLE,
    address TEXT,
    "comment" TEXT,
    explanation TEXT,
    catid BIGINT,
    approved BIGINT,
    cityname TEXT,
    geonames_districtid BIGINT,
    geonames_district TEXT,
    geonames_cityid BIGINT,
    geonames_city TEXT
)
;

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
        cityname,
        NULL,
        NULL,
        NULL,
        NULL
    FROM read_json('./downloaded/vigilo/observations_*.json',filename = true)
;
DROP INDEX IF EXISTS idx_vigilo_observations_lat_lon;
CREATE INDEX idx_vigilo_observations_lat_lon ON vigilo_observations (latitude,longitude);

-------------------------------------------------------------------------------
-- Fix
-------------------------------------------------------------------------------
-- Find geoname ISO code
UPDATE vigilo_scopes vs
    SET iso = (
        SELECT iso
        FROM geonames_countries gc
        WHERE vs.country = gc.country
    )
;

UPDATE vigilo_scopes vs
    SET geonames_countryid = (
        SELECT geonameid
        FROM geonames_countries gc
        WHERE vs.iso = gc.iso
    )
;
-- Define filter for getting a city values (used in SQL query)
UPDATE vigilo_scopes SET geonames_admin_filter = 'ADM4' WHERE iso = 'FR';

-- clean²
UPDATE vigilo_observations set cityname=trim(cityname);
-- DELETE FROM vigilo_observations WHERE cityname = 'undefined';
-- DELETE FROM vigilo_observations WHERE cityname IS NULL;
-- DELETE FROM vigilo_observations WHERE cityname = 'Ille-et-Vilaine';

-- UPDATE vigilo_observations SET cityname = 'Noyal-sur-Vilaine' WHERE cityname = 'Noyal-Sur-Vilaine';
-- UPDATE vigilo_observations SET cityname = 'Saint-Marcellin' WHERE cityname = 'Saint Marcellin';
-- UPDATE vigilo_observations SET cityname = 'Servon-sur-Vilaine' WHERE cityname = 'Servon-Sur-Vilaine';
-- UPDATE vigilo_observations SET cityname = 'Hœnheim' WHERE cityname = 'Hoenheim';
-- UPDATE vigilo_observations SET cityname = 'Brest' WHERE cityname = '29200 brest';
-- UPDATE vigilo_observations SET cityname = 'Brest' WHERE cityname = 'Brest.';
-- UPDATE vigilo_observations SET cityname = 'Saint-Aubin-de-Médoc' WHERE cityname = 'Saint-Aubin de Médoc';
-- UPDATE vigilo_observations SET cityname = 'Saint-Sauveur' WHERE cityname = 'Saint Sauveur';
-- UPDATE vigilo_observations SET cityname = 'La Teste-de-Buch' WHERE cityname = 'La Teste de Buch';
-- UPDATE vigilo_observations SET cityname = 'L''Isle-d''Abeau' WHERE cityname = 'L''Isle-dAbeau';
-- UPDATE vigilo_observations SET cityname = 'Lattes' WHERE cityname = 'Boirargues';
-- UPDATE vigilo_observations SET cityname = 'Saint-Vérand' WHERE cityname = 'Saint Vérand';

-- DELETE FROM vigilo_observations WHERE cityname IN (SELECT  cityname FROM vigilo_observations WHERE geonames_cityid IS NULL GROUP BY cityname having count()=1);
-- DELETE FROM vigilo_observations WHERE cityname IN ('Heonheim');

-- find geoname cityid
-- UPDATE vigilo_observations vo
--     SET geonames_cityid =  (
--         SELECT gc.id
--         FROM vigilo_observations vo1 LEFT JOIN vigilo_scopes vs ON vo1.scopeid = vs.id
--         LEFT JOIN geonames_allentries gc ON vs.iso = gc.country_code AND gc.feature_class='A' AND gc.feature_code=vs.geonames_admin_filter AND vo1.cityname = gc.name
--         WHERE vo1.token = vo.token
--     )
-- ;

UPDATE vigilo_observations AS vo
SET geonames_districtid = (
    SELECT g.id
    FROM geonames_latlon_cache AS g
    WHERE g.latlon = vo.latitude || '-' || vo.longitude
)
WHERE EXISTS (
    SELECT 1
    FROM geonames_latlon_cache AS g
    WHERE g.latlon = vo.latitude || '-' || vo.longitude
);

UPDATE vigilo_observations vo
SET geonames_districtid = (
    SELECT id
    FROM geonames_allentries
    WHERE feature_class = 'P' and latitude > vo.latitude - 0.001 and latitude < vo.latitude + 0.001 and longitude > vo.longitude - 0.001 and longitude < vo.longitude + 0.001
    ORDER BY sqrt( power((latitude - vo.latitude), 2) + power((longitude - vo.longitude), 2) ) ASC
    LIMIT 1
)
WHERE geonames_districtid IS NULL
;

UPDATE vigilo_observations vo
SET geonames_districtid = (
    SELECT id
    FROM geonames_allentries
    WHERE feature_class = 'P' and latitude > vo.latitude - 0.005 and latitude < vo.latitude + 0.005 and longitude > vo.longitude - 0.005 and longitude < vo.longitude + 0.005
    ORDER BY sqrt( power((latitude - vo.latitude), 2) + power((longitude - vo.longitude), 2) ) ASC
    LIMIT 1
)
WHERE geonames_districtid IS NULL
;

UPDATE vigilo_observations vo
SET geonames_districtid = (
    SELECT id
    FROM geonames_allentries
    WHERE feature_class = 'P' and latitude > vo.latitude - 0.01 and latitude < vo.latitude + 0.01 and longitude > vo.longitude - 0.01 and longitude < vo.longitude + 0.01
    ORDER BY sqrt( power((latitude - vo.latitude), 2) + power((longitude - vo.longitude), 2) ) ASC
    LIMIT 1
)
WHERE geonames_districtid IS NULL
;

UPDATE vigilo_observations vo
SET geonames_districtid = (
    SELECT id
    FROM geonames_allentries
    WHERE feature_class = 'P' and latitude > vo.latitude - 0.05 and latitude < vo.latitude + 0.05 and longitude > vo.longitude - 0.05 and longitude < vo.longitude + 0.05
    ORDER BY sqrt( power((latitude - vo.latitude), 2) + power((longitude - vo.longitude), 2) ) ASC
    LIMIT 1
)
WHERE geonames_districtid IS NULL
;

UPDATE vigilo_observations vo
SET geonames_district = (
    SELECT name
    FROM geonames_allentries
    WHERE id = vo.geonames_districtid
)
WHERE geonames_districtid IS NOT NULL;

UPDATE vigilo_observations vo
SET geonames_cityid = (
    SELECT city_id
    FROM geonames_allentries
    WHERE id = vo.geonames_districtid
)
WHERE geonames_districtid IS NOT NULL;

UPDATE vigilo_observations vo
SET geonames_city = (
    SELECT city_name
    FROM geonames_allentries
    WHERE id = vo.geonames_districtid
)
WHERE geonames_districtid IS NOT NULL;

INSERT INTO geonames_latlon_cache
    SELECT geonames_districtid,latitude || '-' || longitude as latlon FROM vigilo_observations WHERE latlon NOT IN (SELECT latlon FROM geonames_latlon_cache)
;
COPY geonames_latlon_cache TO './dataset/geonames/latlon_cache.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
COPY vigilo_categories TO './dataset/vigilo/categories.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY vigilo_scopes TO './dataset/vigilo/scopes.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY vigilo_observations TO './dataset/vigilo/observations.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', PARTITION_BY (scopeid));

COMMIT;
