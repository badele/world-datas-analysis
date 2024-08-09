#!/usr/bin/env python3
# -*- coding: utf-8 -*

import sys
import wdalib

provider = "geonames"
repo_url = "https://download.geonames.org/export"


def update_admin1codes():
    filename = f"./downloaded/{provider}/admin1CodesASCII.txt"

    wdalib.downloadFile(
        f"{repo_url}/dump/admin1CodesASCII.txt",
        "admin1CodesASCII",
        filename,
    )


def update_admin2codes():
    filename = f"./downloaded/{provider}/admin2Codes.txt"

    wdalib.downloadFile(
        f"{repo_url}/dump/admin2Codes.txt",
        "admin2Codes",
        filename,
    )


def update_countries():
    filename = f"./downloaded/{provider}/countryInfo.txt"

    wdalib.downloadFile(
        f"{repo_url}/dump/countryInfo.txt",
        "countryInfo",
        filename,
    )


def update_allentries():
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


def update():
    if not wdalib.isFolderOutdated(f"./dataset/{provider}", 7 * 24):
        return

    wdalib.init_provider(provider)
    wdalib.show_title(f"Update {provider}")

    update_admin1codes()
    update_admin2codes()
    update_countries()
    update_allentries()

    wdalib.export2CSV(provider)
