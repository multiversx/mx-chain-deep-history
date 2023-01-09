FROM golang:1.17.6 as builder

ARG CONFIG_DEVNET_TAG=D1.3.50.0-hf01
ARG CONFIG_MAINNET_TAG=v1.3.50.0
ARG PROXY_DEVNET_TAG=v1.1.27
ARG PROXY_MAINNET_TAG=v1.1.27

RUN apt-get update && apt-get -y install python3-pip && pip3 install toml

# Clone repositories:
WORKDIR /workspace
RUN git clone https://github.com/ElrondNetwork/elrond-config-devnet --branch=${CONFIG_DEVNET_TAG} --single-branch --depth=1
RUN git clone https://github.com/ElrondNetwork/elrond-config-mainnet --branch=${CONFIG_MAINNET_TAG} --single-branch --depth=1

WORKDIR /go
RUN git clone https://github.com/multiversx/mx-chain-go.git --branch=$(cat /workspace/elrond-config-devnet/binaryVersion | sed 's/tags\///') --single-branch mx-chain-go-devnet
RUN git clone https://github.com/multiversx/mx-chain-go.git --branch=$(cat /workspace/elrond-config-mainnet/binaryVersion | sed 's/tags\///') --single-branch mx-chain-go-mainnet
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --branch=${PROXY_DEVNET_TAG} --single-branch --depth=1 mx-chain-proxy-go-devnet
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --branch=${PROXY_MAINNET_TAG} --single-branch --depth=1 mx-chain-proxy-go-mainnet

# Build node, proxy and keygenerator:
WORKDIR /go/mx-chain-go-devnet/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/mx-chain-go-devnet/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

WORKDIR /go/mx-chain-go-mainnet/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/mx-chain-go-mainnet/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

WORKDIR /go/mx-chain-proxy-go-devnet/cmd/proxy
RUN go build

WORKDIR /go/mx-chain-proxy-go-mainnet/cmd/proxy
RUN go build

# TODO: For mx-chain-go v1.4.0 (upcoming), use the flag `--no-key` instead of using the keygenerator.
WORKDIR /go/mx-chain-go-mainnet/cmd/keygenerator
RUN go build

# Adjust configuration files
# TODO: Remove invocation of script (and the script) once the following PR reaches a release:
# https://github.com/multiversx/mx-chain-go/pull/4605
COPY "adjust_config.py" /workspace/
RUN python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config-devnet/config.toml && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config-devnet/prefs.toml && \
    python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config-mainnet/config.toml && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config-mainnet/prefs.toml && \
    python3 /workspace/adjust_config.py --mode=proxy --network=devnet --file=/go/mx-chain-proxy-go-devnet/cmd/proxy/config/config.toml && \
    python3 /workspace/adjust_config.py --mode=proxy --network=mainnet --file=/go/mx-chain-proxy-go-mainnet/cmd/proxy/config/config.toml

# ===== SECOND STAGE ======
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y wget python3.10

# Copy node:
# We are sharing libwasmer among "mx-chain-go-devnet" and "mx-chain-go-mainnet" (no workaround on this yet - left as future work).
COPY --from=builder "/lib/libwasmer_linux_amd64.so" "/lib/libwasmer_linux_amd64.so"
COPY --from=builder "/workspace/elrond-config-devnet" "/devnet/node/config/"
COPY --from=builder "/go/mx-chain-go-devnet/cmd/node/node" "/devnet/node/"
COPY --from=builder "/workspace/elrond-config-mainnet" "/mainnet/node/config/"
COPY --from=builder "/go/mx-chain-go-mainnet/cmd/node/node" "/mainnet/node/"

# Copy proxy:
COPY --from=builder "/go/mx-chain-proxy-go-devnet/cmd/proxy/proxy" "/devnet/proxy/"
COPY --from=builder "/go/mx-chain-proxy-go-devnet/cmd/proxy/config" "/devnet/proxy/config/"
COPY --from=builder "/go/mx-chain-proxy-go-mainnet/cmd/proxy/proxy" "/mainnet/proxy/"
COPY --from=builder "/go/mx-chain-proxy-go-mainnet/cmd/proxy/config" "/mainnet/proxy/config/"

# Copy keygenerator:
COPY --from=builder "/go/mx-chain-go-mainnet/cmd/keygenerator/keygenerator" "/keygenerator"

# Copy bootstrap script:
COPY "./bootstrap.py" "/bootstrap.py"

EXPOSE 8080

LABEL config-devnet=${CONFIG_DEVNET_TAG}
LABEL config-mainnet=${CONFIG_MAINNET_TAG}
LABEL proxy-devnet=${PROXY_DEVNET_TAG}
LABEL proxy-mainnet=${PROXY_MAINNET_TAG}
