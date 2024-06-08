#!/usr/bin/env bash

IMPORT="downloaded/opendata3m/eco_compteur"
rm -rf "$IMPORT"
mkdir -p "$IMPORT" db

#Download compteurs
curl -sL "https://data.montpellier3m.fr/sites/default/files/ressources/MMM_MMM_GeolocCompteurs.csv" -o "$IMPORT/compteurs_origin.csv"

# Download files
echo "Download info"
echo "serie,name,lat,lon,osm_id,city,dem_district,district" >"$IMPORT/compteurs.csv"
while IFS=',' read -r name serie serie1 lat lon osm_id_string; do
	if [ "$name" != "Nom du com" ]; then
		echo "Download '$name($serie)'"
		osm_id=$(echo "$osm_id_string" | grep -oE '[0-9]+')
		city=$(echo "[out:json]; is_in($lat,$lon); area._[admin_level=8];out body;" | curl -sd @- -X POST http://overpass-api.de/api/interpreter | jq -r '.elements[0].tags.name')
		dem_district=$(echo "[out:json]; is_in($lat,$lon); area._[admin_level=10];out body;" | curl -sd @- -X POST http://overpass-api.de/api/interpreter | jq -r '.elements[0].tags.name')
		district=$(echo "[out:json]; is_in($lat,$lon); area._[admin_level=11];out body;" | curl -sd @- -X POST http://overpass-api.de/api/interpreter | jq -r '.elements[0].tags.name')
		echo "$serie,$name,$lat,$lon,$osm_id,$city,$dem_district,$district" >>"$IMPORT/compteurs.csv"

		echo "https://data.montpellier3m.fr/sites/default/files/ressources/MMM_EcoCompt_${serie}_archive.json"
		curl -sL "https://data.montpellier3m.fr/sites/default/files/ressources/MMM_EcoCompt_${serie}_archive.json" -o "$IMPORT/MMM_EcoCompt_${serie}_archive.json"
		echo ""
	fi
done <"$IMPORT/compteurs_origin.csv"

# Convert bad json format
while IFS=',' read -r serie name _; do
	if [ "$(file -b "$IMPORT/MMM_EcoCompt_${serie}_archive.json")" = "New Line Delimited JSON text data" ]; then
		echo "Convert '$name($serie)'"
		jq -s . "$IMPORT/MMM_EcoCompt_${serie}_archive.json" >"$IMPORT/MMM_EcoCompt_${serie}_archive_tmp.json"
		mv "$IMPORT/MMM_EcoCompt_${serie}_archive_tmp.json" "$IMPORT/MMM_EcoCompt_${serie}_archive.json"
	else
		rm -f "$IMPORT/MMM_EcoCompt_${serie}_archive.json"
	fi
done <"$IMPORT/compteurs.csv"
