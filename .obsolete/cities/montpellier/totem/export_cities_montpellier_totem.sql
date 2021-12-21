--------------------------------------
-- Export
--------------------------------------

.head on
.nullvalue NULL
.mode csv
.output cities/montpellier/totem/datas/albert_1er_export.csv
select * from cities_montpellier_totem_downloaded;
