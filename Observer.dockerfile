FROM golang:1.17.6 as builder

ARG CONFIG_DEVNET_TAG=D1.3.48.0-hf-fix
ARG CONFIG_MAINNET_TAG=release-v1.3.48.0

RUN apt-get update && apt-get -y install python3-pip && pip3 install toml

# Clone repositories
WORKDIR /workspace
RUN git clone https://github.com/ElrondNetwork/elrond-config-devnet --branch=${CONFIG_DEVNET_TAG} --depth=1
RUN git clone https://github.com/ElrondNetwork/elrond-config-mainnet --branch=${CONFIG_MAINNET_TAG} --depth=1

WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-go.git --branch=$(cat /workspace/elrond-config-devnet/binaryVersion | sed 's/tags\///') --single-branch elrond-go-devnet
RUN git clone https://github.com/ElrondNetwork/elrond-go.git --branch=$(cat /workspace/elrond-config-mainnet/binaryVersion | sed 's/tags\///') --single-branch elrond-go-mainnet

# Build node
WORKDIR /go/elrond-go-devnet/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/elrond-go/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

WORKDIR /go/elrond-go-mainnet/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/elrond-go/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

# Adjust configuration files
# TODO: Remove invocation of script (and the script) once the following PR reaches a release:
# https://github.com/ElrondNetwork/elrond-go/pull/4605
COPY "adjust_config.py" /workspace/
RUN python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config-devnet/config.toml && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config-devnet/prefs.toml && \
    python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config-mainnet/config.toml && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config-mainnet/prefs.toml &&

# ===== SECOND STAGE ======
FROM ubuntu:20.04

# We are sharing the library among "elrond-go-devnet" and "elrond-go-mainnet" (no workaround on this yet).
COPY --from=builder "/lib/libwasmer_linux_amd64.so" "/lib/libwasmer_linux_amd64.so"
COPY --from=builder "/workspace/elrond-config-devnet" "/elrond/devnet/config/"
COPY --from=builder "/workspace/elrond-go-devnet/cmd/node/node" "/elrond/devnet/node"
COPY --from=builder "/workspace/elrond-config-mainnet" "/elrond/mainnet/config/"
COPY --from=builder "/workspace/elrond-go-mainnet/cmd/node/node" "/elrond/mainnet/node"

EXPOSE 8080
