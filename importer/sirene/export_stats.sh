#!/usr/bin/env bash
# Export sirene:
#   1. Slim parquets for Observable map → dataset/sirene/observable/ape=*/data_0.parquet
#      Fields: siret, name, legal_name, adresse, nb_effectifs_min, is_siege, date_creation, dept, lat, lon
#      One file per APE code — browser loads only the selected APE(s), not a full section
#   2. Aggregate stats parquets → dataset/sirene/observable/{funnel,stats-by-*,top-codes-ape}.parquet
#      Read from full raw parquets (all columns needed for hierarchy stats)
# Called from __init__.py after export_raw_sections.sh.

set -e

FULL_DIR="dataset/sirene/raw"
OBS_DIR="dataset/sirene/observable"
NAF_DIR="dataset/nafrev2/raw"
MEMORY_LIMIT="${DUCKDB_MEMORY:-4GB}"
TEMP_DIR="/tmp/duckdb_sirene_stats"

mkdir -p "$TEMP_DIR" "$OBS_DIR"

FULL_ETS="${FULL_DIR}/section_id=*/data_0.parquet"

if ! ls ${FULL_DIR}/section_id=A/data_0.parquet &>/dev/null; then
    echo "[sirene-stats] ERROR: raw section parquets not found in ${FULL_DIR}"
    exit 1
fi

echo "[sirene-stats] Generating slim observable APE parquets..."

duckdb ":memory:" <<SQL
SET memory_limit='${MEMORY_LIMIT}';
SET temp_directory='${TEMP_DIR}';

-- Slim parquets for Observable map (one file per APE code)
COPY (
  SELECT ape,
         siret,
         name,
         legal_name,
         adresse,
         nb_effectifs_min::INTEGER AS nb_effectifs_min,
         is_siege::BOOLEAN         AS is_siege,
         CAST(date_creation AS VARCHAR) AS date_creation,
         dept,
         latitude,
         longitude
  FROM read_parquet('${FULL_ETS}')
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL
  ORDER BY ape
)
TO '${OBS_DIR}'
(FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 2048, PARTITION_BY (ape), OVERWRITE TRUE);
SQL

echo "[sirene-stats] Slim APE parquets written:"
count=$(ls -d ${OBS_DIR}/ape=*/ 2>/dev/null | wc -l)
total=$(du -sh "${OBS_DIR}/ape="*"/data_0.parquet" 2>/dev/null | awk '{sum+=$1} END{print sum}' || echo "?")
echo "[sirene-stats]   ${count} APE codes — total ~${total}MB"

echo "[sirene-stats] Generating aggregate stats parquets..."

duckdb ":memory:" <<SQL
SET memory_limit='${MEMORY_LIMIT}';
SET temp_directory='${TEMP_DIR}';

-- funnel: full hierarchy with APE counts (reads from raw — needs all columns)
COPY (
  SELECT sc.section_id,  s.section   AS section_label,
         sc.division_id, d.division  AS division_label,
         sc.groupe_id,   g.groupe    AS groupe_label,
         sc.classe_id,   cl.classe   AS classe_label,
         sc.sous_classe_id           AS ape_id,
         sc.sous_classe              AS ape_label,
         COUNT(e.siret)::INTEGER     AS nb_etabs
  FROM read_parquet('${NAF_DIR}/sous_classes.parquet') sc
  JOIN read_parquet('${NAF_DIR}/sections.parquet')  s  ON s.section_id  = sc.section_id
  JOIN read_parquet('${NAF_DIR}/divisions.parquet') d  ON d.division_id = sc.division_id
  JOIN read_parquet('${NAF_DIR}/groupes.parquet')   g  ON g.groupe_id   = sc.groupe_id
  JOIN read_parquet('${NAF_DIR}/classes.parquet')   cl ON cl.classe_id  = sc.classe_id
  LEFT JOIN read_parquet('${FULL_ETS}') e ON e.ape = sc.sous_classe_id
  GROUP BY sc.section_id, s.section, sc.division_id, d.division,
           sc.groupe_id, g.groupe, sc.classe_id, cl.classe,
           sc.sous_classe_id, sc.sous_classe
  ORDER BY sc.section_id, sc.division_id, sc.groupe_id, sc.classe_id, sc.sous_classe_id
) TO '${OBS_DIR}/funnel.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);

-- stats-by-section
COPY (
  SELECT e.section_id, s.section, COUNT(*)::INTEGER AS nb_etablissements
  FROM read_parquet('${FULL_ETS}') e
  JOIN read_parquet('${NAF_DIR}/sections.parquet') s ON s.section_id = e.section_id
  WHERE e.section_id IS NOT NULL AND e.section_id != ''
  GROUP BY e.section_id, s.section
  ORDER BY nb_etablissements DESC
) TO '${OBS_DIR}/stats-by-section.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);

-- stats-by-division
COPY (
  SELECT e.section_id, e.division_id, d.division, COUNT(*)::INTEGER AS nb_etablissements
  FROM read_parquet('${FULL_ETS}') e
  JOIN read_parquet('${NAF_DIR}/divisions.parquet') d ON d.division_id = e.division_id
  WHERE e.division_id IS NOT NULL AND e.division_id != ''
  GROUP BY e.section_id, e.division_id, d.division
  ORDER BY e.section_id, nb_etablissements DESC
) TO '${OBS_DIR}/stats-by-division.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);

-- stats-by-groupe
COPY (
  SELECT e.section_id, e.division_id, e.groupe_id, g.groupe, COUNT(*)::INTEGER AS nb_etablissements
  FROM read_parquet('${FULL_ETS}') e
  JOIN read_parquet('${NAF_DIR}/groupes.parquet') g ON g.groupe_id = e.groupe_id
  WHERE e.groupe_id IS NOT NULL AND e.groupe_id != ''
  GROUP BY e.section_id, e.division_id, e.groupe_id, g.groupe
  ORDER BY nb_etablissements DESC
) TO '${OBS_DIR}/stats-by-groupe.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);

-- stats-by-classe
COPY (
  SELECT e.section_id, e.division_id, e.groupe_id, e.classe_id, c.classe, COUNT(*)::INTEGER AS nb_etablissements
  FROM read_parquet('${FULL_ETS}') e
  JOIN read_parquet('${NAF_DIR}/classes.parquet') c ON c.classe_id = e.classe_id
  WHERE e.classe_id IS NOT NULL AND e.classe_id != ''
  GROUP BY e.section_id, e.division_id, e.groupe_id, e.classe_id, c.classe
  ORDER BY nb_etablissements DESC
) TO '${OBS_DIR}/stats-by-classe.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);

-- top-codes-ape
COPY (
  SELECT e.section_id, e.division_id, e.groupe_id, e.classe_id,
         e.ape AS sous_classe_id, sc.sous_classe, COUNT(*)::INTEGER AS nb_etablissements
  FROM read_parquet('${FULL_ETS}') e
  JOIN read_parquet('${NAF_DIR}/sous_classes.parquet') sc ON sc.sous_classe_id = e.ape
  WHERE e.ape IS NOT NULL AND e.ape != ''
  GROUP BY e.section_id, e.division_id, e.groupe_id, e.classe_id, e.ape, sc.sous_classe
  ORDER BY nb_etablissements DESC
) TO '${OBS_DIR}/top-codes-ape.parquet' (FORMAT PARQUET, COMPRESSION zstd, ROW_GROUP_SIZE 4096);
SQL

echo "[sirene-stats] Done:"
for f in funnel stats-by-section stats-by-division stats-by-groupe stats-by-classe top-codes-ape; do
    size=$(du -sh "${OBS_DIR}/${f}.parquet" 2>/dev/null | cut -f1)
    echo "[sirene-stats]   ${f}.parquet — ${size}"
done
