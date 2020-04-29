# world-datas-analysis
miscellaneous worlds data and analysis

- covid-19

**Init**

```
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Covid 19**

***Download datas***

```
# Download and convert some datas
python global/covid-19/download_from_jhu.py --output global/covid-19/datas/JHU_downloaded.csv
sed -i "s/Korea, South/Korea South/" global/covid-19/datas/JHU_downloaded.csv

# field day distance
POPFILTER=0.0001
FIELDS=(cases deaths)
FILTER="# Country_Region="
COUNTRIES="Spain|US|Italy|United Kingdom|France|Germany|Korea South|Sweden"
# Filter and convert datas
for FIELD in $FIELDS; do
    FIELD="pct_${FIELD}"
    CMD=(python data_manipulation.py --input global/covid-19/datas/JHU_downloaded.csv -f 'Province_State:' -f "?:${FIELD}>=$POPFILTER" --sort Country_Region,date --output global/covid-19/datas/${FIELD}_day_distance_for_1M.csv)

    # Execute command
    "${CMD[@]}"

    # Convert to gnuplot format
    python csv_to.py --input global/covid-19/datas/${FIELD}_day_distance_for_1M.csv \
    --comment "Source: https://github.com/CSSEGISandData/COVID-19" \
    --comment "Filtered with $CMD" --format gnuplot --block-by Country_Region --output global/covid-19/datas/${FIELD}_day_distance_for_1M.gdata

    # Create filter index
    grep "^${FILTER}" global/covid-19/datas/${FIELD}_day_distance_for_1M.gdata | nl -s'|' -v0 | sed "s/${FILTER}//g" | egrep "$COUNTRIES" > global/covid-19/datas/${FIELD}_day_distance_for_1M_filter.gindex

done
```

***Generate graphs***

```
UNIT=10000
FIELDS=(cases deaths)
for FIELD in $FIELDS; do
    FIELD="pct_${FIELD}"
    TDATE=$(grep "2020" global/covid-19/datas/${FIELD}_day_distance_for_1M.gdata | cut -d" " -f1 | sort | tail -n1)
    gnuplot -e "field='${FIELD}';unit=${UNIT};tdate='${TDATE}'" gnuplot/color_grafana.plt global/covid-19/gnuplot/day_distance.gp
    #convert -density 300 global/covid-19/pictures/${FIELD}_day_distance_for_1M_high.eps global/covid-19/pictures/${FIELD}_day_distance_for_1M_high_eps.png
    #convert -density 144 /tmp/covid_${FIELD}_high.svg /tmp/covid_${FIELD}_high_svg.png
done
```

Image result :

<img width="75%" height="75%" src="global/covid-19/pictures/pct_deaths_day_distance_for_1M.png"/>

[Gnuplot Datafile source](https://raw.githubusercontent.com/badele/world-datas-analysis/master/global/covid-19/datas/pct_deaths_day_distance_for_1M.gdata)
