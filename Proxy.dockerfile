FROM golang:1.17.6 as builder

ARG PROXY_DEVNET_TAG=deep-history-24
ARG PROXY_MAINNET_TAG=deep-history-24

RUN apt-get update && apt-get -y install python3-pip && pip3 install toml

WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-proxy-go.git --branch=${PROXY_DEVNET_TAG} --single-branch elrond-proxy-go-devnet
RUN git clone https://github.com/ElrondNetwork/elrond-proxy-go.git --branch=${PROXY_MAINNET_TAG} --single-branch elrond-proxy-go-mainnet

WORKDIR /go/elrond-proxy-go-devnet/cmd/proxy
RUN go build

WORKDIR /go/elrond-proxy-go-mainnet/cmd/proxy
RUN go build

COPY "adjust_config.py" /workspace/
RUN python3 /workspace/adjust_config.py --mode=proxy --network=devnet --file=/go/elrond-proxy-go-devnet/cmd/proxy/config/config.toml && \
    python3 /workspace/adjust_config.py --mode=proxy --network=mainnet --file=/go/elrond-proxy-go-mainnet/cmd/proxy/config/config.toml

# ===== SECOND STAGE ======
FROM ubuntu:20.04

COPY --from=builder "/go/elrond-proxy-go-devnet/cmd/proxy/proxy" "/elrond/devnet/"
COPY --from=builder "/go/elrond-proxy-go-devnet/cmd/proxy/config" "/elrond/devnet/config/"
COPY --from=builder "/go/elrond-proxy-go-mainnet/cmd/proxy/proxy" "/elrond/mainnet/"
COPY --from=builder "/go/elrond-proxy-go-mainnet/cmd/proxy/config" "/elrond/mainnet/config/"

EXPOSE 8080
