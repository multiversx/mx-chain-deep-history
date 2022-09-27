# Observers

## Build the Docker images

```
docker image build --no-cache . -t elrond-observer-mainnet:latest -f ./mainnet.dockerfile 
docker image build --no-cache . -t elrond-observer-devnet:latest -f ./devnet.dockerfile
```

## Prepare filesystem

```
export BASE_PATH=/home/elrond
export MAINNET_DIR=${BASE_PATH}/deep-history-workdir/observers/mainnet
export DEVNET_DIR=${BASE_PATH}/deep-history-workdir/observers/devnet
```

Create empty folders:

```
mkdir -p ${MAINNET_DIR}/node-0
mkdir -p ${MAINNET_DIR}/node-1
mkdir -p ${MAINNET_DIR}/node-2
mkdir -p ${MAINNET_DIR}/node-metachain

mkdir -p ${DEVNET_DIR}/node-0
mkdir -p ${DEVNET_DIR}/node-1
mkdir -p ${DEVNET_DIR}/node-2
mkdir -p ${DEVNET_DIR}/node-metachain
```

## Run the containers

```
docker compose --file ./docker-compose.yml --env-file ./custom.env --profile mainnet-0 --project-name observers-mainnet up --detach
docker compose --file ./docker-compose.yml --env-file ./custom.env --profile devnet-0 --project-name observers-devnet up --detach
```

## Stop the containers

```
docker compose --project-name observers-mainnet down
docker compose --project-name observers-devnet down
```
