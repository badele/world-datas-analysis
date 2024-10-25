#!/usr/bin/env python3
# -*- coding: utf-8 -*

import sys
import wdalib

provider = "geonames"
repo_url = "https://download.geonames.org/export"


def download_countries():
    filename = f"./downloaded/{provider}/countryInfo.txt"

    wdalib.downloadFile(
        f"{repo_url}/dump/countryInfo.txt",
        "countryInfo",
        filename,
    )


def download_allentries():
    filename = f"./downloaded/{provider}/allCountries.zip"

    wdalib.downloadFile(
        f"{repo_url}/dump/allCountries.zip",
        "allCountries",
        filename,
    )

    print("=== Uncompressing allCountries.zip ===")
    wdalib.unzipFile(
        filename,
        f"./downloaded/{provider}",
    )


def download():
    if not wdalib.isFolderOutdated(f"./downloaded/{provider}", 7 * 24):
        return

    wdalib.init_download(provider)
    wdalib.show_title(f"Download {provider}")

    download_countries()
    download_allentries()


def update():
    wdalib.init_dataset(provider)

    wdalib.data2duckdb(provider)
