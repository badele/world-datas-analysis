#!/usr/bin/env python3
# -*- coding: utf-8 -*

import requests
import json

import wdalib

provider = "vigilo"


def update_categories():
    filename = f"./downloaded/{provider}/categories.json"

    resp = requests.get("https://vigilo-bf7f2.firebaseio.com/categorieslist.json")
    if resp.status_code != 200:
        return ""

    wdalib.writeContentToFile(filename, resp.text)


def update_scopes():
    citiesresp = requests.get("https://vigilo-bf7f2.firebaseio.com/citylist.json")
    if citiesresp.status_code != 200:
        return ""

    citiesresult = citiesresp.json()

    scopes = []
    instances = []

    scopefilename = f"./downloaded/{provider}/scopes.json"
    instancesfilename = f"./downloaded/{provider}/instances.json"

    # Download
    for name, value in citiesresult.items():
        try:
            if not value["prod"]:
                continue

            value["name"] = name

            scope = value["scope"]
            api_path = value["api_path"]

            # Get scope informations
            scoperesp = requests.get(f"{api_path}/get_scope.php?scope={scope}")
            if scoperesp.status_code != 200:
                continue

            # Merge with scope informations
            scoperesult = scoperesp.json()
            value = value | scoperesult

            del value["cities"]
            del value["prod"]

            scopes.append(value)

            # Cities informations
            for city in scoperesult["cities"]:
                city["scope"] = scope
                instances.append(city)

            update_observations(scope, name, api_path)

        except requests.exceptions.SSLError:
            print(f"!!! Bad SSL certificate for {name} ({scope}) !!!")
        except requests.exceptions.ConnectionError:
            print(f"!!! Connection error for {name} ({scope}) !!!")
        except requests.exceptions.HTTPError:
            print(f"!!! HTTP error for {name} ({scope}) !!!")

    wdalib.writeContentToFile(scopefilename, json.dumps(scopes))
    wdalib.writeContentToFile(instancesfilename, json.dumps(instances))


def update_observations(scope, name, api_path):
    filename = f"./downloaded/{provider}/observations_{scope}.json"

    wdalib.downloadFile(
        f"{api_path}/get_issues.php?scope={scope}&format=json",
        name,
        filename,
    )


def update():
    if not wdalib.isFolderOutdated(f"./dataset/{provider}", 7 * 24):
        return

    wdalib.init_provider(provider)
    wdalib.show_title(f"Update {provider}")

    update_categories()
    update_scopes()

    wdalib.export2CSV(provider)
