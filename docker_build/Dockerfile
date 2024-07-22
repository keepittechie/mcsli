# Created by SZ27 https://github.com/realSZ27
# This is my first time making a docker image, so feel free to make make changes

# Stage 1: Build and get rcon-cli
FROM golang:1.22.5-alpine3.20 AS builder

# Install necessary build dependencies
RUN apk add --no-cache git

# Install rcon-cli
RUN go install github.com/itzg/rcon-cli@latest

# Stage 2: Create image for Minecraft server
FROM alpine:3.20

# Copy rcon-cli from the builder stage
COPY --from=builder /go/bin/rcon-cli /usr/local/bin/rcon-cli

# Install required packages
RUN apk add --no-cache bash jq curl wget openjdk17-jre-headless openjdk8-jre

# Create a non-root user
RUN addgroup -S minecraft && adduser -S -G minecraft minecraft

# Copy the installation script and set permissions
COPY ./install-docker.sh /install-docker.sh
RUN chmod +x /install-docker.sh

# Set environment variables
ENV SERVER_VERSION="1.21"
ENV SERVER_SOFTWARE="purpur"
ENV MAX_RAM="1G"
ENV MIN_RAM="1G"

# Expose the necessary ports
EXPOSE 25565
EXPOSE 19132

# Add labels for metadata
LABEL maintainer="keepittechie@gmail.com"
LABEL version="1.21"
LABEL description="Minecraft server running Purpur 1.21"

# Set the entrypoint to the installation script
ENTRYPOINT ["/install-docker.sh"]

# Default command (can be overridden by user)
CMD ["stop"]
