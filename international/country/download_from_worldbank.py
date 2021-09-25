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

NB_ZIP_FILE = 0


def download_indicator_description(conn):
    extractor = Extractor.from_yaml_file(
        "./international/country/worldbank_category_fr.yaml"
    )
    r = requests.get("https://donnees.banquemondiale.org/indicateur/")
    data = extractor.extract(r.text)

    categories = []
    indicators = []
    for block in data["block"]:
        category = block["category"]
        catid = len(categories) + 1
        categories.append((catid, "FR", category))

        for idx in range(len(block["indicator"])):
            indicator = block["indicator"][idx]
            m = re.match(r"/indicateur/(.*)\?view=chart", block["indicatorlink"][idx])
            id = m.group(1)
            indicators.append(("FR", catid, id, indicator))

    df_cat = pd.DataFrame(categories, columns=["CATID", "lang", "category"])
    df_cat.to_sql("worldbank_category", conn, if_exists="replace", index=False)

    df_indicator = pd.DataFrame(
        indicators, columns=["lang", "CATID", "IndicatorCode", "description"]
    )
    df_indicator.to_sql("worldbank_indicator", conn, if_exists="replace", index=False)


def download_country_datas(geoid, iso3):
    global NB_ZIP_FILE

    zipfilename = f"/tmp/worldbank_{iso3}.zip"
    if not os.path.exists(zipfilename):
        net.downloadHttpFile(
            f"https://api.worldbank.org/v2/en/country/{iso3}?downloadformat=csv",
            zipfilename,
            f"Download worldbank {iso3} country",
        )

    if zipfile.is_zipfile(zipfilename):
        with zipfile.ZipFile(zipfilename, "r") as ziparchive:
            ziparchive.extractall("/tmp/worldbank")
        NB_ZIP_FILE += 1

        #######################################
        # Country
        #######################################
        print(f"Export {iso3} to sql")
        datafilename = glob.glob(f"/tmp/worldbank/API_{iso3}_DS2_en_csv_v2_*.csv")
        if len(datafilename) > 0:
            df = pd.read_csv(
                datafilename[0], sep=",", skiprows=4, na_values=DEFAULT_MISSING
            )
            df.columns = df.columns.str.replace(" ", "")
            df.drop(df.columns[len(df.columns) - 1], axis=1, inplace=True)
            df.drop(["CountryName"], axis=1, inplace=True)
            df.drop(["IndicatorName"], axis=1, inplace=True)

            df = pd.melt(
                df,
                id_vars=["CountryCode", "IndicatorCode"],
                var_name="year",
                value_name="value",
            )
            df["year"] = df["year"].astype("int32")
            df = df[df["value"].notna()]

            mode = "append"
            if NB_ZIP_FILE <= 1:
                mode = "replace"

            df.to_sql(
                "x_downloaded_worldbank_country", conn, if_exists=mode, index=False
            )


def get_translated_indicator_name(conn):
    url = ""
    headers = {"Accept-Language": "fr-FR,fr"}
    r = requests.get(url, headers=headers)

    m = re.match(r"<title .*>(.*)</title>", r.text)
    print(r.text)
    if m:
        print(m.groups(0))


conn = sql.connect("world-datas-analysis.db")

############################
# Get indicators description
############################

download_indicator_description(conn)

df = pd.read_sql("SELECT geoid,iso3 from v_geonames_country", conn)
for index, row in df.iterrows():
    download_country_datas(row["GEOID"], row["iso3"])
