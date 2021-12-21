# geonames population

## Download geonames and export
```
cd world-datas-analysis

# Use virtualenn python environment
source .venv/bin/activate

# Download datas from official JHU repository
python international/country/download_from_geoname.py
python international/country/download_from_worldbank.py

# Clean and import datas
sqlite3 -bail world-datas-analysis.db < international/country/import_geonames.sql
sqlite3 -bail world-datas-analysis.db < international/country/import_worldbank.sql

# Export to CSV
#sqlite3 -bail world-datas-analysis.db < international/countryexport_geonames.sql

# Export fixed with
international/countryexport_geonames.sh

# Generate graphs
international/covid-19/generate_graphs.sh
```

