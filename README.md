# 🏠 Homelab Quick Setup

**Modular self-hosted services deployment with one-command setup**

Transform your home server into a complete monitoring and service stack in minutes. From basic observability to full-featured homelab with DNS filtering, dashboards, and IoT integration.

**⚠️ IMPORTANT**: All port assignments avoid conflicts with existing services (LVDA on ports 8080, 3001).

---

## 🚀 Quick Start

### 1. Setup Storage (One-time)
```bash
# Configure persistent storage for metrics data
sudo make setup-usb
```

### 2. Choose Your Setup
```bash
# Show all available commands and safe port assignments
make help

# Quick starter: Core observability + dashboard
make homelab-starter

# Complete homelab: Monitoring + Network + Apps (no IoT)
make homelab-complete  

# Everything including IoT/Weather Station
make iot-complete

# Build gradually
make observability    # Start with Grafana + Prometheus
make monitoring      # Add system monitoring + alternative dashboards
make network         # Add Pi-hole + proxy management
make apps           # Add dashboard applications
make mqtt           # Add IoT/weather station support
```

---

## 🏗️ Modular Architecture

### 🔧 **Core Stacks** (`make [stack]`)

| Stack | Services | Use Case | Command |
|-------|----------|----------|---------|
| **observability** | Prometheus + Grafana + Perses | Metrics database & visualization | `make observability` |
| **monitoring** | + cAdvisor + Node Exporter | System metrics collection | `make monitoring` |
| **network** | Pi-hole + Nginx Proxy Manager | DNS filtering + SSL management | `make network` |
| **apps** | Glance | Dashboard applications | `make apps` |
| **mqtt** | MQTT Server + Bridge | IoT & weather station data | `make mqtt` |

### 📦 **Quick Presets** (`make [preset]`)

| Preset | Description | Includes | Best For |
|--------|-------------|----------|----------|
| **homelab-starter** | Basic setup | Observability + Glance | Getting started |
| **homelab-complete** | Full homelab | All except IoT/MQTT | Complete home server |
| **weather-station** | IoT focused | Observability + MQTT | Sensor monitoring |
| **iot-complete** | Everything | All services | Full-featured setup |

---

## 🔌 Service Access (LVDA-Conflict-Free)

| Service | URL | Purpose | Notes |
|---------|-----|---------|-------|
| **🔵 Core Services** ||||
| Grafana | http://localhost:3005 | Metrics visualization | Login: admin/admin |
| Prometheus | http://localhost:9090 | Time-series database | Metrics collection |
| Perses | http://localhost:8082 | GitOps dashboards | **Safe: 8082 ≠ 8080** |
| **🟡 Monitoring Services** ||||
| cAdvisor | http://localhost:8081 | Container monitoring | **Safe: 8081 ≠ 8080** |
| Node Exporter | http://localhost:9100 | Host system metrics | System resources |
| **🟢 Network Services** ||||
| Pi-hole | http://localhost:8083 | DNS ad-blocking | **Safe: 8083 ≠ 8080** |
| Pi-hole DNS | localhost:5053 | DNS server | **Safe: 5053 ≠ 53** |
| Nginx Proxy | http://localhost:8084 | SSL/Proxy mgmt | **Safe: 8084 ≠ 8080** |
| **🟣 Applications** ||||
| Glance | http://localhost:8085 | System overview | **Safe: 8085 ≠ 8080** |
| **🔴 IoT Services** ||||
| MQTT Metrics | http://localhost:8888 | Sensor health/metrics | Weather station only |
| MQTT Server | localhost:1883 | IoT message broker | TCP connection |

**🛡️ Protected Ports**: 8080 (LVDA Frontend), 3001 (LVDA Backend) - **Never used**

---

## 💡 Usage Examples

### Start Simple & Scale
```bash
# 1. Basic observability
make observability
# Access: Grafana (3005), Prometheus (9090), Perses (8082)

# 2. Add system monitoring  
make monitoring
# Access: +cAdvisor (8081), Node Exporter (9100)

# 3. Add network services
make network  
# Access: +Pi-hole (8083), Proxy (8084)

# 4. Add applications
make apps
# Access: +Glance (8085)
```

### Specific Use Cases
```bash
# Just want Pi-hole DNS filtering
make pihole-only

# Just want Grafana monitoring
make grafana-only

# Weather station with metrics
make weather-station

# Complete homelab (no IoT)
make homelab-complete
```

### Development & Testing
```bash
# View status of all services
make status

# View logs
make logs SERVICE=prometheus

# Clean shutdown
make clean

# Development mode with live reload
make dev-observability
```

---

## 📊 What You Get

### 🔍 **Observability & Monitoring**
- **Prometheus**: Time-series metrics database with persistent USB storage
- **Grafana**: Rich visualization dashboards with pre-configured data sources
- **cAdvisor**: Container resource monitoring (CPU, memory, network)
- **Node Exporter**: Host system metrics (disk, network, processes)
- **Perses**: GitOps-native dashboards with dashboard-as-code

### 🌐 **Network & Security**
- **Pi-hole**: DNS-level ad blocking and network monitoring
- **Nginx Proxy Manager**: SSL termination and reverse proxy with web UI
- **Custom DNS**: Conflict-free DNS on port 5053

### 📱 **Applications & Dashboards**
- **Glance**: At-a-glance system overview dashboard
- **Health Checks**: Built-in health monitoring for all services

### 🌡️ **IoT & Weather Station**
- **MQTT Server**: Lightweight message broker for sensor data
- **MQTT-Prometheus Bridge**: Resilient Go app with automatic reconnection
- **Arduino Integration**: Weather station with temperature and wind sensors

---

## ⚙️ Configuration

### Environment Variables (IoT/Weather Station)
```bash
# Customize MQTT settings
export MQTT_BROKER_URL="tcp://mqtt-server:1883"
export MQTT_TOPICS="sensor/temp1,sensor/temp2"
export METRICS_PORT="8888"
export RECONNECT_DELAY_SECONDS=5
```

### Pi-hole Setup
- **Web Interface**: http://localhost:8083 (admin/admin)
- **DNS Server**: Configure devices to use `your-server-ip:5053`
- **Upstream DNS**: 1.1.1.1, 8.8.8.8 (configurable)

### Storage Configuration
- **Prometheus Data**: Persistent on USB drive (`/mnt/usb/prometheus/`)
- **Other Data**: Docker volumes with automatic management

---

## 🐧 Platform Support

### Docker (Recommended)
```bash
make homelab-complete  # Full setup
```

### Podman (CentOS/RHEL)
Full compatibility with:
- Container storage paths (`/var/lib/containers/`)
- Network bridge configuration
- Restart policies optimized for Podman

---

## 🔧 Hardware Integration

### Supported IoT Devices
- **Shelly Temperature Sensors**: Via MQTT JSON messages
- **Arduino Weather Stations**: Custom sensors with OLED display
- **Generic MQTT Devices**: Any device publishing JSON temperature data

### Expected Data Format
```json
{
  "id": 100,
  "tC": 23.5,
  "tF": 74.3,
  "errors": []
}
```

---

## 📁 Project Structure

```
homelab-setup/
├── docker-compose.observability.yml  # Prometheus + Grafana
├── docker-compose.monitoring.yml     # System monitoring + Perses
├── docker-compose.network.yml        # Pi-hole + Nginx proxy
├── docker-compose.apps.yml           # Applications (Glance)
├── docker-compose.mqtt.yml           # IoT/Weather station
├── Makefile                          # One-command orchestration
├── scripts/setup-usb-storage.sh      # USB storage automation
├── client-prom/                      # Go MQTT bridge
├── anemometer/                       # Arduino weather station
└── prometheus/config/                # Monitoring configuration
```

---

## 🆘 Troubleshooting

```bash
# Check all service status
make status

# View logs for specific service  
make logs SERVICE=grafana

# Restart specific service
docker-compose -f docker-compose.observability.yml restart grafana

# Check storage
df -h /mnt/usb

# Clean slate restart
make clean && make homelab-complete
```

### Common Issues
- **Port conflicts**: All services avoid 8080/3001 automatically
- **DNS conflicts**: Pi-hole uses 5053 instead of 53
- **Storage issues**: Run `sudo make setup-usb` for USB configuration
- **Network issues**: Services use shared `homelab` network

---

## 🚀 Why This Setup?

✅ **Conflict-Free**: Respects existing services (LVDA protection)  
✅ **Modular**: Deploy only what you need, scale incrementally  
✅ **Production-Ready**: Health checks, persistent storage, auto-restart  
✅ **One-Command**: Complex deployments simplified to `make [target]`  
✅ **Platform-Agnostic**: Docker + Podman support  
✅ **Extensible**: Easy to add new services to existing stacks  

---

**Transform your homelab in minutes, not hours** 🚀

*Built with ❤️ for reliable self-hosted infrastructure*