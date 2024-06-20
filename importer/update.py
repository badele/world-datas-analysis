#!/usr/bin/env python3


import dr5hn  # cities, countries, regions, states, subregions
import sapics  # asn_ipv4, city_ipv4, country_ipv4
import duggytuxy  # blacklist_ips


def update():
    dr5hn.update()
    sapics.update()
    duggytuxy.update()


if __name__ == "__main__":
    update()
