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
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define the Minecraft service account name
MINECRAFT_USER="minecraft"

# Check if the Minecraft user already exists
if id "$MINECRAFT_USER" &>/dev/null; then
    echo "User $MINECRAFT_USER already exists. Using 'mcsli' instead."
    MINECRAFT_USER="mcsli"
fi

# Create the Minecraft service account with the chosen name
echo "Creating the Minecraft service account: $MINECRAFT_USER"
sudo adduser --system --no-create-home --group "$MINECRAFT_USER"

# Update and Install Necessary Packages
sudo apt update # Refresh package lists

function version {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

# Asks the user for their preferred version
read -p "What version of Minecraft would you like to use? (e.g., 1.20.4): " SERVER_VERSION

# Select which java version to use
if [ $(version $SERVER_VERSION) -ge $(version "1.20.5") ]; then
    sudo apt install openjdk-21-jre-headless -y
    echo "Using java version 21..."
elif [ $(version $SERVER_VERSION) -ge $(version "1.17") ]; then
    sudo apt install openjdk-17-jre-headless -y
    echo "Using java version 17..."
else
    sudo apt install openjdk-8-jre-headless -y
    echo "Using java version 8..."
fi
sudo apt install wget -y # Install Java and wget

# Detect Operating System
OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2)

# Install and configure firewall based on the operating system
if [ "$OS_ID" = "debian" ]; then
    # ... [Debian-specific firewall configuration logic] ...
    # Check if UFW is installed
    if command -v ufw &>/dev/null; then
        echo "Configuring UFW..."
        sudo ufw allow 25565 # Open port for Minecraft
        sudo ufw allow OpenSSH # Open port for SSH
        sudo ufw --force enable
    # Check if firewalld is installed
    elif command -v firewall-cmd &>/dev/null; then
        echo "Configuring firewalld..."
        sudo systemctl start firewalld
        sudo systemctl enable firewalld
        sudo firewall-cmd --permanent --add-port=25565/tcp # Open port for Minecraft
        sudo firewall-cmd --permanent --add-service=ssh # Open port for SSH
        sudo firewall-cmd --reload
    else
        # Prompt the user for their preferred firewall implementation
        echo "No firewall implementation detected. Choose a firewall to install:"
        echo "1) UFW"
        echo "2) firewalld"
        read -p "Enter your choice (1 for UFW, 2 for firewalld): " FIREWALL_CHOICE
        case $FIREWALL_CHOICE in
            1)
                echo "Installing and configuring UFW..."
                sudo apt install ufw -y
                sudo ufw allow 25565 # Open port for Minecraft
                sudo ufw allow OpenSSH # Open port for SSH
                sudo ufw --force enable
                ;;
            2)
                echo "Installing and configuring firewalld..."
                sudo apt install firewalld -y
                sudo systemctl start firewalld
                sudo systemctl enable firewalld
                sudo firewall-cmd --permanent --add-port=25565/tcp # Open port for Minecraft
                sudo firewall-cmd --permanent --add-service=ssh # Open port for SSH
                sudo firewall-cmd --reload
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
elif [ "$OS_ID" = "ubuntu" ]; then
    # ... [Ubuntu-specific firewall configuration logic] ...
    echo "Configuring UFW..."
    sudo ufw allow 25565 # Open port for Minecraft
    sudo ufw allow OpenSSH # Open port for SSH
    sudo ufw --force enable
else
    echo "This script only works on Debian and Ubuntu distributions. Exiting."
    exit 1
fi

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft"

# Create Minecraft directory
sudo mkdir -p "$MINECRAFT_DIR" # Create the directory

# Download the specific Minecraft server version
while true; do
    # Present options to the user
    echo -e "${BLUE}1) paper:${NC} Very widely used (Will automatically install curl and jq if not installed already)"
    echo -e "${GREEN}2) purpur:${NC} Fork of paper; adds greater customization and some performance gains"
    echo -e "${RED}3) vanilla:${NC} Completely vanilla server from Mojang (Will automatically install curl and jq if not installed already)"
    echo -e "${YELLOW}4) fabric:${NC} Adds support for fabric mods (Will automatically install curl and jq if not installed already)"
    echo -e "${NC}5) manual:${NC} Bring your own server .jar"

    # Ask the user for their choice of server software
    read -p "Choose your server software (1 for paper, 2 for purpur, 3 for vanilla, etc.): " SERVER_SOFTWARE_CHOICE

    case $SERVER_SOFTWARE_CHOICE in
        1)
            SERVER_SOFTWARE="paper"
            # Downloads curl and jq because of paper api limitations
            sudo apt install curl jq -y

            # Get the build number of the most recent build
            latest_build="$(curl -sX GET "https://papermc.io/api/v2/projects/paper/versions/$SERVER_VERSION/builds" -H 'accept: application/json' | jq '.builds[-1].build')"

            # Construct download URL
            download_url="https://papermc.io/api/v2/projects/paper/versions/$SERVER_VERSION/builds/$latest_build/downloads/paper-$SERVER_VERSION-$latest_build.jar"
            
            # Set SERVER_JAR after download
            SERVER_JAR="$MINECRAFT_DIR/paper-$SERVER_VERSION.jar"
            
            # Download file
            wget -O "$SERVER_JAR" "$download_url"
            
            # Verify Download
            if [ ! -f "$SERVER_JAR" ]; then
                echo -e "${RED}Failed to download the Minecraft server JAR file. Exiting.${NC}"
                exit 1
            fi

            break
            ;;
        2)
            SERVER_SOFTWARE="purpur"
            # Construct download URL
            download_url="https://api.purpurmc.org/v2/purpur/$SERVER_VERSION/latest/download"

            # Set SERVER_JAR after download
            SERVER_JAR="$MINECRAFT_DIR/purpur-$SERVER_VERSION.jar"

            # Download file
            wget -O "$SERVER_JAR" "$download_url"
            
            # Verify Download
            if [ ! -f "$SERVER_JAR" ]; then
                echo -e "${RED}Failed to download the Minecraft server JAR file. Exiting.${NC}"
                exit 1
            fi

            break
            ;;
        3)
            SERVER_SOFTWARE="vanilla"
            # Downloads curl and jq because of mojang api limitations
            sudo apt install curl jq -y

            # Get the download url from mojang
            download_url=$(curl -sX GET "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg ver "$SERVER_VERSION" '.versions[] | select(.id == $ver) | .url' | xargs curl -s | jq -r '.downloads.server.url')

            # Set SERVER_JAR after download
            SERVER_JAR="$MINECRAFT_DIR/minecraft_server.$SERVER_VERSION.jar"

            # Download file
            wget -O "$SERVER_JAR" "$download_url"
            
            # Verify Download
            if [ ! -f "$SERVER_JAR" ]; then
                echo -e "${RED}Failed to download the Minecraft server JAR file. Exiting.${NC}"
                exit 1
            fi

            break
            ;;
        4)
            SERVER_SOFTWARE="vanilla"
            # Downloads curl and jq because of mojang api limitations
            sudo apt install curl jq -y

            # Get the latest fabric loader version
            loader_version=$(curl -sX GET "https://meta.fabricmc.net/v2/versions/loader/$SERVER_VERSION" | jq -r '[.[] | select(.loader.stable == true)] | sort_by(.loader.build) | last | .loader.version')

            # Get the latest server installer version
            installer_version=$(curl -sX GET "https://meta.fabricmc.net/v2/versions/installer" | jq -r '[.[] | select(.stable == true)] | sort_by(.version) | last | .version')

            # Assemble download url
            download_url="https://meta.fabricmc.net/v2/versions/loader/$SERVER_VERSION/$loader_version/$installer_version/server/jar"

            # Set SERVER_JAR after download
            SERVER_JAR="$MINECRAFT_DIR/fabric-$SERVER_VERSION.jar"

            # Download file
            wget -O "$SERVER_JAR" "$download_url"

            # Verify Download
            if [ ! -f "$SERVER_JAR" ]; then
                echo -e "${RED}Failed to download the Minecraft server JAR file. Exiting.${NC}"
                exit 1
            fi

            break
            ;;
        5)
        SERVER_JAR="$MINECRAFT_DIR/manual-$SERVER_VERSION.jar"
        echo "Please name your jar file \"manual-$SERVER_VERSION.jar\" and place it inside \"$MINECRAFT_DIR\" (Full path \"$MINECRAFT_DIR/manual-$SERVER_VERSION.jar\"). Make sure the mcsli user can access this file."
        while true; do
            read -s -n 1 -p "Press any key once complete..."
            if [ -f "$SERVER_JAR" ]; then
                echo -e "${GREEN}Minecraft server JAR file found.${NC}"
                break
            else
                echo -e "${RED}Failed to find the Minecraft server JAR file. Try again.${NC}"
            fi
        done
        
        break
        ;;
        *)
            echo "Not a valid response, try again."
            ;;
    esac
done

# Set server jar name based on the user's choice
SERVER_JAR="$MINECRAFT_DIR/$SERVER_SOFTWARE-$SERVER_VERSION.jar"

# Write Minecraft server type and version to a text file
echo "Minecraft Server Type: $SERVER_SOFTWARE" | sudo tee "$MINECRAFT_DIR/server_info.txt"
echo "Minecraft Server Version: $SERVER_VERSION" | sudo tee -a "$MINECRAFT_DIR/server_info.txt"

# Change ownership to minecraft user
echo -e "${GREEN}Changing ownership to $MINECRAFT_USER...${NC}"
sudo chown "$MINECRAFT_USER":"$MINECRAFT_USER" -R "$MINECRAFT_DIR"

# Change permissions
echo -e "${GREEN}Changing permissions...${NC}"
sudo chmod 755 -R "$MINECRAFT_DIR"

# Change to Minecraft directory
cd "$MINECRAFT_DIR"

# Run the server once to generate eula.txt and server.properties
echo -e "${GREEN}Starting Minecraft server to generate eula.txt and server.properties...${NC}"
sudo -u "$MINECRAFT_USER" java -Xms1024M -Xmx1024M -jar "$SERVER_JAR" nogui

# Accept EULA by modifying eula.txt
echo -e "${GREEN}Accepting EULA...${NC}"
sudo sed -i 's/eula=false/eula=true/g' eula.txt

# Create a Service File for Minecraft Server
echo -e "${GREEN}Creating Minecraft service...${NC}"
echo "[Unit]
Description=Minecraft Server
After=network.target
[Service]
WorkingDirectory=$MINECRAFT_DIR
User=$MINECRAFT_USER
Nice=5
ExecStart=/usr/bin/java -Xms1024M -Xmx4G -jar $SERVER_JAR nogui
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
