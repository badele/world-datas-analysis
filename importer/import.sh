#!/usr/bin/env bash

# Install requirements if not exists
./importer/requirements.sh

datasets="dr5hn sapics duggytuxy wda"

###############################################################################
# duckdb
###############################################################################

# Init database
rm -f db/wda.duckdb
duckdb db/wda.duckdb <./importer/init_duckdb.sql

for dataset in $datasets; do
	if [ -f "./importer/$dataset/_import2db.sql" ]; then
		echo "Importing $dataset datasets to duckdb"
		duckdb db/wda.duckdb <"./importer/$dataset/_import2db.sql"
	fi
done
# duckdb db/wda.duckdb <./importer/dr5hn/_import2db.sql  # cities, countries, regions, states, subregions
# duckdb db/wda.duckdb <./importer/sapics/_import2db.sql # asn_ipv4, city_ipv4, country_ipv4
# # duckdb db/wda.duckdb <./importer/duggytuxy/_import2db.sql # blacklist_ips
# duckdb db/wda.duckdb <./importer/wda/_import2db.sql # blacklist_ips

###############################################################################
# Convert to sqlite
###############################################################################
rm -f db/wda.sqlite
duckdb db/wda.duckdb <./importer/init_sqlite.sql
for dataset in $datasets; do
	if [ -f "./importer/$dataset/_export2sqlite.sql" ]; then
		echo "Export $dataset datasets to sqlite"
		duckdb db/wda.duckdb <./importer/$dataset/_export2sqlite.sql
	fi
done
# duckdb db/wda.duckdb <./importer/dr5hn/_export2sqlite.sql
# duckdb db/wda.duckdb <./importer/sapics/_export2sqlite.sql
# # duckdb db/wda.duckdb <./importer/duggytuxy/_export2sqlite.sql
# # duckdb db/wda.duckdb <./importer/wda/_export2sqlite.sql
