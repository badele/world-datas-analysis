#!/usr/bin/env python3
# -*- coding: utf-8 -*

import wdalib

PROVIDER = "geonames"
REPO_URL = "https://download.geonames.org/export"


def download_countries():
    """Downloads the GeoNames country info file."""
    filename = f"./downloaded/{PROVIDER}/countryInfo.txt"
    wdalib.downloadFile(
        f"{REPO_URL}/dump/countryInfo.txt",
        "countryInfo",
        filename,
    )


def download_allentries():
    """Downloads and unzips the GeoNames allCountries archive."""
    filename = f"./downloaded/{PROVIDER}/allCountries.zip"
    wdalib.downloadFile(
        f"{REPO_URL}/dump/allCountries.zip",
        "allCountries",
        filename,
    )

    print("=== Uncompressing allCountries.zip ===")
    wdalib.unzipFile(
        filename,
        f"./downloaded/{PROVIDER}",
    )


def download():
    """Downloads all required files if the folder is outdated."""
    if not wdalib.isFolderOutdated(f"./downloaded/{PROVIDER}", 7 * 24):
        return

    wdalib.init_download(PROVIDER)
    wdalib.show_title(f"Download {PROVIDER}")

    download_countries()
    download_allentries()


def update():
    """Updates the dataset for the provider."""
    wdalib.init_dataset(PROVIDER)
    wdalib.data2duckdb(PROVIDER)
