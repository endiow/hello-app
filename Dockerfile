FROM docker.m.daocloud.io/golang:1.26.2 AS builder
WORKDIR /app
RUN go mod init hello-app
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /hello-app

FROM docker.m.daocloud.io/alpine:3.20
WORKDIR /
COPY --from=builder /hello-app /hello-app
ENV PORT=8080
EXPOSE 8080
RUN addgroup -S nonroot && adduser -S nonroot -G nonroot
USER nonroot:nonroot
CMD ["/hello-app"]
