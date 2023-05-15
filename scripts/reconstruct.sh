if [ -z "$MX_NETWORK" ]
then
    echo "Environment variable isn't defined: MX_NETWORK."
    exit 1
fi

if [ -z "$MX_SHARD" ]
then
    echo "Environment variable isn't defined: MX_SHARD."
    exit 1
fi

if [ -z "$MX_WORKSPACE_ROOT" ]
then
    echo "Environment variable isn't defined: MX_WORKSPACE_ROOT."
    exit 1
fi

MX_WORKSPACE=$MX_WORKSPACE_ROOT/$MX_NETWORK/node-$MX_SHARD

# Downloads (and extracts) a regular, "full-history", daily archive.
download_daily_archive() {
    if [ -z "$MX_URL_DAILY_ARCHIVE" ]
    then
        echo "Environment variable isn't defined: MX_URL_DAILY_ARCHIVE."
        return 1
    fi

    mkdir -p $MX_WORKSPACE/daily_archive

    echo "Downloading archive ..."
    wget -O $MX_WORKSPACE/daily_archive/archive $URL_DAILY_ARCHIVE || return 1

    echo "Extracting archive" $MX_WORKSPACE/daily_archive/archive "..."
    tar -xf  $MX_WORKSPACE/daily_archive/archive -C $MX_WORKSPACE/daily_archive || return 1
}

# Prepares the import-db folder (using the data extracted from the daily archive).
prepare_import_db() {
    mkdir -p $MX_WORKSPACE/data/db
    mkdir -p $MX_WORKSPACE/data/import-db
    mv $MX_WORKSPACE/daily_archive/db $MX_WORKSPACE/data/import-db/ || return 1
}

# Runs the import-db process (using Docker).
run_import_db() {
    if [ ! -d "${MX_WORKSPACE}/data/import-db" ] 
    then
        echo "Error: ${MX_WORKSPACE}/data/import-db does not exist. Please run prepare_import_db first." 
        return 1
    fi

    docker run -d \
        --user $(id -u):$(id -g) \
        --name deep-history-reconstruct-${MX_NETWORK}-${MX_SHARD} \
        --volume ${MX_WORKSPACE}/data:/data \
        --env LD_LIBRARY_PATH=/${MX_NETWORK}/node \
        --workdir /${MX_NETWORK}/node \
        --entrypoint /${MX_NETWORK}/node/node \
        multiversx/deep-history:latest \
        --working-directory=/data \
        --log-save \
        --log-level=*:INFO \
        --log-logger-name \
        --rest-api-interface=0.0.0.0:8080 \
        --destination-shard-as-observer=${MX_SHARD} \
        --import-db=/data/import-db \
        --import-db-no-sig-check || return 1
}
