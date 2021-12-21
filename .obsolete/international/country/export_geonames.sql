--------------------------------------
-- Export
--------------------------------------

.head on
.nullvalue NULL
.mode csv

--------------------------------------
-- Full export
--------------------------------------

.output international/countrydatas/population_continent_full.csv
select * from v_geonames_continent ORDER BY population DESC;

.output international/countrydatas/population_country_full.csv
select * from v_geonames_country ORDER BY population DESC;

.output international/countrydatas/population_city_full.csv
select * from v_geonames_city ORDER BY population DESC;
