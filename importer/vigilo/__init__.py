#!/usr/bin/env python3
# -*- coding: utf-8 -*

import json
import os

import requests
import wdalib

provider = "vigilo"
REQUEST_TIMEOUT = 30


def _record_failure(failures, name, scope, error):
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


def download_observations(scope, api_path):
    filename = f"./downloaded/{provider}/observations_{scope}.json"
    response = requests.get(
        f"{api_path}/get_issues.php?scope={scope}&format=json",
        timeout=REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    response.json()
    wdalib.writeContentToFile(filename, response.text)


def download_scopes():
    scopes = []
    instances = []
    failures = []

    VIGILO_CONF_URL = "https://github.com/jesuisundesdeux/vigilo-conf/releases/latest/download/check_result.json"
    try:
        citiesresp = requests.get(VIGILO_CONF_URL, timeout=REQUEST_TIMEOUT)
        citiesresp.raise_for_status()
        citiesresult = citiesresp.json()
        if not isinstance(citiesresult.get("instances"), list):
            raise ValueError("check_result.json has no instances list")
    except (requests.exceptions.RequestException, ValueError) as error:
        _record_failure(failures, "citylist", "citylist", error)
        _write_results(scopes, instances, failures)
        return

    for value in citiesresult["instances"]:
        scope = "unknown"
        try:
            if not value.get("prod"):
                continue

            name = value.get("name", "unknown")
            scope = value.get("scope", "unknown")
            api_path = value["api_path"]

            scoperesp = requests.get(
                f"{api_path}/get_scope.php?scope={scope}",
                timeout=REQUEST_TIMEOUT,
            )
            scoperesp.raise_for_status()
            scoperesult = scoperesp.json()
            if not isinstance(scoperesult, dict):
                raise ValueError("scope response is not a JSON object")
            if not isinstance(scoperesult.get("cities"), list):
                raise ValueError("scope response has no cities list")
            value = value | scoperesult
            value.pop("cities", None)
            value.pop("prod", None)

            download_observations(scope, api_path)
            scopes.append(value)

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

    _write_results(scopes, instances, failures)


def _write_results(scopes, instances, failures):
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/scopes.json", json.dumps(scopes)
    )
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/instances.json", json.dumps(instances)
    )
    wdalib.writeContentToFile(
        f"./downloaded/{provider}/download_failures.json", json.dumps(failures)
    )


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


def update():
    wdalib.show_title(f"Update {provider}")
    wdalib.data2duckdb(provider)
