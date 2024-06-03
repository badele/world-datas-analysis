.head on
.nullvalue NULL
.mode csv

PRAGMA synchronous = OFF;

BEGIN TRANSACTION;

--------------------------------------
-- Export categories
--------------------------------------
.output ./dataset/vigilo/categories.csv
SELECT * FROM vigilo_categories;

--------------------------------------
-- Export instances
--------------------------------------
.output ./dataset/vigilo/instances.csv
SELECT * FROM vigilo_instances;

--------------------------------------
-- Export observations
--------------------------------------
.output ./dataset/vigilo/observations.csv
SELECT * FROM vigilo_observations;

COMMIT;
