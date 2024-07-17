#!/bin/bash

# Minecraft Server Uninstallation and Cleanup Script
# Created by: Josh
# YouTube Channel: https://youtube.com/@KeepItTechie
# Blog: https://docs.keepittechie.com/

# Purpose:
# This script automates the uninstallation and cleanup of a Minecraft server on Ubuntu Server 22.04.
# It removes installed packages, deletes created directories and files, and undoes changes made during the installation process.

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define Minecraft server directory
MINECRAFT_DIR="/opt/minecraft"

# Define the Minecraft service account name
MINECRAFT_USER="minecraft"

# Function to stop and disable the Minecraft service
function stopMinecraftService {
    echo -e "${GREEN}Stopping and disabling Minecraft service...${NC}"
    sudo systemctl stop minecraft.service
    sudo systemctl disable minecraft.service
    sudo rm -f /etc/systemd/system/minecraft.service
    sudo systemctl daemon-reload
}

# Function to remove installed packages
function removePackages {
    echo -e "${GREEN}Removing installed packages...${NC}"
    sudo apt remove --purge -y openjdk-21-jre-headless openjdk-17-jre-headless openjdk-8-jre-headless wget curl jq apache2 libapache2-mod-wsgi-py3 firewalld ufw
    sudo apt autoremove -y
    sudo apt clean
}

# Function to delete Minecraft server files and directories
function deleteMinecraftFiles {
    echo -e "${GREEN}Deleting Minecraft server files and directories...${NC}"
    sudo rm -rf "$MINECRAFT_DIR"
}

# Function to delete the Minecraft service account
function deleteMinecraftUser {
    echo -e "${GREEN}Deleting Minecraft service account...${NC}"
    sudo deluser --system --group "$MINECRAFT_USER"
}

# Function to revert firewall changes
function revertFirewallChanges {
    if command -v ufw &>/dev/null; then
        echo -e "${GREEN}Reverting UFW firewall changes...${NC}"
        sudo ufw delete allow 25565
        sudo ufw delete allow OpenSSH
        sudo ufw --force disable
        sudo apt remove --purge -y ufw
    elif command -v firewall-cmd &>/dev/null; then
        echo -e "${GREEN}Reverting firewalld firewall changes...${NC}"
        sudo firewall-cmd --permanent --remove-port=25565/tcp
        sudo firewall-cmd --permanent --remove-service=ssh
        sudo firewall-cmd --reload
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo apt remove --purge -y firewalld
    fi
}

# Function to remove the web UI configuration and files
function removeWebUI {
    echo -e "${GREEN}Removing web UI configuration and files...${NC}"
    sudo a2dissite mcsli-webui
    sudo a2ensite 000-default
    sudo systemctl restart apache2
    sudo rm -rf /var/www/mcsli_webui
    sudo rm -f /etc/apache2/sites-available/mcsli-webui.conf
}

# Main function to execute the uninstallation steps
function uninstall {
    stopMinecraftService
    deleteMinecraftFiles
    deleteMinecraftUser
    revertFirewallChanges
    removePackages
    removeWebUI
    echo -e "${GREEN}Uninstallation and cleanup complete!${NC}"
}

# Prompt the user for confirmation
echo -e "${YELLOW}Are you sure you want to uninstall the Minecraft server and clean up everything?${NC}"
echo -e "${YELLOW}The following packages will be removed:${NC}"
echo -e "${BLUE}- openjdk-21-jre-headless${NC}"
echo -e "${BLUE}- openjdk-17-jre-headless${NC}"
echo -e "${BLUE}- openjdk-8-jre-headless${NC}"
echo -e "${BLUE}- wget${NC}"
echo -e "${BLUE}- curl${NC}"
echo -e "${BLUE}- jq${NC}"
echo -e "${BLUE}- apache2${NC}"
echo -e "${BLUE}- libapache2-mod-wsgi-py3${NC}"
echo -e "${BLUE}- firewalld${NC}"
echo -e "${BLUE}- ufw${NC}"
read -p "Type 'y' to proceed with the uninstallation or 'N' to cancel: " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    uninstall
else
    echo -e "${GREEN}Uninstallation cancelled.${NC}"
fi
