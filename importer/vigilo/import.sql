.head on
.nullvalue NULL

PRAGMA synchronous = OFF;

BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Import category
--------------------------------------
DROP TABLE IF EXISTS "vigilo_categories";
CREATE TABLE "vigilo_categories" (
  "CategoryID" INTEGER,
  "catid" TEXT,
  "catcolor" TEXT,
  "catname" TEXT,
  "catdisable" INTEGER,
  PRIMARY KEY (CategoryID)
);

INSERT INTO "vigilo_categories" SELECT
  rowid+1,
  json_extract(value, '$.catid'),
  json_extract(value, '$.catcolor'),
  json_extract(value, '$.catname'),
  json_extract(value, '$.catdisable')
FROM json_each(readfile('./downloaded/vigilo/categories.json'));

-- --------------------------------------
-- -- Import scope
-- --------------------------------------
DROP TABLE IF EXISTS "vigilo_tmp_scopes";
CREATE TEMPORARY TABLE "vigilo_tmp_scopes" (
  "ScopeID" INTEGER,
  "scope" TEXT,
  "name" TEXT,
  "api_path" TEXT,
  "country" TEXT
  -- PRIMARY KEY (ScopeID)
);

INSERT INTO "vigilo_tmp_scopes" SELECT
  rowid+1,
  json_extract(value, '$.scope'),
  json_extract(value, '$.name'),
  json_extract(value, '$.api_path'),
  json_extract(value, '$.country')
FROM json_each(readfile('./downloaded/vigilo/scopes.json'));

-- --------------------------------------
-- -- Import instance
-- --------------------------------------
DROP TABLE IF EXISTS "vigilo_instances";
CREATE TABLE "vigilo_instances" (
  "InstanceID" INTEGER,
  "name" TEXT,
  "department" TEXT,
  "lat_min" REAL,
  "lat_max" REAL,
  "lon_min" REAL,
  "lon_max" REAL,
  "map_center_string" TEXT,
  "map_zoom" INTEGER,
  "contact_email" TEXT,
  "tweet_content" TEXT,
  "twitter" TEXT,
  "map_url" TEXT,
  "backend_version" TEXT,
  "scope" TEXT,
  "scopename" TEXT,
  "api_path" TEXT,
  "country" TEXT,
  PRIMARY KEY (InstanceID)
);
INSERT INTO "vigilo_instances" SELECT
  rowid+1,
  json_extract(value, '$.display_name'),
  json_extract(value, '$.department'),
  json_extract(value, '$.coordinate_lat_min'),
  json_extract(value, '$.coordinate_lat_max'),
  json_extract(value, '$.coordinate_lon_min'),
  json_extract(value, '$.coordinate_lon_max'),
  json_extract(value, '$.map_center_string'),
  json_extract(value, '$.map_zoom'),
  json_extract(value, '$.contact_email'),
  json_extract(value, '$.tweet_content'),
  json_extract(value, '$.twitter'),
  json_extract(value, '$.map_url'),
  json_extract(value, '$.backend_version'),
  json_extract(value, '$.scope'),
  '',
  '',
  ''
FROM json_each(readfile('./downloaded/vigilo/instances.json'));

UPDATE vigilo_instances SET scopename = (SELECT name FROM vigilo_tmp_scopes WHERE scope = vigilo_instances.scope);
UPDATE vigilo_instances SET api_path = (SELECT api_path FROM vigilo_tmp_scopes WHERE scope = vigilo_instances.scope);
UPDATE vigilo_instances SET country = (SELECT country FROM vigilo_tmp_scopes WHERE scope = vigilo_instances.scope);
-- --------------------------------------
-- -- Import cobservation
-- --------------------------------------
--
DROP TABLE IF EXISTS "vigilo_observations";
CREATE TABLE "vigilo_observations" (
  "InstanceID" INTEGER,
  "scope" INTEGER,
  "token" TEXT,
  "timestamp" INTEGER,
  "coordinates_lat" REAL,
  "coordinates_lon" REAL,
  "address" TEXT,
  "comment" TEXT,
  "explanation" TEXT,
  "status" INTEGER,
  "group" INTEGER,
  "category" INTEGER,
  "approved" INTEGER,
  "cityname" TEXT,
  "CategoryID" INTEGER
  -- PRIMARY KEY (ObservationID)
);
INSERT INTO "vigilo_observations" SELECT
  0,
  json_extract(value, '$.scope'),
  json_extract(value, '$.token'),
  json_extract(value, '$.time'),
  json_extract(value, '$.coordinates_lat'),
  json_extract(value, '$.coordinates_lon'),
  json_extract(value, '$.address'),
  json_extract(value, '$.comment'),
  json_extract(value, '$.explanation'),
  json_extract(value, '$.status'),
  json_extract(value, '$.group'),
  json_extract(value, '$.categorie'),
  json_extract(value, '$.approved'),
  json_extract(value, '$.cityname'),
  0
FROM json_each(readfile('downloaded/vigilo/observations.json'));
UPDATE vigilo_observations SET InstanceID = (SELECT InstanceID FROM vigilo_instances WHERE scope = vigilo_observations.scope);
UPDATE vigilo_observations SET CategoryID = (SELECT CategoryID FROM vigilo_categories WHERE catid = vigilo_observations.category);

ALTER TABLE vigilo_observations DROP COLUMN scope;
ALTER TABLE vigilo_observations DROP COLUMN category;
CREATE UNIQUE INDEX idx_vigilo_observations ON vigilo_observations(InstanceID,token);

-- --------------------------------------
-- -- view
-- --------------------------------------
DROP VIEW IF EXISTS v_vigilo_observations;
CREATE VIEW IF NOT EXISTS v_vigilo_observations
AS
SELECT vi.name,vi.country,vo.*,vc.catname FROM vigilo_observations vo
INNER JOIN vigilo_instances vi ON vo.instanceid = vi.InstanceID
INNER JOIN vigilo_categories vc ON vo.CategoryID = vc.CategoryID
ORDER BY name,timestamp;
--
-- --------------------------------------
-- -- dataset summaries
-- --------------------------------------
-- -- Summarize dataset
INSERT OR REPLACE INTO wda_variable
SELECT 'vigilo', 'vigilo', 'Urban observations', 'Vigilo observations', 'city', 'Vigilo website', count(distinct cityname),9, COUNT(*) FROM v_vigilo_observations vvo;

INSERT OR REPLACE INTO wda_dataset
SELECT provider,real_provider,dataset, max(nb_variables), sum(nb_observations),max(nb_scope) FROM wda_variable wv
WHERE provider='vigilo'
GROUP BY provider,real_provider,dataset;
--
--
-- -- Summarize provider
INSERT OR REPLACE INTO wda_provider
SELECT provider,  'Vigilo observations', 'https://vigilo.city', 0, max(nb_variables),sum(nb_observations),max(nb_scope)
FROM wda_variable wv
WHERE provider='vigilo'
GROUP BY provider;
--
UPDATE wda_provider SET nb_datasets = (SELECT count() FROM wda_dataset WHERE provider='vigilo')
WHERE provider='vigilo';
--
-- -- UPDATE wda_dataset
-- -- SET nb_scopes=(SELECT COUNT(DISTINCT id) FROM owid_entities WHERE validated=1)
-- -- WHERE provider='owid' and scope='country';
--
-- -- UPDATE wda_dataset SET nb_variables=(SELECT count(DISTINCT variableId ) FROM owid_data_values)
-- -- WHERE provider='owid' and scope='country';
COMMIT;
