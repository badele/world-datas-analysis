#!/usr/bin/python
import os
import re
import sys
#import csv
import glob
#import argparse
import zipfile
import pandas as pd
import numpy as np

import sqlite3 as sql

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

#######################################
# Country
#######################################
COUNTRY_COLUMNS = [
    'iso2', 
    'iso3', 
    'isonum', 
    'fips', 
    'country', 
    'capital',
    'area', 
    'countrypopulation', 
    'continent', 
    'tld', 
    'currencycode',
    'currencyname', 
    'phone', 
    'postalcodeformat',
    'postalcoderegex',
    'language', 
    'GEOID', 
    'neighbours', 
    'equivfipscode'
]

COUNTRY_COLUMNS_TYPE = {
    'iso2': np.str, 
    'iso3': np.str, 
    'isonum': np.int, 
    'fips': np.str, 
    'country': np.str, 
    'capital': np.str,
    'area': np.float,  
    'countrypopulation': np.int, 
    'continent': np.str, 
    'tld': np.str, 
    'currencycode': np.str,
    'currencyname': np.str, 
    'phone': np.str, 
    'postalcodeformat': np.str,
    'postalcoderegex': np.str,
    'language': np.str, 
    'GEOID': np.str,  
    'neighbours': np.str, 
    'equivfipscode': np.str
}

ALLCOUNTRIES_COLUMNS = [
    'GEOID', 
    'name', 
    'asciiname', 
   'alternatenames', 
    'latitude', 
    'longitude',
    'featureclass',  
    'featurecode', 
    'countrycode', 
    'cc2', 
    'adm1',
    'adm2',
    'adm3',
    'adm4',
    'population', 
    'elevation', 
    'dem',
    'timezone',
    'lastupdate'
]

ALLCOUNTRIES_COLUMNS_TYPE = {
    'GEOID': np.int, 
    'name': np.str, 
    'asciiname': np.str, 
    'alternatenames': np.str, 
    'latitude': np.float, 
    'longitude': np.float,
    'featureclass': np.str,  
    'featurecode': np.str, 
    'countrycode': np.str, 
    'cc2': np.str, 
    'adm1': np.str,
    'adm2': np.str,
    'adm3': np.str,
    'adm4': np.str,
    'population': np.int, 
    'elevation': np.str, 
    'dem': np.int,
    'timezone': np.str,
    'lastupdate': np.str
}

FEATURE_COLUMNS = [
    'code', 
    'info1', 
    'info2'
]

FEATURE_COLUMNS_TYPE = {
    'code': np.str, 
    'info1': np.str, 
    'info2': np.str
}


HIERARCHY_COLUMNS = [
    'parent', 
    'child', 
    'type'
]

HIERARCHY_COLUMNS_TYPE = {
    'parent': np.int, 
    'child': np.int, 
    'type': np.str
}

conn = sql.connect('world-datas-analysis.db')


#######################################
# Continent
#######################################
print('Export continent to sql')
continents = {'code': ['AF','AS','EU','NA','OC','SA','AN'], 'continent': ['Africa','Asia','Europe','North America','Oceania','South America','Antarctica'],'GEOID': [6255146,6255147,6255148,6255149,6255151,6255150,6255152]}
df = pd.DataFrame.from_dict(continents)
df.to_sql('x_downloaded_geonames_continent',conn, if_exists='replace',index=False)


#######################################
# Feature class
#######################################
print('Export Featureclass to sql')
features = {'code': ['A','H','L','P','R','S','T','U','V'], 'name': ['country, state, region,...','stream, lake, ...','parks,area, ...','city, village,...','road, railroad ','spot, building, farm','mountain,hill,rock,... ','undersea','forest,heath,...']}
df = pd.DataFrame.from_dict(features)
df.to_sql('x_downloaded_geonames_featureclass',conn, if_exists='replace',index=False)


#######################################
# Feature code
#######################################
net.downloadHttpFile(
    'https://download.geonames.org/export/dump/featureCodes_en.txt',
    '/tmp/featureCodes_en.txt',
    'Download Feature code'
)

print('Export Featurecode to sql')
df = pd.read_csv('/tmp/featureCodes_en.txt', sep='\t', header = None,  names=FEATURE_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
#df = pd.read_sql('SELECT * FROM geonames_featurecode_downloaded', conn)
df[["featureclass", "featurecode"]] = df['code'].str.split('.', 1, expand=True)
df = df[["featureclass",'featurecode','info1','info2']]
df.to_sql('x_downloaded_geonames_featurecode',conn, if_exists='replace',index=False)

#######################################
# CountryInfo
#######################################
# Download
net.downloadHttpFile(
    'https://download.geonames.org/export/dump/countryInfo.txt',
    '/tmp/countryInfo.txt',
    'Download Country info'
)

# Count Nb comment lines
skiprows=0
with open ('/tmp/countryInfo.txt', 'r') as tmpfile:
    for line in tmpfile.readlines():
        if re.match("^#.*", line): 
            skiprows+=1

# Export to sql
print('Export CountryInfo to sql')
df = pd.read_csv('/tmp/countryInfo.txt', sep='\t', header = None, skiprows=skiprows, names=COUNTRY_COLUMNS,dtype=COUNTRY_COLUMNS_TYPE,na_values=DEFAULT_MISSING)

# Insert column at column 0 position
GEOID = df['GEOID']
df.drop(labels=['GEOID'], axis=1,inplace = True)
df.insert(0, 'GEOID', GEOID)

df.to_sql('x_downloaded_geonames_country',conn, if_exists='replace',index=False)

#######################################
# All countries
#######################################

# All countries
if not os.path.exists('/tmp/allCountries/allCountries.txt'):
    net.downloadHttpFile(
        'https://download.geonames.org/export/dump/allCountries.zip',
        '/tmp/allCountries.zip',
        'Download All countries'
    )

    print("Unzip All countries")
    with zipfile.ZipFile('/tmp/allCountries.zip', 'r') as ziparchive:
        ziparchive.extractall('/tmp/allCountries')

# Split files
filenames = glob.glob("/tmp/allCountries/allCountries-*")
if len(filenames) == 0:
    print("split All countries files")
    file.splitFile('/tmp/allCountries/allCountries.txt',100000)

print('Export All countries to sql')
filenames = glob.glob("/tmp/allCountries/allCountries-*")
for filename in filenames:
    mode='append'
    if filename == filenames[0]:
        mode='replace'

    df = pd.read_csv(filename, sep='\t', header = None, names=ALLCOUNTRIES_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
    df.drop(labels=['alternatenames'], axis=1,inplace = True)
    df['geolevel'] = None
    df['populationdate'] = None
    df['source'] = 'geonames'

    df.to_sql('x_downloaded_geonames_allcuntries',conn, if_exists=mode,index=False)


#######################################
# Hierarchy
#######################################

if not os.path.exists('/tmp/hierarchy/hierarchy.txt'):
    net.downloadHttpFile(
        'https://download.geonames.org/export/dump/hierarchy.zip',
        '/tmp/hierarchy.zip',
        'Download hierarchy'
    )    

    print("Unzip Hierarchy")
    with zipfile.ZipFile(f'/tmp/hierarchy.zip', 'r') as ziparchive:
        ziparchive.extractall(f'/tmp/hierarchy')

df = pd.read_csv('/tmp/hierarchy/hierarchy.txt', sep='\t', header = None, names=HIERARCHY_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
df.to_sql('x_downloaded_geonames_hierarchy',conn, if_exists='replace',index=False)
