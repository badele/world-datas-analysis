.head on
.nullvalue NULL

PRAGMA synchronous = OFF;

BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Import category
--------------------------------------
DROP TABLE IF EXISTS "vigilo_category";
CREATE TABLE "vigilo_category" (
  "catcolor" TEXT,
  "CategoryID" INTEGER,
  "catname" TEXT,
  "catname_en" TEXT,
  "catdisable" INTEGER,
  PRIMARY KEY (CategoryID)
);

.import --csv --skip 1 './downloaded/vigilo/category.csv' vigilo_category

--------------------------------------
-- Import instance
--------------------------------------
DROP TABLE IF EXISTS "vigilo_instance";
CREATE TABLE "vigilo_instance" (
  "InstanceID" INTEGER,
  "name" TEXT,
  "api_path" TEXT,
  "country" TEXT,
  "scope" TEXT,
  "version" TEXT,
  "lat_min" REAL,
  "lat_max" REAL,
  "lon_min" REAL,
  "lon_max" REAL,
  PRIMARY KEY (InstanceID)
);

.import --csv --skip 1 './downloaded/vigilo/instance.csv' vigilo_instance

--------------------------------------
-- Import cobservation
--------------------------------------

DROP TABLE IF EXISTS "vigilo_observation";
CREATE TABLE "vigilo_observation" (
  "InstanceID" INTEGER,
  "token" TEXT,
  "coordinates_lat" REAL,
  "coordinates_lon" REAL,
  "address" TEXT,
  "comment" TEXT,
  "explanation" TEXT,
  "timestamp" INTEGER,
  "status" INTEGER,
  "group" INTEGER,
  "CategoryID" INTEGER,
  "approved" INTEGER,
  "cityname" TEXT,
  PRIMARY KEY (InstanceID, token)
);

.import --csv --skip 1 './downloaded/vigilo/observation.csv' vigilo_observation

--------------------------------------
-- view
--------------------------------------

DROP VIEW IF EXISTS v_vigilo_observations;
CREATE VIEW IF NOT EXISTS v_vigilo_observations
AS
SELECT vi.name,vi.country,vo.*,vc.catname FROM vigilo_observation vo
INNER JOIN vigilo_instance vi ON vo.instanceid = vi.InstanceID
INNER JOIN vigilo_category vc ON vo.CategoryID = vc.CategoryID
ORDER BY name,timestamp;
COMMIT;

--------------------------------------
-- dataset summaries
--------------------------------------
-- Summarize dataset 
INSERT OR REPLACE INTO wda_variable 
SELECT "vigilo", "vigilo", "Urban observations", "Vigilo observations", "city", "Vigilo website", count(distinct cityname),9, COUNT(*) FROM v_vigilo_observations vvo;

INSERT OR REPLACE INTO wda_dataset
SELECT provider,real_provider,dataset, max(nb_variables), sum(nb_observations),max(nb_scope) FROM wda_variable wv
WHERE provider="vigilo"
GROUP BY provider,real_provider,dataset;


-- Summarize provider
INSERT OR REPLACE INTO wda_provider 
SELECT provider,  "Vigilo observations", "https://vigilo.city", 0, max(nb_variables),sum(nb_observations),max(nb_scope)
FROM wda_variable wv
WHERE provider="vigilo"
GROUP BY provider;

UPDATE wda_provider SET nb_datasets = (SELECT count() FROM wda_dataset WHERE provider='vigilo')
WHERE provider='vigilo';

-- UPDATE wda_dataset 
-- SET nb_scopes=(SELECT COUNT(DISTINCT id) FROM owid_entities WHERE validated=1)
-- WHERE provider='owid' and scope='country';

-- UPDATE wda_dataset SET nb_variables=(SELECT count(DISTINCT variableId ) FROM owid_data_values)
-- WHERE provider='owid' and scope='country';