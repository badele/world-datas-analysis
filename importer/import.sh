#!/usr/bin/env bash

set -ex

# TODO automate this
datasets=${DATAS_LIST:-""}
datasets=${datasets//,/ }

echo "[import] Datasets: ${datasets:-none}"

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
    echo "[import] Initializing common tables for '$dataset'"
    PGPASSWORD=wda psql -v ON_ERROR_STOP=1 -h "$HOST" -U wda -d wda -f "./importer/init_commons.sql"
	if [ -f "./importer/$dataset/_export2psql.sql" ]; then
		echo "===================================================================="
		echo "[import] Export $dataset datasets to PostgreSQL database"
		echo "===================================================================="
		PGPASSWORD=wda psql -v ON_ERROR_STOP=1 -h "$HOST" -U wda -d wda -f "./importer/$dataset/_export2psql.sql"
	else
		echo "[import] Warning: no PostgreSQL export script found for '$dataset'"
	fi
done
