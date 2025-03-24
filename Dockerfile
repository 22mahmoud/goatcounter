FROM golang:1.24.1 AS build

WORKDIR /app

COPY go.mod go.sum ./
COPY ./bgrun ./bgrun
RUN go mod download

COPY . .
RUN go build -tags osusergo,netgo,sqlite_omit_load_extension \
	-ldflags="-X zgo.at/goatcounter/v2.Version=$SOURCE_COMMIT -extldflags=-static" \
	./cmd/goatcounter

FROM debian:bookworm-slim AS runtime

COPY --from=build /app/goatcounter /usr/local/bin

WORKDIR /app

VOLUME ["/app/db"]
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/goatcounter"]
CMD ["serve", "-listen", ":8080", "-tls", "none"]
