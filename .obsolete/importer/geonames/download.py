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

FEATURE_COLUMNS = [
    'code', 
    'info1', 
    'info2'
]

HIERARCHY_COLUMNS = [
    'parent', 
    'child', 
    'type'
]

# Create temorary folder
if not os.path.exists('./downloaded/geonames'):
    os.makedirs('./downloaded/geonames')

#######################################
# Continent
#######################################
print('Export continent to sql')
continents = {'Continent_Key': ['AF','AS','EU','NA','OC','SA','AN'], 'Continent': ['Africa','Asia','Europe','North America','Oceania','South America','Antarctica'],'GEOID': [6255146,6255147,6255148,6255149,6255151,6255150,6255152]}
df = pd.DataFrame.from_dict(continents)
df.to_csv('./downloaded/geonames/continent.csv',index=False)


#######################################
# Feature class
#######################################
print('Export Featureclass to sql')
features = {'code': ['A','H','L','P','R','S','T','U','V'], 'name': ['country, state, region,...','stream, lake, ...','parks,area, ...','city, village,...','road, railroad ','spot, building, farm','mountain,hill,rock,... ','undersea','forest,heath,...']}
df = pd.DataFrame.from_dict(features)
df.to_csv('./downloaded/geonames/featureclass.csv',index=False)


#######################################
# Feature code
#######################################
net.downloadHttpFile(
    'https://download.geonames.org/export/dump/featureCodes_en.txt',
    './downloaded/geonames/featureCodes_en.txt',
    True
    )

print('Export Featurecode to sql')
df = pd.read_csv('./downloaded/geonames/featureCodes_en.txt', sep='\t', header = None,  names=FEATURE_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
#df = pd.read_sql('SELECT * FROM geonames_featurecode_downloaded', conn)
df[["featureclass", "featurecode"]] = df['code'].str.split('.', 1, expand=True)
df = df[["featureclass",'featurecode','info1','info2']]
df.to_csv('./downloaded/geonames/featurecode.csv',index=False)

#######################################
# CountryInfo
#######################################
# Download
net.downloadHttpFile(
    'https://download.geonames.org/export/dump/countryInfo.txt',
    './downloaded/geonames/countryInfo.txt',
    True
    )

# Count Nb comment lines
skiprows=0
with open ('./downloaded/geonames/countryInfo.txt', 'r') as tmpfile:
    for line in tmpfile.readlines():
        if re.match("^#.*", line): 
            skiprows+=1

# Export to sql
print('Export CountryInfo to sql')
df = pd.read_csv('./downloaded/geonames/countryInfo.txt', sep='\t', header = None, skiprows=skiprows, names=COUNTRY_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)

# Insert column at column 0 position
GEOID = df['GEOID']
df.drop(labels=['GEOID','countrypopulation'], axis=1,inplace = True)
df.insert(0, 'GEOID', GEOID)
df = df[df["GEOID"].notnull()]
df.to_csv('./downloaded/geonames/country.csv',index=False)

#######################################
# All countries
#######################################

# All countries
if not os.path.exists('./downloaded/geonames/allCountries.zip'):
    net.downloadHttpFile(
        'https://download.geonames.org/export/dump/allCountries.zip',
        './downloaded/geonames/allCountries.zip',
        True
    )

    print("Unzip All countries")
    with zipfile.ZipFile('./downloaded/geonames/allCountries.zip', 'r') as ziparchive:
        ziparchive.extractall('./downloaded/geonames/allCountries')

# Split files
filenames = glob.glob("./downloaded/geonames/allCountries/allCountries-*")
if len(filenames) == 0:
    print("split All countries files")
    file.splitFile('./downloaded/geonames/allCountries/allCountries.txt',100000)

print('Export All countries to sql')
filenames = glob.glob("./downloaded/geonames/allCountries/allCountries-*")
for filename in filenames:
    append=False
    if filename != filenames[0]:
        append=True

    df = pd.read_csv(filename, sep='\t', header = None, names=ALLCOUNTRIES_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
    df.drop(labels=['alternatenames'], axis=1,inplace = True)
    
    df.drop(['population'],axis=1,inplace=True)  
    #df['populationdensity'] = None
    #df['populationdate'] = None
    df['scope'] = None

    df = df[(df["featureclass"] == 'A') | (df["featureclass"] == 'P') | (df["featureclass"] == 'L' )]
    
    if append:
        df.to_csv('./downloaded/geonames/allcountries.csv',index=False,mode='a', header=False)
    else:
        df.to_csv('./downloaded/geonames/allcountries.csv',index=False)


#######################################
# Hierarchy
#######################################

if not os.path.exists('./downloaded/geonames/hierarchy/hierarchy.txt'):
    net.downloadHttpFile(
        'https://download.geonames.org/export/dump/hierarchy.zip',
        './downloaded/geonames/hierarchy.zip',
        True
    )    

    print("Unzip Hierarchy")
    with zipfile.ZipFile(f'./downloaded/geonames/hierarchy.zip', 'r') as ziparchive:
        ziparchive.extractall(f'./downloaded/geonames/hierarchy')

df = pd.read_csv('./downloaded/geonames/hierarchy/hierarchy.txt', sep='\t', header = None, names=HIERARCHY_COLUMNS,dtype=np.str,na_values=DEFAULT_MISSING)
df.to_csv('./downloaded/geonames/hierarchy.csv',index=False)
