# Deep-history Observing Squad

Also see [docs.multiversx.com](https://docs.multiversx.com/integrators/deep-history-squad).

A Deep History Squad holds the **entire trie data**, and it can be used to reconstruct the state of the network for each past block.

## For contributors

### Build the Docker images

```
docker image build --network=host . -t multiversx/deep-history:latest -f ./Dockerfile
```
