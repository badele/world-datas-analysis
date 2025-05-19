#!/usr/bin/env python3

import os

import geonames

# import dr5hn  # cities, countries, regions, states, subregions
import duggytuxy  # blacklist_ips
import ipsum  # blacklist_ips
import nafrev2  # NAFRev2
import opendata3m.ecocompteur  # ecocompteur
import sapics  # asn_ipv4, city_ipv4, country_ipv4
import sirene  # SIRENE
import vigilo  # Vigilo city
import wda  # computed tables from previous datas


def download():
    # Map dataset names to their download functions
    download_functions = {
        "geonames": geonames.download,
        "nafrev2": nafrev2.download,
        "sirene": sirene.download,
        "vigilo": vigilo.download,
    }

    # Get the DATAS_LIST environment variable
    datasets_to_download = os.getenv("DATAS_LIST", "").split(",")

    # If DATAS_LIST is empty, use all keys from download_functions
    if not datasets_to_download or datasets_to_download == [""]:
        datasets_to_download = list(download_functions.keys())

    # Call the download function for each dataset in the list
    for dataset in datasets_to_download:
        dataset = dataset.strip()  # Remove any extra whitespace
        if dataset in download_functions:
            print(f"Downloading {dataset}...")
            download_functions[dataset]()
        else:
            print(f"Warning: No download function found for '{dataset}'")


if __name__ == "__main__":
    download()
