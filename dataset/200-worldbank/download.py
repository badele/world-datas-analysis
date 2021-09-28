#!/usr/bin/python
import os
import re
import sys

# import csv
import glob

# import argparse
import zipfile
import pandas as pd
import numpy as np

import requests
import sqlite3 as sql

from selectorlib import Extractor, Formatter
from pprint import pprint

# Add module path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

import lib.python.net as net
import lib.python.file as file

# # Set pandas options
pd.set_option("mode.chained_assignment", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.max_rows", None)
pd.set_option("display.width", 1000)

DEFAULT_MISSING = pd._libs.parsers.STR_NA_VALUES
DEFAULT_MISSING = DEFAULT_MISSING.remove("NA")

def download_french_category_and_indicator():
    extractor = Extractor.from_yaml_file(
        f"./dataset/200-worldbank/french_category.yaml"
    )
    r = requests.get("https://donnees.banquemondiale.org/indicateur/?tab=all")
    data = extractor.extract(r.text)

    indicators = []
    for block in data["block"]:
        category = block["category"]
        for idx in range(len(block["indicator"])):
            indicator = block["indicator"][idx]
            m = re.match(r"/indicateur/(.*)\?view=chart", block["link"][idx])
            id = m.group(1)
            indicators.append((id, category, indicator))

    df_indicator = pd.DataFrame(
        indicators, columns=["Series Code", "Topic", "Indicator Name"]
    )
    df_indicator.to_csv("./downloaded/worldbank/french_indicator.csv", index=False)



def get_translated_indicator_name(conn):
    url = ""
    headers = {"Accept-Language": "fr-FR,fr"}
    r = requests.get(url, headers=headers)

    m = re.match(r"<title .*>(.*)</title>", r.text)
    print(r.text)
    if m:
        print(m.groups(0))


def download_worldbank_datas():
    zipfilename = f"./downloaded/worldbank_csv.zip"
    if not os.path.exists(zipfilename):
        print(f"Download {zipfilename}")
        net.downloadStreamedHttpFile(
            f"http://databank.worldbank.org/data/download/WDI_csv.zip",
            zipfilename,
        )

    if not os.path.exists('./downloaded/worldbank/WDIData.csv'):
        if zipfile.is_zipfile(zipfilename):
            print("Unzip worldbank datas")
            with zipfile.ZipFile(zipfilename, "r") as ziparchive:
                ziparchive.extractall("./downloaded/worldbank")

def pivot_datas():
    if not os.path.exists('./downloaded/worldbank/WDIData_pivot.csv'):
            df = pd.read_csv('./downloaded/worldbank/WDIData.csv')
            df.drop(["Country Name"], axis=1, inplace=True)
            df.drop(["Indicator Name"], axis=1, inplace=True)

            df = pd.melt(
                df,
                id_vars=["Country Code", "Indicator Code"],
                var_name="year",
                value_name="value",
            )
#            df["year"] = df["year"].astype("int32")
            df = df[df["value"].notna()]
            df.rename(columns={
                'Country Code': 'COUNTRYCODE',
                'Indicator Code': 'IndicatorKey',
                'year': 'YEAR'
            },
            inplace=True)

            df.to_csv('./downloaded/worldbank/WDIData_Pivot.csv',index=False)

############################
# Download Datas
############################

# Create temorary folder
if not os.path.exists('./downloaded/worldbank'):
    os.makedirs('./downloaded/worldbank')

# Download worldbank datas
download_worldbank_datas()
pivot_datas()

# Download french indicators
download_french_category_and_indicator()
