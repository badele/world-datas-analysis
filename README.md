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

## Providers

<!-- BEGIN PROVIDER -->

| provider   | description                                 | website                        | nb_datasets | nb_observations |
| ---------- | ------------------------------------------- | ------------------------------ | ----------: | --------------: |
| opendata3m | OpenData Montpellier Méditerranée Métropole | https://data.montpellier3m.fr/ |           1 |           51454 |

<!-- END PROVIDER -->

## Scopes reference

When you add new data to this project, you can sync with reference data by
scope.

For example, if you import a new dataset associated with cities, you can link
them with geonames city elements

<!-- BEGIN SCOPEREFERENCE -->

| provider | dataset                | wda_scope | nb_variables | nb_entries |
| -------- | ---------------------- | --------- | -----------: | ---------: |
| geonames | wda_geonames_cities    | city      |           79 |    3003154 |
| geonames | wda_geonames_countries | country   |           20 |        252 |

<!-- END SCOPEREFERENCE -->

## Datasets

<!-- BEGIN DATASET -->

| provider   | real_provider | dataset                                 | wda_scope | wda_scope_ref       | description                 | source                                                                                                                  | nb_variables | nb_observations | nb_scopes |
| ---------- | ------------- | --------------------------------------- | --------- | ------------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -----------: | --------------: | --------: |
| opendata3m | opendata3m    | wda_opendata3m_ecocompteur_observations | city      | wda_geonames_cities | ecocompteur observations    | https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-eco-compteurs/resource/edf3e04f-9409-40fe-be66 |           88 |           51454 |        11 |
| vigilo     | vigilo        | wda_vigilo_observations                 | city      | wda_geonames_cities | vigilo citizen observations | https://vigilo.city                                                                                                     |           89 |           26130 |       260 |

<!-- END DATASET -->

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
    logs                    # Show grafana logs
    dump                    # Dump grafana database
    restore                 # Restore grafana database
    update                  # Update datas
    import                  # Import datas
    browse                  # Browse world datas
    packages                # Show installed packages
```

<!-- /COMMANDS -->
