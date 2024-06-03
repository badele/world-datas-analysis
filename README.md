<!-- ===================================================================== -->
<!-- This file is generated from .tpl/README.rmd -->
<!-- ===================================================================== -->

# world-datas-analysis

miscellaneous worlds data and analysis

## Providers of dataset

| Dataset                      | Description                                                   | Avg scope | Nb datasets                                        | Max variables                                        | Nb observations |
| :--------------------------- | :------------------------------------------------------------ | --------: | :------------------------------------------------- | :--------------------------------------------------- | --------------: |
| [geonames](dataset/geonames) | [Geonames entries](https://download.geonames.org/export/dump) |   4070489 | [1](dataset/dataset_geonames.md#geonames-datasets) | [15](dataset/dataset_geonames.md#geonames-variables) |         4823955 |
| [owid](dataset/owid)         | [Our World In Data](https://ourworldindata.org)               |       836 | [1472](dataset/dataset_owid.md#owid-datasets)      | [1](dataset/dataset_owid.md#owid-variables)          |        32609745 |
| [vigilo](dataset/vigilo)     | [Vigilo observations](https://vigilo.city)                    |       232 | [1](dataset/dataset_vigilo.md#vigilo-datasets)     | [9](dataset/dataset_vigilo.md#vigilo-variables)      |           31623 |

## Todo

| Status | Category           | Scope       | Description                                                                                                                             | Sample Report                                                                                                       |
| ------ | ------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| [_]    | Geonames           | Cities      | [Geonames](https://download.geonames.org/export/dump/)                                                                                  | [International Covid-19](international/covid-19/README.md) / [French Covid-19](countries/french/covid-19/README.md) |
| [_]    | Covid              | Countries   | [Johns Hopkins University](https://github.com/CSSEGISandData/COVID-19)                                                                  | [International Covid-19](international/covid-19/README.md) / [French Covid-19](countries/french/covid-19/README.md) |
| [_]    | Population         | Countries   | [United nation](https://population.un.org/wpp/Download/Standard/Population/)                                                            |                                                                                                                     |
| [_]    | Population         | Cities      | [insee](https://www.insee.fr/fr/information/2008354)                                                                                    |                                                                                                                     |
| [_]    | Population         | Cities      | [insee estimation](https://www.insee.fr/fr/statistiques/1893198)                                                                        |                                                                                                                     |
| [_]    | Weather            | Cities      | [European Climate Assessment & Dataset](https://www.ecad.eu/dailydata/predefinedseries.php)                                             |                                                                                                                     |
| [_]    | Weather            | Cities      | [European Centre for Medium-Range Weather Forecasts](https://confluence.ecmwf.int/display/WEBAPI/Accessing+ECMWF+data+servers+in+batch) |                                                                                                                     |
| [_]    | bike counter       | Montpellier | [Montpellier 3M/Velocité](https://compteurs.velocite-montpellier.fr/)                                                                   |                                                                                                                     |
| [_]    | Rental bike        | Montpellier | [Montpellier 3M](https://data.montpellier3m.fr/dataset/courses-des-velos-velomagg-de-montpellier-mediterranee-metropole)                |                                                                                                                     |
| [_]    | universitetetioslo | Countries   | [CO2 emissions](https://folk.universitetetioslo.no/roberan/GCB2020.shtml)                                                               |                                                                                                                     |
| [_]    | NASA               | Countries   | [Anormal température](https://data.giss.nasa.gov/gistemp/)                                                                              |                                                                                                                     |

## Init environment

If you have a `nix` environment, the `world-datas-analysis` environment is
installed automaticaly when you enter on this project folder (`direnv`) or type
`nix develop`.

[Here the documentation](https://devops.jesuislibre.org/onboarding/nix-direnv-just/)
for installation note for the `direnv & nix` tool.

## Usage

```
just update # Update datas
just start  # Start grafana
```

Go to http://localhost:3000 (`admin:admin`)

## Project commands

<!-- COMMANDS -->

```text
justfile commands:
    help                    # This help
    precommit-install       # Setup pre-commit
    precommit-update        # Update pre-commit
    precommit-check         # precommit check
    lint                    # Lint the project
    doc-update FAKEFILENAME # Update documentation
    start                   # Start grafana
    stop                    # Stop grafana
    dump                    # Dump grafana database
    restore                 # Restore grafana database
    update                  # Update datas
    browse                  # Browse world datas
    packages                # Show installed packages
```

<!-- /COMMANDS -->
