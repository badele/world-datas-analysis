#!/usr/bin/python
import os
import sys

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Set pandas options
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', 1000)

# Argument options
ap = argparse.ArgumentParser()
ap.add_argument("--input",  type=str, help="filename")

# Column
ap.add_argument("--drop", type=str,
                help="drop column. ex: col1,col2")
ap.add_argument("--columns", type=str,
                help="Select columns to save col1,col2")

ap.add_argument("-f", "--filter", action='append',
                help="filter = column:field,field, use ! for exclude. ex: !column:field,filed")
ap.add_argument("--limit", type=str,
                help="limit")
ap.add_argument("--missing", type=str,
                help="replace missing data: ?", default="")
ap.add_argument("--pivot", type=str,
                help="Create Pivot. ex: index:column:value")
ap.add_argument("--replace-by-null", action='append',
                help="Replace values by null. ex: col:0.0,col1:<0.1")
ap.add_argument("--remove-and-shift", action='store_true',
                help="Remove and shift NaN values")
ap.add_argument("--sort", type=str,
                help="sort by column. ex: col1,!col2")
ap.add_argument("--stat",  action='store_true',
                help="Show table header info")
ap.add_argument("--output", type=str,
                help="output filename")
args = vars(ap.parse_args())


# Read data]:
data = pd.read_csv(args['input'])

# Show table information
if args['stat']:
    # print(f'Columns: {list(data.columns)}')
    limit = 2
    if args['limit']:
        limit = args['limit']

    print(data.head(limit))
    print()
    print(data.describe())
    print()
    sys.exit(0)


# Filter
if args['filter'] is not None:
    for afilter in args['filter']:
        column, stringfilter = afilter.split(':')

        include = True
        if column[0] == "!":
            include = False
            column = column[1:]

        if stringfilter == "":
            if include:
                data = data[data[column].isnull()]
            else:
                data = data[~data[column].isnull()]
        else:
            search = stringfilter.split(',')
            if include:
                data = data[data[column].isin(search)]
            else:
                data = data[~data[column].isin(search)]


# Replace by null
if args['replace_by_null'] is not None:
    for replaceby in args['replace_by_null']:
        column, replacefilter = replaceby.split(':')
        less = True
        if replacefilter[0] in ['<', '>']:
            compare = pd.Series([float(replacefilter[1:])]*len(data))
            if replacefilter[0] == '>':
                filteredseclection = data[column] > compare
            else:
                filteredseclection = data[column] < compare
        else:
            compare = pd.Series([replacefilter]*len(data))
            compare = compare.astype(data[column].dtype)

            filteredseclection = data[column] == compare

        data.loc[filteredseclection, column] = np.NaN

# Sort
if args['sort']:
    sortby = []
    orderby = []

    opts = args['sort'].split(',')
    for opt in opts:
        # Get order sorting
        asc = True
        if opt[0] in ['>', '<']:
            opt = opt[1:]
            asc = opt[0] == '>'
        orderby.append(asc)

        # Try get column id
        try:
            idx = int(opt)
            sortby.append(data.columns[idx])
        except:
            # Get column name
            sortby.append(opt)

    data = data.sort_values(by=sortby, ascending=orderby)

# Pivot
if args['pivot']:
    index, column, value = args['pivot'].split(':')
    data = data.pivot(index=index,
                      columns=column, values=value)
    data = data.reset_index()

# Remove and Shift
if args['remove_and_shift']:
    # Remove and shift
    startcolumn = int(args['remove_and_shift'])
    data.set_index(data.columns[0])
    data = data.drop(data.columns[0], axis=1)
    data = data.apply(lambda x: x.shift(-x.notnull().values.argmax()), axis=0)
    data.index = np.arange(1, len(data)+1)
    data = data.reset_index()

# get only selected columns
if args['columns']:
    columns = args['columns'].split(',')
    data = data[columns]

# Drop column
if args['drop']:
    drop = args['drop'].split(',')
    data = data.drop(drop, axis=1)

    # limit
if args['limit']:
    data = data.head(args['limit'])

# Save
if args['output']:
    na_rep = args['missing']
    data.to_csv(
        args['output'],
        sep=",",
        na_rep=na_rep,
        index=False,
        float_format='%.5f'
    )
else:
    print(data)
