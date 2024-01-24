from flask import Blueprint, render_template, jsonify
from mcstatus import JavaServer
import psutil
import time
import subprocess
import datetime

# Initialize a Blueprint for your views
views = Blueprint('views', __name__)

@views.route('/')
def home():
    """
    Render the home page of the dashboard.
    """
    return render_template("home.html")

def execute_command(command):
    """
    Execute a shell command and return the output.
    :param command: Shell command to be executed.
    :return: Output of the command or 'Unknown' in case of an error.
    """
    try:
        result = subprocess.check_output(command, shell=True, text=True)
        return result.strip()
    except subprocess.CalledProcessError:
        return "Unknown"

def get_network_stats_using_ip():
    """
    Gather network statistics using the 'ip' command.
    :return: Total bytes received and transmitted.
    """
    total_bytes_received = 0
    total_bytes_transmitted = 0

    try:
        # Execute the 'ip -s link' command
        output = subprocess.check_output(["ip", "-s", "link"], text=True)

        # Split the output by lines
        lines = output.split('\n')

        # Process each line to extract received and transmitted bytes
        for i, line in enumerate(lines):
            if "RX:" in line and i+1 < len(lines):
                rx_stats = lines[i + 1].split()
                total_bytes_received += int(rx_stats[0])
            if "TX:" in line and i+1 < len(lines):
                tx_stats = lines[i + 1].split()
                total_bytes_transmitted += int(tx_stats[0])

    except subprocess.CalledProcessError as e:
        return f"Error executing 'ip' command: {e}"

    return total_bytes_received, total_bytes_transmitted

    # Example Pull
    received, transmitted = get_network_stats_using_ip()
    print(f"Total Bytes Received: {received}")
    print(f"Total Bytes Transmitted: {transmitted}")

def get_active_connections():
    connections = psutil.net_connections()
    return len(connections)

def read_server_properties():
    properties = {}
    properties_file_path = '/opt/minecraft/server.properties'  # Update with the actual path to your server.properties file

    try:
        with open(properties_file_path, 'r') as file:
            for line in file:
                if line.strip() and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    properties[key.strip()] = value.strip()
    except FileNotFoundError:
        return {"error": "server.properties file not found."}
    except Exception as e:
        return {"error": f"An error occurred: {e}"}

    # Extract specific properties
    gamemode = properties.get('gamemode', 'Unknown')
    difficulty = properties.get('difficulty', 'Unknown')
    online_mode = properties.get('online-mode', 'Unknown')
    max_world_size = properties.get('max-world-size', 'Unknown')
    view_distance = properties.get('view-distance', 'Unknown')

    return {
        "gamemode": gamemode,
        "difficulty": difficulty,
        "online_mode": online_mode,
        "max_world_size": max_world_size,
        "view_distance": view_distance
    }


## Views Routes ##

@views.route('/get-stats')
def get_stats():
    """
    Fetch and return various system statistics.
    :return: JSON object containing system statistics.
    """
    cpu_usage = psutil.cpu_percent()
    memory_usage = psutil.virtual_memory()
    swap_usage = psutil.swap_memory()
    load_average = psutil.getloadavg()
    
    stats = {
        'cpu_usage': cpu_usage,
        'memory_usage': memory_usage.percent,
        'memory_used': memory_usage.used // (1024**2),
        'memory_total': memory_usage.total // (1024**2),
        'swap_usage': swap_usage.percent,
        'swap_used': swap_usage.used // (1024**2),
        'swap_total': swap_usage.total // (1024**2),
        'load_average': load_average
    }
    return jsonify(stats)

@views.route('/get-minecraft-status')
def get_minecraft_status():
    """
    Check and return the status of the Minecraft server.
    :return: JSON object containing Minecraft server status.
    """
    try:
        output = subprocess.check_output(['systemctl', 'is-active', 'minecraft.service'], text=True).strip()
        is_running = output == 'active'
    except subprocess.CalledProcessError:
        is_running = False

    server_info_file_path = "/opt/minecraft/server_info.txt"
    try:
        with open(server_info_file_path, "r") as file:
            lines = file.readlines()
            server_type = lines[0].split(':', 1)[1].strip() if len(lines) > 0 else "Unknown"
            mc_version = lines[1].split(':', 1)[1].strip() if len(lines) > 1 else "Unknown"
    except FileNotFoundError:
        server_type, mc_version = "Unknown", "Unknown"
    except Exception as e:
        server_type, mc_version = "Error", str(e)

    status = "Up" if is_running else "Down"
    return jsonify({"status": status, "server_type": server_type, "mc_version": mc_version})

@views.route('/get-system-info')
def get_system_info():
    """
    Fetch and return system information such as distribution and kernel version.
    :return: JSON object containing system information.
    """
    distro = execute_command("lsb_release -d | cut -f2")
    kernel_version = execute_command("uname -r")

    return jsonify({"distro": distro, "kernel_version": kernel_version})

@views.route('/get-server-uptime')
def get_server_uptime():
    try:
        # Execute the uptime command
        uptime_output = subprocess.check_output("uptime -p", shell=True, text=True)
        uptime = uptime_output.strip()
    except subprocess.CalledProcessError as e:
        uptime = f"Error: {e.output}"
    except Exception as e:
        uptime = f"Error: {e}"

    return jsonify({"uptime": uptime})

@views.route('/get-disk-space')
def get_disk_space():
    """
    Calculate and return disk space usage.
    :return: JSON object containing disk space usage information.
    """
    disk_usage = psutil.disk_usage('/')
    total_disk_space = disk_usage.total / (1024**3)  # Convert to GB
    used_disk_space = disk_usage.used / (1024**3)    # Convert to GB
    free_disk_space = disk_usage.free / (1024**3)    # Convert to GB

    return jsonify({
        "total_disk_space": round(total_disk_space, 2),
        "used_disk_space": round(used_disk_space, 2),
        "free_disk_space": round(free_disk_space, 2)
    })

@views.route('/get-network-usage')
def get_network_usage():
    received, transmitted = get_network_stats_using_ip()
    active_connections = get_active_connections()
    unusual_activity = "None"  # Placeholder

    return jsonify({
        "received_bytes": received,
        "transmitted_bytes": transmitted,
        "active_connections": active_connections,
        "unusual_activity": unusual_activity
    })

@views.route('/get-server-logs')
def get_server_logs():
    try:
        # Execute the journalctl command
        command = "journalctl -u minecraft.service --no-pager -n 50"  # Get the last 50 lines
        logs = subprocess.check_output(command, shell=True, text=True)
    except subprocess.CalledProcessError as e:
        logs = f"An error occurred while fetching logs: {e.output}"
    except Exception as e:
        logs = f"An error occurred: {e}"

    return jsonify({"logs": logs})

@views.route('/get-online-players')
def get_online_players():
    try:
        server = JavaServer.lookup("localhost:25565")
        status = server.status()
        online_players = status.players.online
        player_names = status.players.sample if status.players.sample else []
    except Exception as e:
        online_players = f"Error: {e}"
        player_names = []

    return jsonify({"online_players": online_players, "player_names": player_names})

@views.route('/get-world-info')
def get_world_info():
    world_info = read_server_properties()
    return jsonify(world_info)


if __name__ == '__main__':
    app.run(debug=True)
