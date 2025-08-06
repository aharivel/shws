# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-Hosted Weather Station (SHWS) is a multi-component IoT system that collects environmental data from sensors and provides monitoring through a complete observability stack. The system consists of:

1. **Arduino-based Anemometer/Temperature Sensor** - Physical sensor device
2. **MQTT-to-Prometheus Bridge** - Go application that processes sensor data
3. **Complete Monitoring Stack** - MQTT broker, Prometheus, Grafana, and system monitoring

## Architecture

### Physical Layer
- **Arduino Anemometer** (`anemometer/anemometer_v3.ino`): Measures wind speed using Hall effect sensor and temperature using Dallas DS18B20 sensor. Features OLED display with button navigation between current and maximum readings.

### Data Layer
- **MQTT Broker** (mochimqtt/server): Lightweight MQTT broker for sensor communication
- **Go Bridge Application** (`client-prom/client-prom.go`): Subscribes to MQTT topics and exposes metrics to Prometheus with resilient reconnection logic

### Monitoring Stack
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and alerting platform
- **cAdvisor**: Container monitoring
- **Node Exporter**: System metrics

## Key Components

### MQTT-to-Prometheus Bridge (`client-prom/`)
- **Environment-based Configuration**: All settings configurable via environment variables
- **Resilient Connection Handling**: Automatic reconnection with exponential backoff
- **Health Monitoring**: `/health` endpoint and connection status metrics
- **Expected Message Format**: 
  ```json
  {"id": 100, "tC": 23.5, "tF": 74.3, "errors": []}
  ```

### Arduino Sensor (`anemometer/`)
- **Dual Measurement**: Wind speed (Hall effect) and temperature (DS18B20)
- **Moving Average**: 5-sample moving average for wind speed stability
- **Display Interface**: OLED with button-switchable screens (current/maximum values)

## Common Commands

### Go Application (client-prom/)
```bash
# Build
go build -o client-prom .

# Run locally
./client-prom

# Run with custom configuration
MQTT_BROKER_URL="tcp://192.168.1.50:1883" MQTT_TOPICS="topic1,topic2" ./client-prom

# Docker build
docker build -t mqtt-prometheus .

# Dependencies
go mod download
go mod tidy
```

### Modular Deployment (RECOMMENDED)
```bash
# Show all available commands and safe port assignments
make help

# Core observability stack
make observability    # Prometheus + Grafana + Perses

# Add system monitoring
make monitoring      # + cAdvisor + Node Exporter

# Add network services
make network         # Pi-hole + Nginx Proxy Manager

# Add applications
make apps           # Glance dashboard

# Add CI/CD services
make cicd           # GitLab + GitLab Runners

# Deploy complete stack
make full           # Everything including CI/CD

# Quick presets
make homelab-starter    # Observability + Apps
make homelab-complete   # Everything except IoT
make cicd-dev          # Observability + CI/CD
make iot-complete      # Full stack with weather station

# Individual services
make glance-only      # Just Glance dashboard
make prometheus-only  # Just Prometheus
make perses-only     # Just Perses dashboard
make pihole-only     # Just Pi-hole

# GitLab management
make gitlab-setup    # Configure runners after GitLab starts

# Infrastructure setup
make setup-usb       # Configure USB storage + fstab
make clean          # Stop all services
make status         # Show service status
make logs SERVICE=prometheus  # View specific service logs
```

### Traditional Docker Compose (Legacy)
```bash
# Full stack (all services) - use only if you need everything
docker-compose up -d
podman-compose up -d  # For CentOS/RHEL
```

### Arduino Development
- Use Arduino IDE or PlatformIO
- Required libraries: OneWire, DallasTemperature, gButton, Adafruit_GFX, Adafruit_SSD1306
- Upload to Arduino-compatible board with proper pin connections

## Configuration

### Environment Variables (Go Application)
- `MQTT_BROKER_URL`: MQTT broker connection string (default: "tcp://192.168.1.27:1883")
- `MQTT_TOPICS`: Comma-separated list of topics to subscribe to
- `MQTT_CLIENT_ID`: MQTT client identifier
- `METRICS_PORT`: HTTP server port for metrics (default: "8888")
- `RECONNECT_DELAY_SECONDS`: Initial reconnection delay (default: 5)
- `MAX_RECONNECT_DELAY_SECONDS`: Maximum reconnection delay (default: 60)

### Service Ports (LVDA-Conflict Safe)
**Core Services:**
- **MQTT Broker**: 1883 (TCP), 1882 (WebSocket), 1880 (System Info)
- **Prometheus Metrics**: 8888 (Go application)
- **Prometheus Server**: 9090
- **Grafana**: 3005 (mapped from 3000)

**Monitoring Stack:**
- **Node Exporter**: 9100
- **cAdvisor**: 8081 (SAFE: avoids LVDA on 8080)
- **Perses Dashboard**: 8082 (SAFE: avoids LVDA on 8080)

**Network Services:**
- **Pi-hole Web**: 8083 (SAFE: avoids LVDA on 8080)
- **Pi-hole DNS**: 5053 (SAFE: avoids system DNS on 53)
- **Nginx Proxy Manager**: 8084 (SAFE: avoids LVDA on 8080)

**Applications:**
- **Glance Dashboard**: 8085 (SAFE: avoids LVDA on 8080)

**CI/CD Services:**
- **GitLab Web**: 8086 (SAFE: avoids LVDA on 8080)
- **GitLab HTTPS**: 4433 (mapped from 443)
- **GitLab SSH**: 2222 (mapped from 22)

**⚠️ PROTECTED PORTS (LVDA Services):**
- **8080**: LVDA Frontend (DO NOT USE)
- **3001**: LVDA Backend (DO NOT USE)

## CentOS/Podman Compatibility

The docker-compose.yml has been modified for Podman compatibility:
- `restart: unless-stopped` → `restart: always`
- `/var/lib/docker/` → `/var/lib/containers/` (cAdvisor volume)

### CentOS Prerequisites
```bash
# Install podman-compose
sudo dnf install podman-compose

# SELinux configuration (if needed)
sudo setsebool -P container_manage_cgroup true

# Firewall ports
sudo firewall-cmd --permanent --add-port={1883,3005,8888,9090}/tcp
sudo firewall-cmd --reload
```

## Key Files

- `client-prom/client-prom.go:101`: Main application entry point with graceful shutdown
- `client-prom/client-prom.go:166`: MQTT client connection logic with reconnection handling
- `client-prom/client-prom.go:242`: Health check endpoint implementation
- `anemometer/anemometer_v3.ino:54`: Main sensor reading loop
- `docker-compose.ci.yml`: GitLab CI/CD services with LVDA-safe port assignments
- `docker-compose.yml`: Complete service orchestration (Podman compatible)
- `prometheus/config/prometheus.yml`: Prometheus scrape configuration
- `Makefile`: Modular deployment system with safe port management

## Message Flow

### IoT/Weather Station Flow
1. Arduino sensor publishes temperature/wind data to MQTT topics
2. Go bridge subscribes to MQTT topics and parses JSON messages
3. Bridge exposes temperature data as Prometheus metrics on `/metrics`
4. Prometheus scrapes metrics every 5 minutes from the bridge
5. Grafana visualizes data from Prometheus
6. Health status available at `/health` endpoint

### CI/CD Flow
1. Code pushed to GitLab repository (http://localhost:8086)
2. GitLab CI triggers pipeline based on `.gitlab-ci.yml`
3. GitLab Runners execute jobs in Docker containers
4. Runners can access both Docker host and GitLab services
5. Pipeline results visible in GitLab web interface
6. Artifacts and logs stored in GitLab
7. Optional: GitLab Runner cache (Redis) speeds up builds