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

# Create the Minecraft service account
sudo adduser --system --no-create-home --group "$MINECRAFT_USER"

# Update and Install Necessary Packages
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
while true; do
    # Present options to the user
    echo -e "${BLUE}1) paper:${NC} Very widely used (Will automatically install curl and jq if not installed already)"
    echo -e "${GREEN}2) purpur:${NC} Fork of paper; adds greater customization and some performance gains"
    echo -e "${RED}3) vanilla:${NC} Completely vanilla server from Mojang (Will automatically install curl and jq if not installed already)"

    # Ask the user for their choice of server software
    read -p "Choose your server software (1 for paper, 2 for purpur, 3 for vanilla): " SERVER_SOFTWARE_CHOICE
    read -p "What version of Minecraft would you like to use? (e.g., 1.20.4): " SERVER_VERSION

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

echo -e "${GREEN}Installing mcsli_webui...${NC}"
# Exit on any error
set -e

# Update Server and Install Apache2
sudo apt update
sudo apt install -y apache2 libapache2-mod-wsgi-py3

# Define the path for the Apache virtual host configuration file
VHOST_FILE="/etc/apache2/sites-available/mcsli-webui.conf"

# Write the virtual host configuration to the file
sudo bash -c "cat > $VHOST_FILE" <<EOF
<VirtualHost *:5000>
    ServerName localhost
    WSGIDaemonProcess mcsli_webui python-home=/var/www/mcsli_webui/venv user=www-data group=www-data threads=5
    WSGIScriptAlias / /var/www/mcsli_webui/mcsliapp.wsgi

    <Directory /var/www/mcsli_webui>
        WSGIProcessGroup mcsli_webui
        WSGIApplicationGroup %{GLOBAL}
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Virtual host configuration file created at $VHOST_FILE"

# Define the path for the Apache ports configuration file
PORTS_FILE="/etc/apache2/ports.conf"

# Check if 'Listen 5000' already exists in the file
if grep -q "Listen 5000" "$PORTS_FILE"; then
    echo "'Listen 5000' is already in $PORTS_FILE"
else
    # Append 'Listen 5000' to the file
    echo "Listen 5000" | sudo tee -a "$PORTS_FILE"
    echo "'Listen 5000' added to $PORTS_FILE"
fi

# Open Port
sudo ufw allow 5000

# Create Website Directory
ORIGINAL_USER="${SUDO_USER:-$USER}"

# Construct the path to the mcsli_webui directory
MCSLI_WEBUI_DIR="/home/$ORIGINAL_USER/mcsli/mcsli_webui"

if [ -d "$MCSLI_WEBUI_DIR" ]; then
    sudo cp -r "$MCSLI_WEBUI_DIR/" /var/www/mcsli_webui/
else
    echo "The directory $MCSLI_WEBUI_DIR does not exist. Exiting."
    exit 1
fi

# Edit Permissions
sudo chmod 755 -R /var/www/mcsli_webui
sudo usermod -a -G adm www-data

# Enable the Site and Restart Apache
sudo a2ensite mcsli-webui
sudo a2dissite 000-default
sudo a2enmod wsgi
sudo systemctl restart apache2

echo "WebUI Setup complete."

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
echo "You can connect to the WebUI using this IP and port 5000 (e.g., $SERVER_IP:5000)"
echo "Note: Its recommended to set a static IP address for the server.${NC}"
echo ""
echo -e "${GREEN}Minecraft server installation and setup complete!${NC}"