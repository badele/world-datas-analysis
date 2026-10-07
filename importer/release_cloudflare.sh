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
R2_PARALLEL="${R2_PARALLEL:-8}"

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
    declare -A local_keys  # r2_key → local_file_size
    declare -A r2_sizes    # r2_key → r2_object_size

    # Quick local-hash check — skip entirely if parquets unchanged since last sync
    sync_cache="dataset/${dataset}/.r2-sync-hash"
    current_hash=$(find "dataset/${dataset}" \( -name "*.parquet" \) -printf '%s %T@\n' 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    if [ -f "$sync_cache" ] && [ "$(cat "$sync_cache" 2>/dev/null)" = "$current_hash" ]; then
        echo "[release-r2] ${dataset}: parquets unchanged since last sync, skipping"
        continue
    fi

    # Fetch current R2 state once — used for both skip-upload and stale-delete
    echo "[release-r2] ${dataset}: listing R2 objects..."
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        r2_size=$(echo "$line" | awk '{print $3}')
        r2_key=$(echo "$line"  | awk '{print $4}')
        r2_sizes["$r2_key"]=$r2_size
    done < <(
        aws s3 ls "s3://${R2_BUCKET}/${dataset}/" \
            --endpoint-url "$R2_ENDPOINT" \
            --recursive
    )

    task_file=$(mktemp)
    skipped=0
    uploaded=0

    for subdir in raw observable; do
        src_dir="dataset/${dataset}/${subdir}"
        [ -d "$src_dir" ] || continue

        while IFS= read -r f; do
            rel=$(realpath --relative-to="dataset/${dataset}" "$f")
            flat=$(echo "$rel" | sed 's|/|__|g')
            r2_key="${dataset}/$(echo "$flat" | sed 's|=|\.|g')"
            local_size=$(wc -c <"$f" | tr -d ' ')
            local_keys["$r2_key"]=$local_size

            # Skip upload if R2 already has the same size
            if [ "${r2_sizes[$r2_key]+_}" ] && [ "${r2_sizes[$r2_key]}" -eq "$local_size" ]; then
                skipped=$((skipped + 1))
                continue
            fi

            printf '%s\0%s\0' "$f" "$r2_key" >>"$task_file"
            uploaded=$((uploaded + 1))
        done < <(find "$src_dir" -name "*.parquet" | sort)
    done

    if [ "$skipped" -gt 0 ]; then
        echo "[release-r2] ${dataset}: $skipped file(s) unchanged, skipped"
    fi

    if [ "$uploaded" -eq 0 ] && [ "$skipped" -eq 0 ]; then
        echo "[release-r2] ${dataset}: no raw/ or observable/ directory found, skipping"
    elif [ "$uploaded" -gt 0 ]; then
        echo "[release-r2] ${dataset}: uploading $uploaded new/changed file(s) (parallel=${R2_PARALLEL})..."
        progress_file=$(mktemp)
        export PROGRESS_FILE="$progress_file"

        (
            while true; do
                done=$(wc -l <"$progress_file" 2>/dev/null | tr -d ' ')
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

    # Delete R2 keys that no longer exist locally (batch DeleteObjects, 1000/req)
    echo "[release-r2] ${dataset}: checking for stale R2 files..."
    stale_keys=()
    for r2_key in "${!r2_sizes[@]}"; do
        if [ -z "${local_keys[$r2_key]+_}" ]; then
            stale_keys+=("$r2_key")
        fi
    done

    deleted=${#stale_keys[@]}
    if [ "$deleted" -gt 0 ]; then
        echo "[release-r2] ${dataset}: deleting $deleted stale file(s) in batches of 1000..."
        i=0
        while [ $i -lt $deleted ]; do
            batch=("${stale_keys[@]:$i:1000}")
            json=$(printf '{"Key":"%s"},' "${batch[@]}")
            json="{\"Objects\":[${json%,}],\"Quiet\":true}"
            aws s3api delete-objects \
                --bucket "$R2_BUCKET" \
                --endpoint-url "$R2_ENDPOINT" \
                --delete "$json" \
                --output text > /dev/null
            i=$((i + 1000))
            echo "[release-r2]   deleted $((i < deleted ? i : deleted)) / $deleted"
        done
        echo "[release-r2] ${dataset}: $deleted stale file(s) deleted"
    else
        echo "[release-r2] ${dataset}: no stale files"
    fi

    # Save hash so next run skips if nothing changed
    echo "$current_hash" > "$sync_cache"

    unset local_keys r2_sizes
done
