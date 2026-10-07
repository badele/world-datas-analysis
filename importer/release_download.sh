#!/usr/bin/env bash
# Download parquets from GitHub Releases and reconstruct the original directory structure.
# Usage: DATAS_LIST="sirene,geonames" just release-download
#        FORCE=1 DATAS_LIST="sirene" just release-download   # overwrite existing files
#
# Convention: the release contains a manifest-{dataset}.json that maps each GitHub asset name
# (where GitHub converts = to .) to its original relative path (with = preserved).
# Example manifest entry:
#   "raw__section_id.A__data_0.parquet": "raw/section_id=A/data_0.parquet"
#
# By default, existing local files are skipped (safe to run before "just import").
# Set FORCE=1 to overwrite.

set -e

FORCE=${FORCE:-0}

datasets=${DATAS_LIST:-""}
datasets=${datasets//,/ }

if [ -z "$datasets" ]; then
    echo "[release-download] DATAS_LIST is empty, nothing to do"
    exit 0
fi

if ! command -v gh &>/dev/null; then
    echo "[release-download] ERROR: gh CLI not found. Install from https://cli.github.com"
    exit 1
fi

REPO=${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")}
if [ -z "$REPO" ]; then
    echo "[release-download] ERROR: not in a GitHub repository or gh not authenticated"
    exit 1
fi

DL_TMP="/tmp/release_dl_$$"
mkdir -p "$DL_TMP"
trap 'rm -rf "$DL_TMP"' EXIT

for dataset in $datasets; do
    tag="dataset-${dataset}"

    if ! gh release view "$tag" --repo "$REPO" &>/dev/null 2>&1; then
        echo "[release-download] ${dataset}: release ${tag} not found, skipping"
        continue
    fi

    # Download manifest to get the asset name → original path mapping
    manifest_local="$DL_TMP/manifest-${dataset}.json"
    if ! gh release download "$tag" --repo "$REPO" -p "manifest-${dataset}.json" -D "$DL_TMP" --clobber 2>/dev/null; then
        echo "[release-download] ${dataset}: ERROR — manifest-${dataset}.json not found in release ${tag}"
        echo "[release-download] ${dataset}: Re-run './importer/release_github.sh' to regenerate the release with a manifest."
        exit 1
    fi

    echo "[release-download] ${dataset}: syncing from ${tag}..."
    python3 - "$manifest_local" "$dataset" "$FORCE" "$DL_TMP" "$REPO" "$tag" << 'PYEOF'
import sys, json, os, subprocess

manifest_path, dataset, force, dl_tmp, repo, tag = sys.argv[1:]
force = force == "1"

with open(manifest_path) as f:
    manifest = json.load(f)

for asset_name, rel_path in manifest.items():
    target = f"dataset/{dataset}/{rel_path}"
    if not force and os.path.exists(target):
        print(f"[release-download]   skip {target} (already exists)")
        continue
    os.makedirs(os.path.dirname(target), exist_ok=True)
    result = subprocess.run(
        ["gh", "release", "download", tag, "--repo", repo,
         "-p", asset_name, "-D", dl_tmp, "--clobber"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"[release-download]   ERROR downloading {asset_name}: {result.stderr.strip()}")
        continue
    downloaded = os.path.join(dl_tmp, asset_name)
    os.rename(downloaded, target)
    print(f"[release-download]   {asset_name} → {target}")
PYEOF

    echo "[release-download] ${dataset}: done"
done
