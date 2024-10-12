#!/usr/bin/env bash

# TODO automate this
datasets="dr5hn sapics duggytuxy vigilo wda"
datasets="geonames vigilo opendata3m wda"
datasets="geonames vigilo"

###############################################################################
# Import to postgresql
###############################################################################
for dataset in $datasets; do
	PGPASSWORD=wda psql -h 127.0.0.1 -U wda -d wda -f "./importer/init_commons.sql"
	if [ -f "./importer/$dataset/_export2psql.sql" ]; then
		echo "===================================================================="
		echo "Export $dataset datasets to postgresql database"
		echo "===================================================================="
		PGPASSWORD=wda psql -h 127.0.0.1 -U wda -d wda -f "./importer/$dataset/_export2psql.sql"
	fi
done
