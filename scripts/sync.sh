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

MX_WORKSPACE=$MX_WORKSPACE_ROOT/$MX_NETWORK/$MX_SHARD

# Runs the observer (using Docker).
run_observer() {
    if [ ! -d "${MX_WORKSPACE}/data/db" ] 
    then
        echo "Error: ${MX_WORKSPACE}/data/db does not exist. Perhaps it hasn't been reconstructed yet?" 
        return 1
    fi

    docker run -d \
        --user $(id -u):$(id -g) \
        --name deep-history-observer-${MX_NETWORK}-${MX_SHARD} \
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
        --destination-shard-as-observer=${MX_SHARD} || return 1
}
