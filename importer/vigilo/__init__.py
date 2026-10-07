#!/usr/bin/env python3
# -*- coding: utf-8 -*

import json
import os
import shutil
import subprocess
import tempfile

import requests
import wdalib

provider = "vigilo"
REQUEST_TIMEOUT = 30


def _write_download_results(scopes, instances, failures):
    """Write the successful results and the failures collected during download."""
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/scopes.json", json.dumps(scopes)
    )
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/instances.json", json.dumps(instances)
    )
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/download_failures.json", json.dumps(failures)
    )


def _record_failure(failures, name, scope, error):
    """Record and display a failed city download."""
    failure = {
        "name": name,
        "scope": scope,
        "error": type(error).__name__,
        "message": str(error),
    }
    failures.append(failure)
    print(f"!!! Vigilo download failed for {name} ({scope}): {error} !!!\n")


def download_categories():
    filename = f"./downloaded/{provider}/categories.json"

    resp = requests.get(
        "https://vigilo-bf7f2.firebaseio.com/categorieslist.json",
        timeout=REQUEST_TIMEOUT,
    )
    resp.raise_for_status()

    wdalib.writeContentToFile(filename, resp.text)


def download_scopes():
    scopes = []
    instances = []
    failures = []

    try:
        citiesresp = requests.get(
            "https://vigilo-bf7f2.firebaseio.com/citylist.json",
            timeout=REQUEST_TIMEOUT,
        )
        citiesresp.raise_for_status()
        citiesresult = citiesresp.json()
        if not isinstance(citiesresult, dict):
            raise ValueError("city list is not a JSON object")
    except (requests.exceptions.RequestException, ValueError) as error:
        _record_failure(failures, "citylist", "citylist", error)
        _write_download_results(scopes, instances, failures)
        return

    # Download
    for name, value in citiesresult.items():
        scope = "unknown"
        try:
            if not value["prod"]:
                continue

            value["name"] = name

            scope = value.get("scope", "unknown")
            api_path = value["api_path"]

            # Get scope informations
            scoperesp = requests.get(
                f"{api_path}/get_scope.php?scope={scope}",
                timeout=REQUEST_TIMEOUT,
            )
            scoperesp.raise_for_status()

            # Merge with scope informations
            scoperesult = scoperesp.json()
            if not isinstance(scoperesult, dict):
                raise ValueError("scope response is not a JSON object")
            if not isinstance(scoperesult.get("cities"), list):
                raise ValueError("scope response has no cities list")
            value = value | scoperesult

            value.pop("cities", None)
            value.pop("prod", None)

            download_observations(scope, name, api_path)

            scopes.append(value)

            # Cities informations
            for city in scoperesult["cities"]:
                city["scope"] = scope
                instances.append(city)

        except (
            requests.exceptions.RequestException,
            ValueError,
            KeyError,
            TypeError,
        ) as error:
            _record_failure(failures, name, scope, error)

    _write_download_results(scopes, instances, failures)


def download_observations(scope, name, api_path):
    filename = f"./downloaded/{provider}/observations_{scope}.json"

    response = requests.get(
        f"{api_path}/get_issues.php?scope={scope}&format=json",
        timeout=REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    response.json()
    wdalib.writeContentToFile(filename, response.text)


def download():
    if not wdalib.isFolderOutdated(f"./downloaded/{provider}", 7 * 24):
        return

    wdalib.init_download(provider)
    wdalib.show_title(f"Download {provider}")

    try:
        download_categories()
    except (requests.exceptions.RequestException, ValueError) as error:
        print(f"!!! Vigilo categories download failed: {error} !!!")

    download_scopes()


MIGRATION_DATE = "2025-05-11"

_HISTORICAL_SCHEMA = (
    "id TEXT, name TEXT, display_name TEXT, iso TEXT, country TEXT, department BIGINT,"
    " lat_min DOUBLE, lat_max DOUBLE, lon_min DOUBLE, lon_max DOUBLE,"
    " map_center_string TEXT, map_zoom BIGINT, api_path TEXT, map_url TEXT,"
    " nominatim_urlbase TEXT, contact_email TEXT, tweet_content TEXT, twitter TEXT,"
    " backend_version TEXT, geonames_admin_filter TEXT, geonames_countryid BIGINT,"
    " is_active BOOLEAN, first_seen_at DATE, last_seen_at DATE"
)

_BASE_COLS = (
    "id, name, display_name, iso, country, department,"
    " lat_min, lat_max, lon_min, lon_max, map_center_string, map_zoom,"
    " api_path, map_url, nominatim_urlbase, contact_email, tweet_content,"
    " twitter, backend_version, geonames_admin_filter, geonames_countryid"
)


def _run_duckdb_sql(sql):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".sql", delete=False) as f:
        f.write(sql)
        tmp_path = f.name
    try:
        subprocess.run(f"duckdb :memory: < {tmp_path}", shell=True, check=True)
    finally:
        os.remove(tmp_path)


def _save_scopes_historical():
    """Back up current scopes.parquet (normalized to new schema) before the dataset dir is wiped."""
    current = f"./dataset/{provider}/scopes.parquet"
    historical = f"./downloaded/{provider}/scopes_historical.parquet"

    if not os.path.exists(current) or os.path.getsize(current) == 0:
        if os.path.exists(historical):
            # Previous backup survives a failed run — keep it, just enrich with partitions
            _add_partition_only_scopes(historical)
            return
        # First ever run — create empty historical parquet with correct schema
        _run_duckdb_sql(
            f"CREATE OR REPLACE TABLE _h ({_HISTORICAL_SCHEMA});"
            f" COPY _h TO '{historical}' (FORMAT PARQUET, COMPRESSION ZSTD);"
        )
        _add_partition_only_scopes(historical)
        return

    # Check if current parquet already has the tracking columns (post-migration)
    check = subprocess.run(
        f"duckdb :memory: -c \"SELECT is_active FROM read_parquet('{current}') LIMIT 0\"",
        shell=True,
        capture_output=True,
    )
    if check.returncode == 0:
        tracking = "is_active, first_seen_at, last_seen_at"
    else:
        tracking = (
            f"false AS is_active,"
            f" DATE '{MIGRATION_DATE}' AS first_seen_at,"
            f" DATE '{MIGRATION_DATE}' AS last_seen_at"
        )

    _run_duckdb_sql(
        f"COPY (SELECT {_BASE_COLS}, {tracking} FROM read_parquet('{current}'))"
        f" TO '{historical}' (FORMAT PARQUET, COMPRESSION ZSTD);"
    )
    _add_partition_only_scopes(historical)


def _add_partition_only_scopes(historical):
    """Add minimal scope entries for scopes found in observation partitions but absent from scopes_historical."""
    obs_dir = f"./dataset/{provider}/observations.parquet"
    if not os.path.exists(obs_dir):
        obs_dir = f"./downloaded/{provider}/observations_historical"
    if not os.path.exists(obs_dir):
        return

    discovered = [
        d[len("scopeid="):]
        for d in os.listdir(obs_dir)
        if d.startswith("scopeid=")
    ]
    if not discovered:
        return

    values = ", ".join(f"('{sid}')" for sid in discovered)
    _run_duckdb_sql(
        f"CREATE OR REPLACE TABLE _disc AS"
        f" SELECT id,"
        f"  NULL::TEXT AS name, NULL::TEXT AS display_name, NULL::TEXT AS iso,"
        f"  NULL::TEXT AS country, NULL::BIGINT AS department,"
        f"  NULL::DOUBLE AS lat_min, NULL::DOUBLE AS lat_max,"
        f"  NULL::DOUBLE AS lon_min, NULL::DOUBLE AS lon_max,"
        f"  NULL::TEXT AS map_center_string, NULL::BIGINT AS map_zoom,"
        f"  NULL::TEXT AS api_path, NULL::TEXT AS map_url,"
        f"  NULL::TEXT AS nominatim_urlbase, NULL::TEXT AS contact_email,"
        f"  NULL::TEXT AS tweet_content, NULL::TEXT AS twitter,"
        f"  NULL::TEXT AS backend_version, NULL::TEXT AS geonames_admin_filter,"
        f"  NULL::BIGINT AS geonames_countryid,"
        f"  false AS is_active,"
        f"  DATE '{MIGRATION_DATE}' AS first_seen_at,"
        f"  DATE '{MIGRATION_DATE}' AS last_seen_at"
        f" FROM (VALUES {values}) t(id)"
        f" WHERE id NOT IN (SELECT id FROM read_parquet('{historical}'));"
        f"CREATE OR REPLACE TABLE _merged AS"
        f"  SELECT * FROM read_parquet('{historical}')"
        f"  UNION ALL SELECT * FROM _disc;"
        f"COPY _merged TO '{historical}' (FORMAT PARQUET, COMPRESSION ZSTD);"
    )


def _save_observations_historical():
    """Back up all observation partitions before the dataset dir is wiped."""
    current = f"./dataset/{provider}/observations.parquet"
    historical = f"./downloaded/{provider}/observations_historical"

    if not os.path.exists(current):
        # No current data — keep existing historical backup from a previous run if any
        return
    if os.path.exists(historical):
        shutil.rmtree(historical)
    shutil.copytree(current, historical)


def _restore_historical_observations():
    """Restore observation partitions for inactive scopes after the SQL update."""
    historical = f"./downloaded/{provider}/observations_historical"
    current = f"./dataset/{provider}/observations.parquet"

    if not os.path.exists(historical):
        return

    for scope_dir in os.listdir(historical):
        src = os.path.join(historical, scope_dir)
        dst = os.path.join(current, scope_dir)
        if not os.path.exists(dst):
            shutil.copytree(src, dst)


def update():
    _save_scopes_historical()
    _save_observations_historical()
    wdalib.init_dataset(provider)
    wdalib.data2duckdb(provider)
    _restore_historical_observations()
