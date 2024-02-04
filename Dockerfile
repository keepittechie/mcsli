# Created by SZ27 https://github.com/realSZ27
# This is my first time making a docker image, so feel free to make make changes

FROM alpine:3
LABEL org.opencontainers.image.source="https://github.com/realSZ27/mcsli"

# Install required packages
RUN apk add --no-cache bash jq curl wget openjdk17 openjdk8

# Copy rcon client
COPY --from=outdead/rcon /rcon /rcon

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