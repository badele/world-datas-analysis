#!/usr/bin/env python3

import datetime
import glob
import hashlib
import json
import os
import shutil
import subprocess
import zipfile



def init_download(provider):
    shutil.rmtree(f"./downloaded/{provider}", ignore_errors=True)
    os.makedirs(f"./downloaded/{provider}", exist_ok=True)


def init_dataset(provider):
    # shutil.rmtree(f"./dataset/{provider}", ignore_errors=True)
    os.makedirs(f"./dataset/{provider}", exist_ok=True)


def show_title(title):
    print("###################################################################")
    print(f"# {title}")
    print("###################################################################")


def computeProviderHashes(provider, tables):
    hashes = []
    for table in tables:
        hashes.append(computeFileHashes(table))

    sha1 = hashlib.sha1()
    for hash in hashes:
        sha1.update(hash.encode())

    return sha1.hexdigest()


def computeFileHashes(pattern):
    hashes = []
    files = glob.glob(pattern)
    for file in files:
        hashes.append(computeHash(file))

    sha1 = hashlib.sha1()
    for hash in hashes:
        sha1.update(hash.encode())

    return sha1.hexdigest()


def computeHash(filename):
    sha1 = hashlib.sha1()

    # Compute the hash
    with open(filename, "rb") as file:
        while chunk := file.read(8192):
            sha1.update(chunk)

    return sha1.hexdigest()


def loadHash(provider):
    # Try to load the hash file
    os.makedirs(f"dataset/{provider}", exist_ok=True)
    if not os.path.exists(f"dataset/{provider}/hash.txt"):
        return ""

    # Load the hash file
    with open(f"dataset/{provider}/hash.txt") as f:
        return f.read()


def writeContentToFile(filename, content):
    with open(filename, "w") as f:
        f.write(content)


def writeHash(provider, hash):
    writeContentToFile(f"dataset/{provider}/hash.txt", hash)


# Write a content list to a file
def writeListToFile(filename, contentlist):
    with open(filename, "w", encoding="utf-8") as f:
        f.write("\n".join(contentlist))


# read a content list from a file
def readList(filename):
    with open(filename, "r") as f:
        return f.read().split("\n")


def isFolderOutdated(folder, hours):
    if not os.path.exists(folder):
        return True

    current_time = datetime.datetime.now()
    creation_timestamp = os.path.getctime(folder)
    creation_time = datetime.datetime.fromtimestamp(creation_timestamp)
    time_difference = current_time - creation_time
    hours_difference = time_difference.total_seconds() / 3600

    if hours_difference < hours:
        print(f"{folder} is up to date")

    return hours_difference > hours


###############################################################################
# Clone or pull repository
###############################################################################
def pull(provider, repo_url):
    import git

    clone_dir = f"./downloaded/{provider}"

    print(f"Sync {provider} repository ...")
    if os.path.exists(f"{clone_dir}/.git"):
        repo = git.Repo(clone_dir)
        origin = repo.remotes.origin
        origin.pull()
    else:
        git.Repo.clone_from(
            repo_url,
            clone_dir,
            depth=1,
        )


###############################################################################
# Export tables to CSV (./dataset/*)
###############################################################################
def data2duckdb(provider, tables=None):
    if tables is not None:
        lasthash = loadHash(provider)
        computedhash = computeProviderHashes(provider, tables)

        if lasthash == computedhash:
            return

    show_title(f"Exporting {provider} to DuckDB")

    os.makedirs(f"./dataset/{provider}/raw", exist_ok=True)

    sql_file = f"./importer/{provider}/_data2duckdb.sql"
    command = f"duckdb db/wda.duckdb -f {sql_file}"
    print(f"[{provider}] Executing DuckDB script: {sql_file}", flush=True)
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as error:
        raise RuntimeError(
            f"DuckDB export failed for provider '{provider}' "
            f"using '{sql_file}' (exit code {error.returncode})"
        ) from error

    if tables is not None:
        writeHash(provider, computedhash)


###############################################################################
# Download file
###############################################################################


def download(url, desc="", save_path=""):
    import requests
    from tqdm import tqdm

    # Init stream downloader
    response = requests.get(url, stream=True)
    response.raise_for_status()

    stream = []
    file_size = int(response.headers.get("Content-Length", 0))
    with open(save_path, "wb") as file:
        with tqdm(
            total=file_size,
            unit="B",
            unit_scale=True,
            unit_divisor=1024,
            desc=url.split("/")[-1] if desc == "" else desc,
            ncols=100,
            bar_format="{desc:<50}{bar:20}{r_bar}{bar:-20b}",
        ) as pbar:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    if save_path:
                        file.write(chunk)
                    else:
                        stream.append(chunk)
                    pbar.update(len(chunk))

    return stream


def downloadFile(url, desc, save_path):
    download(url, desc, save_path)


def downloadStream(url, desc):
    return download(url, desc)


###############################################################################
# Download previous dataset release from GitHub
###############################################################################
def _get_github_repo():
    """Return 'owner/repo' from git remote origin, or None if not determinable."""
    result = subprocess.run(
        "git remote get-url origin",
        shell=True,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    url = result.stdout.strip()
    # ssh: git@github.com:owner/repo.git
    if url.startswith("git@github.com:"):
        return url.removeprefix("git@github.com:").removesuffix(".git")
    # https: https://github.com/owner/repo.git
    if "github.com/" in url:
        return url.split("github.com/", 1)[1].removesuffix(".git")
    return None


def download_last_dataset(provider):
    import requests

    tag = f"dataset-{provider}"
    dest = f"./downloaded/{provider}/last_release"

    show_title(f"Downloading {provider} dataset from GitHub release {tag}")

    repo = _get_github_repo()
    if not repo:
        print(f"[{provider}] Cannot determine GitHub repo, skipping last_release download")
        return

    api_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    resp = requests.get(api_url, timeout=30)
    if resp.status_code == 404:
        print(f"[{provider}] No GitHub release '{tag}' found, skipping download")
        return
    resp.raise_for_status()

    assets = [a for a in resp.json().get("assets", []) if a["name"].endswith(".parquet")]
    if not assets:
        print(f"[{provider}] Release '{tag}' has no parquet assets, skipping download")
        return

    os.makedirs(dest, exist_ok=True)
    for asset in assets:
        dest_path = os.path.join(dest, asset["name"])
        downloadFile(asset["browser_download_url"], asset["name"], dest_path)

    print(f"[{provider}] {len(assets)} parquet file(s) downloaded to {dest}")


###############################################################################
# Unzip file
###############################################################################
def unzipFile(filename, destination):
    with zipfile.ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall(destination)
        os.remove(filename)


###############################################################################
# Cloudflare R2 upload / download
#
# Naming convention in R2: {dataset}/{subdir}__{path separators → __}{= → .}
# Example: dataset/vigilo, file raw/scopes.parquet → vigilo/raw__scopes.parquet
#
# uploadToR2  — runs locally (hors Docker), needs R2 credentials
# downloadFromR2 — runs inside Docker, uses the public R2 URL
###############################################################################

_R2_BUCKET = "world-datas-analysis"


def uploadToR2(dataset: str) -> None:
    import boto3

    account_id = os.environ.get("CF_ACCOUNT_ID")
    access_key = os.environ.get("CF_R2_ACCESS_KEY_ID")
    secret_key = os.environ.get("CF_R2_SECRET_ACCESS_KEY")

    if not account_id or not access_key or not secret_key:
        raise RuntimeError(
            "[uploadToR2] Missing credentials: "
            "CF_ACCOUNT_ID, CF_R2_ACCESS_KEY_ID, CF_R2_SECRET_ACCESS_KEY"
        )

    files = []
    for subdir in ["raw", "observable"]:
        src_dir = f"dataset/{dataset}/{subdir}"
        if not os.path.isdir(src_dir):
            continue
        for root, _, filenames in os.walk(src_dir):
            for fn in sorted(filenames):
                if fn.endswith(".parquet"):
                    files.append(os.path.join(root, fn))
    files.sort()

    if not files:
        print(f"[uploadToR2] {dataset}: no parquet files found in raw/ or observable/")
        return

    endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"
    client = boto3.client(
        "s3",
        endpoint_url=endpoint_url,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
    )

    sync_cache = f"dataset/{dataset}/.r2-sync-hash"
    hash_input = "\n".join(
        f"{os.path.getsize(f):.0f} {os.path.getmtime(f):.6f}" for f in files
    )
    current_hash = hashlib.sha256(hash_input.encode()).hexdigest()
    if os.path.exists(sync_cache):
        with open(sync_cache) as f:
            if f.read().strip() == current_hash:
                print(f"[uploadToR2] {dataset}: parquets unchanged since last sync, skipping")
                return

    r2_sizes = {}
    paginator = client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=_R2_BUCKET, Prefix=f"{dataset}/"):
        for obj in page.get("Contents", []):
            r2_sizes[obj["Key"]] = obj["Size"]

    manifest = {}
    local_keys = set()
    uploaded = 0
    skipped = 0

    for f in files:
        rel = os.path.relpath(f, f"dataset/{dataset}")
        flat = rel.replace("/", "__").replace("=", ".")
        r2_key = f"{dataset}/{flat}"
        local_keys.add(r2_key)
        manifest[flat] = rel

        local_size = os.path.getsize(f)
        if r2_key in r2_sizes and r2_sizes[r2_key] == local_size:
            skipped += 1
            continue

        with open(f, "rb") as fp:
            client.put_object(Bucket=_R2_BUCKET, Key=r2_key, Body=fp.read())
        uploaded += 1

    manifest_key = f"{dataset}/manifest-{dataset}.json"
    client.put_object(
        Bucket=_R2_BUCKET,
        Key=manifest_key,
        Body=json.dumps(manifest).encode(),
        ContentType="application/json",
    )
    local_keys.add(manifest_key)
    print(f"[uploadToR2] {dataset}: manifest uploaded ({len(manifest)} file(s) listed)")

    if skipped:
        print(f"[uploadToR2] {dataset}: {skipped} file(s) unchanged, skipped")
    if uploaded:
        print(f"[uploadToR2] {dataset}: {uploaded} file(s) uploaded")

    stale = [k for k in r2_sizes if k not in local_keys]
    if stale:
        for i in range(0, len(stale), 1000):
            batch = stale[i : i + 1000]
            client.delete_objects(
                Bucket=_R2_BUCKET,
                Delete={"Objects": [{"Key": k} for k in batch], "Quiet": True},
            )
        print(f"[uploadToR2] {dataset}: {len(stale)} stale file(s) deleted")
    else:
        print(f"[uploadToR2] {dataset}: no stale files")

    with open(sync_cache, "w") as f:
        f.write(current_hash)


def downloadFromR2(dataset: str, subdir: str = "raw") -> None:
    import requests

    base_url = os.environ.get("WDA_PUBLIC_DATASET_URL", "").rstrip("/")
    if not base_url:
        raise RuntimeError("[downloadFromR2] WDA_PUBLIC_DATASET_URL is not set")

    manifest_url = f"{base_url}/{dataset}/manifest-{dataset}.json"
    resp = requests.get(manifest_url, timeout=30)
    if resp.status_code == 404:
        print(
            f"[downloadFromR2] {dataset}: no manifest found at {manifest_url}, "
            "skipping (run 'just release' first)"
        )
        return
    resp.raise_for_status()
    manifest = resp.json()

    prefix = f"{subdir}/"
    dest_base = f"./downloaded/{dataset}/from_r2"
    downloaded_count = 0

    for flat_name, rel_path in manifest.items():
        if not rel_path.startswith(prefix):
            continue

        file_url = f"{base_url}/{dataset}/{flat_name}"
        dest_path = os.path.join(dest_base, rel_path)
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)

        file_resp = requests.get(file_url, timeout=60, stream=True)
        file_resp.raise_for_status()
        with open(dest_path, "wb") as f:
            for chunk in file_resp.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        downloaded_count += 1

    print(
        f"[downloadFromR2] {dataset}/{subdir}: "
        f"{downloaded_count} file(s) downloaded to {dest_base}"
    )
