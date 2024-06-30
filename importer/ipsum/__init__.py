#!/usr/bin/env python3

import wdalib
import shutil

provider = "ipsum"
repo_url = "https://github.com/stamparm/ipsum.git"
tables = {
    "blacklist_ips": f"./downloaded/{provider}/ipsum.txt",
}


def update():
    shutil.rmtree(f"./downloaded/{provider}", ignore_errors=True)
    wdalib.pull(provider, repo_url)
    wdalib.export2CSV(provider, tables)
