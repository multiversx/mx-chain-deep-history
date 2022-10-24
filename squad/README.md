# Observing Squad

## For integrators

First, decide on a path to serve as a **workspace**. This has to be the same workspace as the one used for the **reconstruction** step. For example, `/home/elrond/deep-history-workspace` - export it as an environment variable:

```
export DEEP_HISTORY_WORKSPACE=/home/elrond/deep-history-workspace
```

Then, start the squad using docker-compose, as follows:

For devnet:

```
DOCKER_USER=$(id -u):$(id -g) docker compose --file ./docker-compose.yml \
    --profile devnet-proxy --profile devnet-0 --profile devnet-1 --profile devnet-2 --profile devnet-metachain \
    --project-name deep-history-squad-devnet up --detach
```

For mainnet:

```
DOCKER_USER=$(id -u):$(id -g) docker compose --file ./docker-compose.yml \
    --profile mainnet-0 --profile mainnet-1 --profile mainnet-2 --profile mainnet-metachain \
    --project-name deep-history-squad-mainnet up --detach
```

## For contributors (developers)

### Build the Docker images

Proxy (devnet):

```
docker image build \
    --build-arg NETWORK=devnet \
    --build-arg ELROND_PROXY_TAG=deep-history-24 \
    --no-cache . -t elrondnetwork/deep-history-proxy-devnet:latest -f ./Proxy.dockerfile
```

Proxy (mainnet):

```
docker image build \
    --build-arg NETWORK=mainnet \
    --build-arg ELROND_PROXY_TAG=deep-history-24 \
    --no-cache . -t elrondnetwork/deep-history-proxy-mainnet:latest -f ./Proxy.dockerfile
```

Node (devnet):

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-devnet \
    --build-arg ELROND_CONFIG_TAG=release-D1.3.47.0 \
    --no-cache . -t elrondnetwork/deep-history-reconstruction-devnet:latest -f ./Node.dockerfile 
```

Node (mainnet):

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-mainnet \
    --build-arg ELROND_CONFIG_TAG=release-v1.3.47.0 \
    --no-cache . -t elrondnetwork/deep-history-reconstruction-mainnet:latest -f ./Node.dockerfile 
```
