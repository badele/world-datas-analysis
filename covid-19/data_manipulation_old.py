#!/usr/bin/python
import os

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Set pandas options
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)


# Argument options
ap = argparse.ArgumentParser()
# ap.add_argument("-d", "--data", choices=['confirmed', 'recovered', 'death'],
#                 help="(default: %(default)s)", default='confirmed')
ap.add_argument("-c", "--column", type=str,
                help="column filter")
ap.add_argument("-f", "--filter", action='append',
                help="filter")
ap.add_argument("-l", "--limit", type=int,
                help="limit")
ap.add_argument("-r", "--reverse", action='store_true',
                help="reverse")
ap.add_argument("-v", "--value", choices=[
    'cases',
    'deaths',
    'recovered',
    'norm_cases',
    'norm_deaths',
    'norm_recovered',
],
    help="get column value", required=True)
ap.add_argument("-o", "--output", type=str,
                help="output filename", required=True)
args = vars(ap.parse_args())


# Read datas
filename = '/tmp/downloaded_coronadatascraper.pd'
data = None
if os.path.exists(filename):
    data = pd.read_pickle(filename)
else:
    data = pd.read_csv('https://coronadatascraper.com/timeseries.csv')
    data.to_pickle(filename)

# Filter
if args['filter'] is not None:
    data = data[data['name'].isin(args['filter'])]

# Normalize number data for 100.000 peoples
data['norm_cases'] = data['cases'].div(
    data['population']/100000, axis=0).round(2)
data['norm_deaths'] = data['deaths'].div(
    data['population']/100000, axis=0).round(2)
data['norm_recovered'] = data['recovered'].div(
    data['population']/100000, axis=0).round(2)
data['norm_active'] = data['active'].div(
    data['population']/100000, axis=0).round(2)

# Pivot datas
data = data[data['level'] == args['column']]
data = data.pivot(index='name', columns='date', values=args['value'])

# Sort and limit
data = data.sort_values(by=data.columns[-1], ascending=args['reverse'])
data = data.head(args['limit'])

# Recompute datas
# Align country with first data apparition
columns = {}
rows = []
first_column_idx = 1
max_col = 0
for name, cols in data.iterrows():
    non_zero_idx = (cols > 0).argmax()
    if non_zero_idx > 0:
        columns[name] = cols[non_zero_idx+first_column_idx:].to_list()
        max_col = max(max_col, len(columns[name]))

# Convert data into columns and fill empty data(to NaN)
for k in columns:
    nb_col = len(columns[k])
    columns[k].extend([np.nan]*(max_col-nb_col))

result = pd.DataFrame.from_dict(columns)
result.index = np.arange(1, len(result)+1)

result.to_csv(args['output'], na_rep="?", sep="\t",
              index_label="idx", header=columns)
