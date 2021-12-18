#!/usr/bin/env bash

CONTAINERNAME="mysql-wda"
docker ps -a | grep "${CONTAINERNAME}" > /dev/null
if [ $? = 0 ];  then
    docker rm --force $CONTAINERNAME
fi

##########################################################
# Import data from owid
##########################################################

# Set permission
docker run --rm -it -v $PWD/importer/owid/exported:/exported busybox sh -c "chmod ugo+rw /exported ; rm -f /exported/*.csv"

# Init container
docker run -d --name mysql-wda -p 3306:3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
-v ${PWD}/importer/owid/docker_download.sh:/scripts/docker_download.sh \
-v ${PWD}/importer/owid/docker_export_to_csv.sh:/scripts/docker_export_to_csv.sh \
-v ${PWD}/importer/owid/init.sql:/scripts/init.sql \
-v ${PWD}/importer/owid/to_csv.sql:/scripts/to_csv.sql \
-v $PWD/importer/owid/exported:/exported/ \
-v ${PWD}/downloaded:/downloaded/ \
mysql:5.7 --secure-file-priv="/exported/"

# Execute importer
docker exec -it mysql-wda bash -c "/scripts/docker_download.sh"

##########################################################
# Export to CSV 
##########################################################

# Execute exporter
docker exec -it mysql-wda bash -c "/scripts/docker_export_to_csv.sh"

# Fix datas
sed -i 's/\\"/""/g' importer/owid/exported/*.csv
sed -i 's/\\N/NULL/g' importer/owid/exported/*.csv