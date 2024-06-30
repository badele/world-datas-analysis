#!/usr/bin/env python3
# -*- coding: utf-8 -*

import requests
import os
import shutil

from json_repair import repair_json

import wdalib

provider = "opendata3m/eco_compteur"
repo_url = "https://data.montpellier3m.fr/dataset/comptages-velo-et-pieton-issus-des-compteurs-de-velo"


# Get counters list
def get_counters_list():
    # delete and recreate the downloaded folder
    shutil.rmtree(f"./downloaded/{provider}", ignore_errors=True)
    os.makedirs(f"./downloaded/{provider}", exist_ok=True)

    # Download counters
    resp = requests.get(
        "https://data.montpellier3m.fr/sites/default/files/ressources/MMM_MMM_GeolocCompteurs.csv"
    )

    if resp.status_code != 200:
        return ""

    resp.encoding = resp.apparent_encoding
    return resp.text.split("\r\n")


def update_counter_list():
    os.makedirs(f"./downloaded/{provider}", exist_ok=True)

    srccounters = get_counters_list()

    dstcounters = ["name|serie|lat|lon|osm_id|city|democraty_district|district"]

    for counter in srccounters:
        try:
            if "Nom du com" in counter:
                continue

            name, serie, serie1, lat, lon, osm_id = counter.split(",")
            city = overpass_request(lat, lon, 8)
            democraty_district = overpass_request(lat, lon, 10)
            district = overpass_request(lat, lon, 11)

            dstcounters.append(
                f"{name}|{serie}|{lat}|{lon}|{osm_id}|{city}|{democraty_district}|{district}"
            )
        except ValueError:
            pass

    wdalib.writeList(f"./downloaded/{provider}/counters_list.csv", dstcounters)

    return dstcounters


def update_counters_values(counters):
    # Get values from counters

    for counter in counters:
        (
            name,
            serie,
            lat,
            lon,
            osm_id,
            city,
            democraty_district,
            district,
        ) = counter.split("|")
        print(name, serie)
        resp = requests.get(
            f"https://data.montpellier3m.fr/sites/default/files/ressources/MMM_EcoCompt_{serie}_archive.json"
        )
        if resp.status_code != 200:
            continue

        content = repair_json(resp.text)
        wdalib.writeContentToFile(f"./downloaded/{provider}/{serie}.json", content)


# Get information from latitute and longitude
def overpass_request(lat, long, level):
    req = f"[out:json]; is_in({lat},{long}); area._[admin_level={level}];out body;"
    resp = requests.get(f"https://overpass-api.de/api/interpreter?data={req}")
    result = resp.json()

    try:
        value = result.get("elements", [{}])[0].get("tags", {}).get("name", "")
        return value
    except IndexError:
        return ""


def update():
    # dstcounters = update_counter_list()
    # # dstcounters = wdalib.readList(f"./downloaded/{provider}/counters_list.csv")
    #
    # dstcounters.pop(0)
    # update_counters_values(dstcounters)
    #
    wdalib.export2CSV(provider)
