# Reconstruction of history

## For integrators

First, decide on a path to serve as a **workspace**. For example, `/home/elrond/deep-history-workspace` - export it as an environment variable:

```
export DEEP_HISTORY_WORKSPACE=/home/elrond/deep-history-workspace
```

Afterwards, prepare a configuration file called `reconstruction.json`, following the example of `default.reconstruction.json`, and save it in the chosen workspace. For the fields `oldestArchive` and `newestArchive`, you can use URLs towards the Elrond public archive (which are available [on request](https://t.me/ElrondDevelopers)).

Then, bootstrap the reconstruction (download and extract the necessary archives, to be used by `import-db`, under the hood) as follows:

```
DOCKER_USER=$(id -u):$(id -g) docker compose --file ./docker-compose.yml \
    --project-name deep-history-reconstruction \
    run -it --rm elrond-deep-history-reconstruction-bootstrap
```

Once the bootstrap step is ready, you can proceed with running the reconstruction containers.

For devnet:

```
DOCKER_USER=$(id -u):$(id -g) docker compose --file ./docker-compose.yml \
    --profile devnet-0 --profile devnet-1 --profile devnet-2 --profile devnet-metachain \
    --project-name deep-history-reconstruction up --detach
```

For mainnet:

```
DOCKER_USER=$(id -u):$(id -g) docker compose --file ./docker-compose.yml \
    --profile mainnet-0 --profile mainnet-1 --profile mainnet-2 --profile mainnet-metachain \
    --project-name deep-history-reconstruction-mainnet up --detach
```

## For contributors (developers)

### Build the Docker images

Bootstrap:

```
docker image build \
    --no-cache . -t elrondnetwork/elrond-deep-history-reconstruction-bootstrap:latest -f ./Bootstrap.dockerfile
```

Node (devnet):

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-devnet \
    --build-arg ELROND_CONFIG_TAG=release-D1.3.46.0 \
    --no-cache . -t elrondnetwork/elrond-deep-history-reconstruction-devnet:latest -f ./Node.dockerfile 
```

Node (mainnet):

```
docker image build \
    --build-arg ELROND_CONFIG_NAME=elrond-config-mainnet \
    --build-arg ELROND_CONFIG_TAG=release-v1.3.46.0 \
    --no-cache . -t elrondnetwork/elrond-deep-history-reconstruction-mainnet:latest -f ./Node.dockerfile 
```
