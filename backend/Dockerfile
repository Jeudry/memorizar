# syntax=docker/dockerfile:1

# ─── Build ────────────────────────────────────────────────────────────────
FROM golang:1.25-alpine AS build
WORKDIR /src

# Descarga de dependencias en capa cacheable.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# modernc.org/sqlite es puro Go → binario estático sin CGo.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath -ldflags="-s -w" \
    -o /out/memorizar-api ./cmd/api

# Directorio de datos pre-creado con dueño nonroot (uid 65532) para que el
# volumen montado herede permisos de escritura del binario sandboxed.
RUN mkdir -p /out/data

# ─── Runtime ──────────────────────────────────────────────────────────────
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app

COPY --from=build /out/memorizar-api /app/memorizar-api
COPY --from=build --chown=65532:65532 /out/data /data

ENV MEMORIZAR_API_ADDR=:8080 \
    MEMORIZAR_STORE=sqlite \
    MEMORIZAR_SQLITE_PATH=/data/memorizar.db

EXPOSE 8080
VOLUME ["/data"]
USER nonroot:nonroot

ENTRYPOINT ["/app/memorizar-api"]
