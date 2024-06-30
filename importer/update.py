#!/usr/bin/env python3


import dr5hn  # cities, countries, regions, states, subregions
import duggytuxy  # blacklist_ips
import ipsum  # blacklist_ips
import opendata3m.eco_compteur  # eco_counter
import sapics  # asn_ipv4, city_ipv4, country_ipv4
import wda  # computed tables from previous datas


def update():
    # dr5hn.update()
    # sapics.update()
    #
    # duggytuxy.update()
    # ipsum.update()
    opendata3m.eco_compteur.update()
    # wda.update()


if __name__ == "__main__":
    update()
