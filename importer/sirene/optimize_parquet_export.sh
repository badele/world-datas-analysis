#!/usr/bin/env bash
# Optimize sirene raw section parquets: sort by (ape, name) for zone map pruning.
# Processed section by section to avoid OOM.

set -e

RAW_DIR="dataset/sirene/raw"
MEMORY_LIMIT="${DUCKDB_MEMORY:-4GB}"
TEMP_DIR="/tmp/duckdb_sirene_sort"

mkdir -p "$TEMP_DIR"

sections=$(find "$RAW_DIR" -mindepth 2 -name "data_0.parquet" \
    | sed 's|.*/section_id=||;s|/data_0.parquet||' | sort)

if [ -z "$sections" ]; then
    echo "[sirene] ERROR: no section files found in $RAW_DIR"
    exit 1
fi

total=$(echo "$sections" | wc -l | tr -d ' ')
i=0

echo "[sirene] Sorting ${total} raw section files by (ape, name)..."

for section in $sections; do
    i=$((i + 1))
    file="${RAW_DIR}/section_id=${section}/data_0.parquet"
    tmp_file="${TEMP_DIR}/section_id=${section}__sorted.parquet"

    nb=$(duckdb -csv -noheader -c \
        "SELECT COUNT(*) FROM read_parquet('${file}');" 2>/dev/null)

    echo "[sirene]   [${i}/${total}] section=${section} — ${nb} rows"

    duckdb -c "
SET memory_limit='${MEMORY_LIMIT}';
SET temp_directory='${TEMP_DIR}';
COPY (
    SELECT * FROM read_parquet('${file}')
    ORDER BY ape, name
) TO '${tmp_file}' (FORMAT PARQUET, ROW_GROUP_SIZE 50000, COMPRESSION zstd);
"
    mv "$tmp_file" "$file"
    echo "[sirene]     → $(du -sh "$file" | cut -f1)"
done

echo ""
echo "[sirene] Done."
