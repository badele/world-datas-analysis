#!/usr/bin/env bash
# Upload parquets to Cloudflare R2 via wdalib.uploadToR2().
# Usage: DATAS_LIST="sirene,geonames" just release-cloudflare
#
# Required env vars:
#   CF_ACCOUNT_ID           — Cloudflare account ID
#   CF_R2_ACCESS_KEY_ID     — R2 API token Access Key ID
#   CF_R2_SECRET_ACCESS_KEY — R2 API token Secret Access Key

set -e

datasets=${DATAS_LIST:-""}
if [ -z "$datasets" ]; then
    echo "[uploadToR2] DATAS_LIST is empty, nothing to do"
    exit 0
fi

PYTHON="${PYTHON:-.venv/bin/python3}"
"$PYTHON" - "$datasets" <<'PYEOF'
import sys
sys.path.insert(0, 'importer')
import wdalib
for d in sys.argv[1].split(','):
    d = d.strip()
    if d:
        wdalib.uploadToR2(d)
PYEOF
