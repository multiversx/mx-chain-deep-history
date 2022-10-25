FROM golang:1.17.6 as builder

# TODO: For elrond-go v1.4.0 (upcoming), use the flag `--no-key` instead of invoking keygenerator.
WORKDIR /go
RUN git clone https://github.com/ElrondNetwork/elrond-go.git --single-branch
WORKDIR /go/elrond-go/cmd/keygenerator
RUN go build

# ===== SECOND STAGE ======
FROM ubuntu:22.04

COPY --from=builder "/go/elrond-go/cmd/keygenerator/keygenerator" "/keygenerator"

RUN apt-get update && apt-get install -y \
    wget \ 
    python3.10 python-is-python3

COPY "./bootstrap.py" "/bootstrap.py"
ENTRYPOINT ["python", "/bootstrap.py", "--workspace", "/workspace"]
