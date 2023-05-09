
download_daily_archive() {
    mkdir -p $WORKSPACE/daily_archive

    echo "Downloading archive ..."
    wget -O $WORKSPACE/daily_archive/archive $URL_DAILY_ARCHIVE || return 1

    echo "Extracting archive" $WORKSPACE/daily_archive/archive "..."
    tar -xf  $WORKSPACE/daily_archive/archive -C $WORKSPACE/daily_archive || return 1
}

prepare_import_db() {
    mkdir -p $WORKSPACE/data/db
    mkdir -p $WORKSPACE/data/import-db
    mv $WORKSPACE/daily_archive/db $WORKSPACE/data/import-db/ || return 1
}

run_import_db() {
    if [ ! -d "${WORKSPACE}/data/import-db" ] 
    then
        echo "Error: ${WORKSPACE}/data/import-db does not exist. Please run prepare_import_db first." 
        return 1
    fi

    docker run --rm -it \
        --user $(id -u):$(id -g) \
        --name reconstruct-${NETWORK}-${SHARD} \
        --volume ${WORKSPACE}/data:/data \
        --env LD_LIBRARY_PATH=/${NETWORK}/node \
        --workdir /${NETWORK}/node \
        --entrypoint /${NETWORK}/node/node \
        multiversx/deep-history:latest \
        --working-directory=/data \
        --log-save \
        --log-level=*:INFO \
        --log-logger-name \
        --rest-api-interface=0.0.0.0:8080 \
        --destination-shard-as-observer=${SHARD} \
        --import-db=/data/import-db \
        --import-db-no-sig-check || return 1
}
