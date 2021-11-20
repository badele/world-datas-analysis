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

DROP VIEW IF EXISTS v_vigilo_approved_observations;
CREATE VIEW IF NOT EXISTS v_vigilo_approved_observations
AS
SELECT vi.name,vi.country,vo.*,vc.catname FROM vigilo_observation vo
INNER JOIN vigilo_instance vi ON vo.instanceid = vi.InstanceID
INNER JOIN vigilo_category vc ON vo.CategoryID = vc.CategoryID
WHERE vo.approved=1 AND vc.catname NOT lIKE 'COVID%'
ORDER BY name,timestamp;
COMMIT;

-- select * FROM vigilo_observation
-- LEFT JOIN geonames_allentries ON cityname=name
-- WHERE cityname <> ''
-- GROUP BY cityname
-- order by count() DESC