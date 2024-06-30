#!/usr/bin/env python3

import wdalib

provider = "wda"
tables = {
    "wda": "./db/wda.duckdb",
}


def update():
    wdalib.export2CSV(provider, tables)
