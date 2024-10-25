#!/usr/bin/env bash

set -x

# TODO automate this
datasets="dr5hn sapics duggytuxy vigilo wda"
datasets="geonames vigilo opendata3m wda"
datasets="geonames vigilo"

###############################################################################
# Import to postgresql
###############################################################################

HOST="127.0.0.1"
PORT="5432"
while ! nc -zv "$HOST" "$PORT" 2>/dev/null; do
	echo "Waiting for postgresql availability"
	sleep 5
done

for dataset in $datasets; do
	PGPASSWORD=wda psql -h "$HOST" -U wda -d wda -f "./importer/init_commons.sql"
	if [ -f "./importer/$dataset/_export2psql.sql" ]; then
		echo "===================================================================="
		echo "Export $dataset datasets to postgresql database"
		echo "===================================================================="
		PGPASSWORD=wda psql -h "$HOST" -U wda -d wda -f "./importer/$dataset/_export2psql.sql"
	fi
done
