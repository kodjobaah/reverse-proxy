# syntax=docker/dockerfile:1

FROM golang:1.18.0-alpine3.15
WORKDIR /app
COPY go.mod ./
COPY go.sum ./
ADD cmd cmd
ADD internal internal
RUN go build -o /proxy cmd/proxy/main.go 

CMD [ "/proxy" ]