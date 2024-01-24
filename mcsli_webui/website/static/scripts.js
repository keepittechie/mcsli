    function updateProgressBar(barId, percentage) {
        var bar = document.querySelector(`#${barId} > div`);
        bar.style.width = `${percentage}%`;
    }

    function fetchAndUpdateStats() {
        fetch('/get-stats')
            .then(response => response.json())
            .then(data => {
                document.getElementById('cpu-usage').textContent = data.cpu_usage;
                updateProgressBar('cpu-bar', data.cpu_usage);

                document.getElementById('memory-usage').textContent = data.memory_usage;
                document.getElementById('memory-used').textContent = (data.memory_used / 1024).toFixed(2); // GB
                document.getElementById('memory-total').textContent = (data.memory_total / 1024).toFixed(2); // GB

                document.getElementById('swap-usage').textContent = data.swap_usage;
                document.getElementById('swap-used').textContent = (data.swap_used / 1024).toFixed(2); // GB
                document.getElementById('swap-total').textContent = (data.swap_total / 1024).toFixed(2); // GB

                document.getElementById('load-average').textContent = `${data.load_average[0].toFixed(2)}, ${data.load_average[1].toFixed(2)}, ${data.load_average[2].toFixed(2)}`;
            })
            .catch(error => console.error('Error fetching stats:', error));
    }

    function fetchAndUpdateSystemInfo() {
        fetch('/get-system-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('server-distribution').textContent = 'Distribution: ' + data.distro;
                document.getElementById('server-version').textContent = 'Kernel Version: ' + data.kernel_version;
            })
            .catch(error => console.error('Error fetching system info:', error));
    }
    // Fetch and update stats and system info every 2 seconds
    setInterval(fetchAndUpdateStats, 2000);
    setInterval(fetchAndUpdateSystemInfo, 2000);
    
    function fetchAndUpdateServerUptime() {
        fetch('/get-server-uptime')
            .then(response => response.json())
            .then(data => {
                document.getElementById('server-uptime').textContent = data.uptime;
            })
            .catch(error => console.error('Error fetching server uptime:', error));
    }
    // Fetch and update server uptime periodically
    setInterval(fetchAndUpdateServerUptime, 10000);  // every 10 seconds    


    // Server Status Container
    // Fetch and update server status every 2 seconds
    function fetchAndUpdateServerStatus() {
        fetch('/get-minecraft-status')
            .then(response => response.json())
            .then(data => {
                const statusLabelUp = document.querySelector('label[for="status-up"]');
                const statusLabelDown = document.querySelector('label[for="status-down"]');
                
                document.getElementById('server-type').textContent = data.server_type;
                document.getElementById('mc-version').textContent = data.mc_version;
                document.getElementById('server-status').textContent = data.status;
                document.getElementById('status-up').checked = data.status === "Up";
                document.getElementById('status-down').checked = data.status === "Down";

                // Update label colors based on status
                if (data.status === "Up") {
                    statusLabelUp.style.color = "lime";
                    statusLabelDown.style.color = "white";
                } else {
                    statusLabelUp.style.color = "white";
                    statusLabelDown.style.color = "red";
                }
            })
            .catch(error => console.error('Error fetching server status:', error));
    }
    // Fetch and update server status every 2 seconds
    setInterval(fetchAndUpdateServerStatus, 2000);

    function updateDiskSpaceProgressBar(used, total) {
        var percentageUsed = (used / total) * 100;
        var diskSpaceBar = document.querySelector('#disk-space-bar > div');
        diskSpaceBar.style.width = `${percentageUsed.toFixed(2)}%`;
    }
    // END

    // Disk Usage Container
    function fetchAndUpdateDiskSpace() {
        fetch('/get-disk-space')
            .then(response => response.json())
            .then(data => {
                document.getElementById('total-disk-space').textContent = data.total_disk_space.toFixed(2);
                document.getElementById('used-disk-space').textContent = data.used_disk_space.toFixed(2);
                document.getElementById('free-disk-space').textContent = data.free_disk_space.toFixed(2);
                updateDiskSpaceProgressBar(data.used_disk_space, data.total_disk_space);
            })
            .catch(error => {
                console.error('Error fetching disk space info:', error);
            });
    }
    // Set an interval to refresh the disk space information
    setInterval(fetchAndUpdateDiskSpace, 2000); // Refresh every 60 seconds
    // END

    // Network Usage Container
    function fetchAndUpdateNetworkUsage() {
        fetch('/get-network-usage')
            .then(response => response.json())
            .then(data => {
                document.getElementById('bandwidth-usage').innerHTML = data.bandwidth_usage;
                document.getElementById('active-connections').textContent = data.active_connections;
                document.getElementById('unusual-activity').textContent = data.unusual_activity;
            })
            .catch(error => console.error('Error fetching network usage info:', error));
    }
    
    // Fetch and update network usage information every 2 seconds
    setInterval(fetchAndUpdateNetworkUsage, 2000);
    
    
    // Network Chart Container
    let networkTrafficChart;
    let networkTrafficChartData = {
        labels: [],
        datasets: [{
            label: 'Network Traffic',
            data: [],
            borderColor: 'rgb(75, 192, 192)',
            tension: 0.1
        }]
    };
    
    function setupNetworkTrafficChart() {
        const ctx = document.getElementById('networkTrafficChart').getContext('2d');
        networkTrafficChart = new Chart(ctx, {
            type: 'line',
            data: networkTrafficChartData,
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
    
    function updateNetworkTrafficChart(newData) {
        networkTrafficChartData.labels.push(newData.timestamp);
        networkTrafficChartData.datasets[0].data.push(newData.traffic);
    
        if (networkTrafficChartData.labels.length > 20) {
            networkTrafficChartData.labels.shift();
            networkTrafficChartData.datasets[0].data.shift();
        }
    
        networkTrafficChart.update();
    }

    function fetchNetworkTrafficData() {
        fetch('/get-network-usage')
            .then(response => response.json())
            .then(data => {
                // Update the network traffic chart
                updateNetworkTrafficChart({
                    timestamp: new Date().toLocaleTimeString(),
                    traffic: data.received_bytes / 1024  // Convert to KB and update the chart
                });
    
                // Convert bytes to kilobytes (KB) and format for display
                const formattedReceived = `${(data.received_bytes / 1024).toFixed(2)} KB`;
                const formattedTransmitted = `${(data.transmitted_bytes / 1024).toFixed(2)} KB`;
                const bandwidthUsageText = `Received: ${formattedReceived}<br>Transmitted: ${formattedTransmitted}`;
    
                // Update the Network Usage container
                document.getElementById('bandwidth-usage').innerHTML = bandwidthUsageText;
                document.getElementById('active-connections').textContent = data.active_connections;
                document.getElementById('unusual-activity').textContent = data.unusual_activity;
            })
            .catch(error => console.error('Error fetching network usage info:', error));
    }        

    // Initialize and fetch data
    document.addEventListener('DOMContentLoaded', function() {
        setupNetworkTrafficChart();
        setInterval(fetchNetworkTrafficData, 2000); // Fetch data every 2 seconds
    });
    // END

    // Server Logs Container
    function fetchAndUpdateServerLogs() {
        fetch('/get-server-logs')
            .then(response => response.json())
            .then(data => {
                const serverLogsElement = document.getElementById('server-logs');
                const isScrolledToBottom = serverLogsElement.scrollHeight - serverLogsElement.clientHeight <= serverLogsElement.scrollTop + 1;
    
                serverLogsElement.textContent = data.logs;
    
                if (isScrolledToBottom) {
                    serverLogsElement.scrollTop = serverLogsElement.scrollHeight;
                }
            })
            .catch(error => console.error('Error fetching server logs:', error));
    } 
    document.addEventListener('DOMContentLoaded', function() {
        // Fetch and update server logs periodically (e.g., every 10 seconds)
        setInterval(fetchAndUpdateServerLogs, 10000);
        // Scroll server logs to the bottom initially
        const serverLogsElement = document.getElementById('server-logs');
        serverLogsElement.scrollTop = serverLogsElement.scrollHeight;
    });
    // END

    // Players Online Container
    function fetchAndUpdateOnlinePlayers() {
        fetch('/get-online-players')
            .then(response => response.json())
            .then(data => {
                document.getElementById('online-players').textContent = data.online_players;
                
                // Update player names
                const playerNamesDiv = document.getElementById('player-names');
                playerNamesDiv.innerHTML = '';  // Clear existing names
                data.player_names.forEach(player => {
                    const playerElement = document.createElement('div');
                    playerElement.textContent = player.name;
                    playerNamesDiv.appendChild(playerElement);
                });
            })
            .catch(error => console.error('Error fetching online players:', error));
    }
    
    // Fetch and update online players count and names periodically
    setInterval(fetchAndUpdateOnlinePlayers, 10000);  // every 10 seconds
    // END

    // World Info Container
    function fetchAndUpdateWorldInfo() {
        fetch('/get-world-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('gamemode').textContent = data.gamemode;
                document.getElementById('difficulty').textContent = data.difficulty;
                document.getElementById('online-mode').textContent = data.online_mode;
                document.getElementById('max-world-size').textContent = data.max_world_size;
                document.getElementById('view-distance').textContent = data.view_distance;
            })
            .catch(error => console.error('Error fetching world info:', error));
    }
    
    // Fetch and update world information periodically
    setInterval(fetchAndUpdateWorldInfo, 10000);  // every 10 seconds
    