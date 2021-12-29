.head on
.nullvalue NULL


PRAGMA synchronous = OFF;

BEGIN TRANSACTION;

.read './importer/init.sql'

--------------------------------------
-- Import datas
--------------------------------------

DROP TABLE IF EXISTS owid_continent;
CREATE TABLE owid_continent (
  id INTEGER,
  continent_code TEXT,
  continent_name TEXT,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/continent.csv' owid_continent


-- DROP TABLE IF EXISTS owid_country_latest_data;
-- CREATE TABLE owid_country_latest_data (
--   country_code TEXT DEFAULT NULL,
--   variable_id INTEGER DEFAULT NULL,
--   year INTEGER DEFAULT NULL,
--   value REAL DEFAULT NULL,
--   PRIMARY KEY (country_code,variable_id)
-- );

--.import --csv './importer/owid/exported/country_latest_data.csv' owid_country_latest_data

--------------------------------------
-- Import country
--------------------------------------

DROP TABLE IF EXISTS owid_country;
CREATE TABLE owid_country (
  id INTEGER NOT NULL,
  owid_name TEXT NOT NULL,
  iso_alpha2 TEXT DEFAULT NULL,
  iso_alpha3 TEXT DEFAULT NULL,
  imf_code INTEGER DEFAULT NULL,
  cow_letter TEXT DEFAULT NULL,
  cow_code INTEGER DEFAULT NULL,
  unctad_code TEXT DEFAULT NULL,
  marc_code TEXT DEFAULT NULL,
  ncd_code TEXT DEFAULT NULL,
  kansas_code TEXT DEFAULT NULL,
  penn_code TEXT DEFAULT NULL,
  continent INTEGER DEFAULT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/country.csv' owid_country

--------------------------------------
-- Import country data values
--------------------------------------

DROP TABLE IF EXISTS owid_data_values;
CREATE TABLE owid_data_values (
  value REAL NOT NULL,
  year INTEGER NOT NULL,
  entityId INTEGER NOT NULL,
  variableId INTEGER NOT NULL,
  PRIMARY KEY (variableId,entityId,year)
);

.import --csv './importer/owid/exported/data_values.csv' owid_data_values

--------------------------------------
-- Import dataset tags
--------------------------------------

DROP TABLE IF EXISTS owid_dataset_tags;
CREATE TABLE owid_dataset_tags (
  datasetId INTEGER NOT NULL,
  tagId INTEGER NOT NULL,
  PRIMARY KEY (datasetId,tagId)
);

.import --csv './importer/owid/exported/dataset_tags.csv' owid_dataset_tags

--------------------------------------
-- Import dataset
--------------------------------------

DROP TABLE IF EXISTS owid_datasets;
CREATE TABLE owid_datasets (
  id INTEGER NOT NULL,
  name TEXT DEFAULT NULL,
  description TEXT NOT NULL,
  createdAt datetime NOT NULL,
  updatedAt datetime NOT NULL,
  namespace TEXT NOT NULL,
  isPrivate INTEGER NOT NULL DEFAULT '0',
  createdByUserId INTEGER NOT NULL,
  metadataEditedAt datetime NOT NULL,
  metadataEditedByUserId INTEGER NOT NULL,
  dataEditedAt datetime NOT NULL,
  dataEditedByUserId INTEGER NOT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/datasets.csv' owid_datasets

-- Fix bad characters
update owid_datasets set 
name=replace(trim(name),char(9),''),
description=replace(trim(description),char(9),'');

--------------------------------------
-- Import entities
--------------------------------------

DROP TABLE IF EXISTS owid_entities;
CREATE TABLE owid_entities (
  id INTEGER NOT NULL ,
  code TEXT DEFAULT NULL,
  name TEXT NOT NULL,
  validated INTEGER NOT NULL,
  createdAt datetime NOT NULL,
  updatedAt datetime NOT NULL,
  displayName TEXT NOT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/entities.csv' owid_entities

--------------------------------------
-- Import namespaces
--------------------------------------

DROP TABLE IF EXISTS owid_namespaces;
CREATE TABLE owid_namespaces (
  id INTEGER NOT NULL ,
  name TEXT NOT NULL,
  description TEXT DEFAULT NULL,
  isArchived INTEGER NOT NULL DEFAULT '0',
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/namespaces.csv' owid_namespaces

--------------------------------------
-- Import sources
--------------------------------------

DROP TABLE IF EXISTS owid_sources;
CREATE TABLE owid_sources (
  id INTEGER NOT NULL ,
  name TEXT DEFAULT NULL,
  description json NOT NULL,
  createdAt datetime NOT NULL,
  updatedAt datetime NOT NULL,
  datasetId INTEGER DEFAULT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/sources.csv' owid_sources

--------------------------------------
-- Import tags
--------------------------------------

DROP TABLE IF EXISTS owid_tags;
CREATE TABLE owid_tags (
  id INTEGER NOT NULL ,
  name TEXT NOT NULL,
  createdAt datetime NOT NULL,
  updatedAt datetime NOT NULL,
  parentId INTEGER DEFAULT NULL,
  isBulkImport INTEGER NOT NULL DEFAULT '0',
  specialType TEXT DEFAULT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/tags.csv' owid_tags

--------------------------------------
-- Import variables
--------------------------------------

DROP TABLE IF EXISTS owid_variables;
CREATE TABLE owid_variables (
  id INTEGER NOT NULL ,
  name varchar(1000) NOT NULL,
  unit TEXT NOT NULL,
  description TEXT,
  createdAt datetime NOT NULL,
  updatedAt datetime NOT NULL,
  code TEXT DEFAULT NULL,
  coverage TEXT NOT NULL,
  timespan TEXT NOT NULL,
  datasetId INTEGER NOT NULL,
  sourceId INTEGER NOT NULL,
  shortUnit TEXT DEFAULT NULL,
  display json NOT NULL,
  columnOrder INTEGER NOT NULL DEFAULT '0',
  originalMetadata json DEFAULT NULL,
  PRIMARY KEY (id)
);

.import --csv './importer/owid/exported/variables.csv' owid_variables

-- Add variable type
ALTER TABLE owid_variables
  ADD var_type TEXT;

-- Update variable type from owid_data_values
UPDATE owid_variables AS ov 
SET var_type=ocld.var_type
FROM (select variableId,typeof(value) as var_type from owid_data_values GROUP BY variableId) AS ocld
WHERE ov.id = ocld.variableId;

-- Fix bad characters
update owid_variables set 
name=replace(trim(name),char(9),''),
description=replace(trim(description),char(9),'');


--------------------------------------
-- Import wda summary
--------------------------------------

DROP TABLE IF EXISTS wda_owid_country_summary;
CREATE TABLE wda_owid_country_summary (
  entity_id INTEGER,
  variable_id INTEGER,
  firstyear INTEGER,
  lastyear INTEGER,
  nbyears INTEGER,
  firstvalue REAL,
  lastvalue REAL,
  growth_percent REAL,
  min_value REAL,
  max_value REAL,
  lr_a REAL,
  lr_b REAL,
  lr_percent_slope REAL,
  data_quality REAL,
  corr REAL,
  PRIMARY KEY (entity_id,variable_id)
);

-- summaries
INSERT INTO wda_owid_country_summary
SELECT 
odv.entityID,
odv.variableId,
MIN(odv.year) AS firstyear,
MAX(odv.year) AS lastyear,
COUNT(odv.year) AS nbyears,
NULL AS first_value,
NULL AS last_value,
NULL AS growth_percent,
MIN(odv.value) AS min_value,
MAX(odv.value) AS max_value,
ROUND((COUNT(odv.value) * SUM(odv.year * odv.value) - (SUM(odv.year) * SUM(odv.value))) / ((COUNT(odv.value) * SUM(POW(odv.year,2))) - (SUM(odv.year) * SUM(odv.year))),4) AS lr_a,
(SUM(odv.value) / COUNT(odv.value)) - (ROUND((COUNT(odv.value) * SUM(odv.year * odv.value) - (SUM(odv.year) * SUM(odv.value))) / ((COUNT(odv.value) * SUM(POW(odv.year,2))) - (SUM(odv.year) * SUM(odv.year))),4)) * (SUM(odv.year) / COUNT(odv.year)) AS lr_b,
NULL AS lr_percent_slope,
ROUND(COUNT(odv.year) / odv1.nb_years * 100,2) AS data_quality,
SUM((odv.year-odv2.avg_year)*(odv.value-odv2.avg_value)) /
(SQRT(SUM(POW(odv.year-odv2.avg_year,2))) * SQRT(SUM(POW(odv.value-odv2.avg_value,2)))) AS corr
FROM owid_data_values odv,
(SELECT
MAX(YEAR) - MIN(YEAR) + 1.0 nb_years, 
MIN(YEAR) min_year,
MAX(YEAR) max_year
FROM owid_data_values) odv1,
 (SELECT
 *,
AVG(value) AS avg_value,
AVG(YEAR) AS avg_year
FROM owid_data_values
GROUP BY EntityId,VariableId) AS odv2
INNER JOIN owid_entities oen ON odv.EntityId = oen.id 
WHERE oen.validated = 1 AND odv.EntityId = odv2.EntityId AND odv.VariableId = odv2.VariableId
GROUP BY odv.EntityId,odv.VariableId;

-- slope
UPDATE wda_owid_country_summary SET lr_percent_slope=((2*lr_a+lr_b)-(lr_a+lr_b))/abs(lr_a+lr_b)*100;

-- first value
UPDATE wda_owid_country_summary AS du SET firstvalue=(
  SELECT value FROM owid_data_values ds 
  WHERE du.entity_id = ds.EntityId AND du.variable_id = ds.VariableId AND du.firstyear = ds.year
  );


-- last value
UPDATE wda_owid_country_summary AS du SET lastvalue=(
  SELECT value FROM owid_data_values ds
  WHERE du.entity_id = ds.EntityId AND du.variable_id = ds.VariableId AND du.lastyear = ds.year
  );

-- Percent range
UPDATE wda_owid_country_summary SET growth_percent=(lastvalue - firstvalue) / ABS(firstvalue)*100;

--------------------------------------
-- view
--------------------------------------

DROP VIEW IF EXISTS v_owid_country;
CREATE VIEW IF NOT EXISTS v_owid_country
AS
SELECT cy.id, owid_name AS country, iso_alpha2, iso_alpha3, continent_code, continent_name as continent
FROM owid_country cy
INNER JOIN owid_continent ct ON cy.continent = ct.id
ORDER BY cy.owid_name;


--------------------------------------
-- dataset summaries
--------------------------------------

-- Summarize dataset 
INSERT OR REPLACE INTO wda_variable 
SELECT "owid", od.namespace, od.name, ov.name, ov.coverage, os.name, count(distinct entityId),1,count(odv.variableId) FROM owid_data_values odv
INNER JOIN owid_variables ov ON odv.variableId = ov.id
INNER JOIN owid_sources os ON ov.sourceId = os.id
INNER JOIN owid_datasets od ON ov.datasetId  = od.id
GROUP BY odv.variableId;

INSERT OR REPLACE INTO wda_dataset 
SELECT provider,real_provider,dataset, max(nb_variables), sum(nb_observations),max(nb_scope) FROM wda_variable wv
WHERE provider="owid"
GROUP BY provider,real_provider,dataset;

-- Summarize provider
INSERT OR REPLACE INTO wda_provider 
SELECT provider, "Our World In Data", "https://ourworldindata.org", 0, max(nb_variables),sum(nb_observations), max(nb_scope)
FROM wda_variable wv
WHERE provider="owid"
GROUP BY provider;

UPDATE wda_provider SET nb_datasets = (SELECT count() FROM wda_dataset WHERE provider='owid')
WHERE provider='owid';

--------------------------------------
-- geonames views
--------------------------------------
DROP VIEW IF EXISTS v_owid_entities;
CREATE VIEW IF NOT EXISTS v_owid_entities
AS
SELECT id as entityId, iso3, GEOID, country FROM owid_entities oe
LEFT JOIN v_geonames_country gc ON oe.code = gc.iso3
WHERE iso3 IS NOT NULL;

DROP VIEW IF EXISTS v_owid_data_values;
CREATE VIEW IF NOT EXISTS v_owid_data_values
AS
SELECT variableID, GEOID, iso3, year, value  FROM owid_data_values odv
INNER JOIN  v_owid_entities voe ON odv.entityId = voe.entityId;

DROP VIEW IF EXISTS v_owid_variables;
CREATE VIEW IF NOT EXISTS v_owid_variables
AS
SELECT variableId, min(year) as minyear, max(year) as maxyear, ov.name as variable, os.name as source  FROM owid_data_values odv
INNER JOIN owid_variables ov ON odv.variableId = ov.id
INNER JOIN owid_sources os ON ov.sourceId = os.id 
GROUP BY variableId, ov.name; 

-- SELECT variableId, odv.entityId, iso3, GEOID,min(year) as minyear, max(year) as maxyear, ov.name as variable, os.name as source  FROM owid_data_values odv
-- INNER JOIN  v_owid_entities voe ON odv.entityId = voe.entityId
-- INNER JOIN owid_variables ov ON odv.variableId = ov.id
-- INNER JOIN owid_sources os ON ov.sourceId = os.id 
-- GROUP BY variableId, odv.entityId,iso3, GEOID,ov.name; 

-- Summarize provider
-- INSERT OR REPLACE INTO wda_provider
-- SELECT 'owid', real_provider,description, max(nb_scope), sum(nb_variables),sum(nb_observations)
-- FROM wda_dataset wd
-- INNER JOIN owid_namespaces own ON wd.real_provider = own.name
-- WHERE provider="owid"
-- GROUP BY provider,real_provider;

-- INSERT OR REPLACE INTO wda_dataset 
-- SELECT "vigilo-" || instanceID, "city", "Urban observation for " || name, COUNT(*) FROM v_vigilo_observations
-- GROUP BY InstanceID;


-- UPDATE wda_dataset 
-- SET nb_scopes=(SELECT COUNT(DISTINCT id) FROM owid_entities WHERE validated=1)
-- WHERE provider='owid' and scope='country';

-- UPDATE wda_dataset SET nb_variables=(SELECT count(DISTINCT variableId ) FROM owid_data_values)
-- WHERE provider='owid' and scope='country';


COMMIT;

