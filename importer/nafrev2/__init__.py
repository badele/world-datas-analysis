#!/usr/bin/env python3
# -*- coding: utf-8 -*

# https://www.data.gouv.fr/fr/datasets/nomenclature-dactivites-francaise-naf/#/community-resources
# https://static.data.gouv.fr/resources/nomenclature-dactivites-francaise-naf/20200217-090550/naf2008-listes-completes-5-niveaux.csv

import wdalib

PROVIDER = "nafrev2"
FILES = {
    "nafrev2_alllevels": {
        "url": "https://static.data.gouv.fr/resources/nomenclature-dactivites-francaise-naf/20200217-090550/naf2008-listes-completes-5-niveaux.csv",
    },
}


def download_file(file_key):
    """
    Downloads a file based on the given key.
    """
    file_info = FILES[file_key]
    if "output_file" in file_info:
        output_file = file_info["output_file"]
    else:
        output_file = file_info["url"].split("/")[-1]
    filename = f"./downloaded/{PROVIDER}/{output_file}"
    url = file_info["url"]
    wdalib.downloadFile(url, file_key, filename)
    print(f"=== Downloaded {output_file} ===")

    return output_file, filename


def download():
    """
    Downloads all required files if the folder is outdated.
    """
    if not wdalib.isFolderOutdated(f"./downloaded/{PROVIDER}", 7 * 24):
        return

    wdalib.init_download(PROVIDER)
    wdalib.show_title(f"Download {PROVIDER}")

    download_file("nafrev2_alllevels")


def update():
    """
    Updates the dataset for the provider.
    """
    wdalib.init_dataset(PROVIDER)
    wdalib.data2duckdb(PROVIDER)
