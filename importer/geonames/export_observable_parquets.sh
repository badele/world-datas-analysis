#!/usr/bin/env bash
# Generate observable parquets for geonames (countries + allentries + latlon cache).
# Output: dataset/geonames/observable/

set -e

RAW_DIR="./dataset/geonames/raw"
OBS_DIR="./dataset/geonames/observable"

mkdir -p "$OBS_DIR"

echo "[geonames] Copying geonames parquets to observable/..."

duckdb -c "
COPY (SELECT * FROM read_parquet('${RAW_DIR}/countries.parquet'))
  TO '${OBS_DIR}/countries.parquet' (FORMAT parquet, COMPRESSION zstd);
COPY (SELECT * FROM read_parquet('${RAW_DIR}/latlon_cache.parquet'))
  TO '${OBS_DIR}/latlon_cache.parquet' (FORMAT parquet, COMPRESSION zstd);
"

# allentries is partitioned by country_code — copy partition structure
if [ -d "${RAW_DIR}/allentries.parquet" ]; then
    echo "[geonames] Copying allentries partitions..."
    rm -rf "${OBS_DIR}/allentries.parquet"
    cp -r "${RAW_DIR}/allentries.parquet" "${OBS_DIR}/allentries.parquet"
fi

COUNT=$(find "$OBS_DIR" -name "*.parquet" | wc -l)
echo "[geonames] Done — ${COUNT} parquet files written to ${OBS_DIR}"
