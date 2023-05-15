# Deep-history Observing Squad

Also see [docs.multiversx.com](https://docs.multiversx.com/integrators/deep-history-squad).

A Deep History Squad holds the **entire trie data**, and it can be used to reconstruct the state of the network at any point in time.

## For integrators

### Reconstructing the databases

Under the hood, the **reconstruction** process relies on the `import-db` feature, which allows us to reprocess previously processed blocks - and, while doing so, for our purposes, we'll also retain the whole, non-pruned history. 

Here's an example of how to reconstruct the databases for a shard:

```
export MX_NETWORK=mainnet
export MX_SHARD=1
export MX_WORKSPACE_ROOT=$HOME/deep-history-workspace
export MX_URL_DAILY_ARCHIVE=https://multiversx.com/example/example/example-${SHARD}.tar.gz

source ./scripts/reconstruct.sh && download_daily_archive
source ./scripts/reconstruct.sh && prepare_import_db
source ./scripts/reconstruct.sh && run_import_db
```

Above, `MX_URL_DAILY_ARCHIVE` must be a "regular" daily archive (e.g. taken from a so-called "full history" node).

In order to reconstruct the databases for all shards, run the above (independently) for `MX_SHARD` set to `0`, `1`, `2` and `metachain`.

### Running the squad

Upon reconstruction, one can individually start the observers for each shard (example below is for Mainnet, shard 0):

```
export MX_WORKSPACE_ROOT=$HOME/deep-history-workspace
export DOCKER_USER=$(id -u):$(id -g)

docker compose \
    --file ./docker-compose.yml \
    --profile squad-mainnet-0 \
    --project-name my-project up --detach
```

Alternatively, one can start all observers (and the Proxy) at once:

```
export MX_WORKSPACE_ROOT=$HOME/deep-history-workspace
export DOCKER_USER=$(id -u):$(id -g)

docker compose \
    --file ./docker-compose.yml \
    --profile squad-mainnet \
    --project-name my-mainnet-squad up --detach
```

## For contributors

### Build the Docker images

Bootstrap:

```
docker image build . -t multiversx/deep-history:latest -f ./Dockerfile
```
