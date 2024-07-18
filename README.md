# Minecraft Server Linux Installer

![GitHub stars](https://img.shields.io/github/stars/keepittechie/mcsli?style=social)
![GitHub forks](https://img.shields.io/github/forks/keepittechie/mcsli?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/keepittechie/mcsli?style=social)
![GitHub repo size](https://img.shields.io/github/repo-size/keepittechie/mcsli)
![GitHub language count](https://img.shields.io/github/languages/count/keepittechie/mcsli)
![GitHub top language](https://img.shields.io/github/languages/top/keepittechie/mcsli)
![GitHub last commit](https://img.shields.io/github/last-commit/keepittechie/mcsli?color=red)

## Table of Contents
1. [Installing the Script](#installing-the-script)
2. [Uninstalling](#uninstalling)
3. [Docker Container](#using-the-docker-container)
4. [Updating](#updating)
5. [Connecting](#connecting)

## Introduction/Overview
This script automates the installation and setup of a Minecraft server on Ubuntu Server 22.04. It simplifies the process of getting a Minecraft server operational by handling tasks such as installing necessary packages, opening ports, downloading the server JAR file, accepting the Minecraft EULA, setting file ownership and permissions, and creating a systemd service for server management.

## Features
- Adds Java PPA and installs OpenJDK 21.
- Opens ports for Minecraft and SSH.
- Offers a choice of Minecraft server software: Paper, Purpur, Vanilla, or Fabric.
- Downloads the specified version of the selected Minecraft server JAR file.
- Automatically accepts the Minecraft EULA.
- Sets file ownership and permissions for security.
- Creates a systemd service for easy server management.
- Provides customization instructions for `server.properties`.

## Distributions Tested
- **Ubuntu Server 24.04**
- **Ubuntu Server 22.04**
- **Ubuntu Server 20.04**
- **Ubuntu Server 18.04**
- **Debian 11**

Docker image will work with any distro and windows

## Installing the Script

1. **Download the script:**  

Download the script to your server.

```bash
git clone https://github.com/keepittechie/mcsli.git
```
2. **Run the Installation Script:**

Execute the install.sh script. The script must be run with root privileges.

```bash
cd mcsli
sudo bash ./install.sh
```

*Note: If the script doesn't run, this could be that the script is not executable.*
```bash
chmod +x install.sh
```
*Run again:*
```bash
sudo bash ./install.sh
``` 
(Of course, you should [review it](https://github.com/keepittechie/mcsli/blob/main/install.sh) first)

<details>
<summary><b>3. Script Prompts and Answers:</b></summary>

**Prompt 1: Web UI Installation**
- **Prompt**: `Would you like to install the webui? (y/N):`
- **Options**:
  - `y` or `Y`: Yes, install the web UI
  - `N` or `n` (or just press Enter): No, do not install the web UI
- **Example Answer**: `y`

**Prompt 2: Minecraft Version**
- **Prompt**: `What version of Minecraft would you like to use? (e.g., 1.20.4):`
- **Example Answer**: `1.20.4`

**Prompt 3: Server Software Type**
- **Prompt**: `Choose your server software (1 for paper, 2 for purpur, 3 for vanilla, etc.):`
- **Options**:
  - `1`: Paper
  - `2`: Purpur
  - `3`: Vanilla
  - `4`: Fabric
  - `5`: Manual (bring your own server .jar)
- **Example Answer**: `1`

**Prompt 4: Firewall Installation**
- **Prompt**: `Choose a firewall to install (1 for UFW, 2 for firewalld):`
- **Options**:
  - `1`: UFW
  - `2`: firewalld
- **Example Answer**: `1`

</details>

4. **Review and Customize server.properties:**

After the script has completed, you can find the server.properties file in the Minecraft server directory (/opt/minecraft). Customize this file as needed based on your server preferences. Refer to the Official Minecraft Wiki for a detailed list of server properties.

5. **Start the Minecraft Server:**

Manually start the Minecraft server using the following command:

```bash
sudo systemctl start minecraft.service
```

6. **Access the mcsli_webui:**

To access the webui go to link:

```bash
http://localhost:5000
```
or
```bash
http://ip-address:5000
```

## Uninstalling

1. **Run the Uninstallation Script:**

Execute the install.sh script with the uninstall option. The script must be run with root privileges.

```bash
cd mcsli
sudo bash ./install.sh
```

<details>
<summary><b>2. Script Prompts and Answers:</b></summary>

**Prompt 1: Uninstall Minecraft Server or WebUI**
- **Prompt**: `Would you like to uninstall the Minecraft server or the webui?`
- **Options**:
  - `1`: Minecraft server
  - `2`: WebUI
- **Example Answer**: `1`

</details>

## Using the docker container

**Note: the docker container does not include the web ui. If you know a solution to this, please feel free to contribute**
1. Make sure you have [docker](https://docs.docker.com/engine/install) and [docker compose](https://docs.docker.com/compose/install/#scenario-two-install-the-compose-plugin) installed
2. Make a ``docker-compose.yml`` file with these contents. Change the values as desired:
```yaml
services:
  mcsli-docker:
    container_name: mcsli-docker
    image: ghcr.io/realsz27/mcsli:latest
    volumes:
      - ./config:/data/minecraft
    environment:
      - SERVER_SOFTWARE=purpur
      - SERVER_VERSION=1.21
      - MAX_RAM=1G
      - MIN_RAM=1G
    ports:
      - 25565:25565
```

3. Run ``docker compose up -d``

4. If and when you need to run a command on the server, you can run:
```bash
docker exec -it mcsli-docker /rcon-cli --port 25575 --password mcsli-docker
```
If you changed the rcon password (recommended) or container name, you will have to subsitute either (or both) of the ``mscli-docker``'s for those values

### Available config options:

variabe|options
---|---
SERVER_SOFTWARE|**purpur** (default), **paper**, **vanilla**, **fabric** (automatically uses the latest fabric loader avalible for your version), **manual** (```SERVER_JAR``` needed)
SERVER_VERSION|Any valid minecraft version (default, 1.20.4); **must be the full version, like *1.20.4***
MIN/MAX_RAM|Any valid java ram amount like **5G** (5 gigabytes) or **1024M** (1024 megabytes); (default 1G on both)
SERVER_JAR **Optional; only needed if you chose `manual` as your server software*|The filename of your supplied jar. This jar should be placed in the config directory it makes when you run it.


- Ports in docker are arranged ```host:container```, meaning that **you can only change the host port**.
- Same goes for volumes, you can change the *host* volume but not the *container* volume.

### Building
As long as you have ``Dockerfile`` and ``install-docker.sh`` in the same directory you are running the build on, it should work like any other docker image.

## Updating
If you run the script again, it will detect that the directory is already there and run the update process. It will then ask you for your minecraft version and server type and handle the rest for you.

## Connecting
You can connect to the minecraft server by putting the server's ip address into the game. But without port forwarding, a proxy, or a vpn, this will not work outside your own network. To fix this you could:
1. **Use a VPN:** There are many selfhosted options to go with, [WireGuard](https://www.wireguard.com/), [OpenVPN](https://openvpn.net/), [Netbird](https://netbird.io/). But the one that is the easiest, in my opinion, is [**Tailscale**](https://tailscale.com/). Specifically, the [Github community plan](https://tailscale.dev/blog/multi-user-tailnet-github-orgs). This allows you to invite your friends to your "tailnet" and play on your server with your *Tailscale* IP.
2. **Use a Proxy:** This is by far the easiest way to do it, and the easiest proxy service to use is probably [playit.gg](https://playit.gg/). Simply download the client on your server, create a tunnel for Java Minecraft, and it will provide you with a domain you can connect to.
3. **Port forward:** this can vary from router to router, look up online how to do it on yours. The only port you need to forward is 25565 unless you have your own config (ie. If you're using geyser). **This is the most insecure option, as anyone on the internet can see the open port, and potentially exploit it.** The chances of this are very low, but when there are better options out there, I would stay away from this one.

## Important Notes

- **Application Versions:** The script installs OpenJDK version based and the Minecraft server version specified in the script. Example (Minecraft 1.20.5 will install OpenJDK 21)
- **Updating the Minecraft Server JAR:** Check for the latest server versions and update the script as needed.
- **Review the Script:** Always review the script's code before running it on your server to ensure it meets your requirements and to understand the changes it will make.
- **Static IP Address:** It is recommended to set a static IP address for your server to ensure that players can consistently connect to it.
- **Security Considerations:** The script makes changes to system configurations and opens network ports. Run the script in a secure and controlled environment.

## Contributing

Your contributions to improve the script or keep the Minecraft server version up-to-date are welcome. Please submit pull requests or issues to the repository.
