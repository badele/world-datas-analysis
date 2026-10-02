#!/usr/bin/env bash
# Upload parquets to Cloudflare R2 (S3-compatible) with parallel uploads.
# Usage: DATAS_LIST="sirene,geonames" just release-cloudflare
#
# Required env vars:
#   CF_ACCOUNT_ID           — Cloudflare account ID
#   CF_R2_ACCESS_KEY_ID     — R2 API token Access Key ID
#   CF_R2_SECRET_ACCESS_KEY — R2 API token Secret Access Key
#
# Optional:
#   R2_PARALLEL             — number of parallel uploads (default: 8)
#
# Naming convention in R2: {dataset}/{subdir}__{path separators → __}{= → .}
# Example: sirene/observable__ape.46.38Z__data_0.parquet

set -e

R2_BUCKET="world-datas-analysis"
R2_PARALLEL="${R2_PARALLEL:-16}"

if [ -z "$CF_ACCOUNT_ID" ] || [ -z "$CF_R2_ACCESS_KEY_ID" ] || [ -z "$CF_R2_SECRET_ACCESS_KEY" ]; then
    echo "[release-r2] ERROR: missing credentials — set CF_ACCOUNT_ID, CF_R2_ACCESS_KEY_ID, CF_R2_SECRET_ACCESS_KEY"
    exit 1
fi

if ! command -v aws &>/dev/null; then
    echo "[release-r2] ERROR: aws CLI not found (pip install awscli)"
    exit 1
fi

datasets=${DATAS_LIST:-""}
datasets=${datasets//,/ }

if [ -z "$datasets" ]; then
    echo "[release-r2] DATAS_LIST is empty, nothing to do"
    exit 0
fi

R2_ENDPOINT="https://${CF_ACCOUNT_ID}.r2.cloudflarestorage.com"

# Export credentials + config once — inherited by all xargs subshells
export AWS_ACCESS_KEY_ID="$CF_R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$CF_R2_SECRET_ACCESS_KEY"
export R2_ENDPOINT R2_BUCKET

for dataset in $datasets; do
    declare -A local_keys
    task_file=$(mktemp)
    uploaded=0

    for subdir in raw observable; do
        src_dir="dataset/${dataset}/${subdir}"
        [ -d "$src_dir" ] || continue

        while IFS= read -r f; do
            rel=$(realpath --relative-to="dataset/${dataset}" "$f")
            flat=$(echo "$rel" | sed 's|/|__|g')
            r2_key="${dataset}/$(echo "$flat" | sed 's|=|\.|g')"
            printf '%s\0%s\0' "$f" "$r2_key" >>"$task_file"
            echo "[release-r2]   ${rel} → ${r2_key}"
            local_keys["$r2_key"]=1
            uploaded=$((uploaded + 1))
        done < <(find "$src_dir" -name "*.parquet" | sort)
    done

    if [ "$uploaded" -eq 0 ]; then
        echo "[release-r2] ${dataset}: no raw/ or observable/ directory found, skipping"
    else
        echo "[release-r2] ${dataset}: uploading $uploaded files (parallel=${R2_PARALLEL})..."
        progress_file=$(mktemp)
        export PROGRESS_FILE="$progress_file"

        # Background process: display counter updated every 0.2s
        (
            while true; do
                done=$(wc -l < "$progress_file" 2>/dev/null | tr -d ' ')
                printf "\r[release-r2]   %d / %d" "$done" "$uploaded"
                [ "$done" -ge "$uploaded" ] && break
                sleep 0.2
            done
        ) &
        progress_pid=$!

        xargs -0 -P "$R2_PARALLEL" -n 2 bash -c \
            'aws s3 cp "$1" "s3://${R2_BUCKET}/$2" --endpoint-url "$R2_ENDPOINT" --quiet && echo >> "$PROGRESS_FILE"' _ \
            <"$task_file"

        wait "$progress_pid" 2>/dev/null
        printf "\r[release-r2] ${dataset}: done (%d files uploaded)\n" "$uploaded"
        rm -f "$progress_file"
    fi
    rm -f "$task_file"

    # Delete R2 keys that no longer exist locally
    echo "[release-r2] ${dataset}: checking for stale R2 files..."
    deleted=0
    while IFS= read -r r2_key; do
        [ -z "$r2_key" ] && continue
        if [ -z "${local_keys[$r2_key]+_}" ]; then
            aws s3 rm "s3://${R2_BUCKET}/${r2_key}" \
                --endpoint-url "$R2_ENDPOINT" --quiet
            echo "[release-r2]   deleted stale: ${r2_key}"
            deleted=$((deleted + 1))
        fi
    done < <(
        aws s3 ls "s3://${R2_BUCKET}/${dataset}/" \
            --endpoint-url "$R2_ENDPOINT" \
            --recursive |
            awk '{print $4}'
    )
    if [ "$deleted" -gt 0 ]; then
        echo "[release-r2] ${dataset}: $deleted stale file(s) deleted"
    else
        echo "[release-r2] ${dataset}: no stale files"
    fi

    unset local_keys
done
