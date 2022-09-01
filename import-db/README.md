# Import DB

## Build the Docker images

```
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-mainnet:latest -f ./mainnet.dockerfile 
docker image build --build-arg NUM_EPOCHS_TO_KEEP=128 --no-cache . -t elrond-import-db-devnet:latest -f ./mainnet.dockerfile
```

## Run the containers

```
docker compose --file ./docker-compose-devnet.yml --project-name import-db-devnet up --detach
docker compose --file ./docker-compose-mainnet.yml --project-name import-db-mainnet up --detach
```
