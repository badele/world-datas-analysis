#!/bin/bash

import os
import requests

from tqdm import tqdm
from ftplib import FTP

MAX_RETRIES = 5
CHUNK_SIZE = 8192

# Source: https://github.com/owid/importers
def downloadStreamFile(
    url, filename, max_retries: int = MAX_RETRIES, bytes_read: int = None, verbose = False
) -> bytes:
    if bytes_read:
        headers = {"Range": f"bytes={bytes_read}-"}
    else:
        headers = {}
        bytes_read = 0

    content = b""
    try:
        with requests.get(url, headers=headers, stream=True) as r:
            r.raise_for_status()
            for chunk in tqdm(r.iter_content(chunk_size=CHUNK_SIZE)):
                bytes_read += CHUNK_SIZE
                content += chunk
    except requests.exceptions.ChunkedEncodingError:
        if max_retries > 0:
            if verbose:
                print(f"Resuming downloading, remaining retry={max_retries-1}")
            content += downloadStreamFile(url, filename, max_retries - 1, bytes_read)
        else:
            print.info("Download error")

    return content

# Download Streamed http file
def downloadStreamedHttpFile(url, filename, verbose=False):
    if verbose:
        print(f"Download {url}")
    
    content = downloadStreamFile(url, filename)
    with open(filename, "wb") as f:
        f.write(content)


def downloadHttpFile(url, filename, verbose=False):
    if verbose:
        print(f"Download {url}")
        
    r = requests.get(url, allow_redirects=True)
    with open(filename, 'wb') as f:
        f.write(r.content)    

def downloadFtpFile(domaine, ftpfile, filename, username=None, password=None):
    ftp = FTP(domaine)
    ftp.login(username, password)

    with open(filename, "wb") as f:
        ftp.retrbinary(f"RETR {ftpfile}", f.write)
