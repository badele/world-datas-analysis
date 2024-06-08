BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Categories
--------------------------------------
CREATE OR REPLACE TABLE vigilo_categories(
  catid BIGINT,
  catname VARCHAR,
  catname_en_US VARCHAR,
  catcolor VARCHAR,
  catdisable BOOLEAN
);

INSERT INTO vigilo_categories SELECT catid,catname,catname_en_US,catcolor,catdisable FROM read_json_auto('./downloaded/vigilo/categories.json');
CREATE UNIQUE INDEX vigilo_categories_idx ON vigilo_categories (catid);

--------------------------------------
-- Scopes
--------------------------------------
CREATE OR REPLACE TABLE vigilo_scopes(
  "scopeid" VARCHAR,
  "name" VARCHAR,
  api_path VARCHAR,
  country VARCHAR
);

INSERT INTO vigilo_scopes SELECT scope,name,api_path,country FROM read_json_auto('./downloaded/vigilo/scopes.json') WHERE prod=true;
CREATE UNIQUE INDEX vigilo_scopes_idx ON vigilo_scopes (scopeid);

--------------------------------------
-- Instances
--------------------------------------
CREATE OR REPLACE TABLE vigilo_instances(
  scopeid VARCHAR,
  name VARCHAR,
  department VARCHAR,
  coordinate_lat_min VARCHAR,
  coordinate_lat_max VARCHAR,
  coordinate_lon_min VARCHAR,
  coordinate_lon_max VARCHAR,
  map_center_string VARCHAR,
  map_zoom VARCHAR,
  contact_email VARCHAR,
  tweet_content VARCHAR,
  twitter VARCHAR,
  map_url VARCHAR,
  backend_version VARCHAR,
  nominatim_urlbase VARCHAR,
  scopename VARCHAR,
  api_path VARCHAR,
  country VARCHAR,
);

INSERT INTO vigilo_instances SELECT
  regexp_extract(filename,'.*([0-9][0-9]_.*)\..*',1),
  display_name,
  department,
  coordinate_lat_min,
  coordinate_lat_max,
  coordinate_lon_min,
  coordinate_lon_max,
  map_center_string,
  map_zoom,
  contact_email,
  tweet_content,
  twitter,
  map_url,
  backend_version,
  nominatim_urlbase,
  '',
  '',
  ''
FROM read_json_auto('./downloaded/vigilo/instance_*.json',filename=true);

UPDATE vigilo_instances SET scopename = (SELECT name FROM vigilo_scopes WHERE scopeid = vigilo_instances.scopeid);
UPDATE vigilo_instances SET api_path = (SELECT api_path FROM vigilo_scopes WHERE scopeid = vigilo_instances.scopeid);
UPDATE vigilo_instances SET country = (SELECT country FROM vigilo_scopes WHERE scopeid = vigilo_instances.scopeid);

CREATE UNIQUE INDEX vigilo_instances_idx ON vigilo_instances (scopeid);

--------------------------------------
-- Observations
--------------------------------------
CREATE OR REPLACE TABLE vigilo_observations(
  scopeid VARCHAR,
  token VARCHAR,
  ts VARCHAR,
  coordinates_lat VARCHAR,
  coordinates_lon VARCHAR,
  address VARCHAR,
  comment VARCHAR,
  explanation VARCHAR,
  status JSON,
  "group" BIGINT,
  catid VARCHAR,
  approved VARCHAR,
  cityname VARCHAR,
);
INSERT INTO vigilo_observations SELECT
  regexp_extract(filename,'.*([0-9][0-9]_.*)\..*',1),
  token,
  "time",
  coordinates_lat,
  coordinates_lon,
  address,
  comment,
  explanation,
  status,
  "group",
  categorie,
  approved,
  cityname
FROM read_json_auto('./downloaded/vigilo/observation_*.json',filename=true);

UPDATE vigilo_observations SET cityname = 'Unknow' WHERE cityname IS NULL;

CREATE UNIQUE INDEX vigilo_observations_idx ON vigilo_observations (scopeid,token);

--------------------------------------
-- view
--------------------------------------
DROP VIEW IF EXISTS v_vigilo_observations;
CREATE VIEW IF NOT EXISTS v_vigilo_observations
AS
SELECT vi.name,vi.country,vo.*,vc.catname FROM vigilo_observations vo
INNER JOIN vigilo_instances vi ON vo.scopeid = vi.scopeid
INNER JOIN vigilo_categories vc ON vo.catid = vc.catid
ORDER BY name,ts;

--------------------------------------
-- dataset summaries
--------------------------------------
INSERT OR REPLACE INTO wda_scopes
SELECT 'vigilo', 'v_vigilo_observations', cityname, COUNT(*)
FROM v_vigilo_observations vvo
GROUP BY 'vigilo', 'v_vigilo_observations', cityname;

INSERT OR REPLACE INTO wda_datasets
SELECT 'vigilo','vigilo','v_vigilo_observations', 'city', 'Vigilo bike observations', 'https://vigilo.city', (SELECT column_count FROM duckdb_views WHERE view_name='v_vigilo_observations'), COUNT(*), COUNT(DISTINCT cityname)
FROM v_vigilo_observations;

INSERT OR REPLACE INTO wda_providers
SELECT 'vigilo',  'Vigilo Android & Web application', 'https://vigilo.city', count(*), sum(nb_observations)
FROM wda_datasets wd
WHERE provider='vigilo';

COMMIT;
