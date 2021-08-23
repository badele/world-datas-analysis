# world-datas-analysis
miscellaneous worlds data and analysis

## Init environment

```
python -m venv .venv
source .venv/bin/activate
pip install --only-binary=:all: -r requirements.txt
```

## Report Sample

- [International Covid-19](international/covid-19/README.md)
- **In progress** [French Covid-19](countries/french/covid-19/README.md)

## Source;

- covid 
    - international [Johns Hopkins University](https://github.com/CSSEGISandData/COVID-19)
- population 
    - International [geonames](https://download.geonames.org/export/dump/)
    - International (TODO) [United nation](https://population.un.org/wpp/Download/Standard/Population/)
    - International (TODO) [World of bank](https://data.worldbank.org/indicator/SP.POP.TOTL)
    - France (TODO) [insee](https://www.insee.fr/fr/information/2008354)
    - France (TODO) [insee estimation](https://www.insee.fr/fr/statistiques/1893198)
- weather
    - european (TODO) [European Climate Assessment & Dataset](https://www.ecad.eu/dailydata/predefinedseries.php)
    - european (TODO) [European Centre for Medium-Range Weather Forecasts](https://confluence.ecmwf.int/display/WEBAPI/Accessing+ECMWF+data+servers+in+batch)