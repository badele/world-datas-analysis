#!/usr/bin/env python3
# -*- coding: utf-8 -*

# https://sirene.fr/static-resources/htm/v_sommaire_311.htm
# https://www.insee.fr/fr/statistiques/fichier/2406147/Nomenclatures_NAF_et_CPF_Reedition_2020.pdf

import wdalib

PROVIDER = "sirene"
FILES = {
    "sirene_unite_legale": {
        "url": "https://files.data.gouv.fr/insee-sirene/StockUniteLegale_utf8.zip",
    },
    "sirene_etablissement": {
        "url": "https://files.data.gouv.fr/insee-sirene/StockEtablissement_utf8.zip",
    },
    "sirene_etablissement_geoloc": {
        "url": "https://files.data.gouv.fr/insee-sirene-geo/GeolocalisationEtablissement_Sirene_pour_etudes_statistiques_utf8.zip",
    },
    "sirene_nafrev2": {
        "url": "https://static.data.gouv.fr/resources/nomenclature-dactivites-francaise-naf/20190206-152239/naf2008-liste-n4-classes.csv",
        "output_file": "NAFRev2.csv",
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


def download_file_and_unzip(file_key):
    """
    Downloads and unzips a file based on the given key.
    """
    output_file, filename = download_file(file_key)

    print(f"=== Uncompressing {output_file} ===")
    wdalib.unzipFile(filename, f"./downloaded/{PROVIDER}")


def download():
    """
    Downloads all required files if the folder is outdated.
    """
    if not wdalib.isFolderOutdated(f"./downloaded/{PROVIDER}", 7 * 24):
        return

    wdalib.init_download(PROVIDER)
    wdalib.show_title(f"Download {PROVIDER}")

    download_file("sirene_nafrev2")
    download_file_and_unzip("sirene_unite_legale")
    download_file_and_unzip("sirene_etablissement")
    download_file_and_unzip("sirene_etablissement_geoloc")


def update():
    """
    Updates the dataset for the provider.
    """
    wdalib.init_dataset(PROVIDER)
    wdalib.data2duckdb(PROVIDER)
