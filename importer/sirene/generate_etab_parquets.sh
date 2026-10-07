#!/usr/bin/env bash
# Generate etab prefix parquets from APE parquets.
# Processes one starting-letter at a time + SET threads=1 to force one file per partition.
set -euo pipefail

DATASET_DIR="./dataset/sirene/observable"
OUT_DIR="${DATASET_DIR}/etab"
mkdir -p "$OUT_DIR" /tmp/duckdb_etab

LETTERS=(
  "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m"
  "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"
  "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
)

echo "=== Generating etab prefix parquets (${#LETTERS[@]} groups) ==="

run_letter() {
  local filter="$1"
  duckdb -c "
    SET temp_directory='/tmp/duckdb_etab';
    SET threads=1;
    COPY (
        SELECT
            siret,
            name,
            legal_name,
            adresse,
            nb_effectifs_min,
            is_siege,
            date_creation,
            dept,
            latitude,
            longitude,
            regexp_extract(filename, 'ape=([^/\\\\]+)[/\\\\]', 1) AS ape,
            LEFT(LOWER(TRIM(COALESCE(name, ''))), 2) AS pfx
        FROM read_parquet('${DATASET_DIR}/ape=*/data_0.parquet',
                          hive_partitioning=false,
                          filename=true)
        WHERE latitude IS NOT NULL
          AND longitude IS NOT NULL
          AND ${filter}
    ) TO '${OUT_DIR}/'
    (FORMAT PARQUET, PARTITION_BY (pfx), OVERWRITE_OR_IGNORE true);
  " 2>/dev/null || true
}

for letter in "${LETTERS[@]}"; do
  printf "  processing '%s'…\r" "$letter"
  run_letter "LEFT(LOWER(TRIM(COALESCE(name, ''))), 1) = '${letter}'"
done

# Accented letters and other special starting chars
printf "  processing 'other'…\r"
run_letter "NOT regexp_matches(LOWER(TRIM(COALESCE(name, ''))), '^[a-z0-9].*')"

echo ""
echo "=== Done: $(ls ${OUT_DIR}/ | wc -l) prefix groups generated ==="
