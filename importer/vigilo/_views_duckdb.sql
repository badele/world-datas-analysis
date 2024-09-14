BEGIN TRANSACTION;

--------------------------------------
-- Views
--------------------------------------

-- Observations
DROP VIEW IF EXISTS wda_vigilo_observations;
CREATE VIEW wda_vigilo_observations AS
    SELECT
        token AS obs_token,
        ts AS obs_ts,
        vo.latitude AS obs_latitude,
        vo.longitude AS obs_longitude,
        address AS obs_address,
        "comment" AS obs_comment,
        explanation AS obs_explanation,
        catid AS obs_catid,
        vc.name AS cat_name ,
        approved AS obs_approved,
        cityname AS obs_cityname,
        vo.scopeid AS obs_scopeid,
        vs.display_name as scope_displayname,
        --
        gc.*
    FROM vigilo_observations vo
    LEFT JOIN vigilo_categories vc ON vo.catid=vc.id
    LEFT JOIN vigilo_scopes vs ON vo.scopeid=vs.id
    LEFT JOIN wda_geonames_cities gc ON vo.geonames_city_id=gc.geonames_city_id
    WHERE vo.geonames_city_id IS NOT NULL
;

COMMIT;
