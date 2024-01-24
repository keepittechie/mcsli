# Minecraft Server Linux Installer

![GitHub stars](https://img.shields.io/github/stars/keepittechie/mcsli?style=social)
![GitHub forks](https://img.shields.io/github/forks/keepittechie/mcsli?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/keepittechie/mcsli?style=social)
![GitHub repo size](https://img.shields.io/github/repo-size/keepittechie/mcsli)
![GitHub language count](https://img.shields.io/github/languages/count/keepittechie/mcsli)
![GitHub top language](https://img.shields.io/github/languages/top/keepittechie/mcsli)
![GitHub last commit](https://img.shields.io/github/last-commit/keepittechie/mcsli?color=red)

## Introduction/Overview
This script automates the installation and setup of a Minecraft server on Ubuntu Server 22.04. It simplifies the process of getting a Minecraft server operational by handling tasks such as installing necessary packages, opening ports, downloading the server JAR file, accepting the Minecraft EULA, setting file ownership and permissions, and creating a systemd service for server management.

## Features
- Adds Java PPA and installs OpenJDK 17.
- Opens ports for Minecraft and SSH.
- Offers a choice of Minecraft server software: Paper, Purpur, or Vanilla.
- Downloads the specified version of the selected Minecraft server JAR file.
- Automatically accepts the Minecraft EULA.
- Sets file ownership and permissions for security.
- Creates a systemd service for easy server management.
- Provides customization instructions for `server.properties`.

## Distributions Tested
- **Ubuntu Server 22.04**
- **Ubuntu Server 20.04**
- **Ubuntu Server 18.04**
- **Debian 11**

## Instructions on Using the 'install.sh' Script
1. **Clone the Repository:**  

Clone the repository containing the script to your server.
   
```bash
   git clone https://github.com/keepittechie/mcsli.git
```
2. **Navigate to the Script Directory:**

Change to the directory containing the script.

```bash
cd ./mcsli
```
3. **Run the Installation Script:**

Execute the install.sh script. The script must be run with root privileges.

```bash
sudo bash ./install.sh
```
4. **Review and Customize server.properties:**

After the script has completed, you can find the server.properties file in the Minecraft server directory (/opt/minecraft). Customize this file as needed based on your server preferences. Refer to the Official Minecraft Wiki for a detailed list of server properties.

5. **Start the Minecraft Server:**

Manually start the Minecraft server using the following command:

```bash
sudo systemctl start minecraft.service
```

## Instructions on Using the 'install_full.sh' Script

This script will install both mcsli & mcsli_webui.

1. **Clone the Repository:**  

Clone the repository containing the script to your server.
   
```bash
   git clone https://github.com/keepittechie/mcsli.git
```
2. **Navigate to the Script Directory:**

Change to the directory containing the script.

```bash
cd ./mcsli
```
3. **Run the Installation Script:**

Execute the install_full.sh script. The script must be run with root privileges.

```bash
sudo bash ./install_full.sh
```
4. **Review and Customize server.properties:**

After the script has completed, you can find the server.properties file in the Minecraft server directory (/opt/minecraft). Customize this file as needed based on your server preferences. Refer to the Official Minecraft Wiki for a detailed list of server properties.

5. **Start the Minecraft Server:**

Manually start the Minecraft server using the following command:

```bash
sudo systemctl start minecraft.service
```

5. **Access the mcsli_webui:**

To access the webui goto link:

```bash
http://localhost/5000
```
or
```bash
http://ip-address/5000
```

![mcsli_webui](mcsli_webui.png)
<img src="mcsli_webui.png" width="300">

## Important Notes

- **Application Versions:** The script installs OpenJDK 17 and downloads the Minecraft server version specified in the script.
- **Updating the Minecraft Server JAR:** Check for the latest server versions and update the script as needed.
- **Review the Script:** Always review the script's code before running it on your server to ensure it meets your requirements and to understand the changes it will make.
- **Static IP Address:** It is recommended to set a static IP address for your server to ensure that players can consistently connect to it.
- **Security Considerations:** The script makes changes to system configurations and opens network ports. Run the script in a secure and controlled environment.

## Contributing

Your contributions to improve the script or keep the Minecraft server version up-to-date are welcome. Please submit pull requests or issues to the repository.
