#!/bin/bash

# This is a modified version of the script, used in the docker image
# Modified by SZ27 https://github.com/realSZ27

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

JAVA_17_PATH=$PATH
JAVA_8_PATH=/opt/java/openjdk_8/bin/java

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft/"

# Set server jar name
SERVER_JAR=$MINECRAFT_DIR"server.jar"
echo $SERVER_JAR

# Create Minecraft directory
mkdir -p "$MINECRAFT_DIR" # Create the directory

# Download the specific Minecraft server version
if [ ! -e $MINECRAFT_DIR"server.jar" ]; then
    if [ "$SERVER_SOFTWARE" = "paper" ]; then
        # Get the build number of the most recent build
        latest_build="$(curl -sX GET "https://papermc.io/api/v2"/projects/"paper"/versions/"$SERVER_VERSION"/builds -H 'accept: application/json' | jq '.builds [-1].build')"
        # Construct download URL
        download_url="https://papermc.io/api/v2"/projects/"paper"/versions/"$SERVER_VERSION"/builds/"$latest_build"/downloads/"paper"-"$SERVER_VERSION"-"$latest_build".jar
        # Download file
        wget -O "$SERVER_JAR" "$download_url"
    elif [ "$SERVER_SOFTWARE" = "purpur" ]; then
        # Construct download URL
        download_url="https://api.purpurmc.org/v2/purpur/"$SERVER_VERSION"/latest/download"
        # Download file
        wget -O "$SERVER_JAR" "$download_url"
    elif [ "$SERVER_SOFTWARE" = "vanilla" ]; then
        # Get the download url from mojang
        download_url=$(curl -sX GET "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg ver "$SERVER_VERSION" '.versions[] | select(.id == $ver) | .url' | xargs curl -s | jq -r '.downloads.server.url')
        # Download file
        wget -O "$SERVER_JAR" "$download_url"
    fi
fi
# Write Minecraft server type and version to a text file
echo "Minecraft Server Type: $SERVER_SOFTWARE" | tee "$MINECRAFT_DIR/server_info.txt"
echo "Minecraft Server Version: $SERVER_VERSION" | tee -a "$MINECRAFT_DIR/server_info.txt"

# Change to Minecraft directory
cd "$MINECRAFT_DIR"


echo $JAVA_17_PATH

if [ ! -e $MINECRAFT_DIR"eula.txt" ]; then
    $JAVA_17_PATH" -Xms1024M -Xmx1024M -jar "$SERVER_JAR" nogui"
    # Accept EULA by modifying eula.txt
    echo -e "${GREEN}Accepting EULA...${NC}"
    echo $JAVA_HOME
    sed -i 's/eula=false/eula=true/g' eula.txt
fi
echo -e "${GREEN}Minecraft server installation and setup complete! Starting...${NC}"

cd $MINECRAFT_DIR
STARTUP_COMMAND="java -Xms"$MIN_RAM" -Xmx"$MAX_RAM" -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar "$SERVER_JAR" nogui"
# echo $STARTUP_COMMAND
