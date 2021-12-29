#!/usr/bin/env bash

ROOTDIR=$(dirname $(realpath $0))

$ROOTDIR/download.sh
$ROOTDIR/import.sh
$ROOTDIR/export.sh
