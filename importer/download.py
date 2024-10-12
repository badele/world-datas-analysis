#!/usr/bin/env python3


import geonames

# import dr5hn  # cities, countries, regions, states, subregions
import duggytuxy  # blacklist_ips
import ipsum  # blacklist_ips
import opendata3m.ecocompteur  # ecocompteur
import sapics  # asn_ipv4, city_ipv4, country_ipv4
import vigilo  # Vigilo city
import wda  # computed tables from previous datas


def download():
    # references
    geonames.download()

    # dr5hn.update()
    # sapics.update()
    #
    # duggytuxy.update()
    # ipsum.update()
    # opendata3m.ecocompteur.update()
    vigilo.download()

    # World Datas Analysis
    # wda.update()


if __name__ == "__main__":
    download()
