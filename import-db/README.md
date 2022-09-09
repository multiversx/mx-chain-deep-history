# Import DB

## Build the Docker images

```
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-mainnet:latest -f ./mainnet.dockerfile 
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-devnet:latest -f ./devnet.dockerfile
```

## Prepare filesystem

```
export BASE_PATH=/home/elrond
export MAINNET_DIR=${BASE_PATH}/deep-history-workdir/import-db/mainnet
export DEVNET_DIR=${BASE_PATH}/deep-history-workdir/import-db/devnet
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

## Attach databases

As desired, download, extract and attach node databases to `import-db` and `db` folders.

## Run the containers

```
docker compose --file ./docker-compose.yml --env-file ./custom.env --profile mainnet --profile shard-0 --project-name import-db-mainnet up --detach
docker compose --file ./docker-compose.yml --env-file ./custom.env --profile devnet --profile shard-0 --project-name import-db-devnet up --detach
```

## Stop the containers

```
docker compose --project-name import-db-mainnet down
docker compose --project-name import-db-devnet down
```
