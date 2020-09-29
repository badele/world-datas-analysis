#!/usr/bin/python
import os
import sys

import argparse
import pandas as pd

# Add module path
sys.path.insert(0, os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../..")))

import lib.python.net as net

# Download datas from https://docs.google.com/spreadsheets/d/e/2PACX-1vQVtdpXMHB4g9h75a0jw8CsrqSuQmP5eMIB2adpKR5hkRggwMwzFy5kB-AIThodhVHNLxlZYm8fuoWj/pub?gid=59478853&single=true&output=csv

# https://docs.google.com/spreadsheets/d/e/2PACX-1vQVtdpXMHB4g9h75a0jw8CsrqSuQmP5eMIB2adpKR5hkRggwMwzFy5kB-AIThodhVHNLxlZYm8fuoWj/pub?gid=734724637&single=true&output=csv


SAISON=["Printemps", "Eté", "Automne", "Hiver"]
def getIdxSeason(date):
    # https://stackoverflow.com/a/24582617/2015612

    doy =  date.dayofyear

    is_leap = date.is_leap_year
    spring = range(80+int(is_leap), 172+int(is_leap))
    summer = range(172+int(is_leap), 264+int(is_leap))
    fall = range(264+int(is_leap), 355+int(is_leap))

    if doy in spring:
        season = 0
    elif doy in summer:
        season = 1
    elif doy in fall:
        season = 2
    else:
        season = 3

    return season


def getSeason(date):
    # https://stackoverflow.com/a/24582617/2015612

     return SAISON[getIdxSeason(date)]

TRANCHE = ["Nuit", "Matin", "Après-Midi","Soir"]
def getIdxTimeSlot(date):
    # https://stackoverflow.com/a/24582617/2015612

    hour =  date.hour

    night =range(0, 8)
    morning = range(8, 12)
    afternoom = range(12,18)

    if hour in night:
        idxslot = 0
    elif hour in morning:
        idxslot = 1
    elif hour in afternoom:
        idxslot = 2
    else:
        idxslot = 3

    return idxslot

def getTimeSlot(date):
    # https://stackoverflow.com/a/24582617/2015612

     return TRANCHE[getIdxTimeSlot(date)]

JOUR=["Lundi", "Mardi", "Mecredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
def getDayName(date):
    return JOUR[date.dayofweek]



def analyseTotemDatas(totemname, url):
    df = pd.read_csv(
        url,
    )


    # Rename column
    df = df.rename(columns={
        'Date': 'date',
        'Heure / Time': 'horaire',
        'Vélos depuis la mise en service / Grand total': 'comptage_cumul',
        "Vélos ce jour / Today's total": 'comptage_quotidien'
    })

    # Define datetime
    df["datetime"] = df['date'] + ' ' + df['horaire']
    df['datetime'] = pd.to_datetime(df['datetime'],format='%d/%m/%Y %H:%M:%S')

    # Filter and sort
    df = df[~df["comptage_cumul"].isnull()]
    df = df[~df['horaire'].str.match("00:00:00")]

    # Format cumul column
    df['methode']="Relevé"

    # Report midnight counter
    df['comptage_minuit'] = df["comptage_cumul"] - df["comptage_quotidien"]
    df['date_minuit'] = pd.to_datetime(df['datetime']).dt.floor('D').dt.strftime('%Y-%m-%d %H:%M:%S')
    midnight = df[["comptage_minuit","date_minuit"]].drop_duplicates()
    midnight['comptage_cumul'] = df['comptage_minuit']
    #midnight['comptage_quotidien'] = 0
    midnight['datetime'] = df['date_minuit']
    midnight['methode'] = "Reporté"
    df = df.append(midnight)

    # Reformat datetime
    df['datetime'] = pd.to_datetime(df['datetime'],format='%Y-%m-%d %H:%M:%S')

    # Resample
    df = df.resample('1H', on='datetime').last().drop('datetime', 1).reset_index()

    # Estimate value
    df['comptage_cumul'] = df['comptage_cumul'].interpolate(method='linear',order=2).round(0)
    df.loc[df['methode'].isnull(),'methode'] ="Estimé"
    df['comptage_minuit'] = df['comptage_minuit'].fillna(method='ffill')
    df['comptage_quotidien'] = df['comptage_cumul'] - df['comptage_minuit']

    # Complete column
    df['date'] = df['datetime'].dt.strftime('%Y-%m-%d')
    df['horaire'] = df['datetime'].dt.strftime('%H:%M:%S')
    df['annee'] = df['datetime'].dt.year
    df['mois'] = df['datetime'].dt.month
    df['jours'] = df['datetime'].dt.day
    df['heure'] = df['datetime'].dt.hour
    df['minute'] = df['datetime'].dt.minute
    df['jour_annee'] = df['datetime'].dt.dayofyear
    df['idx_semaine'] = df['datetime'].dt.week
    df['idx_jour'] = df['datetime'].dt.dayofweek
    df['jour_semaine'] = df['datetime'].apply(getDayName)
    df['idx_tranche'] = df['datetime'].apply(getIdxTimeSlot)
    df['tranche_horaire'] = df['datetime'].apply(getTimeSlot)
    df['idx_saison'] = df['datetime'].apply(getIdxSeason)
    df['saison'] = df['datetime'].apply(getSeason)


    # Sort
    df = df.sort_values(by=['datetime'])

    # Select column
    df = df[["date", "horaire", "annee", "mois", "jours", "heure", "minute", "jour_annee", "idx_semaine", "idx_jour",  "jour_semaine", "idx_tranche", "tranche_horaire", "idx_saison", "saison", "comptage_cumul", "comptage_quotidien", "methode"]]

    df.to_csv(
        f'cities/montpellier/totem/datas/{totemname}_downloaded.csv',
        index=False
    )

    return df

#######################################
# Download datas
#######################################
net.downloadHttpFile(
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vQVtdpXMHB4g9h75a0jw8CsrqSuQmP5eMIB2adpKR5hkRggwMwzFy5kB-AIThodhVHNLxlZYm8fuoWj/pub?gid=59478853&single=true&output=csv',
    '/tmp/totem_albert_1er.csv'
)


#######################################
# Load and export
#######################################
albert1er = analyseTotemDatas(
    'albert_1er',
    '/tmp/totem_albert_1er.csv'
)
