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

COLUMNS = ['cases', 'recovered', 'deaths']


def loadData(field, url):
    df = pd.read_csv(url)

    df = df.rename(columns={
        'Country/Region': 'Country_Region',
        'Province/State': 'Province_State',
        field: 'value'
    })

    df = df.melt(id_vars=["Province_State", "Country_Region", "Lat", "Long"],
                 var_name="date",
                 value_name=field)

    # Country & State
    iscountry = df['Province_State'].isnull()
    df.loc[iscountry, 'zone'] = 'country'
    df.loc[~iscountry, 'zone'] = 'state'

    # Merge country and state
    df = df.set_index(['Country_Region', 'Province_State', 'date'])

    return df


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

countries = countries.drop(['Long_'], axis=1)
provinces = provinces.drop(['Long_'], axis=1)


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


# Merge column
df = cases.copy()
df['recovered'] = recovered['recovered']
df['deaths'] = deaths['deaths']

# Update columns
#df = df.drop(['Lat', 'Long'], axis=1)
df[COLUMNS] = df[COLUMNS].fillna(0)
df[COLUMNS] = df[COLUMNS].astype(int)

df = df.reset_index()
df = pd.merge(
    df, population,
    left_on=['Province_State', 'Country_Region'],
    right_on=['Province_State', 'Country_Region']
)

# Add/Update column informations
for column in COLUMNS:
    df[f'pct_{column}'] = (
        df[column] / df['population']*100).astype(float)

# Convert date
df['date'] = pd.to_datetime(df['date'])

df = df.drop(['Long_', 'Combined_Key', 'Lat_y'], axis=1)
df = df.rename({'Lat_x': 'Lat'}, axis=1)

# Order column
df = df[['date', 'cases', 'recovered', 'deaths', 'pct_cases', 'pct_recovered', 'pct_deaths', 'Country_Region', 'Province_State',
         'zone', 'UID', 'iso2', 'iso3', 'FIPS', 'Admin2', 'Lat', 'Long', 'population']]

# Sort
df = df.sort_values(['Country_Region', 'Province_State', 'date'])

# Save file
df.to_csv(args['output'],  sep=",", index=False,
          index_label="idx", float_format='%.6f')
