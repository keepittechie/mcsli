# Minecraft Server Linux Installer

## Introduction/Overview
This script is designed to automate the installation and setup of a Minecraft server on Ubuntu Server 22.04. It simplifies the process of getting a Minecraft server up and running by executing a series of commands to install necessary packages, configure the server, and set up a systemd service for easy management.

## Features
- Automatically adds the Java PPA and installs OpenJDK 17.
- Opens necessary ports for Minecraft and SSH.
- Downloads the specified version of the Minecraft server JAR file.
- Automatically accepts the Minecraft EULA.
- Sets file ownership and permissions for security.
- Creates a systemd service for the Minecraft server for easy starting, stopping, and restarting.
- Provides instructions for further customization and manual steps required after installation.

## Instructions on Using the Script
1. Clone the Repository:
Clone the repository containing the script to your server.

```bash
git clone [repository URL]
```
2. Navigate to the Script Directory:
Change to the directory containing the script.

```bash
cd [script directory]
```
3. Run the Installation Script:
Execute the install.sh script. The script must be run with root privileges.

```bash
sudo ./install.sh
```
4. Review and Customize server.properties:
After the script has completed, you can find the server.properties file in the Minecraft server directory (/opt/minecraft). Customize this file as needed based on your server preferences. Refer to the Official Minecraft Wiki for a detailed list of server properties.

5. Start the Minecraft Server:
Manually start the Minecraft server using the following command:

```bash
sudo systemctl start minecraft.service
```

## Important Notes
- Application Versions: The script installs OpenJDK 17 and downloads the Minecraft server version specified in the script.
- Updating the Minecraft Server JAR: The link to the Minecraft server JAR file will change over time as new versions are released. The script currently points to a specific version. Users are encouraged to check for the latest version and update the script accordingly.
- Review the Script: Always review the script's code before running it on your server to ensure it meets your requirements and to understand the changes it will make.
- server.properties File: The server.properties file is located in /opt/minecraft. Customize this file to configure your Minecraft server settings.
- Static IP Address: It is recommended to set a static IP address for your server to ensure that players can consistently connect to it.
- Security Considerations: The script makes changes to system configurations and opens network ports. Run the script in a secure and controlled environment.

## Contributing
Your contributions to improve the script or keep the Minecraft server version up-to-date are welcome. Please submit pull requests or issues to the repository.
