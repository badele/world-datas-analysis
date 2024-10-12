#!/usr/bin/env python3

import wdalib

provider = "wda"


def update():
    wdalib.init_provider(provider)
    wdalib.show_title(f"Update {provider}")

    wdalib.data2duckdb(provider)
