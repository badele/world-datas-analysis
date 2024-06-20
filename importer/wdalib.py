#!/usr/bin/env python3

import sys

import git
import glob
import hashlib
import json
import os
import subprocess


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


def writeHash(provider, hash):
    # Save the hash file
    with open(f"dataset/{provider}/hash.txt", "w") as f:
        f.write(hash)


###############################################################################
# Clone or pull repository
###############################################################################
def pull(provider, repo_url):
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
def export(provider, tables):
    lasthash = loadHash(provider)
    computedhash = computeProviderHashes(provider, tables)

    if lasthash == computedhash:
        return

    print(f"  Exporting {provider}")

    command = f"duckdb db/duckdb.db < ./importer/{provider}/_export2csv.sql"
    process = subprocess.run(command, shell=True, check=True)
    if process.returncode != 0:
        print(
            "###############################################################################"
        )
        print("# ERROR")
        print(
            "###############################################################################"
        )
        print("stderr:", process.stderr)

    writeHash(provider, computedhash)
