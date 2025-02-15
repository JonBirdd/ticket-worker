# Build container
FROM golang:1.22 AS builder

RUN go version

RUN apt-get update && apt-get upgrade -y && apt-get install -y ca-certificates git zlib1g-dev

COPY . /root/buildTickets/worker
WORKDIR /root/buildTickets/worker

RUN git submodule update --init --recursive --remote

RUN set -Eeux && \
    go mod download && \
    go mod verify

RUN GOOS=linux GOARCH=amd64 \
    go build \
    -tags=jsoniter \
    -trimpath \
    -o main cmd/worker/main.go

# Prod container
FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && apt-get install -y ca-certificates curl

COPY --from=builder /root/buildTickets/worker/locale /srv/worker/locale
COPY --from=builder /root/buildTickets/worker/main /srv/worker/main

RUN chmod +x /srv/worker/main

RUN useradd -m container
USER container
WORKDIR /srv/worker

CMD ["/srv/worker/main"]