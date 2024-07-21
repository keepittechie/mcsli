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

# Define log files
MINECRAFT_LOG="/var/log/minecraft_install.log"
WEBUI_LOG="/var/log/webui_install.log"

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft"

# Define the Minecraft service account name
MINECRAFT_USER="minecraft"

# Function to log installed packages
log_package_installation() {
    PACKAGE_NAME=$1
    LOG_FILE=$2
    echo "$PACKAGE_NAME" | sudo tee -a "$LOG_FILE" > /dev/null 2>&1
}

# Function for version comparisons
version() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

# Function to install Java
installJava() {
    # Asks the user for their preferred version
    while true; do
        read -r -p "What version of Minecraft would you like to use? (e.g., 1.20.4): " SERVER_VERSION

        # Select which Java version to use
        if [ "$(version "$SERVER_VERSION")" -ge "$(version "1.20.5")" ]; then
            sudo apt install -y openjdk-21-jre-headless > /dev/null 2>&1
            echo -e "${GREEN}Using Java version 21...${NC}"
            log_package_installation "openjdk-21-jre-headless" "$MINECRAFT_LOG"
            break
        elif [ "$(version "$SERVER_VERSION")" -ge "$(version "1.17")" ]; then
            sudo apt install -y openjdk-17-jre-headless > /dev/null 2>&1
            echo -e "${GREEN}Using Java version 17...${NC}"
            log_package_installation "openjdk-17-jre-headless" "$MINECRAFT_LOG"
            break
        elif [ "$(version "$SERVER_VERSION")" -ge "$(version "1.8")" ]; then
            sudo apt install -y openjdk-8-jre-headless > /dev/null 2>&1
            echo -e "${GREEN}Using Java version 8...${NC}"
            log_package_installation "openjdk-8-jre-headless" "$MINECRAFT_LOG"
            break
        else
            echo -e "${RED}Invalid version. Please enter a valid Minecraft version.${NC}"
        fi
    done
}

# Function to check if a Minecraft version is available
isVersionAvailable() {
    local version=$1
    local type=$2
    local url

    case $type in
        "paper")
            url="https://papermc.io/api/v2/projects/paper/versions/$version"
            ;;
        "purpur")
            url="https://api.purpurmc.org/v2/purpur/$version"
            ;;
        "vanilla")
            url=$(curl -sX GET "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg ver "$version" '.versions[] | select(.id == $ver) | .url')
            ;;
        "fabric")
            url="https://meta.fabricmc.net/v2/versions/loader/$version"
            ;;
    esac

    if [ -z "$url" ]; then
        return 1
    else
        return 0
    fi
}

# Function to install Minecraft JAR
installJar() {
    # Download the specific Minecraft server version
    while true; do
        # Present options to the user
        echo -e "${BLUE}1) paper:${NC} Very widely used (Will automatically install curl and jq if not installed already)"
        echo -e "${GREEN}2) purpur:${NC} Fork of paper; adds greater customization and some performance gains"
        echo -e "${RED}3) vanilla:${NC} Completely vanilla server from Mojang (Will automatically install curl and jq if not installed already)"
        echo -e "${YELLOW}4) fabric:${NC} Adds support for fabric mods (Will automatically install curl and jq if not installed already)"
        echo -e "${NC}5) manual:${NC} Bring your own server .jar"

        # Ask the user for their choice of server software
        read -r -p "Choose your server software (1 for paper, 2 for purpur, 3 for vanilla, etc.): " SERVER_SOFTWARE_CHOICE

        case $SERVER_SOFTWARE_CHOICE in
            1)
                SERVER_SOFTWARE="paper"
                sudo apt install -y curl jq > /dev/null 2>&1
                log_package_installation "curl" "$MINECRAFT_LOG"
                log_package_installation "jq" "$MINECRAFT_LOG"

                latest_build="$(curl -sX GET "https://papermc.io/api/v2/projects/paper/versions/$SERVER_VERSION/builds" -H 'accept: application/json' | jq '.builds[-1].build')"
                download_url="https://papermc.io/api/v2/projects/paper/versions/$SERVER_VERSION/builds/$latest_build/downloads/paper-$SERVER_VERSION-$latest_build.jar"
                SERVER_JAR="$MINECRAFT_DIR/paper-$SERVER_VERSION.jar"
                ;;
            2)
                SERVER_SOFTWARE="purpur"
                download_url="https://api.purpurmc.org/v2/purpur/$SERVER_VERSION/latest/download"
                SERVER_JAR="$MINECRAFT_DIR/purpur-$SERVER_VERSION.jar"
                ;;
            3)
                SERVER_SOFTWARE="vanilla"
                sudo apt install -y curl jq > /dev/null 2>&1
                log_package_installation "curl" "$MINECRAFT_LOG"
                log_package_installation "jq" "$MINECRAFT_LOG"

                download_url=$(curl -sX GET "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r --arg ver "$SERVER_VERSION" '.versions[] | select(.id == $ver) | .url' | xargs curl -s | jq -r '.downloads.server.url')
                SERVER_JAR="$MINECRAFT_DIR/minecraft_server.$SERVER_VERSION.jar"
                ;;
            4)
                SERVER_SOFTWARE="fabric"
                sudo apt install -y curl jq > /dev/null 2>&1
                log_package_installation "curl" "$MINECRAFT_LOG"
                log_package_installation "jq" "$MINECRAFT_LOG"

                while ! isVersionAvailable "$SERVER_VERSION" "fabric"; do
                    echo -e "${RED}Version $SERVER_VERSION is not available for fabric. Please enter another version.${NC}"
                    read -r -p "Enter a valid version for fabric: " SERVER_VERSION
                done

                loader_version=$(curl -sX GET "https://meta.fabricmc.net/v2/versions/loader/$SERVER_VERSION" | jq -r '[.[] | select(.loader.stable == true)] | sort_by(.loader.build) | last | .loader.version')
                installer_version=$(curl -sX GET "https://meta.fabricmc.net/v2/versions/installer" | jq -r '[.[] | select(.stable == true)] | sort_by(.version) | last | .version')
                download_url="https://meta.fabricmc.net/v2/versions/loader/$SERVER_VERSION/$loader_version/$installer_version/server/jar"
                SERVER_JAR="$MINECRAFT_DIR/fabric-$SERVER_VERSION.jar"
                ;;
            5)
                SERVER_JAR="$MINECRAFT_DIR/manual-$SERVER_VERSION.jar"
                echo "Please name your jar file \"manual-$SERVER_VERSION.jar\" and place it inside \"$MINECRAFT_DIR\" (Full path \"$MINECRAFT_DIR/manual-$SERVER_VERSION.jar\"). Make sure the minecraft user can access this file."
                while true; do
                    read -r -s -n 1 -p "Press any key once complete..."
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

        if [ "$SERVER_SOFTWARE_CHOICE" -ne 5 ]; then
            sudo mkdir -p "$MINECRAFT_DIR"
            curl -o "$SERVER_JAR" "$download_url" > /dev/null 2>&1

            if [ ! -f "$SERVER_JAR" ]; then
                echo -e "${RED}Failed to download the Minecraft server JAR file. Exiting.${NC}"
                exit 1
            fi
        fi

        break
    done

    echo "Minecraft Server Type: $SERVER_SOFTWARE" | sudo tee "$MINECRAFT_DIR/server_info.txt" > /dev/null 2>&1
    echo "Minecraft Server Version: $SERVER_VERSION" | sudo tee -a "$MINECRAFT_DIR/server_info.txt" > /dev/null 2>&1
}

# Function to install Minecraft server
install() {
    # Ensure that the Minecraft directory is defined
    if [ -z "$MINECRAFT_DIR" ]; then
        echo -e "${RED}Error: Minecraft directory is not defined.${NC}"
        exit 1
    fi

    # Set the default Minecraft user if not already set
    MINECRAFT_USER=${MINECRAFT_USER:-"minecraft"}

    # Check if the Minecraft user already exists
    if id "$MINECRAFT_USER" &>/dev/null; then
        echo "User $MINECRAFT_USER already exists. Using 'mcsli' instead."
        MINECRAFT_USER="mcsli"
    fi

    # Create the Minecraft service account with the chosen name
    echo "Creating the Minecraft service account: $MINECRAFT_USER"
    sudo adduser --system --no-create-home --group "$MINECRAFT_USER" > /dev/null 2>&1

    installJava

    sudo apt install -y wget > /dev/null 2>&1
    log_package_installation "wget" "$MINECRAFT_LOG" # Log wget installation

    # Configure firewall based on user choice
    if [ -n "$FIREWALL_CHOICE" ]; then
        if [ "$FIREWALL_CHOICE" -eq 1 ]; then
            echo "Installing and configuring UFW..."
            sudo apt install -y ufw > /dev/null 2>&1
            log_package_installation "ufw" "$MINECRAFT_LOG" # Log ufw installation
            sudo ufw allow 25565 > /dev/null 2>&1
            sudo ufw allow OpenSSH > /dev/null 2>&1
            sudo ufw --force enable > /dev/null 2>&1
        elif [ "$FIREWALL_CHOICE" -eq 2 ]; then
            echo "Installing and configuring firewalld..."
            sudo apt install -y firewalld > /dev/null 2>&1
            log_package_installation "firewalld" "$MINECRAFT_LOG" # Log firewalld installation
            sudo systemctl start firewalld > /dev/null 2>&1
            sudo systemctl enable firewalld > /dev/null 2>&1
            sudo firewall-cmd --permanent --add-port=25565/tcp > /dev/null 2>&1
            sudo firewall-cmd --permanent --add-service=ssh > /dev/null 2>&1
            sudo firewall-cmd --reload > /dev/null 2>&1
        else
            echo "Invalid choice. Exiting."
            exit 1
        fi
    fi

    sudo mkdir -p "$MINECRAFT_DIR"

    installJar

    sudo chown "$MINECRAFT_USER":"$MINECRAFT_USER" -R "$MINECRAFT_DIR"
    sudo chmod 755 -R "$MINECRAFT_DIR"

    cd "$MINECRAFT_DIR"

    echo -e "${GREEN}Starting Minecraft server to generate eula.txt and server.properties...${NC}"
    sudo -u "$MINECRAFT_USER" java -Xms1024M -Xmx1024M -jar "$SERVER_JAR" nogui > /dev/null 2>&1

    echo -e "${GREEN}Accepting EULA...${NC}"
    sudo sed -i 's/eula=false/eula=true/g' eula.txt

    echo -e "${GREEN}Creating Minecraft service...${NC}"
    echo "[Unit]
Description=Minecraft Server
After=network.target
[Service]
WorkingDirectory=$MINECRAFT_DIR
User=$MINECRAFT_USER
Nice=5
ExecStart=/usr/bin/java -Xms1024M -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar $SERVER_JAR nogui
Restart=on-failure
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/minecraft.service > /dev/null 2>&1

    echo -e "${GREEN}Enabling Minecraft service...${NC}"
    sudo systemctl enable minecraft.service > /dev/null 2>&1

    sleep 15
    echo ""

    echo -e "${GREEN}The 'server.properties' file contains all of the configuration options for your Minecraft server."
    echo "You can find this file at: $MINECRAFT_DIR/server.properties"
    echo "You should modify this file with your preferred settings before starting your server."
    echo "A detailed list of all server properties can be found on the Official Minecraft Wiki.${NC}"
    echo ""

    echo -e "${GREEN}Please start the Minecraft service manually using the following command:"
    echo "sudo systemctl start minecraft.service${NC}"
    echo ""

    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}The server IP address is: $SERVER_IP"
    echo "You can connect to the Minecraft server using this IP and port 25565 (e.g., $SERVER_IP:25565)"
    echo "Note: It's recommended to set a static IP address for the server.${NC}"
    echo ""
    echo -e "${GREEN}Minecraft server installation and setup complete!${NC}"
}

# Function to install WebUI
installWebUI() {
    echo -e "${GREEN}Installing mcsli_webui...${NC}"
    set -e

    sudo apt update > /dev/null 2>&1
    sudo apt install -y apache2 libapache2-mod-wsgi-py3 > /dev/null 2>&1
    log_package_installation "apache2" "$WEBUI_LOG"
    log_package_installation "libapache2-mod-wsgi-py3" "$WEBUI_LOG"

    VHOST_FILE="/etc/apache2/sites-available/mcsli-webui.conf"

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

    PORTS_FILE="/etc/apache2/ports.conf"

    if grep -q "Listen 5000" "$PORTS_FILE"; then
        echo "'Listen 5000' is already in $PORTS_FILE"
    else
        echo "Listen 5000" | sudo tee -a "$PORTS_FILE" > /dev/null 2>&1
        echo "'Listen 5000' added to $PORTS_FILE"
    fi

    echo "Choose a firewall to install:"
    echo "1) UFW"
    echo "2) firewalld"
    read -r -p "Enter your choice (1 for UFW, 2 for firewalld): " FIREWALL_CHOICE

    if [ "$FIREWALL_CHOICE" -eq 1 ]; then
        echo "Configuring UFW..."
        sudo apt install -y ufw > /dev/null 2>&1
        log_package_installation "ufw" "$WEBUI_LOG"
        sudo ufw allow 5000 > /dev/null 2>&1
    elif [ "$FIREWALL_CHOICE" -eq 2 ]; then
        echo "Configuring firewalld..."
        sudo apt install -y firewalld > /dev/null 2>&1
        log_package_installation "firewalld" "$WEBUI_LOG"
        sudo systemctl start firewalld > /dev/null 2>&1
        sudo systemctl enable firewalld > /dev/null 2>&1
        sudo firewall-cmd --permanent --add-port=5000/tcp > /dev/null 2>&1
        sudo firewall-cmd --reload > /dev/null 2>&1
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi

    ORIGINAL_USER="${SUDO_USER:-$USER}"
    MCSLI_WEBUI_DIR="/home/$ORIGINAL_USER/mcsli/mcsli_webui"

    if [ -d "$MCSLI_WEBUI_DIR" ]; then
        sudo cp -r "$MCSLI_WEBUI_DIR/" /var/www/mcsli_webui/ > /dev/null 2>&1
    else
        echo "The directory $MCSLI_WEBUI_DIR does not exist. Exiting."
        exit 1
    fi

    sudo chmod 755 -R /var/www/mcsli_webui
    sudo usermod -a -G adm www-data > /dev/null 2>&1

    sudo a2ensite mcsli-webui > /dev/null 2>&1
    sudo a2dissite 000-default > /dev/null 2>&1
    sudo a2enmod wsgi > /dev/null 2>&1
    sudo systemctl restart apache2 > /dev/null 2>&1

    echo "WebUI Setup complete."
}

# Function to uninstall applications
uninstall() {
    echo -e "${GREEN}Would you like to uninstall the Minecraft server or the webui?${NC}"
    echo "1) Minecraft server"
    echo "2) WebUI"
    read -r -p "Enter your choice (1 for Minecraft, 2 for WebUI): " UNINSTALL_CHOICE

    case $UNINSTALL_CHOICE in
        1)
            echo -e "${RED}Uninstalling Minecraft server...${NC}"
            while IFS= read -r package; do
                sudo apt remove -y "$package" > /dev/null 2>&1
            done < "$MINECRAFT_LOG"
            sudo rm -rf "$MINECRAFT_DIR"
            sudo rm -f "$MINECRAFT_LOG"
            sudo systemctl disable minecraft.service > /dev/null 2>&1
            sudo rm /etc/systemd/system/minecraft.service
            echo -e "${GREEN}Minecraft server uninstalled.${NC}"
            ;;
        2)
            echo -e "${RED}Uninstalling WebUI...${NC}"
            while IFS= read -r package; do
                sudo apt remove -y "$package" > /dev/null 2>&1
            done < "$WEBUI_LOG"
            sudo rm -rf /var/www/mcsli_webui
            sudo rm -f "$WEBUI_LOG"
            sudo a2dissite mcsli-webui > /dev/null 2>&1
            sudo systemctl restart apache2 > /dev/null 2>&1
            echo -e "${GREEN}WebUI uninstalled.${NC}"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

echo -e "${GREEN}Would you like to install or uninstall?${NC}"
echo "1) Install"
echo "2) Uninstall"
read -r -p "Enter your choice (1 for install, 2 for uninstall): " ACTION_CHOICE

case $ACTION_CHOICE in
    1)
        echo -e "${GREEN}Would you like to install the webui?${NC}"
        read -r -p "(y/N): " WEBUI_CHOICE
        case $WEBUI_CHOICE in
            y|Y|yes)
                installWebUI
                ;;
            *)
                echo -e "${GREEN}Not installing webui...${NC}"
                ;;
        esac

        if [ -d "$MINECRAFT_DIR" ]; then
            echo -e "${GREEN}$MINECRAFT_DIR already exists, updating server...${NC}"
            echo -e "${GREEN}Uninstalling other java versions...${NC}"
            echo -e "${YELLOW}Don't worry if you see 'Package 'openjdk-VERSION-jre-headless' is not installed, so not removed', this is normal${NC}"
            sudo apt remove openjdk-21-jre-headless openjdk-17-jre-headless openjdk-8-jre-headless > /dev/null 2>&1
            sudo rm -f "$MINECRAFT_LOG"
            installJava
            installJar
            echo -e "${GREEN}Done updating${NC}"
            echo "You can start the server with"
            echo "sudo systemctl start minecraft.service${NC}"
        else
            if [ -z "$FIREWALL_CHOICE" ]; then
                echo "Choose a firewall to install:"
                echo "1) UFW"
                echo "2) firewalld"
                read -r -p "Enter your choice (1 for UFW, 2 for firewalld): " FIREWALL_CHOICE
            fi
            echo -e "${GREEN}$MINECRAFT_DIR does not exist, doing first-time setup...${NC}"
            install
        fi
        ;;
    2)
        uninstall
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
