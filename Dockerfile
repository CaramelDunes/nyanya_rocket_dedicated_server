FROM google/dart-runtime AS builder

WORKDIR /app
RUN dart2native bin/server.dart -o ./server

FROM debian:stretch-slim

WORKDIR /app
COPY --from=builder /app/server .

ENTRYPOINT ["./server"]