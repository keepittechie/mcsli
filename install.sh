#!/bin/bash

# Minecraft Server Installation Script
# Created by: Josh
# YouTube Channel: https://youtube.com/@KeepItTechie
# Blog: https://docs.keepittechie.com/

# Purpose:
# This script automates the installation and setup of a Minecraft server on Ubuntu Server 22.04.
# It simplifies the process of getting a Minecraft server up and running by handling tasks such as:
# - Installing necessary packages (Java, wget)
# - Opening ports for Minecraft and SSH
# - Downloading and setting up the Minecraft server JAR file
# - Accepting the Minecraft EULA
# - Setting file ownership and permissions for security
# - Creating and configuring a systemd service for easy server management

# This script was created to make it easier for Linux users and Minecraft enthusiasts to host
# their own Minecraft server. It minimizes the manual configuration required and provides a
# quick and efficient way to get a Minecraft server operational.

# Please review the script before running it on your server to ensure it meets your requirements
# and to understand the changes it will make. Customize the server.properties file as needed
# to configure your Minecraft server settings.

# Full details and instructions can be found on my GitHub repository:
# https://github.com/keepittechie/mcsli

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the Minecraft service account name
MINECRAFT_USER="minecraft"

# Set server jar name, can be whatever you like
SERVER_JAR="server.jar"

# Create the Minecraft service account
sudo adduser --system --no-create-home --group "$MINECRAFT_USER"

# Update and Install Necessary Packages
sudo add-apt-repository ppa:openjdk-r/ppa -y # Add Java PPA
sudo apt update # Refresh package lists
sudo apt install openjdk-17-jre-headless wget -y # Install Java and wget

# Detect Operating System
OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2)

# Install and configure firewall based on the operating system
if [ "$OS_ID" = "debian" ]; then
    echo "Debian system detected. Installing and configuring firewalld..."
    sudo apt install firewalld -y
    sudo systemctl start firewalld
    sudo systemctl enable firewalld

    sudo firewall-cmd --permanent --add-port=25565/tcp # Open port for Minecraft
    sudo firewall-cmd --permanent --add-service=ssh # Open port for SSH

    sudo firewall-cmd --reload
else
    echo "Ubuntu system detected. Configuring UFW..."
    sudo ufw allow 25565 # Open port for Minecraft
    sudo ufw allow OpenSSH # Open port for SSH

    # Enable UFW (Uncomplicated Firewall) with --force to automatically answer yes
    echo "Enabling firewall..."
    sudo ufw --force enable
fi

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft"

# Create Minecraft directory
sudo mkdir -p "$MINECRAFT_DIR" # Create the directory

# Download the specific Minecraft server version

# Ask the user about server version
read -p $'paper: Very widely used  (Will automatically install curl and jq if not installed already)\npurpur: Fork of paper; adds greater customization and some performance gains\nWhat server software would you like to use? ' SERVER_SOFTWARE
read -p $'What version of minecraft would you like to use? (ex. 1.20.4): ' SERVER_VERSION

if [ "$SERVER_SOFTWARE" = "paper" ]; then
    # Downloads curl and jq because of paper api limitations
    sudo apt install curl jq -y
    
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
fi
# Change to Minecraft directory
cd "$MINECRAFT_DIR"

# Run the server once to generate eula.txt and server.properties
echo -e "${GREEN}Starting Minecraft server to generate eula.txt and server.properties...${NC}"
sudo java -Xms1024M -Xmx1024M -jar "$SERVER_JAR" nogui

# Accept EULA by modifying eula.txt
echo -e "${GREEN}Accepting EULA...${NC}"
sudo sed -i 's/eula=false/eula=true/g' eula.txt

# Change ownership to minecraft user
echo -e "${GREEN}Changing ownership to $MINECRAFT_USER...${NC}"
sudo chown "$MINECRAFT_USER":"$MINECRAFT_USER" "$MINECRAFT_DIR"

# Change permissions
echo -e "${GREEN}Changing permissions...${NC}"
sudo chmod 750 "$MINECRAFT_DIR"

# Create a Service File for Minecraft Server
echo -e "${GREEN}Creating Minecraft service...${NC}"
echo "[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=$MINECRAFT_DIR
User=$MINECRAFT_USER
Nice=5
ExecStart=/usr/bin/java -Xms1024M -Xmx4G -jar $MINECRAFT_DIR/$SERVER_JAR nogui
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/minecraft.service

# Enable Minecraft Service
echo -e "${GREEN}Enabling Minecraft service...${NC}"
sudo systemctl enable minecraft.service

# Wait for 15 seconds
sleep 15
echo ""

# Instructions for modifying server.properties
echo -e "${GREEN}The 'server.properties' file contains all of the configuration options for your Minecraft server."
echo "You can find this file at: $MINECRAFT_DIR/server.properties"
echo "You should modify this file with your preferred settings before starting your server."
echo "A detailed list of all server properties can be found on the Official Minecraft Wiki.${NC}"
echo ""

# Instructions for starting the Minecraft service
echo -e "${GREEN}Please start the Minecraft service manually using the following command:"
echo "sudo systemctl start minecraft.service${NC}"
echo ""

# Get the current IP address of the server
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}The server IP address is: $SERVER_IP"
echo "You can connect to the Minecraft server using this IP and port 25565 (e.g., $SERVER_IP:25565)"
echo "Note: Its recommended to set a static IP address for the server.${NC}"
echo ""

echo -e "${GREEN}Minecraft server installation and setup complete!${NC}"
