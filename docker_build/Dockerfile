# Created by SZ27 https://github.com/realSZ27
# This is my first time making a docker image, so feel free to make make changes

# Stage 1, get rcon-cli
FROM alpine:3 AS grabber

RUN apk add --no-cache go && go install github.com/itzg/rcon-cli@latest

# Stage 2, make image for server
FROM alpine:3

COPY --from=grabber $GOPATH/root/go/bin/rcon-cli /rcon-cli

# Install required packages
RUN apk add --no-cache bash jq curl wget openjdk21-jre-headless openjdk17-jre-headless openjdk8-jre-headless

# Copies script
COPY ./install-docker.sh /
RUN chmod +x /install-docker.sh

ENV SERVER_VERSION "1.20.4"
ENV SERVER_SOFTWARE "purpur"
ENV MAX_RAM "1G"
ENV MIN_RAM "1G"
ENV MANUAL_FILENAME ""

EXPOSE 25565
EXPOSE 19132

ENTRYPOINT ["/install-docker.sh"]
CMD ["stop"]