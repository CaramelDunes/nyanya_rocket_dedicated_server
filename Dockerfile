FROM dart:stable AS builder

WORKDIR /app
COPY . ./
RUN dart pub get
RUN dart compile exe bin/server.dart -o ./server

FROM debian:bullseye-slim

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
EXPOSE 43210-43310/udp

ENTRYPOINT ["./server"]