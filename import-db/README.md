# Import DB

## Explicit setup

### Build the Docker images

Devnet:

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-devnet \
    --build-arg ELROND_CONFIG_TAG=release-D1.3.46.0 \
    --build-arg ELROND_GO_TAG=v1.3.46 \
    --no-cache . -t elrond-deep-history-import-db-devnet:latest -f ./Dockerfile 
```

Mainnet:

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-mainnet \
    --build-arg ELROND_CONFIG_TAG=release-v1.3.46.0 \
    --build-arg ELROND_GO_TAG=v1.3.46 \
    --no-cache . -t elrond-deep-history-import-db-mainnet:latest -f ./Dockerfile 
```

### Prepare filesystem

```
source default.env

export MAINNET_DIR=${BASE_PATH}/import-db/mainnet
export DEVNET_DIR=${BASE_PATH}/import-db/devnet
```

Create empty folders:

```
mkdir -p ${MAINNET_DIR}/node-0/import-db
mkdir -p ${MAINNET_DIR}/node-1/import-db
mkdir -p ${MAINNET_DIR}/node-2/import-db
mkdir -p ${MAINNET_DIR}/node-metachain/import-db

mkdir -p ${DEVNET_DIR}/node-0/import-db
mkdir -p ${DEVNET_DIR}/node-1/import-db
mkdir -p ${DEVNET_DIR}/node-2/import-db
mkdir -p ${DEVNET_DIR}/node-metachain/import-db
```

### Attach databases

As desired, download, extract and attach node databases to `import-db` and `db` folders.

### Run the containers

```
docker compose --file ./docker-compose.yml --env-file ./custom.env --profile mainnet-0 --project-name import-db-mainnet up --user $(id -u):$(id -g) --detach

docker compose --file ./docker-compose.yml --env-file ./custom.env --profile devnet-0 --project-name import-db-devnet up --user $(id -u):$(id -g) --detach
```

### Stop the containers

```
docker compose --project-name import-db-mainnet down
docker compose --project-name import-db-devnet down
```
