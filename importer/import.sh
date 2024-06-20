#!/usr/bin/env bash

# Install requirements if not exists
./importer/requirements.sh

###############################################################################
# duckdb
###############################################################################

rm -f db/duckdb.db
duckdb db/duckdb.db <./importer/dr5hn/_import2db.sql # cities, countries, regions, states, subregions
# duckdb db/duckdb.db <./importer/sapics/_import.sql    # asn_ipv4, city_ipv4, country_ipv4
# duckdb db/duckdb.db <./importer/duggytuxy/_import.sql # blacklist_ips

###############################################################################
# Convert to sqlite
###############################################################################
rm -f db/world-datas-analysis.db
duckdb db/duckdb.db <./importer/dr5hn/_export2sqlite.sql
# duckdb db/duckdb.db <./importer/sapics/_to_sqlite.sql
# duckdb db/duckdb.db <./importer/duggytuxy/_to_sqlite.sql
