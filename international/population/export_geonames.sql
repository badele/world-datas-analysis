--------------------------------------
-- Export
--------------------------------------

.head on
.nullvalue NULL
.mode csv

--------------------------------------
-- Full export
--------------------------------------

.output international/population/datas/population_continent_full.csv
select * from v_geonames_continent ORDER BY population DESC;

.output international/population/datas/population_country_full.csv
select * from v_geonames_country ORDER BY population DESC;

.output international/population/datas/population_city_full.csv
select * from v_geonames_city ORDER BY population DESC;
