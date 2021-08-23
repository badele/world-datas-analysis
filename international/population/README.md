# geonames population

## Download geonames and export
```
cd world-datas-analysis

# Use virtualenn python environment
source .venv/bin/activate

# Download datas from official JHU repository
python international/population/download_from_geoname.py

# Clean and import datas
sqlite3 -bail world-datas-analysis.db < international/population/import_geonames.sql

# Export to CSV
#sqlite3 -bail world-datas-analysis.db < international/population/export_geonames.sql

# Export fixed with
international/population/export_geonames.sh

# Generate graphs
international/covid-19/generate_graphs.sh
```

