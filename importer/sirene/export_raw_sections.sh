#!/usr/bin/env bash
# Export sirene raw section parquets from db/wda.duckdb (view v_sirene_export).
# Processes one section at a time (~600k rows each) to avoid OOM on the full 14M rows.
# Called from __init__.py after _data2duckdb.sql.

set -e

DB="db/wda.duckdb"
RAW_DIR="dataset/sirene/raw"
MEMORY_LIMIT="${DUCKDB_MEMORY:-4GB}"
TEMP_DIR="/tmp/duckdb_sirene_export"

mkdir -p "$TEMP_DIR"

if [ ! -f "$DB" ]; then
    echo "[sirene-export] ERROR: database $DB not found"
    exit 1
fi

# List of all section IDs
SECTIONS="A B C D E F G H I J K L M N O P Q R S T U"
total=$(echo "$SECTIONS" | wc -w | tr -d ' ')
i=0

echo "[sirene-export] Exporting ${total} sections from ${DB}..."

for section in $SECTIONS; do
    i=$((i + 1))
    out_dir="${RAW_DIR}/section_id=${section}"
    mkdir -p "$out_dir"

    echo "[sirene-export] [${i}/${total}] section=${section}..."

    duckdb "$DB" "
SET memory_limit='${MEMORY_LIMIT}';
SET temp_directory='${TEMP_DIR}';
COPY (
    SELECT * FROM v_sirene_export
    WHERE section_id = '${section}'
) TO '${out_dir}/data_0.parquet'
(FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 50000);
"
    nb=$(duckdb -csv -noheader "$DB" \
        "SELECT COUNT(*) FROM read_parquet('${out_dir}/data_0.parquet');" 2>/dev/null)
    echo "[sirene-export]   → ${nb} rows, $(du -sh "${out_dir}/data_0.parquet" | cut -f1)"
done

echo ""
echo "[sirene-export] Done — ${total} sections exported."
