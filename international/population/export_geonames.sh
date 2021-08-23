#!/bin/env bash

SOURCE="https://download.geonames.org/export/dump/"

##########################################################
# Preview
##########################################################

# Export continent
QUERY="select GEOID, code, name,  population \
FROM v_geonames_continent \
ORDER BY population DESC LIMIT 10000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--output international/population/datas/population_continent_preview.txt

# Export country
QUERY="select GEOID, iso3, country, capital, continentname,  population \
FROM v_geonames_country \
ORDER BY continentname, population DESC LIMIT 10000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--block-by "continentname" \
--comment "Grouped by continent" \
--output international/population/datas/population_country_preview.txt

# Export city
QUERY="select ci.GEOID, ci.name, co.country, co.continent, ci.population \
FROM v_geonames_city ci INNER JOIN geonames_country co \
ON ci.countrycode = co.iso2 \
ORDER BY ci.population DESC LIMIT 10000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--output international/population/datas/population_city_preview.txt

##########################################################
# Sample full columns
##########################################################

# Export continent
QUERY="select * from v_geonames_continent ORDER BY population DESC LIMIT 1000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--output international/population/datas/population_continent_sample_all_columns.txt

# Export country
QUERY="select * from v_geonames_country ORDER BY population DESC LIMIT 1000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--block-by "continentname" \
--comment "Grouped by continent" \
--output international/population/datas/population_country_sample_all_columns.txt

# Export city
QUERY="select * from v_geonames_city ORDER BY population DESC LIMIT 1000;"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--output international/population/datas/population_city_sample_all_columns.txt