#!/usr/bin/env bash

set -e

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

echo ""
echo "===================================================================="
echo " START IMPORT "
echo "===================================================================="
echo ""

PGPASSWORD=wda psql -v ON_ERROR_STOP=1 -h "$HOST" -U wda -d wda -f "./importer/init_commons.sql"
for dataset in $datasets; do
    echo "[import] Initializing common tables for '$dataset'"
    if [ -f "./importer/$dataset/_export2psql.sql" ]; then

        echo ""
        echo "===================================================================="
        echo "[import] Export $dataset datasets to PostgreSQL database"
        echo "===================================================================="
        echo ""

        PGPASSWORD=wda psql -v ON_ERROR_STOP=1 -h "$HOST" -U wda -d wda -f "./importer/$dataset/_export2psql.sql"
    else
        echo "[import] Warning: no PostgreSQL export script found for '$dataset'"
    fi

    if [ -f "./importer/$dataset/export_etabs_json.sh" ]; then
        echo ""
        echo "===================================================================="
        echo "[import] Pre-generating static JSON files for '$dataset'"
        echo "===================================================================="
        echo ""
        bash "./importer/$dataset/export_etabs_json.sh"
    fi
done
