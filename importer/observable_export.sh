#!/usr/bin/env bash
# Generate observable parquets for each dataset in DATAS_LIST.
# Output: dataset/<dataset>/observable/
# Upload afterwards with: just release-upload

set -e

datasets=${DATAS_LIST:-""}
datasets=${datasets//,/ }

echo "[observable-export] Datasets: ${datasets:-none}"

for dataset in $datasets; do
    script="./importer/${dataset}/export_observable_parquets.sh"
    if [ -f "$script" ]; then
        echo ""
        echo "===================================================================="
        echo "[observable-export] Generating observable parquets for '${dataset}'"
        echo "===================================================================="
        echo ""
        bash "$script"
    else
        echo "[observable-export] No export_observable_parquets.sh found for '${dataset}', skipping"
    fi
done
