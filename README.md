# Deep-history Observing Squad

## For integrators

See [docs.elrond.com](https://docs.elrond.com/integrators/deep-history-squad).

## For contributors (developers)

### Build the Docker images

Bootstrap:

```
docker image build \
    --no-cache . -t elrondnetwork/deep-history-reconstruction-bootstrap:latest -f ./Bootstrap.dockerfile
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
