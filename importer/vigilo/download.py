#!/usr/bin/python
import os
import re
import sys
import json
#import csv
import glob
#import argparse
import zipfile
import pandas as pd
import numpy as np
import requests
import glob

import sqlite3 as sql
from packaging import version

# Add module path
sys.path.insert(0, os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../..")))

import lib.python.net as net
import lib.python.file as file

# # Set pandas options
pd.set_option('mode.chained_assignment', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', 1000)

DEFAULT_MISSING = pd._libs.parsers.STR_NA_VALUES
DEFAULT_MISSING = DEFAULT_MISSING.remove('NA')

# Create temorary folder
if not os.path.exists('./downloaded/vigilo'):
    os.makedirs('./downloaded/vigilo')

def download_instances():
    df = pd.read_json('https://vigilo-bf7f2.firebaseio.com/citylist.json',orient='index')
    df.reset_index(inplace=True)
    df.rename(columns={'index': 'name'},inplace=True)
    df=df[df['prod']]
    df.drop(["prod"], axis=1, inplace=True)
    df.insert(0,'InstanceID',df.index + 1) 
    df.to_csv('./downloaded/vigilo/instance.csv',index=False)

    return df

def download_categories():
    df = pd.read_json('https://vigilo-bf7f2.firebaseio.com/categorieslist.json',orient='values')
    df.to_csv('./downloaded/vigilo/category.csv',index=False)


def download_observations(instances):
    for index, row in instances.iterrows():
        api_path = row['api_path'] 
        scope = row['scope'] 
        instance_id = row['InstanceID']
        try:
            # Get version
            r = requests.get(f'{api_path}/get_version.php', allow_redirects=True)
            apiversion = r.json()['version']
            if version.parse(apiversion) > version.parse("0.0.11"):
                df = pd.read_json(f"{api_path}/get_issues.php?scope={scope}&format=json")
                df.insert(0,'InstanceID',instance_id)
                df.to_csv(f'./downloaded/vigilo/obs_{scope}.csv',index=False)
                print(f"Downloader {scope} => {api_path}")
            else:
                print(f"!! BAD API VERSION !! {scope} => {api_path}")
        except:
            print(f"!! ERROR !! {scope} => {api_path}")
            pass

def concatenate_observation():
    modes = ['w','a']

    files = glob.glob('./downloaded/vigilo/obs_*.csv')
    for idx in range(len(files)):
        filename = files[idx]
        mode = modes[min(idx,1)]

        df = pd.read_csv(filename)
        df.to_csv('./downloaded/vigilo/observation.csv',mode=mode,index=False,header=idx<1)

#######################################
# Main
#######################################

download_categories()
instances = download_instances()
download_observations(instances)
concatenate_observation()