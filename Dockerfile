# Created by SZ27 https://github.com/realSZ27
# This is my first time making a docker image, so feel free to make make changes

FROM alpine:3

# Copy the first Java installation (e.g., Eclipse Temurin)
COPY --from=eclipse-temurin:17 /opt/java/openjdk /opt/java/openjdk/17

# Copy the second Java installation (replace 'path/to/your/java' with the actual path)
COPY --from=eclipse-temurin:8 /opt/java/openjdk /opt/java/openjdk/8

# Copies script
COPY ./install-docker.sh /
RUN chmod +x /install-docker.sh

ENV SERVER_VERSION "1.20.4"
ENV SERVER_SOFTWARE "purpur"
ENV MAX_RAM "2G"
ENV MIN_RAM "1G"

EXPOSE 25565
EXPOSE 19132

CMD ["/install-docker.sh"]