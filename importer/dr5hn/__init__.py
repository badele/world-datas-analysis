#!/usr/bin/env python3

import wdalib

provider = "dr5hn"
repo_url = "https://github.com/dr5hn/countries-states-cities-database.git"
tables = {
    "regions": f"./downloaded/{provider}/regions.json",
    "subregions": f"./downloaded/{provider}/subregions.json",
    "states": f"./downloaded/{provider}/states.json",
    "countries": f"./downloaded/{provider}/countries.json",
    "cities": f"./downloaded/{provider}/cities.json",
}


def update():
    wdalib.pull(provider, repo_url)
    wdalib.export2CSV(provider, tables)
