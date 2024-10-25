#!/usr/bin/env python3

import wdalib

provider = "duggytuxy"
repo_url = "https://github.com/duggytuxy/malicious_ip_addresses.git"
tables = {
    "blacklist_ips": f"./downloaded/{provider}/blacklist_ips_for_fortinet_firewall_*.txt",
}


def update():
    wdalib.pull(provider, repo_url)
    wdalib.export2CSV(provider, tables)
