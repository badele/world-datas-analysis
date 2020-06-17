#!/bin/bash

# Commons
NBVALUE=1 # For filtered query
FORHAB=1000000
SOURCE="https://github.com/CSSEGISandData/COVID-19"
COUNTRIES="'Spain','US','Italy','Brazil', 'United Kingdom','France','Germany','Korea South','Sweden'"


# Cases
FIELD="ratio_cases"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries.gp


# Deaths
FIELD="ratio_deaths"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries.gp


# Filter value datas

# Cases
FIELD="ratio_cases"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries_without_axis_date.gp

# Deaths
FIELD="ratio_deaths"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries_without_axis_date.gp
