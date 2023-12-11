FROM golang:1.20.7 as builder

ARG CONFIG_TESTNET_TAG=T1.6.5.0
ARG CONFIG_DEVNET_TAG=D1.5.15.0
ARG CONFIG_MAINNET_TAG=v1.5.15.0
ARG PROXY_TESTNET_TAG=v1.1.41
ARG PROXY_DEVNET_TAG=v1.1.39
ARG PROXY_MAINNET_TAG=v1.1.39

# Install Python dependencies, necessary for "adjust_binary.py" and "adjust_observer_src.py"
RUN apt-get update && apt-get -y install python3-pip && pip3 install toml --break-system-packages

# Clone repositories:
WORKDIR /workspace
RUN git clone https://github.com/multiversx/mx-chain-testnet-config --branch=${CONFIG_TESTNET_TAG} --single-branch --depth=1
RUN git clone https://github.com/multiversx/mx-chain-devnet-config --branch=${CONFIG_DEVNET_TAG} --single-branch --depth=1
RUN git clone https://github.com/multiversx/mx-chain-mainnet-config --branch=${CONFIG_MAINNET_TAG} --single-branch --depth=1

WORKDIR /go
RUN git clone https://github.com/multiversx/mx-chain-go --branch=$(cat /workspace/mx-chain-testnet-config/binaryVersion | sed 's/tags\///') --single-branch mx-chain-go-testnet
RUN git clone https://github.com/multiversx/mx-chain-go --branch=$(cat /workspace/mx-chain-devnet-config/binaryVersion | sed 's/tags\///') --single-branch mx-chain-go-devnet
RUN git clone https://github.com/multiversx/mx-chain-go --branch=$(cat /workspace/mx-chain-mainnet-config/binaryVersion | sed 's/tags\///') --single-branch mx-chain-go-mainnet
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --branch=${PROXY_TESTNET_TAG} --single-branch --depth=1 mx-chain-proxy-go-testnet
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --branch=${PROXY_DEVNET_TAG} --single-branch --depth=1 mx-chain-proxy-go-devnet
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --branch=${PROXY_MAINNET_TAG} --single-branch --depth=1 mx-chain-proxy-go-mainnet

# Adjust node source code
COPY "adjust_observer_src.py" /workspace/
RUN python3 /workspace/adjust_observer_src.py --src=/go/mx-chain-go-testnet --max-headers-to-request-in-advance=150 && \
    python3 /workspace/adjust_observer_src.py --src=/go/mx-chain-go-devnet --max-headers-to-request-in-advance=150 && \
    python3 /workspace/adjust_observer_src.py --src=/go/mx-chain-go-mainnet --max-headers-to-request-in-advance=150

# Adjust node configuration files
COPY "prefs_observer.toml" /workspace/mx-chain-testnet-config/prefs.toml
COPY "prefs_observer.toml" /workspace/mx-chain-devnet-config/prefs.toml
COPY "prefs_observer.toml" /workspace/mx-chain-mainnet-config/prefs.toml

# Adjust proxy configuration files
COPY "adjust_proxy_config.py" /workspace/
RUN python3 /workspace/adjust_proxy_config.py --network=testnet --file=/go/mx-chain-proxy-go-testnet/cmd/proxy/config/config.toml && \
    python3 /workspace/adjust_proxy_config.py --network=devnet --file=/go/mx-chain-proxy-go-devnet/cmd/proxy/config/config.toml && \
    python3 /workspace/adjust_proxy_config.py --network=mainnet --file=/go/mx-chain-proxy-go-mainnet/cmd/proxy/config/config.toml

# Build node and proxy
WORKDIR /go/mx-chain-go-testnet/cmd/node
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /workspace/mx-chain-testnet-config/.git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/multiversx/$(cat /go/mx-chain-go-testnet/go.mod | grep mx-chain-vm-v | sort -n | tail -n -1| awk -F '/' '{print$3}'| sed 's/ /@/g')/wasmer/libwasmer_linux_amd64.so /go/mx-chain-go-testnet/cmd/node/libwasmer_linux_amd64.so
RUN cp /go/pkg/mod/github.com/multiversx/$(cat /go/mx-chain-go-testnet/go.mod | grep mx-chain-vm-go | sort -n | tail -n -1| awk -F '/' '{print$3}'| sed 's/ /@/g')/wasmer2/libvmexeccapi.so /go/mx-chain-go-testnet/cmd/node/libvmexeccapi.so

WORKDIR /go/mx-chain-go-devnet/cmd/node
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /workspace/mx-chain-devnet-config/.git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/multiversx/$(cat /go/mx-chain-go-devnet/go.mod | grep mx-chain-vm-v | sort -n | tail -n -1| awk -F '/' '{print$3}'| sed 's/ /@/g')/wasmer/libwasmer_linux_amd64.so /go/mx-chain-go-devnet/cmd/node/libwasmer_linux_amd64.so

WORKDIR /go/mx-chain-go-mainnet/cmd/node
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /workspace/mx-chain-mainnet-config/.git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/multiversx/$(cat /go/mx-chain-go-mainnet/go.mod | grep mx-chain-vm-v | sort -n | tail -n -1| awk -F '/' '{print$3}'| sed 's/ /@/g')/wasmer/libwasmer_linux_amd64.so /go/mx-chain-go-mainnet/cmd/node/libwasmer_linux_amd64.so

WORKDIR /go/mx-chain-proxy-go-testnet/cmd/proxy
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /go/mx-chain-proxy-go-testnet/.git describe --tags --long --dirty --always)"

WORKDIR /go/mx-chain-proxy-go-devnet/cmd/proxy
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /go/mx-chain-proxy-go-devnet/.git describe --tags --long --dirty --always)"

WORKDIR /go/mx-chain-proxy-go-mainnet/cmd/proxy
RUN go build -v -ldflags="-X main.appVersion=$(git --git-dir /go/mx-chain-proxy-go-mainnet/.git describe --tags --long --dirty --always)"

# ===== SECOND STAGE ======
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y wget python3.10

# Copy node (config, binary, libwasmer):
COPY --from=builder "/workspace/mx-chain-testnet-config" "/testnet/node/config/"
COPY --from=builder "/workspace/mx-chain-devnet-config" "/devnet/node/config/"
COPY --from=builder "/workspace/mx-chain-mainnet-config" "/mainnet/node/config/"

COPY --from=builder "/go/mx-chain-go-testnet/cmd/node/node" "/testnet/node/"
COPY --from=builder "/go/mx-chain-go-devnet/cmd/node/node" "/devnet/node/"
COPY --from=builder "/go/mx-chain-go-mainnet/cmd/node/node" "/mainnet/node/"

COPY --from=builder "/go/mx-chain-go-testnet/cmd/node/libwasmer_linux_amd64.so" "/testnet/node/"
COPY --from=builder "/go/mx-chain-go-testnet/cmd/node/libvmexeccapi.so" "/testnet/node/"
COPY --from=builder "/go/mx-chain-go-devnet/cmd/node/libwasmer_linux_amd64.so" "/devnet/node/"
COPY --from=builder "/go/mx-chain-go-mainnet/cmd/node/libwasmer_linux_amd64.so" "/mainnet/node/"

# Copy proxy (config, binary):
COPY --from=builder "/go/mx-chain-proxy-go-testnet/cmd/proxy/config" "/testnet/proxy/config/"
COPY --from=builder "/go/mx-chain-proxy-go-devnet/cmd/proxy/config" "/devnet/proxy/config/"
COPY --from=builder "/go/mx-chain-proxy-go-mainnet/cmd/proxy/config" "/mainnet/proxy/config/"

COPY --from=builder "/go/mx-chain-proxy-go-testnet/cmd/proxy/proxy" "/testnet/proxy/"
COPY --from=builder "/go/mx-chain-proxy-go-devnet/cmd/proxy/proxy" "/devnet/proxy/"
COPY --from=builder "/go/mx-chain-proxy-go-mainnet/cmd/proxy/proxy" "/mainnet/proxy/"

# Copy bootstrap script:
COPY "./bootstrap.py" "/bootstrap.py"

EXPOSE 8080

LABEL config-testnet=${CONFIG_TESTNET_TAG}
LABEL config-devnet=${CONFIG_DEVNET_TAG}
LABEL config-mainnet=${CONFIG_MAINNET_TAG}

LABEL proxy-testnet=${PROXY_TESTNET_TAG}
LABEL proxy-devnet=${PROXY_DEVNET_TAG}
LABEL proxy-mainnet=${PROXY_MAINNET_TAG}
