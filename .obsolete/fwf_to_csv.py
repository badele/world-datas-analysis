#!/usr/bin/python
import os
import sys
import csv
import json 
import argparse
import pandas as pd
import numpy as np

import sqlite3

from tabulate import tabulate

#cat international/countrydatas/population_country_preview.txt| grep -Ev "#|---|^$" > /tmp/result.txt

# For pipe exception error
from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE, SIG_DFL)

# Set pandas options
pd.set_option('mode.chained_assignment', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', 1000)

DEFAULT_MISSING = pd._libs.parsers.STR_NA_VALUES
DEFAULT_MISSING = DEFAULT_MISSING.remove('NA')

# Argument options
ap = argparse.ArgumentParser()
ap.add_argument("--comment", action='append',
                help="Add comment")
ap.add_argument("--input", type=str,
                required=True,
                help="input filename")
ap.add_argument("--output", type=str,
                required=True,
                help="output filename")
args = ap.parse_args()

# Search columns formater
with open(args.input) as ifile:
    while filtercolumns := next(ifile, None):  
        if "# columns:" in filtercolumns:
            break

    columns = filtercolumns.split(':')[1]
    colspecs = json.loads(columns)

df = pd.read_fwf(args.input, colspecs=colspecs, comment='#',na_values=DEFAULT_MISSING)
df.to_csv(args.output,sep='\t',index=False)



