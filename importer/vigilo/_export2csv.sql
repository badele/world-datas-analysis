BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Import
-------------------------------------------------------------------------------
-- categories
CREATE OR REPLACE TABLE vigilo_categories (
    id INTEGER,
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
    backend_version TEXT,
    geonames_admin_filter TEXT,
    geonames_countryid INTEGER
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
--
--instances
CREATE OR REPLACE TABLE vigilo_instances (
    scopeid TEXT,
    id INTEGER,
    name TEXT,
    postcode INTEGER,
    website TEXT,
    geonames_city_id INTEGER
)
;

INSERT INTO vigilo_instances
    SELECT scope,id,name,postcode,website,NULL
    FROM read_json('./downloaded/vigilo/instances.json')
;

-- observations
CREATE OR REPLACE TABLE vigilo_observations (
    scopeid TEXT,
    token TEXT,
    ts INTEGER,
    latitude DOUBLE,
    longitude DOUBLE,
    address TEXT,
    "comment" TEXT,
    explanation TEXT,
    catid INTEGER,
    approved INTEGER,
    cityname TEXT,
    geonames_city_id INTEGER
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
        NULL

    FROM read_json('./downloaded/vigilo/observations_*.json',filename = true)
;

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
-- CHECK NOT FOUND
SELECT 'vigilo_scopes';
SELECT * FROM vigilo_scopes WHERE geonames_countryid IS NULL;


-- clean²
UPDATE vigilo_observations set cityname=ltrim(cityname);
DELETE FROM vigilo_observations WHERE cityname = 'undefined';
DELETE FROM vigilo_observations WHERE cityname IS NULL;

UPDATE vigilo_observations SET cityname = 'Noyal-sur-Vilaine' WHERE cityname = 'Noyal-Sur-Vilaine';
UPDATE vigilo_observations SET cityname = 'Saint-Marcellin' WHERE cityname = 'Saint Marcellin';
UPDATE vigilo_observations SET cityname = 'Servon-sur-Vilaine' WHERE cityname = 'Servon-Sur-Vilaine';
UPDATE vigilo_observations SET cityname = 'Hœnheim' WHERE cityname = 'Hoenheim';
UPDATE vigilo_observations SET cityname = 'Brest' WHERE cityname = 'Brest. ';
UPDATE vigilo_observations SET cityname = 'Saint-Aubin-de-Médoc' WHERE cityname = 'Saint-Aubin de Médoc';
UPDATE vigilo_observations SET cityname = 'Saint-Sauveur' WHERE cityname = 'Saint Sauveur';
UPDATE vigilo_observations SET cityname = 'La Teste-de-Buch' WHERE cityname = 'La Teste de Buch';
UPDATE vigilo_observations SET cityname = 'L''Isle-d''Abeau' WHERE cityname = 'L''Isle-dAbeau';

UPDATE vigilo_instances SET name = 'Noyal-sur-Vilaine' WHERE name = 'Noyal-Sur-Vilaine';
UPDATE vigilo_instances SET name = 'Saint-Marcellin' WHERE name = 'Saint Marcellin';
UPDATE vigilo_instances SET name = 'Servon-sur-Vilaine' WHERE name = 'Servon-Sur-Vilaine';
UPDATE vigilo_instances SET name = 'Hœnheim' WHERE name = 'Hoenheim';
UPDATE vigilo_instances SET name = 'Brest' WHERE name = 'Brest. ';
UPDATE vigilo_instances SET name = 'Saint-Aubin-de-Médoc' WHERE name = 'Saint-Aubin de Médoc';
UPDATE vigilo_instances SET name = 'Saint-Sauveur' WHERE name = 'Saint Sauveur';
UPDATE vigilo_instances SET name = 'La Teste-de-Buch' WHERE name = 'La Teste de Buch';
UPDATE vigilo_instances SET name = 'L''Isle-d''Abeau' WHERE name = 'L''Isle-dAbeau';

UPDATE vigilo_instances SET name = 'Arcachon' WHERE name = 'arcachon';
UPDATE vigilo_instances SET name = 'Saint-Martin-le-Nœud' WHERE name = 'Saint-Martin-Le-Noeud';
UPDATE vigilo_instances SET name = 'Bordeaux' WHERE name = 'bordeaux métropole';
UPDATE vigilo_instances SET name = 'Plougastel-Daoulas' WHERE name = 'Plougastel';
-- UPDATE vigilo_instances SET name = 'Ruy' WHERE name = 'Ruy';
UPDATE vigilo_instances SET name = 'Plougastel-Daoulas' WHERE name = 'Plougastel';
UPDATE vigilo_instances SET name = 'Basse-Goulaine' WHERE name = 'Basse Goulaine';
UPDATE vigilo_instances SET name = 'Saint-Aignan-Grandlieu' WHERE name = 'Saint-Aignan de Grand Lieu';
UPDATE vigilo_instances SET name = 'Saint-Étienne-de-Montluc' WHERE name = 'Saint-etienne-de-Montluc';
UPDATE vigilo_instances SET name = 'Saint-Julien-de-Concelles' WHERE name = 'Saint-Julien-de-concelles';
UPDATE vigilo_instances SET name = 'Treillières' WHERE name = 'treillieres';
UPDATE vigilo_instances SET name = 'La Ville-du-Bois' WHERE name = 'La Ville du Bois';
UPDATE vigilo_instances SET name = 'Chatte' WHERE name like 'Chatte%';
UPDATE vigilo_instances SET name = 'Saint-Vérand' WHERE name = 'Saint Vérand';
UPDATE vigilo_instances SET name = 'Le Fœil' WHERE name = 'Le Foeil';
UPDATE vigilo_instances SET name = 'Le Vieux-Bourg' WHERE name = 'Le Vieux Bourg';
UPDATE vigilo_instances SET name = 'Plœuc-L''Hermitage' WHERE name = 'Ploeuc - l''Hermitage';
UPDATE vigilo_instances SET name = 'Saint-Quay-Portrieux' WHERE name like'Saint-Quay Portrieux%';
-- UPDATE vigilo_instances SET name = 'Kehl' WHERE name like 'Kehl%';
UPDATE vigilo_instances SET name = 'Avilly-Saint-Léonard' WHERE name = 'Avilly-Saint-Leonard';
UPDATE vigilo_instances SET name = 'Île-d''Arz' WHERE name = 'L Île d Arz';
UPDATE vigilo_instances SET name = 'Île-aux-Moines' WHERE name = 'L''Île-aux-Moines';
UPDATE vigilo_instances SET name = 'Lattes' WHERE name = 'Boirargues';




-- find geoname city
UPDATE vigilo_instances vi
    SET geonames_city_id =  (
        SELECT gc.id as cityid
        FROM vigilo_instances vi1 LEFT JOIN vigilo_scopes vs ON vi1.scopeid = vs.id
        LEFT JOIN geonames_allentries gc ON vs.iso = gc.country_code AND gc.feature_class='A' AND gc.feature_code=vs.geonames_admin_filter AND vi1.name = gc.name
        WHERE vi1.scopeid = vi.scopeid AND vi1.id = vi.id
    )
;
-- CHECK NOT FOUND
SELECT 'geonames_instances';
SELECT * FROM vigilo_instances WHERE geonames_city_id IS NULL;


-- find geoname city
UPDATE vigilo_observations vo
    SET geonames_city_id =  (
        SELECT gc.id
        FROM vigilo_observations vo1 LEFT JOIN vigilo_scopes vs ON vo1.scopeid = vs.id
        LEFT JOIN geonames_allentries gc ON vs.iso = gc.country_code AND gc.feature_class='A' AND gc.feature_code=vs.geonames_admin_filter AND vo1.cityname = gc.name
        WHERE vo1.token = vo.token
    )
;
-- CHECK NOT FOUND
SELECT 'vigilo_observations';
SELECT cityname,count(*) AS nb FROM vigilo_observations WHERE geonames_city_id IS NULL GROUP BY cityname ORDER BY nb DESC;


-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
COPY vigilo_categories TO './dataset/vigilo/categories.csv' (DELIMITER '|', HEADER);
COPY vigilo_scopes TO './dataset/vigilo/scopes.csv' (DELIMITER '|', HEADER);
COPY vigilo_instances TO './dataset/vigilo/instances.csv' (DELIMITER '|', HEADER);
COPY vigilo_observations TO './dataset/vigilo/observations.csv' (DELIMITER '|', HEADER);
COMMIT;

.read './importer/vigilo/_commons.sql'
