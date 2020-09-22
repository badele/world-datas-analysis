#!/bin/bash

# Commons
NBVALUE=1 # For filtered query
FORHAB=1000000
SOURCE="https://github.com/CSSEGISandData/COVID-19"


# Country by country
COUNTRIES=("Spain" "US" "Italy" "Brazil" "United Kingdom" "France" "Germany" "Korea South" "Sweden" "Netherlands")

for COUNTRY in "${COUNTRIES[@]}"; do
    FIELD="ratio_deaths"
    QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ('$COUNTRY')"
    python sql_to_gnuplot.py --db world-datas-analysis.db \
    --query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
    --output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

    gnuplot -e "field='${FIELD}';forhab=${FORHAB};country='$COUNTRY'" gnuplot/color_grafana.plt global/covid-19/gnuplot/by_country.gp
    mv global/covid-19/pictures/countries_ratio_deaths_for_1000000hab.png "global/covid-19/pictures/countries_${FIELD}_for_1000000hab_${COUNTRY}.png"
done

# Some countries
COUNTRIES="'Spain','US','Italy','Brazil', 'United Kingdom','France','Germany','Korea South','Sweden','Netherlands'"

# Cases
FIELD="ratio_cases"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/all_countries.gp


# Deaths
FIELD="ratio_deaths"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/all_countries.gp


# Filter value datas

# Cases
FIELD="ratio_cases"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/all_countries_without_axis_date.gp

# Deaths
FIELD="ratio_deaths"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/all_countries_without_axis_date.gp
