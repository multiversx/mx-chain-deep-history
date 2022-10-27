# Deep-history Observing Squad

## For integrators

See [docs.elrond.com](https://docs.elrond.com/integrators/deep-history-squad).

## For contributors (developers)

### Build the Docker images

Bootstrap:

```
docker image build --no-cache . -t elrondnetwork/deep-history-bootstrap:latest -f ./Bootstrap.dockerfile
```

Observer:

```
docker image build --no-cache . -t elrondnetwork/deep-history-observer:latest -f ./Observer.dockerfile 
```

Proxy

```
docker image build --no-cache . -t elrondnetwork/deep-history-proxy:latest -f ./Proxy.dockerfile
```

