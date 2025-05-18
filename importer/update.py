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


def update():
    # Map dataset names to their update functions
    update_functions = {
        "geonames": geonames.update,
        "nafrev2": nafrev2.update,
        "sirene": sirene.update,
        "vigilo": vigilo.update,
    }

    # Get the DATAS_LIST environment variable
    datasets_to_update = os.getenv("DATAS_LIST", "").split(",")

    # If DATAS_LIST is empty, use all keys from update_functions
    if not datasets_to_update or datasets_to_update == [""]:
        datasets_to_update = list(update_functions.keys())

    # Call the update function for each dataset in the list
    for dataset in datasets_to_update:
        dataset = dataset.strip()  # Remove any extra whitespace
        if dataset in update_functions:
            print(f"updateing {dataset}...")
            update_functions[dataset]()
        else:
            print(f"Warning: No update function found for '{dataset}'")


if __name__ == "__main__":
    update()
