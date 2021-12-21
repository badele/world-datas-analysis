#!/usr/bin/python
import os
import sys

import argparse
import pandas as pd

# Add module path
sys.path.insert(0, os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../..")))

import lib.python.net as net

# Download Covid-19 datas from https://github.com/CSSEGISandData/COVID-19

COLUMNS = ['cases', 'recovered', 'deaths']
def loadAndExportData(field, url):
    df = pd.read_csv(url)

    df = df.rename(columns={
        'Country/Region': 'Country_Region',
        'Province/State': 'Province_State',
        field: 'value'
    })

    df = df.melt(id_vars=["Province_State", "Country_Region", "Lat", "Long"],
                 var_name="date",
                 value_name='value')

    df["field"] = field
    df['date'] = pd.to_datetime(df['date'])

    df = df[["date", "Country_Region", "Province_State",  "field", "value"]]

    df.to_csv(
        f'international/covid-19/datas/global_covid19_JHU_{field}_downloaded.csv',
        index=False
    )

    return df

#######################################
# Download datas
#######################################
# Population
net.downloadHttpFile(
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv',
    '/tmp/wda_UID_ISO_FIPS_LookUp_Table.csv'
)

# Cases
net.downloadHttpFile(
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv',
    '/tmp/wda_time_series_covid19_confirmed_global.csv'
)

# Recovered
net.downloadHttpFile(
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv',
    '/tmp/wda_time_series_covid19_recovered_global.csv'
)

# Deaths
net.downloadHttpFile(
    'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv',
    '/tmp/wda_time_series_covid19_deaths_global.csv'
)

#######################################
# population
#######################################
population = pd.read_csv(
    '/tmp/wda_UID_ISO_FIPS_LookUp_Table.csv')
population = population.rename(columns={
    'Population': 'population',
})
# Save JHU datas files
population.to_csv(
    'international/covid-19/datas/global_covid19_JHU_locations_downloaded.csv',
    index=False
)

#######################################
# Load and export cases,recovered,deaths Datas
#######################################
cases = loadAndExportData(
    'cases',
    '/tmp/wda_time_series_covid19_confirmed_global.csv'
)
recovered = loadAndExportData(
    'recovered',
    '/tmp/wda_time_series_covid19_recovered_global.csv'
)
deaths = loadAndExportData(
    'deaths',
    '/tmp/wda_time_series_covid19_deaths_global.csv'
)
