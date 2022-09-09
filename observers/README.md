# Observers

## Build the Docker images

```
docker image build --build-arg NUM_EPOCHS_TO_KEEP=1024 --no-cache . -t elrond-observer-mainnet:latest -f ./mainnet.dockerfile 
docker image build --build-arg NUM_EPOCHS_TO_KEEP=1024 --no-cache . -t elrond-observer-devnet:latest -f ./devnet.dockerfile
```

## Prepare filesystem

```
export MAINNET_DIR=${HOME}/deep-history-workdir/observers/mainnet
export DEVNET_DIR=${HOME}/deep-history-workdir/observers/devnet
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
docker compose --file ./docker-compose-mainnet.yml --project-name observers-mainnet up --detach
docker compose --file ./docker-compose-devnet.yml --project-name observers-devnet up --detach
```
