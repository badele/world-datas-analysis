#!/usr/bin/env python3

import wdalib

provider = "sapics"
repo_url = "https://github.com/sapics/ip-location-db.git"
tables = {
    "asn": "./downloaded/sapics/geolite2-asn-ipv4.csv",
    "countries": "./downloaded/sapics/geolite2-country-ipv4.csv",
    "cities": "./downloaded/sapics/geolite2-city-ipv4.csv.gz",
}


def update():
    wdalib.pull(provider, repo_url)
    wdalib.export2CSV(provider, tables)
