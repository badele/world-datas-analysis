#!/usr/bin/python
import os

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


# Argument options
ap = argparse.ArgumentParser()
ap.add_argument("--output", type=str,
                help="output filename")
args = vars(ap.parse_args())


def loadData(field, url):
    data = pd.read_csv(url)
    data = data.rename(columns={
        'Country/Region': 'Country_Region',
        'Province/State': 'Province_State',
        field: 'value'
    })

    data = data.melt(id_vars=["Province_State", "Country_Region", "Lat", "Long"],
                     var_name="date",
                     value_name="value")

    iscountry = data['Province_State'].isnull()
    data_country = data.loc[iscountry].copy()
    data_country.loc[iscountry, 'zone'] = 'country'
    data_country['field'] = field

    data_state = data[~iscountry].copy()
    data_state.loc[~iscountry, 'zone'] = 'state'
    data_state['field'] = field

    data = data_country.append(data_state)

    return data


#######################################
# population
#######################################
population = pd.read_csv(
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv')
population = population.rename(columns={
    'Population': 'population',
})

# Create countries from population data
countries = population[population['Province_State'].isnull()]
countries = countries.set_index('Country_Region')
countries['zone'] = 'country'

# Create provinces from population data
provinces = population[~population['Province_State'].isnull()]
provinces = provinces.set_index('Province_State')
provinces['zone'] = 'state'


#######################################
# Datas
#######################################
cases = loadData(
    'cases',
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv'
)
recovered = loadData(
    'recovered',
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv'
)
deaths = loadData(
    'deaths',
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv'
)


data = cases.append(recovered)
data = data.append(deaths)

data = pd.merge(
    data, population[['Province_State', 'Country_Region', 'population']],
    left_on=['Province_State', 'Country_Region'],
    right_on=['Province_State', 'Country_Region']
)

# Add/Update column informations
data['per_pop'] = (data['value'] / data['population']).astype(float)
data['date'] = pd.to_datetime(data['date'])

# Save file
data.to_csv(args['output'],  sep=",",
            index_label="idx", float_format='%.6f')
