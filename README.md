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

| provider   | description                      | website                        | nb_datasets | nb_observations |
| ---------- | -------------------------------- | ------------------------------ | ----------: | --------------: |
| opendata3m | OpenData Méditerranée Métropole  | https://data.montpellier3m.fr/ |           1 |           30180 |
| vigilo     | Vigilo Android & Web application | https://vigilo.city            |           1 |           25625 |

## Datasets

| provider   | real_provider | dataset                                | scope | description                  | source                                                                                     | nb_variables | nb_observations | nb_scopes |
| ---------- | ------------- | -------------------------------------- | ----- | ---------------------------- | ------------------------------------------------------------------------------------------ | -----------: | --------------: | --------: |
| opendata3m | opendata3m    | v_opendata3m_ecocompteurs_observations | city  | opendata3m bike ecocompteurs | https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-compteurs-de-velo |           10 |           30180 |        11 |
| vigilo     | vigilo        | v_vigilo_observations                  | city  | Vigilo bike observations     | https://vigilo.city                                                                        |           16 |           25625 |       264 |

## Scopes

| provider   | dataset                                | scope | scopevalue                                                         | nb_observations |
| ---------- | -------------------------------------- | ----- | ------------------------------------------------------------------ | --------------: |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Montpellier                                                        |           17380 |
| vigilo     | v_vigilo_observations                  | city  | Montpellier                                                        |            9675 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Castelnau-le-Lez                                                   |            4339 |
| vigilo     | v_vigilo_observations                  | city  | Nantes                                                             |            3369 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Lavérune                                                           |            2042 |
| vigilo     | v_vigilo_observations                  | city  | Marseille                                                          |            2008 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Montferrier-sur-Lez                                                |            1789 |
| vigilo     | v_vigilo_observations                  | city  | Strasbourg                                                         |             974 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Teyran                                                             |             903 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Lattes                                                             |             903 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Villeneuve-lès-Maguelone                                           |             903 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Herblain                                                     |             851 |
| vigilo     | v_vigilo_observations                  | city  | Castelnau-le-Lez                                                   |             808 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Juvignac                                                           |             726 |
| vigilo     | v_vigilo_observations                  | city  | Brest                                                              |             719 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Grabels                                                            |             541 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Cournonsec                                                         |             541 |
| vigilo     | v_vigilo_observations                  | city  | Massy                                                              |             497 |
| vigilo     | v_vigilo_observations                  | city  | Troyes                                                             |             444 |
| vigilo     | v_vigilo_observations                  | city  | La Rochelle                                                        |             433 |
| vigilo     | v_vigilo_observations                  | city  | Bordeaux                                                           |             418 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Brieuc                                                       |             381 |
| vigilo     | v_vigilo_observations                  | city  | Orvault                                                            |             355 |
| vigilo     | v_vigilo_observations                  | city  | Schiltigheim                                                       |             271 |
| vigilo     | v_vigilo_observations                  | city  | Lattes                                                             |             209 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Sébastien-sur-Loire                                          |             203 |
| vigilo     | v_vigilo_observations                  | city  | Ballainvilliers                                                    |             190 |
| vigilo     | v_vigilo_observations                  | city  | Vendargues                                                         |             182 |
| vigilo     | v_vigilo_observations                  | city  | Palaiseau                                                          |             158 |
| vigilo     | v_vigilo_observations                  | city  | Bègles                                                             |             158 |
| vigilo     | v_vigilo_observations                  | city  | Ploufragan                                                         |             145 |
| vigilo     | v_vigilo_observations                  | city  | Bourgoin-Jallieu                                                   |             128 |
| opendata3m | v_opendata3m_ecocompteurs_observations | city  | Clapiers                                                           |             113 |
| vigilo     | v_vigilo_observations                  | city  | Verrières-le-Buisson                                               |             109 |
| vigilo     | v_vigilo_observations                  | city  | Beauvais                                                           |             102 |
| vigilo     | v_vigilo_observations                  | city  | Périgueux                                                          |              98 |
| vigilo     | v_vigilo_observations                  | city  | Bischheim                                                          |              98 |
| vigilo     | v_vigilo_observations                  | city  | Saclay                                                             |              93 |
| vigilo     | v_vigilo_observations                  | city  | Vertou                                                             |              89 |
| vigilo     | v_vigilo_observations                  | city  | Aix-en-Provence                                                    |              86 |
| vigilo     | v_vigilo_observations                  | city  | Orsay                                                              |              80 |
| vigilo     | v_vigilo_observations                  | city  | Le Crès                                                            |              73 |
| vigilo     | v_vigilo_observations                  | city  | Talence                                                            |              72 |
| vigilo     | v_vigilo_observations                  | city  | Villefontaine                                                      |              66 |
| vigilo     | v_vigilo_observations                  | city  | Périgny                                                            |              61 |
| vigilo     | v_vigilo_observations                  | city  | Illkirch-Graffenstaden                                             |              60 |
| vigilo     | v_vigilo_observations                  | city  | Clapiers                                                           |              60 |
| vigilo     | v_vigilo_observations                  | city  | Villebon-sur-Yvette                                                |              51 |
| vigilo     | v_vigilo_observations                  | city  | Aytré                                                              |              51 |
| vigilo     | v_vigilo_observations                  | city  | Pessac                                                             |              50 |
| vigilo     | v_vigilo_observations                  | city  | Rezé                                                               |              49 |
| vigilo     | v_vigilo_observations                  | city  | Plérin                                                             |              49 |
| vigilo     | v_vigilo_observations                  | city  | Montferrier-sur-Lez                                                |              48 |
| vigilo     | v_vigilo_observations                  | city  | Sainte-Savine                                                      |              47 |
| vigilo     | v_vigilo_observations                  | city  | Pérols                                                             |              42 |
| vigilo     | v_vigilo_observations                  | city  | Longpont-sur-Orge                                                  |              41 |
| vigilo     | v_vigilo_observations                  | city  | Châteaugiron                                                       |              41 |
| vigilo     | v_vigilo_observations                  | city  | Mérignac                                                           |              41 |
| vigilo     | v_vigilo_observations                  | city  | Puilboreau                                                         |              37 |
| vigilo     | v_vigilo_observations                  | city  | Coulounieix-Chamiers                                               |              34 |
| vigilo     | v_vigilo_observations                  | city  | Unknow                                                             |              33 |
| vigilo     | v_vigilo_observations                  | city  | Lingolsheim                                                        |              32 |
| vigilo     | v_vigilo_observations                  | city  | Gif-sur-Yvette                                                     |              32 |
| vigilo     | v_vigilo_observations                  | city  | Chilly-Mazarin                                                     |              32 |
| vigilo     | v_vigilo_observations                  | city  | undefined                                                          |              30 |
| vigilo     | v_vigilo_observations                  | city  | Nieul-sur-Mer                                                      |              29 |
| vigilo     | v_vigilo_observations                  | city  | Trélissac                                                          |              28 |
| vigilo     | v_vigilo_observations                  | city  | Igny                                                               |              25 |
| vigilo     | v_vigilo_observations                  | city  | Palavas-les-Flots                                                  |              23 |
| vigilo     | v_vigilo_observations                  | city  | Vaulx-Milieu                                                       |              22 |
| vigilo     | v_vigilo_observations                  | city  | Plouzané                                                           |              22 |
| vigilo     | v_vigilo_observations                  | city  | Jacou                                                              |              20 |
| vigilo     | v_vigilo_observations                  | city  | Noyal-Sur-Vilaine                                                  |              20 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Jean-de-Védas                                                |              20 |
| vigilo     | v_vigilo_observations                  | city  | Wissous                                                            |              20 |
| vigilo     | v_vigilo_observations                  | city  | Saulx-les-Chartreux                                                |              19 |
| vigilo     | v_vigilo_observations                  | city  | Guipavas                                                           |              19 |
| vigilo     | v_vigilo_observations                  | city  | Mauguio                                                            |              18 |
| vigilo     | v_vigilo_observations                  | city  | Aubagne                                                            |              18 |
| vigilo     | v_vigilo_observations                  | city  | Bouc-Bel-Air                                                       |              17 |
| vigilo     | v_vigilo_observations                  | city  | Gradignan                                                          |              16 |
| vigilo     | v_vigilo_observations                  | city  | Bures-sur-Yvette                                                   |              16 |
| vigilo     | v_vigilo_observations                  | city  | Trégueux                                                           |              16 |
| vigilo     | v_vigilo_observations                  | city  | Le Haillan                                                         |              16 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Rogatien                                                     |              16 |
| vigilo     | v_vigilo_observations                  | city  | Lagord                                                             |              16 |
| vigilo     | v_vigilo_observations                  | city  | Montlhéry                                                          |              16 |
| vigilo     | v_vigilo_observations                  | city  | Saint-André-les-Vergers                                            |              15 |
| vigilo     | v_vigilo_observations                  | city  | Juvignac                                                           |              15 |
| vigilo     | v_vigilo_observations                  | city  | Boulazac Isle Manoire                                              |              15 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Georges-d'Orques                                             |              14 |
| vigilo     | v_vigilo_observations                  | city  | L'Isle-dAbeau                                                      |              14 |
| vigilo     | v_vigilo_observations                  | city  | Villejust                                                          |              14 |
| vigilo     | v_vigilo_observations                  | city  | La Verpillière                                                     |              14 |
| vigilo     | v_vigilo_observations                  | city  | Saint Marcellin                                                    |              13 |
| vigilo     | v_vigilo_observations                  | city  | Longjumeau                                                         |              13 |
| vigilo     | v_vigilo_observations                  | city  | Vauhallan                                                          |              13 |
| vigilo     | v_vigilo_observations                  | city  | Wolfisheim                                                         |              13 |
| vigilo     | v_vigilo_observations                  | city  | La Ville-du-Bois                                                   |              13 |
| vigilo     | v_vigilo_observations                  | city  | Antony                                                             |              13 |
| vigilo     | v_vigilo_observations                  | city  | Frontignan                                                         |              13 |
| vigilo     | v_vigilo_observations                  | city  | Marcoussis                                                         |              12 |
| vigilo     | v_vigilo_observations                  | city  | Domloup                                                            |              12 |
| vigilo     | v_vigilo_observations                  | city  | Servon-Sur-Vilaine                                                 |              11 |
| vigilo     | v_vigilo_observations                  | city  | Villeneuve-lès-Maguelone                                           |              11 |
| vigilo     | v_vigilo_observations                  | city  | Hoenheim                                                           |              10 |
| vigilo     | v_vigilo_observations                  | city  | Lavérune                                                           |              10 |
| vigilo     | v_vigilo_observations                  | city  | Les Ulis                                                           |              10 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Gély-du-Fesc                                                 |              10 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Julien-les-Villas                                            |              10 |
| vigilo     | v_vigilo_observations                  | city  | Eysines                                                            |              10 |
| vigilo     | v_vigilo_observations                  | city  | Pordic                                                             |               9 |
| vigilo     | v_vigilo_observations                  | city  | Castries                                                           |               9 |
| vigilo     | v_vigilo_observations                  | city  | L'Isle-d'Abeau                                                     |               9 |
| vigilo     | v_vigilo_observations                  | city  | Sainte-Luce-sur-Loire                                              |               9 |
| vigilo     | v_vigilo_observations                  | city  | Bordeaux                                                           |               9 |
| vigilo     | v_vigilo_observations                  | city  | Champlan                                                           |               9 |
| vigilo     | v_vigilo_observations                  | city  | Villenave-d'Ornon                                                  |               8 |
| vigilo     | v_vigilo_observations                  | city  | Les Sorinières                                                     |               8 |
| vigilo     | v_vigilo_observations                  | city  | Bruges                                                             |               8 |
| vigilo     | v_vigilo_observations                  | city  | Le Relecq-Kerhuon                                                  |               8 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Médard-en-Jalles                                             |               8 |
| vigilo     | v_vigilo_observations                  | city  | Gometz-le-Châtel                                                   |               7 |
| vigilo     | v_vigilo_observations                  | city  | Grabels                                                            |               7 |
| vigilo     | v_vigilo_observations                  | city  | Gouesnou                                                           |               7 |
| vigilo     | v_vigilo_observations                  | city  | Brest.                                                             |               7 |
| vigilo     | v_vigilo_observations                  | city  | Langueux                                                           |               7 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Aubin de Médoc                                               |               6 |
| vigilo     | v_vigilo_observations                  | city  | Bassillac et Auberoche                                             |               6 |
| vigilo     | v_vigilo_observations                  | city  | Floirac                                                            |               6 |
| vigilo     | v_vigilo_observations                  | city  | Couëron                                                            |               6 |
| vigilo     | v_vigilo_observations                  | city  | Nivolas-Vermelle                                                   |               5 |
| vigilo     | v_vigilo_observations                  | city  | Ostwald                                                            |               5 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Aubin                                                        |               5 |
| vigilo     | v_vigilo_observations                  | city  | La Chapelle-sur-Erdre                                              |               5 |
| vigilo     | v_vigilo_observations                  | city  | Nivolas-Vermelle                                                   |               5 |
| vigilo     | v_vigilo_observations                  | city  | Parempuyre                                                         |               5 |
| vigilo     | v_vigilo_observations                  | city  | Dompierre-sur-Mer                                                  |               4 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Clément-de-Rivière                                           |               4 |
| vigilo     | v_vigilo_observations                  | city  | Fabrègues                                                          |               4 |
| vigilo     | v_vigilo_observations                  | city  | Rosières-près-Troyes                                               |               4 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Aunès                                                        |               4 |
| vigilo     | v_vigilo_observations                  | city  | Prades-le-Lez                                                      |               4 |
| vigilo     | v_vigilo_observations                  | city  | Saint Sauveur                                                      |               4 |
| vigilo     | v_vigilo_observations                  | city  | Clavette                                                           |               4 |
| vigilo     | v_vigilo_observations                  | city  | Villiers-le-Bâcle                                                  |               4 |
| vigilo     | v_vigilo_observations                  | city  | La Chapelle-Saint-Luc                                              |               4 |
| vigilo     | v_vigilo_observations                  | city  | Gujan-Mestras                                                      |               4 |
| vigilo     | v_vigilo_observations                  | city  | Lormont                                                            |               4 |
| vigilo     | v_vigilo_observations                  | city  | Linas                                                              |               4 |
| vigilo     | v_vigilo_observations                  | city  | Oberhausbergen                                                     |               4 |
| vigilo     | v_vigilo_observations                  | city  | Nozay                                                              |               4 |
| vigilo     | v_vigilo_observations                  | city  | Bièvres                                                            |               4 |
| vigilo     | v_vigilo_observations                  | city  | Pignan                                                             |               3 |
| vigilo     | v_vigilo_observations                  | city  | Bièvres                                                            |               3 |
| vigilo     | v_vigilo_observations                  | city  | Morangis                                                           |               3 |
| vigilo     | v_vigilo_observations                  | city  | La Rivière-de-Corps                                                |               3 |
| vigilo     | v_vigilo_observations                  | city  | Le Teich                                                           |               3 |
| vigilo     | v_vigilo_observations                  | city  | L'Houmeau                                                          |               3 |
| vigilo     | v_vigilo_observations                  | city  | Carquefou                                                          |               3 |
| vigilo     | v_vigilo_observations                  | city  | Simiane-Collongue                                                  |               3 |
| vigilo     | v_vigilo_observations                  | city  | La Teste de Buch                                                   |               3 |
| vigilo     | v_vigilo_observations                  | city  | Teyran                                                             |               3 |
| vigilo     | v_vigilo_observations                  | city  | Bonnefamille                                                       |               3 |
| vigilo     | v_vigilo_observations                  | city  | Ille-et-Vilaine                                                    |               3 |
| vigilo     | v_vigilo_observations                  | city  | Holtzheim                                                          |               3 |
| vigilo     | v_vigilo_observations                  | city  | Boirargues                                                         |               3 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Quentin-Fallavier                                            |               3 |
| vigilo     | v_vigilo_observations                  | city  | Champcevinel                                                       |               3 |
| vigilo     | v_vigilo_observations                  | city  | Quintin                                                            |               3 |
| vigilo     | v_vigilo_observations                  | city  | Souffelweyersheim                                                  |               3 |
| vigilo     | v_vigilo_observations                  | city  | Le Bouscat                                                         |               3 |
| vigilo     | v_vigilo_observations                  | city  | Senlis                                                             |               3 |
| vigilo     | v_vigilo_observations                  | city  | Les Noës-près-Troyes                                               |               2 |
| vigilo     | v_vigilo_observations                  | city  | Brest.                                                             |               2 |
| vigilo     | v_vigilo_observations                  | city  | Longpont-sur-Orge                                                  |               2 |
| vigilo     | v_vigilo_observations                  | city  | Martignas-sur-Jalle                                                |               2 |
| vigilo     | v_vigilo_observations                  | city  | Mittelhausbergen                                                   |               2 |
| vigilo     | v_vigilo_observations                  | city  | Gardanne                                                           |               2 |
| vigilo     | v_vigilo_observations                  | city  | Marseille                                                          |               2 |
| vigilo     | v_vigilo_observations                  | city  | Carnoux-en-Provence                                                |               2 |
| vigilo     | v_vigilo_observations                  | city  | Guilers                                                            |               2 |
| vigilo     | v_vigilo_observations                  | city  | Sautron                                                            |               2 |
| vigilo     | v_vigilo_observations                  | city  | Chatte                                                             |               2 |
| vigilo     | v_vigilo_observations                  | city  | Saint Vérand                                                       |               2 |
| vigilo     | v_vigilo_observations                  | city  | Achenheim                                                          |               2 |
| vigilo     | v_vigilo_observations                  | city  | Artigues-près-Bordeaux                                             |               2 |
| vigilo     | v_vigilo_observations                  | city  | 29200 brest                                                        |               2 |
| vigilo     | v_vigilo_observations                  | city  | undefined                                                          |               2 |
| vigilo     | v_vigilo_observations                  | city  | Heonheim                                                           |               2 |
| vigilo     | v_vigilo_observations                  | city  | Domarin                                                            |               2 |
| vigilo     | v_vigilo_observations                  | city  | La Jarne                                                           |               2 |
| vigilo     | v_vigilo_observations                  | city  | Angoulins                                                          |               2 |
| vigilo     | v_vigilo_observations                  | city  | Fresnes                                                            |               2 |
| vigilo     | v_vigilo_observations                  | city  | Mundolsheim                                                        |               2 |
| vigilo     | v_vigilo_observations                  | city  | Trémuson                                                           |               2 |
| vigilo     | v_vigilo_observations                  | city  | marseille                                                          |               1 |
| vigilo     | v_vigilo_observations                  | city  | Bohars                                                             |               1 |
| vigilo     | v_vigilo_observations                  | city  | milizac                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | 29200 Brest                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | Dompierre-sur-Mer juste avant le tunnel                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | 44000 Nantes                                                       |               1 |
| vigilo     | v_vigilo_observations                  | city  | Villebon                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Chancelade                                                         |               1 |
| vigilo     | v_vigilo_observations                  | city  | Reichstett                                                         |               1 |
| vigilo     | v_vigilo_observations                  | city  | Hangenbieten                                                       |               1 |
| vigilo     | v_vigilo_observations                  | city  | Avilly-Saint-Léonard                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | Le Meux                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | Éguilles                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Gif sur Yvette                                                     |               1 |
| vigilo     | v_vigilo_observations                  | city  | Paray-Vieille-Poste                                                |               1 |
| vigilo     | v_vigilo_observations                  | city  | Vauhallan / Saclay                                                 |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Julien                                                       |               1 |
| vigilo     | v_vigilo_observations                  | city  | Geispolsheim                                                       |               1 |
| vigilo     | v_vigilo_observations                  | city  | 2 voitures sur passage piéton.                                     |               1 |
| vigilo     | v_vigilo_observations                  | city  | Plougastel-Daoulas                                                 |               1 |
| vigilo     | v_vigilo_observations                  | city  | Thouaré-sur-Loire                                                  |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Alban-de-Roche                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | L'Isle-dAbeau                                                      |               1 |
| vigilo     | v_vigilo_observations                  | city  | palaiseau                                                          |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Quay Portrieux                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | Villechétif                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | Goincourt                                                          |               1 |
| vigilo     | v_vigilo_observations                  | city  | -0.6474354896712158                                                |               1 |
| vigilo     | v_vigilo_observations                  | city  | Plougastel-Daoulas.                                                |               1 |
| vigilo     | v_vigilo_observations                  | city  | La Grande-Motte                                                    |               1 |
| vigilo     | v_vigilo_observations                  | city  | Sérézin-de-la-Tour                                                 |               1 |
| vigilo     | v_vigilo_observations                  | city  | Les Ulis - Courtaboeuf                                             |               1 |
| vigilo     | v_vigilo_observations                  | city  | Jouy-en-Josas                                                      |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Martin-le-Nœud                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | Cestas                                                             |               1 |
| vigilo     | v_vigilo_observations                  | city  | Bègles                                                             |               1 |
| vigilo     | v_vigilo_observations                  | city  | bordeaux                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Blanquefort                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | rd point Mars 1962 Massy                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Igny. Vers le 2.                                                   |               1 |
| vigilo     | v_vigilo_observations                  | city  | Verrières-le-Buisson grand virage à proximité de la rue de Paradis |               1 |
| vigilo     | v_vigilo_observations                  | city  | bures sur yvette                                                   |               1 |
| vigilo     | v_vigilo_observations                  | city  | Le Légué                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Hoenheim ?                                                         |               1 |
| vigilo     | v_vigilo_observations                  | city  | Gouvieux                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Barberey-Saint-Sulpice                                             |               1 |
| vigilo     | v_vigilo_observations                  | city  | Mérignac                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | rue Etienne Hubac                                                  |               1 |
| vigilo     | v_vigilo_observations                  | city  | Four                                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | Massy place de l'Union Européenne                                  |               1 |
| vigilo     | v_vigilo_observations                  | city  | Châtenay-Malabry                                                   |               1 |
| vigilo     | v_vigilo_observations                  | city  | Bièvres                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | Vinay                                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Hervé                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | Chantilly                                                          |               1 |
| vigilo     | v_vigilo_observations                  | city  | Talence                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | 29200                                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | Brest (Parking Clinique Keraudren)                                 |               1 |
| vigilo     | v_vigilo_observations                  | city  | Baillargues                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | La Montagne                                                        |               1 |
| vigilo     | v_vigilo_observations                  | city  | Indre                                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | Roche                                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | massy                                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | Vauhallan / Palaiseau                                              |               1 |
| vigilo     | v_vigilo_observations                  | city  | Marsac-sur-l'Isle                                                  |               1 |
| vigilo     | v_vigilo_observations                  | city  | Beaulieu                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Hœnheim                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | Compiègne                                                          |               1 |
| vigilo     | v_vigilo_observations                  | city  | Sète                                                               |               1 |
| vigilo     | v_vigilo_observations                  | city  | Basse Goulaine                                                     |               1 |
| vigilo     | v_vigilo_observations                  | city  | Saint-Quentin-Fallavier                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | Morangis                                                           |               1 |
| vigilo     | v_vigilo_observations                  | city  | Villebon sur Yvette                                                |               1 |
| vigilo     | v_vigilo_observations                  | city  | Antony Massy                                                       |               1 |
| vigilo     | v_vigilo_observations                  | city  | Épinay-sur-Orge                                                    |               1 |
| vigilo     | v_vigilo_observations                  | city  | Longpont-sur-Orge                                                  |               1 |
| vigilo     | v_vigilo_observations                  | city  | Châtenay-Malabry                                                   |               1 |
| vigilo     | v_vigilo_observations                  | city  | Hillion                                                            |               1 |
| vigilo     | v_vigilo_observations                  | city  | Yffiniac                                                           |               1 |

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
