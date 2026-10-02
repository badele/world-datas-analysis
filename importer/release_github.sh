#!/usr/bin/env bash
# Check if raw parquets changed since last release and upload raw/ to GitHub Releases if so.
# Observable parquets go to R2 (release_cloudflare.sh), not GitHub Releases.
# Usage: DATAS_LIST="sirene,geonames" just release

set -e

# Encode a dataset-relative path to a flat GitHub release asset name.
# "raw/section_id=A/data_0.parquet" → "raw__section_id=A__data_0.parquet"
# Note: GitHub CLI converts = to . when storing — we record the original path in manifest.json.
release_encode() { echo "$1" | sed 's|/|__|g'; }

datasets=${DATAS_LIST:-""}
datasets=${datasets//,/ }

if [ -z "$datasets" ]; then
    echo "[release] DATAS_LIST is empty, nothing to do"
    exit 0
fi

if ! command -v gh &>/dev/null; then
    echo "[release] ERROR: gh CLI not found. Install from https://cli.github.com"
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo "[release] ERROR: not in a GitHub repository or gh not authenticated"
    exit 1
fi

for dataset in $datasets; do
    tag="dataset-${dataset}"
    raw_dir="dataset/${dataset}/raw"

    if [ ! -d "$raw_dir" ]; then
        echo "[release] ${dataset}: no raw/ directory found, skipping"
        continue
    fi

    # Compute hash of all raw parquets (sorted for reproducibility)
    current_hash=$(find "$raw_dir" -name "*.parquet" | sort | xargs sha256sum 2>/dev/null | sha256sum | cut -d' ' -f1)

    # Try to fetch stored hash and check manifest presence from existing release
    stored_hash=""
    manifest_present=""
    if gh release view "$tag" --repo "$REPO" &>/dev/null 2>&1; then
        stored_hash=$(gh release download "$tag" --repo "$REPO" \
            -p "checksums-raw.sha256" -D /tmp/ --clobber 2>/dev/null \
            && cat /tmp/checksums-raw.sha256 2>/dev/null || echo "")
        manifest_present=$(gh release view "$tag" --repo "$REPO" --json assets \
            -q ".assets[] | select(.name == \"manifest-${dataset}.json\") | .name" 2>/dev/null || echo "")
    fi

    if [ "$current_hash" = "$stored_hash" ] && [ -n "$stored_hash" ] && [ -n "$manifest_present" ]; then
        echo "[release] ${dataset}: raw parquets unchanged (hash: ${current_hash:0:12}...), skipping"
        continue
    fi

    echo "[release] ${dataset}: changes detected (${current_hash:0:12}...), generating observable parquets..."

    # Generate observable parquets via Docker if export script exists
    if [ -f "./importer/${dataset}/export_observable_parquets.sh" ]; then
        DATAS_LIST="$dataset" just observable-export
    fi

    # Delete existing release (hash changed → clean slate, no stale assets)
    if gh release view "$tag" --repo "$REPO" &>/dev/null 2>&1; then
        echo "[release] ${dataset}: deleting old release ${tag}..."
        gh release delete "$tag" --repo "$REPO" --cleanup-tag --yes
    fi

    # Recreate release
    gh release create "$tag" \
        --repo "$REPO" \
        --title "Dataset ${dataset}" \
        --notes "Parquets for dataset \`${dataset}\`. Auto-updated when raw parquets change." \
        --prerelease
    echo "[release] ${dataset}: created release ${tag}"

    upload_dirs=("$raw_dir")

    # Upload parquets — encode path relative to dataset/${dataset}/ using __ separator
    # Also build manifest.json mapping GitHub asset names → original relative paths.
    # GitHub CLI converts = to . in asset names, so we record the mapping to allow
    # exact restoration on download (just import).
    manifest_file="/tmp/manifest-${dataset}.json"
    echo "{" > "$manifest_file"
    first_entry=1
    for upload_dir in "${upload_dirs[@]}"; do
        echo "[release] ${dataset}: uploading parquets from ${upload_dir}..."
        while IFS= read -r f; do
            rel=$(realpath --relative-to="dataset/${dataset}" "$f")
            flat=$(release_encode "$rel")
            # GitHub converts = to . in stored asset names
            github_name=$(echo "$flat" | sed 's|=|\.|g')
            tmp_file="/tmp/${flat}"
            cp "$f" "$tmp_file"
            echo "[release]   ${rel} → ${github_name}"
            gh release upload "$tag" --repo "$REPO" "$tmp_file" --clobber
            rm -f "$tmp_file"
            # Append to manifest
            if [ "$first_entry" = "1" ]; then
                first_entry=0
            else
                echo "," >> "$manifest_file"
            fi
            printf '  "%s": "%s"' "$github_name" "$rel" >> "$manifest_file"
        done < <(find "$upload_dir" -name "*.parquet" | sort)
    done
    echo "" >> "$manifest_file"
    echo "}" >> "$manifest_file"

    gh release upload "$tag" --repo "$REPO" "$manifest_file" --clobber
    echo "[release] ${dataset}: manifest.json uploaded"
    rm -f "$manifest_file"

    # Upload raw hash for future comparison
    echo "$current_hash" > /tmp/checksums-raw.sha256
    gh release upload "$tag" --repo "$REPO" /tmp/checksums-raw.sha256 --clobber

    echo "[release] ${dataset}: done — hash ${current_hash:0:12}... stored"
done
