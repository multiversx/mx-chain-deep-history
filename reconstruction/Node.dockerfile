FROM golang:1.17.6 as builder

ARG ELROND_CONFIG_NAME
ARG ELROND_CONFIG_TAG

# Clone repositories
WORKDIR /workspace
RUN git clone https://github.com/ElrondNetwork/$ELROND_CONFIG_NAME --branch=$ELROND_CONFIG_TAG --depth=1 config
WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-go.git --branch=$(cat /workspace/config/binaryVersion | sed 's/tags\///') --single-branch

# Build node
WORKDIR /go/elrond-go/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty --always)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/elrond-go/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

# Adjust configuration files
# TODO: Remove invocation of script (and the script) once the following PR reaches a release:
# https://github.com/ElrondNetwork/elrond-go/pull/4605
COPY "adjust_config.py" /workspace/
RUN apt-get update && apt-get -y install python3-pip && pip3 install toml
RUN python3 /workspace/adjust_config.py --mode=main --file=/workspace/elrond-config/config.toml && \
    python3 /workspace/adjust_config.py --mode=prefs --file=/workspace/elrond-config/prefs.toml

# ===== SECOND STAGE ======
FROM ubuntu:20.04

COPY --from=builder "/go/elrond-go/cmd/node/node" "/elrond/"
COPY --from=builder "/lib/libwasmer_linux_amd64.so" "/lib/libwasmer_linux_amd64.so"
COPY --from=builder "/workspace/config" "/elrond/config/"

EXPOSE 8080
WORKDIR /elrond
ENTRYPOINT ["/elrond/node", "--import-db=/data/import-db", "--working-directory=/data", "--import-db-no-sig-check", "--log-save", "--log-level=*:INFO", "--log-logger-name", "--rest-api-interface=0.0.0.0:8080"]
