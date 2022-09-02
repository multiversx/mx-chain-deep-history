FROM golang:1.17.6 as builder
ARG NUM_EPOCHS_TO_KEEP

# Clone repositories
WORKDIR /workspace
RUN git clone https://github.com/ElrondNetwork/elrond-config-mainnet --branch=rc-2022-july --depth=1
WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-go.git --branch=v1.3.37 --single-branch

# Build node
WORKDIR /go/elrond-go/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/elrond-go/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

# Adjust configuration files
COPY "adjust_config.py" /workspace/
RUN apt-get update && apt-get -y install python3-pip && pip3 install toml
RUN python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config-mainnet/config.toml --num-epochs-to-keep=$NUM_EPOCHS_TO_KEEP && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config-mainnet/prefs.toml

# ===== SECOND STAGE ======
FROM ubuntu:20.04

COPY --from=builder "/go/elrond-go/cmd/node/node" "/elrond/"
COPY --from=builder "/lib/libwasmer_linux_amd64.so" "/lib/libwasmer_linux_amd64.so"
COPY --from=builder "/workspace/elrond-config-mainnet" "/elrond/config/"

EXPOSE 8080
WORKDIR /elrond
ENTRYPOINT ["/elrond/node", "--import-db=/data/import-db", "--working-directory=/data", "--import-db-no-sig-check", "--log-save", "--log-level=*:INFO", "--log-logger-name", "--rest-api-interface=0.0.0.0:8080"]
