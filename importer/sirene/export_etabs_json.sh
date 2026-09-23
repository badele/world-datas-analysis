#!/usr/bin/env bash
# Pre-generate one JSON file per APE code for Observable static build.
# Output: observable/src/data/sirene-etabs/<ape>.json

set -e

HOST="${PGHOST:-127.0.0.1}"
PORT="${PGPORT:-5432}"
USER="${PGUSER:-wda}"
DB="${PGDATABASE:-wda}"
PASS="${PGPASSWORD:-wda}"
OUT_DIR="./observable/src/data/sirene-etabs"

mkdir -p "$OUT_DIR"

echo "[sirene] Fetching APE codes..."
CODES=$(PGPASSWORD="$PASS" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A \
    -c "SELECT DISTINCT insee_sous_classe_id FROM wda_sirene_etablissements WHERE insee_sous_classe_id IS NOT NULL ORDER BY 1;")

TOTAL=$(echo "$CODES" | wc -l)
COUNT=0

for APE in $CODES; do
    COUNT=$((COUNT + 1))
    printf "\r[sirene] Generating etabs JSON %d/%d (%s)..." "$COUNT" "$TOTAL" "$APE"

    PGPASSWORD="$PASS" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A -c "
        SELECT json_agg(row)
        FROM (
            SELECT ARRAY[
                ROUND(e.ets_latitude::numeric,  5)::text,
                ROUND(e.ets_longitude::numeric, 5)::text,
                COALESCE(
                    NULLIF(TRIM(e.ets_denominationusuelleetablissement), ''),
                    NULLIF(TRIM(e.ets_enseigne1etablissement), ''),
                    NULLIF(TRIM(e.ens_denominationunitelegale), ''),
                    e.ets_siret
                ),
                TRIM(CONCAT_WS(' ',
                    NULLIF(TRIM(CONCAT_WS(' ',
                        NULLIF(TRIM(e.ets_numerovoieetablissement), ''),
                        NULLIF(TRIM(e.ets_typevoieetablissement), ''),
                        NULLIF(TRIM(e.ets_libellevoieetablissement), '')
                    )), ''),
                    NULLIF(TRIM(e.ets_codepostaletablissement), ''),
                    NULLIF(TRIM(e.ets_libellecommuneetablissement), '')
                )),
                e.ets_siret,
                e.ets_minnbeffectifsetablissement::text,
                CASE WHEN e.ets_etablissementsiege THEN '1' ELSE '0' END,
                e.ets_datecreationetablissement::text,
                COALESCE(e.ens_denominationunitelegale, ''),
                COALESCE(e.ets_departementetablissement, ''),
                COALESCE(e.ets_activiteprincipaleetablissement, '')
            ] AS row
            FROM wda_sirene_etablissements e
            WHERE e.insee_sous_classe_id = '$APE'
              AND e.ets_latitude  IS NOT NULL
              AND e.ets_longitude IS NOT NULL
            ORDER BY e.ets_minnbeffectifsetablissement DESC NULLS LAST
        ) sub;
    " > "$OUT_DIR/${APE}.json"
done

echo ""
echo "[sirene] Done — $COUNT APE JSON files written to $OUT_DIR"
