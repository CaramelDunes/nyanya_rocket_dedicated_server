FROM debian:buster-slim AS builder

RUN \
  apt-get -q update && apt-get install --no-install-recommends -y -q gnupg2 curl git ca-certificates apt-transport-https openssh-client && \
  curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
  apt-get update && \
  apt-get install dart && \
  rm -rf /var/lib/apt/lists/*

ENV DART_SDK /usr/lib/dart
ENV PATH $DART_SDK/bin:/root/.pub-cache/bin:$PATH

WORKDIR /app
COPY . ./
RUN pub get
RUN dart2native bin/server.dart -o ./server

FROM debian:buster-slim

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
EXPOSE 43210-43310/udp

ENTRYPOINT ["./server"]