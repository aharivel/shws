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
| **cicd** | GitLab + GitLab Runners | Version control & CI/CD pipelines | `make cicd` |

### 📦 **Quick Presets** (`make [preset]`)

| Preset | Description | Includes | Best For |
|--------|-------------|----------|----------|
| **homelab-starter** | Basic setup | Observability + Glance | Getting started |
| **homelab-complete** | Full homelab | All except IoT/MQTT/CI/CD | Complete home server |
| **cicd-dev** | Development env | Observability + CI/CD | Software development |
| **weather-station** | IoT focused | Observability + MQTT | Sensor monitoring |
| **iot-complete** | Everything | All services including CI/CD | Full-featured setup |

---

## 🔌 Service Access (LVDA-Conflict-Free)

**🌐 Headless Access**: All services bind to `0.0.0.0` for network access

| Service | Local URL | Network URL | Purpose | Notes |
|---------|-----------|-------------|---------|-------|
| **🔵 Core Services** |||||
| Grafana | http://localhost:3005 | http://192.168.1.139:3005 | Metrics visualization | Login: admin/admin |
| Prometheus | http://localhost:9090 | http://192.168.1.139:9090 | Time-series database | Metrics collection |
| Perses | http://localhost:8082 | http://192.168.1.139:8082 | GitOps dashboards | **Safe: 8082 ≠ 8080** |
| **🟡 Monitoring Services** |||||
| cAdvisor | http://localhost:8081 | http://192.168.1.139:8081 | Container monitoring | **Safe: 8081 ≠ 8080** |
| Node Exporter | http://localhost:9100 | http://192.168.1.139:9100 | Host system metrics | System resources |
| **🟢 Network Services** |||||
| Pi-hole | http://localhost:8083 | http://192.168.1.139:8083 | DNS ad-blocking | **Safe: 8083 ≠ 8080** |
| Pi-hole DNS | localhost:5053 | 192.168.1.139:5053 | DNS server | **Safe: 5053 ≠ 53** |
| Nginx Proxy | http://localhost:8084 | http://192.168.1.139:8084 | SSL/Proxy mgmt | **Safe: 8084 ≠ 8080** |
| **🟣 Applications** |||||
| Glance | http://localhost:8085 | http://192.168.1.139:8085 | System overview | **Safe: 8085 ≠ 8080** |
| **🚀 CI/CD Services** |||||
| GitLab | http://localhost:8086 | http://192.168.1.139:8086 | Git repos & CI/CD | **Safe: 8086 ≠ 8080** |
| GitLab SSH | ssh://git@localhost:2222 | ssh://git@192.168.1.139:2222 | Git over SSH | Custom SSH port |
| GitLab HTTPS | https://localhost:4433 | https://192.168.1.139:4433 | Secure web access | Custom HTTPS port |
| **🔴 IoT Services** |||||
| MQTT Metrics | http://localhost:8888 | http://192.168.1.139:8888 | Sensor health/metrics | Weather station only |
| MQTT Server | localhost:1883 | 192.168.1.139:1883 | IoT message broker | TCP connection |

**🛡️ Protected Ports**: 8080 (LVDA Frontend), 3001 (LVDA Backend) - **Never used**
**🌐 Network Access**: Replace `192.168.1.139` with your server's IP address

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

# 5. Add CI/CD services
make cicd
# Access: +GitLab (8086), SSH (2222), HTTPS (4433)
```

### Specific Use Cases
```bash
# Just want Pi-hole DNS filtering
make pihole-only

# Just want Grafana monitoring
make grafana-only

# Weather station with metrics
make weather-station

# Complete homelab (no IoT/CI/CD)
make homelab-complete

# Development environment with GitLab CI/CD
make cicd-dev
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

# Setup GitLab runners after GitLab starts
make gitlab-setup

# Manual GitLab runner setup
./scripts/setup-gitlab-runners.sh
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

### 🚀 **CI/CD & Development**
- **GitLab CE**: Self-hosted Git repositories with web interface
- **GitLab CI/CD**: Automated pipelines with `.gitlab-ci.yml` support
- **GitLab Runners**: Multi-runner support for parallel job execution
- **Docker-in-Docker**: Build and test containerized applications
- **Runner Cache**: Optional Redis cache for faster build times

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

### GitLab Setup
- **Web Interface**: http://localhost:8086 (root/initialpassword123)
- **SSH Git Access**: `git clone ssh://git@localhost:2222/username/repo.git`
- **HTTPS Git Access**: `git clone https://localhost:4433/username/repo.git`
- **Runner Registration**: Run `make gitlab-setup` after GitLab starts
- **Multiple Runners**: Use `--profile multi-runner` for parallel jobs

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
- Automated SELinux configuration (`make setup-selinux`)
- Automated firewall configuration (`make setup-firewall`)

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
├── docker-compose.ci.yml             # GitLab CI/CD services
├── Makefile                          # One-command orchestration
├── scripts/setup-usb-storage.sh      # USB storage automation
├── scripts/setup-gitlab-runners.sh   # GitLab runner registration
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

# Restart GitLab services
docker-compose -f docker-compose.ci.yml restart gitlab

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
- **GitLab slow start**: Initial startup takes 5-10 minutes, use `make gitlab-setup` to wait
- **Runner registration**: Get token from GitLab admin panel before running setup script
- **SELinux permission denied**: Run `make setup-selinux` (CentOS/RHEL only)
- **Container file access**: Check SELinux contexts with `ls -laZ config-dir/`
- **Connection refused from network**: Run `make setup-firewall` (CentOS/RHEL only)
- **Firewall blocking ports**: Check with `sudo firewall-cmd --list-ports`

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