<!-- ===================================================================== -->
<!-- This file is generated from .tpl/README.rmd -->
<!-- ===================================================================== -->

# world-datas-analysis

miscellaneous worlds data and analysis

## Init environment

If you have a `nix` environment, the `world-datas-analysis` environment is
installed automaticaly when you enter on this project folder (`direnv`) or type
`nix develop`.

[Here the documentation](https://devops.jesuislibre.org/onboarding/nix-direnv-just/)
for installation note for the `direnv & nix` tool.

## Usage

```
just update # Update datas
just start  # Start grafana goto http://localhost:3000
just browse # Browse world-datas-analysis datas for helping create a grafana query
```

Go to http://localhost:3000 (`admin:admin`)

## Scopes reference

When you add new data to this project, you can sync with reference data by
scope.

For example, if you import a new dataset associated with cities, you can link
them with geonames city elements

<!-- BEGIN SCOPEREFERENCE -->

| provider | dataset                | wda_scope | source                   | nb_variables | nb_entries |
| -------- | ---------------------- | --------- | ------------------------ | -----------: | ---------: |
| geonames | wda_geonames_cities    | city      | https://www.geonames.org |           79 |    3003154 |
| geonames | wda_geonames_countries | country   | https://www.geonames.org |           20 |        252 |

<!-- END SCOPEREFERENCE -->

## Providers

<!-- BEGIN PROVIDER -->

| provider   | description                                           | website                        | nb_datasets | nb_observations |
| ---------- | ----------------------------------------------------- | ------------------------------ | ----------: | --------------: |
| geonames   | Countries and cities informations                     | https://www.geonames.org       |           2 |         3003406 |
| opendata3m | OpenData Montpellier Méditerranée Métropole           | https://data.montpellier3m.fr/ |           1 |           51590 |
| vigilo     | Observations of the collaborative citizen application | https://vigilo.city            |           1 |           26132 |

<!-- END PROVIDER -->

## Datasets

<!-- BEGIN DATASET -->

| provider   | real_provider | dataset                                 | wda_scope | wda_scope_ref          | description                 | source                                                                                                                  | nb_variables | nb_observations | nb_scopes |
| ---------- | ------------- | --------------------------------------- | --------- | ---------------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -----------: | --------------: | --------: |
| geonames   | geonames      | wda_geonames_cities                     | city      | wda_geonames_cities    | Cities informations         | https://www.geonames.org                                                                                                |           79 |         3003154 |    434309 |
| geonames   | geonames      | wda_geonames_countries                  | city      | wda_geonames_countries | Countries informations      | https://www.geonames.org                                                                                                |           20 |             252 |       252 |
| opendata3m | opendata3m    | wda_opendata3m_ecocompteur_observations | city      | wda_geonames_cities    | ecocompteur observations    | https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-eco-compteurs/resource/edf3e04f-9409-40fe-be66 |           88 |           51590 |        11 |
| vigilo     | vigilo        | wda_vigilo_observations                 | city      | wda_geonames_cities    | vigilo citizen observations | https://vigilo.city                                                                                                     |           89 |           26132 |       261 |

<!-- END DATASET -->

## Todo

| Status | Category           | Scope       | Description                                                                                                                               | Sample Report                                                                                                       |
| ------ | ------------------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| [x]    | Geonames           | Cities      | [Geonames](https://download.geonames.org/export/dump/)                                                                                    | [International Covid-19](international/covid-19/README.md) / [French Covid-19](countries/french/covid-19/README.md) |
| [x]    | bike counter       | Montpellier | [Montpellier 3M](https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-eco-compteurs/resource/edf3e04f-9409-40fe-be66) |                                                                                                                     |
| [x]    | vigilo             | Montpellier | [Vigilo](https://vigilo.city)                                                                                                             |                                                                                                                     |
| [ ]    | Covid              | Countries   | [Johns Hopkins University](https://github.com/CSSEGISandData/COVID-19)                                                                    | [International Covid-19](international/covid-19/README.md) / [French Covid-19](countries/french/covid-19/README.md) |
| [ ]    | NASA               | Countries   | [Anormal température](https://data.giss.nasa.gov/gistemp/)                                                                                |                                                                                                                     |
| [ ]    | Population         | Cities      | [insee estimation](https://www.insee.fr/fr/statistiques/1893198)                                                                          |                                                                                                                     |
| [ ]    | Population         | Cities      | [insee](https://www.insee.fr/fr/information/2008354)                                                                                      |                                                                                                                     |
| [ ]    | Population         | Countries   | [United nation](https://population.un.org/wpp/Download/Standard/Population/)                                                              |                                                                                                                     |
| [ ]    | Rental bike        | Montpellier | [Montpellier 3M](https://data.montpellier3m.fr/dataset/courses-des-velos-velomagg-de-montpellier-mediterranee-metropole)                  |                                                                                                                     |
| [ ]    | Weather            | Cities      | [European Centre for Medium-Range Weather Forecasts](https://confluence.ecmwf.int/display/WEBAPI/Accessing+ECMWF+data+servers+in+batch)   |                                                                                                                     |
| [ ]    | Weather            | Cities      | [European Climate Assessment & Dataset](https://www.ecad.eu/dailydata/predefinedseries.php)                                               |                                                                                                                     |
| [ ]    | universitetetioslo | Countries   | [CO2 emissions](https://folk.universitetetioslo.no/roberan/GCB2020.shtml)                                                                 |                                                                                                                     |

## Project commands

<!-- COMMANDS -->

```text
justfile commands:
    help                    # This help
    precommit-install       # Setup pre-commit
    precommit-update        # Update pre-commit
    precommit-check         # precommit check
    docker-build            # Build the wda docker image
    docker-push             # Push the wda docker image to docker hub
    docker-run CMD=""       # Run the wda docker image
    lint                    # Lint the project
    doc-update FAKEFILENAME # Update documentation
    start                   # Start grafana
    stop                    # Stop grafana
    logs                    # Show grafana logs
    dump                    # Dump grafana database
    restore                 # Restore grafana database
    import                  # Import datas
    browse                  # Browse world datas
    packages                # Show installed packages
```

<!-- /COMMANDS -->
