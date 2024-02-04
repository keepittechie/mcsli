# Created by SZ27 https://github.com/realSZ27
# This is my first time making a docker image, so feel free to make make changes

# Stage 1, build rcon client for all archs
FROM alpine:3 AS builder

WORKDIR /rcon

RUN apk add --no-cache git cmake gcc ninja bash

RUN git clone https://github.com/radj307/ARRCON \
    cd ARRCON \
    git submodule update --init --recursive \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -G Ninja \
    cmake --build build --config Release

# Stage 2, run the server
FROM alpine:3

COPY --from=builder /ARRCON/build/ARRCON/ARRCON /rcon

# Install required packages
RUN apk add --no-cache bash jq curl wget openjdk17 openjdk8

# Copies script
COPY ./install-docker.sh /
RUN chmod +x /install-docker.sh

ENV SERVER_VERSION "1.20.4"
ENV SERVER_SOFTWARE "purpur"
ENV MAX_RAM "1G"
ENV MIN_RAM "1G"

EXPOSE 25565
EXPOSE 19132

ENTRYPOINT ["/install-docker.sh"]
CMD ["stop"]