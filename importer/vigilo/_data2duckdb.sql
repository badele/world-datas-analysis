BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Categories
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE vigilo_categories AS
    SELECT catid AS id, catname AS name, catname_en_US AS name_en, catcolor AS color
    FROM read_json('./downloaded/vigilo/categories.json');

-------------------------------------------------------------------------------
-- Scopes actifs (depuis l'API Vigilo)
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE vigilo_scopes_new AS
    SELECT
        scope                                   AS id,
        name,
        display_name,
        NULL::TEXT                              AS iso,
        'France'                                AS country,
        department,
        TRY_CAST(coordinate_lat_min AS DOUBLE)  AS lat_min,
        TRY_CAST(coordinate_lat_max AS DOUBLE)  AS lat_max,
        TRY_CAST(coordinate_lon_min AS DOUBLE)  AS lon_min,
        TRY_CAST(coordinate_lon_max AS DOUBLE)  AS lon_max,
        map_center_string,
        TRY_CAST(map_zoom AS BIGINT)            AS map_zoom,
        api_path,
        map_url,
        nominatim_urlbase,
        contact_email,
        tweet_content,
        twitter,
        backend_version,
        NULL::TEXT                              AS geonames_admin_filter,
        NULL::BIGINT                            AS geonames_countryid,
        version,
        "count"                                 AS check_count,
        issues_time,
        TRY_CAST("last" AS DATE)                AS last_check_date,
        ok                                      AS check_ok
    FROM read_json('./downloaded/vigilo/scopes.json');

-------------------------------------------------------------------------------
-- Scopes fusionnés : actifs (API) + inactifs (parquet existant)
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE vigilo_scopes (
    id TEXT, name TEXT, display_name TEXT, iso TEXT, country TEXT, department TEXT,
    lat_min DOUBLE, lat_max DOUBLE, lon_min DOUBLE, lon_max DOUBLE,
    map_center_string TEXT, map_zoom BIGINT, api_path TEXT, map_url TEXT,
    nominatim_urlbase TEXT, contact_email TEXT, tweet_content TEXT, twitter TEXT,
    backend_version TEXT, geonames_admin_filter TEXT, geonames_countryid BIGINT,
    is_active BOOLEAN, first_seen_at DATE, last_seen_at DATE, nb_observations BIGINT,
    version TEXT, check_count BIGINT, issues_time DOUBLE, last_check_date DATE, check_ok BOOLEAN
);

-- Scopes actifs : préserve first_seen_at depuis le parquet existant si connu
INSERT INTO vigilo_scopes BY NAME
    SELECT
        n.*,
        true                                        AS is_active,
        COALESCE(
            (SELECT first_seen_at
             FROM read_parquet('./downloaded/vigilo/from_r2/raw/scopes.parquet')
             WHERE id = n.id LIMIT 1),
            CURRENT_DATE
        )                                           AS first_seen_at,
        CURRENT_DATE                                AS last_seen_at,
        0::BIGINT                                   AS nb_observations
    FROM vigilo_scopes_new n;

-- Scopes inactifs : présents dans le parquet existant mais absents du dernier download
-- On force is_active = false quel que soit leur statut précédent (gère la première disparition)
INSERT INTO vigilo_scopes BY NAME
    SELECT * REPLACE (false AS is_active)
    FROM read_parquet('./downloaded/vigilo/from_r2/raw/scopes.parquet')
    WHERE id NOT IN (SELECT id FROM vigilo_scopes_new);

-------------------------------------------------------------------------------
-- Observations actives (depuis les JSON téléchargés)
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE vigilo_observations (
    scopeid TEXT, token TEXT, ts BIGINT, latitude DOUBLE, longitude DOUBLE,
    address TEXT, "comment" TEXT, explanation TEXT, catid BIGINT, approved BIGINT,
    cityname TEXT, geonames_districtid BIGINT, geonames_district TEXT,
    geonames_cityid BIGINT, geonames_city TEXT
);

INSERT INTO vigilo_observations
    SELECT
        regexp_extract(filename, '.*observations_(.*)\.json', 1) AS scopeid,
        token,
        "time"          AS ts,
        coordinates_lat AS latitude,
        coordinates_lon AS longitude,
        address,
        "comment",
        explanation,
        categorie       AS catid,
        approved,
        cityname,
        NULL::BIGINT    AS geonames_districtid,
        NULL::TEXT      AS geonames_district,
        NULL::BIGINT    AS geonames_cityid,
        NULL::TEXT      AS geonames_city
    FROM read_json('./downloaded/vigilo/observations_*.json', filename=true);

-- Observations des scopes inactifs (depuis le parquet existant)
INSERT INTO vigilo_observations
    SELECT scopeid, token, ts, latitude, longitude, address, "comment", explanation,
           catid, approved, cityname, geonames_districtid, geonames_district,
           geonames_cityid, geonames_city
    FROM read_parquet('./downloaded/vigilo/from_r2/raw/observations.parquet')
    WHERE scopeid NOT IN (SELECT DISTINCT scopeid FROM vigilo_observations);

-------------------------------------------------------------------------------
-- Enrichissement geonames
-------------------------------------------------------------------------------
UPDATE vigilo_scopes vs
    SET iso = (SELECT iso FROM geonames_countries gc WHERE vs.country = gc.country LIMIT 1);

UPDATE vigilo_scopes vs
    SET geonames_countryid = (SELECT geonameid FROM geonames_countries gc WHERE vs.iso = gc.iso LIMIT 1);

UPDATE vigilo_scopes SET geonames_admin_filter = 'ADM4' WHERE iso = 'FR';

UPDATE vigilo_observations AS vo
SET geonames_districtid = (
    SELECT g.id FROM geonames_latlon_cache AS g
    WHERE g.latlon = vo.latitude || '-' || vo.longitude LIMIT 1
)
WHERE EXISTS (
    SELECT 1 FROM geonames_latlon_cache AS g
    WHERE g.latlon = vo.latitude || '-' || vo.longitude
);

UPDATE vigilo_observations vo
SET geonames_districtid = (
    SELECT id FROM geonames_allentries
    WHERE feature_class = 'P'
      AND latitude BETWEEN vo.latitude - 0.05 AND vo.latitude + 0.05
      AND longitude BETWEEN vo.longitude - 0.05 AND vo.longitude + 0.05
    ORDER BY sqrt(power(latitude - vo.latitude, 2) + power(longitude - vo.longitude, 2))
    LIMIT 1
)
WHERE geonames_districtid IS NULL;

UPDATE vigilo_observations vo
SET geonames_district = (SELECT name      FROM geonames_allentries WHERE id = vo.geonames_districtid LIMIT 1)
WHERE geonames_districtid IS NOT NULL;

UPDATE vigilo_observations vo
SET geonames_cityid   = (SELECT city_id   FROM geonames_allentries WHERE id = vo.geonames_districtid LIMIT 1)
WHERE geonames_districtid IS NOT NULL;

UPDATE vigilo_observations vo
SET geonames_city     = (SELECT city_name FROM geonames_allentries WHERE id = vo.geonames_districtid LIMIT 1)
WHERE geonames_districtid IS NOT NULL;

INSERT INTO geonames_latlon_cache
    SELECT geonames_districtid, latitude || '-' || longitude AS latlon
    FROM vigilo_observations
    WHERE geonames_districtid IS NOT NULL
      AND (latitude || '-' || longitude) NOT IN (SELECT latlon FROM geonames_latlon_cache);

COPY geonames_latlon_cache TO './dataset/geonames/raw/latlon_cache.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);

-------------------------------------------------------------------------------
-- Mise à jour des stats des scopes
-------------------------------------------------------------------------------
UPDATE vigilo_scopes vs
SET nb_observations = stats.nb_observations,
    first_seen_at   = stats.first_seen_at,
    last_seen_at    = stats.last_seen_at
FROM (
    SELECT scopeid AS id,
           COUNT(*)                          AS nb_observations,
           MIN(to_timestamp(ts::DOUBLE)::DATE) AS first_seen_at,
           MAX(to_timestamp(ts::DOUBLE)::DATE) AS last_seen_at
    FROM vigilo_observations
    GROUP BY scopeid
) stats
WHERE vs.id = stats.id;

UPDATE vigilo_scopes SET name = id, display_name = id WHERE name IS NULL;

-------------------------------------------------------------------------------
-- Nettoyage
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS vigilo_scopes_new;

-------------------------------------------------------------------------------
-- Export parquets
-------------------------------------------------------------------------------
COPY vigilo_categories TO './dataset/vigilo/raw/categories.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 4096);
COPY vigilo_scopes     TO './dataset/vigilo/raw/scopes.parquet'     (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 4096);
COPY (SELECT * FROM vigilo_observations ORDER BY scopeid)
                       TO './dataset/vigilo/raw/observations.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 4096);

COMMIT;
