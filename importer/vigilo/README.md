# Vigilo dataset

## Overview

Vigilo is a citizen reporting platform for cycling infrastructure issues in
French cities. Each city runs its own Vigilo instance (called a _scope_).

## Workflow

```
just download   →   just update   →   just release-cloudflare
```

### 1. `just download`

Fetches live data from the Vigilo API (runs inside Docker):

- `downloaded/vigilo/categories.json` — issue categories
- `downloaded/vigilo/scopes.json` — active city scopes
- `downloaded/vigilo/observations_<scope>.json` — observations per scope

Only runs if the downloaded folder is older than 7 days.

### 2. `just update`

Merges new API data with historical data from R2 (runs inside Docker):

1. **`downloadFromR2`** — downloads the latest `scopes.parquet` and
   `observations.parquet` from R2 into `downloaded/vigilo/from_r2/raw/` using
   the manifest. This ensures the merge always starts from the most recent
   published state.
2. **`_data2duckdb.sql`** — merges new observations with historical data:
   - Active scopes: `first_seen_at` preserved from R2 history
   - Inactive scopes (disappeared from API): kept with `is_active = false`
   - Observations from inactive scopes: preserved from R2 history
3. Outputs to `dataset/vigilo/raw/`

### 3. `just release-cloudflare`

Uploads the generated parquets to Cloudflare R2 (runs **locally**, needs R2
credentials). Also generates `vigilo/manifest-vigilo.json` on R2, which is used
by the next `just update` to download the historical data.

Required env vars:

Stored on `.env` file

```
CF_ACCOUNT_ID
CF_R2_ACCESS_KEY_ID
CF_R2_SECRET_ACCESS_KEY
```

## R2 naming convention

Local path → R2 key: `/` replaced by `__`, `=` replaced by `.`

```
dataset/vigilo/raw/scopes.parquet  →  vigilo/raw__scopes.parquet
```

## First run (no prior R2 data)

If no manifest exists on R2 yet, `downloadFromR2` skips gracefully and the SQL
runs without historical data (all scopes treated as new,
`first_seen_at = today`). Run `just release-cloudflare` after the first
`just update` to publish data and create the manifest.
