FROM golang:1.22.1

WORKDIR /go/src

COPY go.mod go.sum ./

RUN go mod download

ADD main.go /go/src/main.go

EXPOSE 9090

ENTRYPOINT ["go", "run", "main.go"]
