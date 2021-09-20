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

NB_ZIP_FILE = 0

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

def download_country_datas(geoid, iso3):
    global NB_ZIP_FILE

    zipfilename = f'/tmp/worldbank_{iso3}.zip'
    if not os.path.exists(zipfilename):
        net.downloadHttpFile(
            f'https://api.worldbank.org/v2/en/country/{iso3}?downloadformat=csv',
            zipfilename,
            f'Download worldbank {iso3} country'
        )

    if zipfile.is_zipfile(zipfilename):
        with zipfile.ZipFile(zipfilename, 'r') as ziparchive:
            ziparchive.extractall('/tmp/worldbank')
        NB_ZIP_FILE += 1

        #######################################
        # Indicator
        #######################################
        if NB_ZIP_FILE<=1:
            indicfilename = glob.glob('/tmp/worldbank/Metadata_Indicator_API_*.csv') 
            if len(indicfilename)>0:
                df = pd.read_csv(indicfilename[0])
                df.columns = df.columns.str.replace(" ", "")
                # Drop last column
                df.drop(df.columns[len(df.columns)-1], axis=1, inplace=True)

                # Split indicators
                # indics = df['INDICATOR_CODE'].str.split('.',expand=True)
                # df['category'] = indics[0]
                # for i in range(len(indics.columns)): 
                #     indicatorname = f'indic{i+1}'
                #     df[indicatorname] = indics[i]

                df.to_sql('x_downloaded_worldbank_indicator',conn, if_exists='replace',index=False)

        #######################################
        # Country
        #######################################
        print(f'Export {iso3} to sql')
        datafilename = glob.glob(f'/tmp/worldbank/API_{iso3}_DS2_en_csv_v2_*.csv') 
        if len(datafilename)>0:
            df = pd.read_csv(datafilename[0], sep=',', skiprows=4, na_values=DEFAULT_MISSING)
            df.columns = df.columns.str.replace(" ", "")
            df.drop(df.columns[len(df.columns)-1], axis=1, inplace=True)
            df.drop(['CountryName'],axis=1, inplace=True)
            df.drop(['IndicatorName'],axis=1, inplace=True)

            # Split indicators
            # indics = df['IndicatorCode'].str.split('.',expand=True)
            # vars = ['CountryCode','IndicatorCode']
            # df['category'] = indics[0]
           
            # for i in range(len(indics.columns)): 
            #     indicatorname = f'indic{i+1}'
            #     df[indicatorname] = indics[i]
            #     vars.append(indicatorname)

            df = pd.melt(df, id_vars=['CountryCode','IndicatorCode'], var_name='year', value_name='value')
            df['year'] = df['year'].astype('int32')
            df = df[ df['value'].notna() ]
            #df['year_decade'] = pd.to_numeric(df['year']) - (pd.to_numeric(df['year']) % 10)

            df = df.loc[df['IndicatorCode'] == 'EN.ATM.NOXE.EG.ZS']
            df.to_csv('/tmp/result.csv')
            print(df)

            import statsmodels.formula.api as sm
            #df = pd.DataFrame({'x':x, 'y':y})
            model = sm.ols('value~year', data=df).fit( )
            print(dir(model))
            
            print(model.summary( ))
            print(model.params)

            sys.exit()


            test = df.groupby(['CountryCode','IndicatorCode']).apply(lambda x: pd.Series({ 
    "yearvalue": sum(x["year"]*x["value"]), 
    "valuesum": x["value"].sum(),
    "usermean": sum(x["year"]*x["value"])/x["value"].sum(),
    "mean": x["value"].mean(),
    "var": x["value"].var()

}))


            print(test)
            sys.exit() 

            gr = df.groupby(['CountryCode','IndicatorCode']).agg(year_first=('year',np.min),year_last=('year',np.max),value_first=('value',lambda x: list(x)[0]),value_last=('value',lambda x: list(x)[-1]),stat=('value',np.corrcoef))


            gr.to_sql('xxx_test',conn, if_exists='replace',index=True)

            mode="append"
            if NB_ZIP_FILE<=1:
                mode="replace"
            
            df.to_sql('x_downloaded_worldbank_country',conn, if_exists=mode,index=False)


#########################################
# Get country and download worldbank data
#########################################



conn = sql.connect('world-datas-analysis.db')

# orig = pd.read_sql('select * from worldbank_country', conn)
# print(orig)

# df = orig.copy()
# gr = df.groupby(['CountryCode','IndicatorCode','category']).agg(year_first=('year',np.min),year_last=('year',np.max),value_first=('value',lambda x: list(x)[0]),value_last=('value',lambda x: list(x)[-1]))

# gr.to_sql('test',conn,if_exists='replace')
# #print(gr)
# sys.exit()


df = pd.read_sql('SELECT geoid,iso3 from v_geonames_country', conn)
for index, row in df.iterrows():
    download_country_datas(row['GEOID'], row['iso3'])
    sys.exit()