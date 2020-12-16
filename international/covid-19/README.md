# Covid-19 Summaries

## Download JHU datas and Graph
```
# Use virtualenn python environment
source .venv/bin/activate

# Download datas from official JHU repository
python international/covid-19/download_from_jhu.py

# Clean and join datas
sqlite3 world-datas-analysis.db < international/covid-19/import_global_covid19_jhu.sql

# Export to CSV
sqlite3 world-datas-analysis.db < international/covid-19/export_global_covid19_jhu.sql

# Generate graphs
international/covid-19/generate_graphs.sh
```



# Global Graphs

### Cases

<img width="50%" height="50%" src="pictures/countries_ratio_cases_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_cases_for_1000000hab.gdata)


### Deaths

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


# Filter value datas

### Cases

<img width="50%" height="50%" src="pictures/countries_ratio_cases_filter_1_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_cases_filter_1_for_1000000hab.gdata)


### Deaths

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_filter_1_for_1000000hab.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_filter_1_for_1000000hab.gdata)


### Deaths by country

### Brazil

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Brazil.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### France

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_France.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### Germany

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Germany.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### Italy

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Italy.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### Korea South

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Korea South.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### Netherlands

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Netherlands.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)



### Spain

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Spain.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### Sweden

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_Sweden.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### United Kingdom

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_United Kingdom.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)


### US

<img width="50%" height="50%" src="pictures/countries_ratio_deaths_for_1000000hab_US.png"/>

[Gnuplot Datafile source](datas/countries_ratio_deaths_for_1000000hab.gdata)
