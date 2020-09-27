# Covid-19 Summaries

## Download JHU datas and Graph
```
# Download datas from albert 1er totem
python cities/montpellier/totem/download_from_totem.py

# Clean and join datas
sqlite3 world-datas-analysis.db < cities/montpellier/totem/import_cities_montpellier_totem.sql

# Export to CSV
sqlite3 world-datas-analysis.db < cities/montpellier/totem/export_cities_montpellier_totem.sql

# Export gdata
QUERY="SELECT * FROM cities_montpellier_totem_downloaded"
SOURCE="https://docs.google.com/spreadsheets/d/e/2PACX-1vQVtdpXMHB4g9h75a0jw8CsrqSuQmP5eMIB2adpKR5hkRggwMwzFy5kB-AIThodhVHNLxlZYm8fuoWj/pub?gid=59478853&single=true&output=csv"

python sql_to_gnuplot.py --db world-datas-analysis.db \
--query "$QUERY" --comment "Source: $SOURCE" \
--block-by methode \
--output  cities/montpellier/totem/datas/albert_1er.gdata
```
