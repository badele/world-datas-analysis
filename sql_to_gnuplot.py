#!/usr/bin/python
import os
import sys
import csv

import argparse
import pandas as pd

import sqlite3

from tabulate import tabulate

# For pipe exception error
from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE, SIG_DFL)

def agg_count(df):
    return df.count()

def agg_count(df):
    return df.mean()

def agg_sum(df):
    return df.sum()

def agg_min(df):
    return df.min()

def agg_q1(df):
    return df.quantile(0.25)

def agg_median(df):
    return df.median()

def agg_q3(df):
    return df.quantile(0.75)

def agg_max(df):
    return df.max()

def convert2gnuplot(df, args):
    result = ""
    # Add comments
    result += "# Generated by https://github.com/badele/world-datas-analysis\n"
    result += f"# Query: {args.query}\n"
    if args.comment:
        for comment in args.comment:
            result += f"# {comment}\n"
    result += "\n"

    # Group by
    if args.group_by:
        df = df.groupby(args.group_by.split(","))

    if args.group_func:
        # First pass
        mydict = {}
        for groupfunc in args.group_func:
            srcol, func, dstcol = groupfunc.split(':')

            if '%' not in func:
                mydict[dstcol] = (srcol, eval(f'agg_{func}'))

        df = df.agg(**mydict)
        df = df.reset_index()
    # else:
    #     print(df.head())
    #     df = df.filter(lambda x: True)


    # Add datas
    if args.block_by:
        group_by_columns = args.block_by.split(',')
        g = df.groupby(group_by_columns,sort=False)
        lastcolumn = list(g.groups)[-1]

        for groupname, items in g:
            # Quoting string content contains a space
            for column in items.columns:
                if items[column].dtype == object:
                    mask = items[column].astype(str).str.contains(" ")
                    items[column][mask] = '"' + items[column][mask] + '"'

            text = tabulate(
                items,
                headers=items.columns,
                floatfmt=".6f",
                showindex="never",
                tablefmt='plain'
            )

            # Show comments
            result += f"# {group_by_columns[0]}={groupname}\n"
            # Write datas
            result += text

            if groupname != lastcolumn:
                result += "\n\n\n"
    else:
        # Quoting string content contains a space
        for column in df.columns:
            if df[column].dtype == object:
                mask = df[column].astype(str).str.contains(" ")
                df[column][mask] = '"' + df[column][mask] + '"'

        text = tabulate(
            df,
            headers=df.columns,
            floatfmt=".6f",
            showindex="never",
            tablefmt='plain'
        )

        # Write datas
        result += text


    return result


# Set pandas options
pd.set_option('mode.chained_assignment', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', 1000)

# Argument options
ap = argparse.ArgumentParser()
ap.add_argument("--db",  type=str, help="database")
ap.add_argument("--query",  type=str, help="query")
ap.add_argument("--group-by", type=str,
                help="group by columns(separated by commas)")
ap.add_argument("--group-func", action='append',
                help="group functions 'srccolname:function:dstcolname'")
ap.add_argument("--block-by", type=str,
                help="block by column")

# Output
ap.add_argument("--comment", action='append',
                help="Add comment")
ap.add_argument("--output", type=str,
                help="output filename")
args = ap.parse_args()

# Check inclusive argument
if args.group_by and args.group_func is None:
    ap.error("--group-by requires --group-func.")

# Execute query:
conn = sqlite3.connect(args.db)
with conn:
    df = pd.read_sql_query(args.query, conn)

# Save
if args.output:
    # Fill missing value
    df = df.fillna("?")
    # df = df.rename({df.columns[0]: f'# {df.columns[0]}'}, axis=1)

    with open(args.output, 'w') as f:

        f.write(convert2gnuplot(df, args))
else:
    sys.stdout.write((convert2gnuplot(df, args)))
