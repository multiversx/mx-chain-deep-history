# Import DB

## Build the Docker images

```
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-mainnet:latest -f ./mainnet.dockerfile 
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-devnet:latest -f ./devnet.dockerfile
```

## Prepare filesystem

```
export MAINNET_DIR=${HOME}/deep-history-workdir/import-db/mainnet
export DEVNET_DIR=${HOME}/deep-history-workdir/import-db/devnet
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

Attach desired databases:

```
export START_DB_0=${HOME}/downloads/mainnet_28_mar_2022_shard_0
export START_DB_1=${HOME}/downloads/mainnet_28_mar_2022_shard_1
export START_DB_2=${HOME}/downloads/mainnet_28_mar_2022_shard_2

export IMPORT_DB_0=${HOME}/downloads/mainnet_30_mar_2022_shard_0
export IMPORT_DB_1=${HOME}/downloads/mainnet_30_mar_2022_shard_1
export IMPORT_DB_2=${HOME}/downloads/mainnet_30_mar_2022_shard_2
```

```
sudo chown -R ${USER}:${USER} ${MAINNET_DIR}
sudo chown -R ${USER}:${USER} ${DEVNET_DIR}

# Mainnet 0
rm -rf ${MAINNET_DIR}/node-0/db && cp -r ${START_DB_0} ${MAINNET_DIR}/node-0/db
rm -rf ${MAINNET_DIR}/node-0/import-db/db && cp -r ${IMPORT_DB_0} ${MAINNET_DIR}/node-0/import-db/db

# Mainnet 1
rm -rf ${MAINNET_DIR}/node-1/db && cp -r ${START_DB_1} ${MAINNET_DIR}/node-1/db
rm -rf ${MAINNET_DIR}/node-1/import-db/db && cp -r ${IMPORT_DB_1} ${MAINNET_DIR}/node-1/import-db/db

# Mainnet 2
sudo rm -rf ${MAINNET_DIR}/node-2/db && cp -r ${START_DB_2} ${MAINNET_DIR}/node-2/db
sudo rm -rf ${MAINNET_DIR}/node-2/import-db/db && cp -r ${IMPORT_DB_2} ${MAINNET_DIR}/node-2/import-db/db
```

## Run the containers

```
docker compose --file ./docker-compose-mainnet.yml --project-name import-db-mainnet up --detach
docker compose --file ./docker-compose-devnet.yml --project-name import-db-devnet up --detach
```
