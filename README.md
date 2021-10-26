# world-datas-analysis
miscellaneous worlds data and analysis

## Init environment

```
python -m venv .venv
source .venv/bin/activate
pip install --only-binary=:all: -r requirements.txt
```

## indicators;

| Status | Nb indicators               | Scope       | Description                                                                                                                             | Sample Report                                                                                                       |
|--------|-----------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| [x]    | 6204 indicators             | Countries   | [Our World In Data](https://ourworldindata.org/charts)                                                                       |                                                                                                                     |
| [x]    | 18 (geoloc)                 | Cities      | [geonames](https://download.geonames.org/export/dump/)                                                                                  |                                                                                                                     |



| Status | Category                    | Scope       | Description                                                                                                                             | Sample Report                                                                                                       |
|--------|-----------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| [x]    | Covid                       | Countries   | [Johns Hopkins University](https://github.com/CSSEGISandData/COVID-19)                                                                  | [International Covid-19](international/covid-19/README.md) / [French Covid-19](countries/french/covid-19/README.md) |
| [_]    | Population                  | Countries   | [United nation](https://population.un.org/wpp/Download/Standard/Population/)                                                            |                                                                                                                     |
| [_]    | Population                  | Cities      | [insee](https://www.insee.fr/fr/information/2008354)                                                                                    |                                                                                                                     |
| [_]    | Population                  | Cities      | [insee estimation](https://www.insee.fr/fr/statistiques/1893198)                                                                        |                                                                                                                     |
| [_]    | Weather                     | Cities      | [European Climate Assessment & Dataset](https://www.ecad.eu/dailydata/predefinedseries.php)                                             |                                                                                                                     |
| [_]    | Weather                     | Cities      | [European Centre for Medium-Range Weather Forecasts](https://confluence.ecmwf.int/display/WEBAPI/Accessing+ECMWF+data+servers+in+batch) |                                                                                                                     |
| [_]    | vigilo                      | Montpellier | [Vigilo](https://vigilo.city/fr/)                                                                                                       |                                                                                                                     |
| [_]    | bike counter                | Montpellier | [Montpellier 3M/Velocité](https://compteurs.velocite-montpellier.fr/)                                                                   |                                                                                                                     |
| [_]    | Rental bike                 | Montpellier | [Montpellier 3M](https://data.montpellier3m.fr/dataset/courses-des-velos-velomagg-de-montpellier-mediterranee-metropole)                |                                                                                                                     |
| [_]    | universitetetioslo          | Countries   | [CO2 emissions](https://folk.universitetetioslo.no/roberan/GCB2020.shtml)                                                               |                                                                                                                     |
| [_]    | NASA                        | Countries   | [Anormal température](https://data.giss.nasa.gov/gistemp/)                                                                              |                                                                                                                     |

```
# Use virtualenn python environment
source .venv/bin/activate

# owid
dataset/owid/download.sh
dataset/owid/import.sh


# Level 1 (geoname)
dataset/geonames/download.sh
dataset/geonames/import.sh

# Worldbnk
python dataset/200-worldbank/download.py
sqlite3 -bail world-datas-analysis.db < dataset/200-worldbank/import.sql
#international/countryexport_worldbank.sh
#python international/country/download_from_ourworldindata.py

# Summary
sqlite3 -bail world-datas-analysis.db < db_summary.sql
```

```



SELECT * from datasets
INNER JOIN namespaces ON datasets.namespace = namespaces.name
WHERE namespaces.isArchived = 0

SELECT * from variables
INNER JOIN datasets ON variables.datasetId = datasets.id
INNER JOIN namespaces ON datasets.namespace = namespaces.name
WHERE namespaces.isArchived = 0

```