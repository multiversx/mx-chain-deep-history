FROM golang:1.17.6 as builder

ARG ELROND_PROXY_TAG
ARG NETWORK

WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-proxy-go.git --branch=${ELROND_PROXY_TAG} --single-branch

WORKDIR /go/elrond-proxy-go/cmd/proxy
RUN go build

COPY "adjust_config.py" /workspace/
RUN apt-get update && apt-get -y install python3-pip && pip3 install toml
RUN python3 /workspace/adjust_config.py --mode=proxy --network=${NETWORK} --file=/go/elrond-proxy-go/cmd/proxy/config/config.toml

# ===== SECOND STAGE ======
FROM ubuntu:20.04

COPY --from=builder "/go/elrond-proxy-go/cmd/proxy/proxy" "/elrond/"
COPY --from=builder "/go/elrond-proxy-go/cmd/proxy/config" "/elrond/"

EXPOSE 8080
WORKDIR /elrond
ENTRYPOINT ["/elrond/proxy", "--working-directory=/data", "--log-save", "--log-level=*:DEBUG"]
