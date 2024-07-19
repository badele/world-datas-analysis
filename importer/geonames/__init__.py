#!/usr/bin/env python3
# -*- coding: utf-8 -*

import wdalib

provider = "geonames"
repo_url = "https://download.geonames.org/export"


def update_admin1codes():
    wdalib.downloadFile(
        f"{repo_url}/dump/admin1CodesASCII.txt",
        "admin1CodesASCII",
        f"./downloaded/{provider}/admin1CodesASCII.txt",
    )


def update_admin2codes():
    wdalib.downloadFile(
        f"{repo_url}/dump/admin2Codes.txt",
        "admin2Codes",
        f"./downloaded/{provider}/admin2Codes.txt",
    )


def update_countries():
    wdalib.downloadFile(
        f"{repo_url}/dump/countryInfo.txt",
        "countryInfo",
        f"./downloaded/{provider}/countryInfo.txt",
    )


def update_allentries():
    wdalib.downloadFile(
        f"{repo_url}/dump/allCountries.zip",
        "allCountries",
        f"./downloaded/{provider}/allCountries.zip",
    )
    print("=== Uncompressing allCountries.zip ===")
    wdalib.unzipFile(
        f"./downloaded/{provider}/allCountries.zip",
        f"./downloaded/{provider}",
    )


# def update_categories():
#     resp = requests.get("https://vigilo-bf7f2.firebaseio.com/categorieslist.json")
#
#     if resp.status_code != 200:
#         return ""
#
#     wdalib.writeContentToFile(f"./downloaded/{provider}/categories.json", resp.text)
#
#
# def update_scopes():
#     citiesresp = requests.get("https://vigilo-bf7f2.firebaseio.com/citylist.json")
#     if citiesresp.status_code != 200:
#         return ""
#
#     citiesresult = citiesresp.json()
#
#     scopes = []
#     instances = []
#     for name, value in citiesresult.items():
#         try:
#             if not value["prod"]:
#                 continue
#
#             value["name"] = name
#
#             scope = value["scope"]
#             api_path = value["api_path"]
#
#             # Get scope informations
#             scoperesp = requests.get(f"{api_path}/get_scope.php?scope={scope}")
#             if scoperesp.status_code != 200:
#                 return ""
#
#             # Merge with scope informations
#             scoperesult = scoperesp.json()
#             value = value | scoperesult
#
#             del value["cities"]
#             del value["prod"]
#
#             scopes.append(value)
#
#             # Cities informations
#             for city in scoperesult["cities"]:
#                 city["scope"] = scope
#                 instances.append(city)
#
#             update_observations(scope, name, api_path)
#
#         except requests.exceptions.SSLError:
#             print(f"!!! Bad SSL certificate for {name} ({scope}) !!!")
#         except requests.exceptions.ConnectionError:
#             print(f"!!! Connection error for {name} ({scope}) !!!")
#         except requests.exceptions.HTTPError:
#             print(f"!!! HTTP error for {name} ({scope}) !!!")
#
#     wdalib.writeContentToFile(
#         f"./downloaded/{provider}/scopes.json", json.dumps(scopes)
#     )
#
#     wdalib.writeContentToFile(
#         f"./downloaded/{provider}/instances.json", json.dumps(instances)
#     )
#
#
# def update_observations(scope, name, api_path):
#     wdalib.downloadFile(
#         f"{api_path}/get_issues.php?scope={scope}&format=json",
#         name,
#         f"./downloaded/{provider}/observations_{scope}.json",
#     )


def update():
    # wdalib.init_download_provider(provider)
    # wdalib.init_dataset_provider(provider)
    # wdalib.show_title(f"Update {provider}")
    #
    update_admin1codes()
    update_admin2codes()
    update_countries()
    update_allentries()

    wdalib.export2CSV(provider)
