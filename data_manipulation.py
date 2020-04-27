#!/usr/bin/python
import os
import sys
import csv

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Set pandas options
pd.set_option('mode.chained_assignment', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', 1000)

# Argument options
ap = argparse.ArgumentParser()
ap.add_argument("--input",  type=str, help="filename")

# Columns
ap.add_argument("--drop", type=str,
                help="drop column. ex: col1,col2")
ap.add_argument("--columns", type=str,
                help="Select columns to save col1,col2")
# Rows
ap.add_argument("-f", "--filter", action='append',
                help="filter = column:field,field, use operators for each fields !column:field1,fields2, ?:col1>0 and col2<10")
ap.add_argument("--limit", type=str,
                help="limit")
ap.add_argument("--sort", type=str,
                help="sort by column. ex: col1,!col2")

# Datas manipulation
ap.add_argument("--pivot", type=str,
                help="Create Pivot. ex: index:column:value")
ap.add_argument("--set-missing", action='append',
                help="set missing value(gnuplotstyle). ex: col:0.0,col1:<0.1")
# ap.add_argument("--replace-by-null", action='append',
#                 help="Replace values by null. ex: col:0.0,col1:<0.1")
ap.add_argument("--remove-and-shift", action='store_true',
                help="Remove and shift NaN values")

# Output
ap.add_argument("--comment",  action='store_true',
                help="Show table header info", default=False)
ap.add_argument("--missing", type=str,
                help="replace missing data: ?", default="")
ap.add_argument("--format", choices=['csv', 'gnuplot'],
                help="Format output file", default='csv')
ap.add_argument("--output", type=str,
                help="output filename")
args = vars(ap.parse_args())

PRECISION = 6

# Used by apply pandas function


def convert_gnuplot_column(value, size):
    result = ""
    if isinstance(value, str):
        string = value
        if " " in value:
            string = f'"{value}"'
        result = string + " "*(size-len(string))
    else:
        string = str(value)
        result = " "*(size-len(string)) + string

    return result

# Used by apply pandas function


def set_missing(value):
    return f'?{value[1:]}'


# Read data]:
df = pd.read_csv(args['input'], sep=",")

# Filter
if args['filter'] is not None:
    for afilter in args['filter']:
        column, stringfilter = afilter.split(':')

        if column[0] != '?':
            include = True
            if column[0] == "!":
                include = False
                column = column[1:]

            if stringfilter == "":
                # Search null value
                mask = df[column].isnull()
                if include:
                    df = df[mask]
                else:
                    df = df[~mask]
            else:
                # Filter string
                strings = stringfilter.split(',')
                mask = df[column].isin(strings)
                if include:
                    df = df[mask]
                else:
                    df = df[~mask]
        else:
            # Custom query
            df = df.query(stringfilter)

# # Replace some value
# if args['replace_by_null'] is not None:
#     for replaceby in args['replace_by_null']:
#         column, replacefilter = replaceby.split(':')
#         less = True
#         if replacefilter[0] in ['<', '>']:
#             compare = pd.Series([float(replacefilter[1:])]*len(df))
#             if replacefilter[0] == '>':
#                 filteredseclection = df[column] > compare
#             else:
#                 filteredseclection = df[column] < compare
#         else:
#             compare = pd.Series([replacefilter]*len(df))
#             compare = compare.astype(df[column].dtype)

#             filteredseclection = df[column] == compare

#         df.loc[filteredseclection, column] = np.NaN

# Set missing some values
# if args['set_missing'] is not None:
#     for afilter in args['set_missing']:
#         column, stringfilter = afilter.split(':')

#         query = f"df['{column}']{stringfilter}"
#         mask = pd.eval(query)

#         df[column] = df[column].apply(lambda x: '{:010.6f}'.format(x))
#         df[column][mask] = df[column][mask].apply(set_missing)

# df['pct_recovered'] = df['pct_recovered'].apply(
#     lambda x: '{:010.6f}'.format(x))
# df['pct_deaths'] = df['pct_deaths'].apply(
#     lambda x: '{:010.6f}'.format(x))


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
            sortby.append(df.columns[idx])
        except:
            # Get column name
            sortby.append(opt)

    df = df.sort_values(by=sortby, ascending=orderby)

# Pivot
if args['pivot']:
    index, column, value = args['pivot'].split(':')
    # df = df.pivot(index=index,
    #               columns=column, values=value)
    # df = df.pivot(index='date',
    #               columns='field', values='per_pop')

    df.groupby(['Country_Region', 'field', 'date']).sum()
    df = df.reset_index()

# Remove and Shift
if args['remove_and_shift']:
    # Remove and shift
    startcolumn = int(args['remove_and_shift'])
    df.set_index(df.columns[0])
    df = df.drop(df.columns[0], axis=1)
    df = df.apply(lambda x: x.shift(-x.notnull().values.argmax()), axis=0)
    df.index = np.arange(1, len(df)+1)
    df = df.reset_index()

# get only selected columns
if args['columns']:
    columns = args['columns'].split(',')
    df = df[columns]

# Drop column
if args['drop']:
    drop = args['drop'].split(',')
    df = df.drop(drop, axis=1)

# limit
if args['limit']:
    df = df.head(args['limit'])

# # Convert to string
# for column in df.columns:
#     if df[column].dtype

# df[column] = df[column].apply(lambda x: '{:010.6f}'.format(x))
# df[column][mask] = df[column][mask].apply(set_missing)


# Save
if args['output']:
    # Export to csv
    if args['format'] == 'csv':
        na_rep = args['missing']
        df.to_csv(
            args['output'],
            sep=",",
            na_rep=na_rep,
            index=False,
            float_format='%.6f'
        )
    elif args['format'] == 'gnuplot':
        # Export to gnuplot format
        with open(args['output'], 'w') as f:

            # Fill missing value
            df = df.fillna("?")

            # Compute column size and quoting header
            lines = []
            strlens = {}
            # line = ""

            # If comment, add comments char code
            # if args['comment']:
            #     df = df.rename({df.columns[0]: f'# {df.columns[0]}'})

            for column in df.columns:
                space = 0
                if " " in column or df[column].astype(str).str.contains(" ").any():
                    space += 2

                strlen = max(
                    len(column),
                    df[column].astype(str).map(len).max()
                )+space
                strlens[column] = strlen

                # line += convert_gnuplot_column(column, strlen) + " "

            # Compute line template
            template = ""
            for column in df.columns[0:-1]:
                align = "<"
                if df[column].dtype == np.int64 or df[column].dtype == np.int64:
                    align = ">"

                template += f"{{:{align}{strlens[column]}}} "
            template += "{:}"

            # convert to strings
            # for column in df.columns:
            #     df[column] = df[column].apply(
            #         convert_gnuplot_column, args=(strlens[column]))

            # if args['comment']:
            #     line = f"# {line}"

            lines.append(template.format(*df.columns))

            # template = "{:>10s} {:>6d} {:>9d} {:>6d} {:>010f} {:>13} {:>10} {:>16} {:>14} {:>7} {:>3} {:>4} {:>4} {:>5} {:>4} {:>6} {:>7} {:>8} {:}"
            # template = "{:>10} {:>6} {:>9} {:>6} {:>10} {:>13} {:>10} {:>16} {:>14} {:>7} {:>3} {:>4} {:>4} {:>5} {:>4} {:>6} {:>7} {:>8} {:}"

            # Quoting datas
            # for column in df.columns[0:-1]:
            #     df[column] = df[column].apply(
            #         convert_gnuplot_column, args=(strlens[column],))

            for idx, columns in df.iterrows():
                line = ""
                # for column in columns:
                #     line += str(column) + " "

                lines.append(template.format(*columns))
                # lines.append(line)

            with open(args['output'], 'a') as f:
                for line in lines:
                    f.write(f"{line}\n")


else:
    print(df)
