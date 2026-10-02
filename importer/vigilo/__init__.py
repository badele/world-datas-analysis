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
    # Overwrite scopes.json with the processed array so the SQL can read it as rows
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


def download_categories_list():
    filename = f"./downloaded/{provider}/categories.json"

    resp = requests.get(
        "https://vigilo-bf7f2.firebaseio.com/categorieslist.json",
        timeout=REQUEST_TIMEOUT,
    )
    resp.raise_for_status()

    wdalib.writeContentToFile(filename, resp.text)


def download_scopes_list():
    filename = f"./downloaded/{provider}/scopes.json"

    resp = requests.get(
        "https://vigilo-bf7f2.firebaseio.com/citylist.json",
        timeout=REQUEST_TIMEOUT,
    )
    resp.raise_for_status()
    citiesresult = resp.json()
    if not isinstance(citiesresult, dict):
        raise ValueError("city list is not a JSON object")

    wdalib.writeContentToFile(filename, resp.text)


def download_scope_details():
    scopes_file = f"./downloaded/{provider}/scopes.json"
    with open(scopes_file) as f:
        citiesresult = json.load(f)

    scopes = []
    instances = []
    failures = []

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

    task = ""
    try:
        task = "categories"
        download_categories_list()

        task = "scopes"
        download_scopes_list()

        task = "scope details"
        download_scope_details()

        task = "last release"
        wdalib.download_last_dataset(provider)

    except (requests.exceptions.RequestException, ValueError) as error:
        print(f"!!! Vigilo {task} categories download failed: {error} !!!")


_OBS_SCHEMA = (
    "scopeid TEXT, token TEXT, ts BIGINT, latitude DOUBLE, longitude DOUBLE,"
    ' address TEXT, "comment" TEXT, explanation TEXT, catid BIGINT, approved BIGINT,'
    " cityname TEXT, geonames_districtid BIGINT, geonames_district TEXT,"
    " geonames_cityid BIGINT, geonames_city TEXT"
)

_SCOPES_SCHEMA = (
    "id TEXT, name TEXT, display_name TEXT, iso TEXT, country TEXT, department BIGINT,"
    " lat_min DOUBLE, lat_max DOUBLE, lon_min DOUBLE, lon_max DOUBLE,"
    " map_center_string TEXT, map_zoom BIGINT, api_path TEXT, map_url TEXT,"
    " nominatim_urlbase TEXT, contact_email TEXT, tweet_content TEXT, twitter TEXT,"
    " backend_version TEXT, geonames_admin_filter TEXT, geonames_countryid BIGINT,"
    " is_active BOOLEAN, first_seen_at DATE, last_seen_at DATE, nb_observations BIGINT"
)

_CATEGORIES_SCHEMA = "id BIGINT, name TEXT, name_en TEXT, color TEXT"


def _ensure_observable_base():
    """Create empty stub parquets in last_release/ if download_last_dataset found no release."""
    obs_dir = f"./downloaded/{provider}/last_release"
    os.makedirs(obs_dir, exist_ok=True)

    stubs = {
        f"{obs_dir}/observations.parquet": _OBS_SCHEMA,
        f"{obs_dir}/scopes.parquet": _SCOPES_SCHEMA,
        f"{obs_dir}/categories.parquet": _CATEGORIES_SCHEMA,
    }
    for path, schema in stubs.items():
        if not os.path.exists(path):
            with tempfile.NamedTemporaryFile(
                mode="w", suffix=".sql", delete=False
            ) as f:
                f.write(
                    f"CREATE TABLE _empty ({schema});"
                    f" COPY _empty TO '{path}' (FORMAT PARQUET, COMPRESSION ZSTD);"
                )
                tmp = f.name
            try:
                subprocess.run(f"duckdb :memory: < {tmp}", shell=True, check=True)
            finally:
                os.remove(tmp)


def update():
    _ensure_observable_base()
    wdalib.init_dataset(provider)
    # Remove legacy partitioned directory so DuckDB can write a flat file
    obs_legacy = f"./dataset/{provider}/raw/observations.parquet"
    if os.path.isdir(obs_legacy):
        shutil.rmtree(obs_legacy)
    wdalib.data2duckdb(provider)
