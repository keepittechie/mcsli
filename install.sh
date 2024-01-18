#!/bin/bash

# Minecraft Server Installation Script
# Created by: Josh
# YouTube Channel: KeepItTechie
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

# Update and Install Necessary Packages
sudo add-apt-repository ppa:openjdk-r/ppa -y # Add Java PPA
sudo apt update # Refresh package lists
sudo apt install openjdk-17-jre-headless wget -y # Install Java and wget

# Open Ports for Minecraft and SSH
sudo ufw allow 25565 # Open port for Minecraft
sudo ufw allow OpenSSH # Open port for SSH

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft"

# Create Minecraft directory
sudo mkdir -p "$MINECRAFT_DIR" # Create the directory

# Download the specific Minecraft server version
SERVER_VERSION="1.20.4"
SERVER_JAR="minecraft_server.${SERVER_VERSION}.jar"
DOWNLOAD_URL="https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar"

echo -e "${GREEN}Downloading Minecraft server version $SERVER_VERSION...${NC}"
sudo wget -O "$MINECRAFT_DIR/$SERVER_JAR" "$DOWNLOAD_URL" || { echo -e "${RED}Download failed! Exiting.${NC}"; exit 1; }

# Change to Minecraft directory
cd "$MINECRAFT_DIR"

# Run the server once to generate eula.txt and server.properties
echo -e "${GREEN}Starting Minecraft server to generate eula.txt and server.properties...${NC}"
sudo java -Xms1024M -Xmx1024M -jar "$SERVER_JAR" nogui

# Accept EULA by modifying eula.txt
echo -e "${GREEN}Accepting EULA...${NC}"
sudo sed -i 's/eula=false/eula=true/g' eula.txt

# Change ownership to root
echo -e "${GREEN}Changing ownership to root...${NC}"
sudo chown root:root -R "$MINECRAFT_DIR"

# Change permissions
echo -e "${GREEN}Changing permissions...${NC}"
sudo chmod 700 -R "$MINECRAFT_DIR"

# Create a Service File for Minecraft Server
echo -e "${GREEN}Creating Minecraft service...${NC}"
echo "[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=$MINECRAFT_DIR
User=root
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
