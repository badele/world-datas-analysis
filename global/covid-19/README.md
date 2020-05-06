# Covid-19 Summaries

## Download JHU datas
```
# Download datas from official JHU repository
python global/covid-19/download_from_jhu.py

# Clean and join datas
sqlite3 world-datas-analysis.db < global/covid-19/import_global_covid19_jhu.sql

# Export to CSV
sqlite3 world-datas-analysis.db < global/covid-19/export_global_covid19_jhu.sql
```



# Graph datas

### Cases
```
FORHAB=1000000
FIELD="ratio_cases"
SOURCE="https://github.com/CSSEGISandData/COVID-19"
COUNTRIES="'Spain','US','Italy','United Kingdom','France','Germany','Korea South','Sweden'"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries.gp
```

<img width="50%" height="50%" src="pictures/countries_ratio_cases_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_cases_for_1000000hab.gdata)


### Deaths
```
FORHAB=1000000
FIELD="ratio_deaths"
SOURCE="https://github.com/CSSEGISandData/COVID-19"
COUNTRIES="'Spain','US','Italy','United Kingdom','France','Germany','Korea South','Sweden'"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries.gp
```

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


# Filter value datas

### Cases
```
NBVALUE=1
FORHAB=1000000
FIELD="ratio_cases"
SOURCE="https://github.com/CSSEGISandData/COVID-19"
COUNTRIES="'Spain','US','Italy','United Kingdom','France','Germany','Korea South','Sweden'"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries_without_axis_date.gp
```

<img width="50%" height="50%" src="pictures/countries_ratio_cases_filter_1_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_cases_filter_1_for_1000000hab.gdata)


### Deaths
```
NBVALUE=1
FORHAB=1000000
FIELD="ratio_deaths"
SOURCE="https://github.com/CSSEGISandData/COVID-19"
COUNTRIES="'Spain','US','Italy','United Kingdom','France','Germany','Korea South','Sweden'"
QUERY="SELECT * FROM v_global_covid19_JHU WHERE ${FIELD}>(${NBVALUE}.0/${FORHAB}) AND zone='country' AND country_region IN ($COUNTRIES)"
python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --block-by country_region --comment "Source: $SOURCE" \
--output global/covid-19/datas/countries_${FIELD}_filter_${NBVALUE}_for_${FORHAB}hab.gdata

gnuplot -e "field='${FIELD}';nbvalue=${NBVALUE};forhab=${FORHAB}" gnuplot/color_grafana.plt global/covid-19/gnuplot/countries_without_axis_date.gp
```

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_filter_1_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_filter_1_for_1000000hab.gdata)
