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

```
# Download and convert some datas
python covid-19/data_download_jhu.py --output /tmp/covid_all_datas.csv

# Convert datas
COUNTRIES="Spain,US,Italy,United Kingdom,France,Germany,Korea South,Sweden"
FIELDS=(cases recovered deaths)
NBCASES=0.00001
sed -i.bak "s/Korea, South/Korea South/" /tmp/covid_all_datas.csv
#python data_manipulation.py --input /tmp/covid_all_datas.csv --stat
for FIELD in $FIELDS; do
    FILE=/tmp/covid_countries_${FIELD}.csv
    python data_manipulation.py --input /tmp/covid_all_datas.csv -f "Country_Region:${COUNTRIES}" -f "Province_State:" -f "field:${FIELD}" --sort date --drop Lat,Long,population --output ${FILE}
    python data_manipulation.py --input ${FILE} --replace-by-null "per_pop:<${NBCASES}" --output ${FILE}
    python data_manipulation.py --input ${FILE} --pivot date:Country_Region:per_pop --output ${FILE}
    python data_manipulation.py --input ${FILE} --remove-and-shift --missing '?' --columns "index,${COUNTRIES}" --output ${FILE}
done

# Graph
FIELD=cases ; gnuplot -e "field='${FIELD}'" covid-19/color_grafana.plt covid-19/${FIELD}.gnu
convert -density 300 ${FIELD}_high.eps ${FIELD}_high_high_eps.png
#convert -density 144 ${FIELD}_high.svg ${FIELD}_high_high_svg.png
```
