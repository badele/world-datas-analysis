#!/bin/env bash

SOURCE="https://data.worldbank.org/"

##########################################################
# Preview
##########################################################

# All indicators for France
QUERY="SELECT category, description, first_year, last_year, printf(\"%.5f\", first_value) as first_value, printf(\"%.5f\", last_value) as last_value, printf(\"%.5f\", growth_percent) as growth_percent \
FROM v_worldbank_country_summary \
WHERE CountryCode='FRA';"
python sql_to_fwf.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--block-by "category" \
--output international/country/datas/worldbank_france.txt

