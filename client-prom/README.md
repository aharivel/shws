# MQTT to Prometheus Bridge

A resilient Go application that subscribes to MQTT temperature sensor data and exposes it as Prometheus metrics.

## Features

- **Automatic Reconnection**: Handles MQTT broker disconnections with exponential backoff
- **Graceful Shutdown**: Responds to SIGINT/SIGTERM for clean shutdown
- **Environment Configuration**: All settings configurable via environment variables
- **Health Monitoring**: Built-in health check endpoint and connection metrics
- **Error Recovery**: Robust error handling without fatal exits

## Quick Start

```bash
# Build the application
go build -o client-prom .

# Run with default settings
./client-prom

# Or with Docker
docker build -t mqtt-prometheus .
docker run -p 8888:8888 mqtt-prometheus
```

## Configuration

### Environment Variables

**Required/Common Variables:**
```bash
# MQTT broker connection
export MQTT_BROKER_URL="tcp://192.168.1.27:1883"

# Topics to subscribe to (comma-separated)
export MQTT_TOPICS="shellyplusuni/status/temperature:100,shellyplusuni/status/temperature:101"

# HTTP metrics server port
export METRICS_PORT="8888"
```

**Optional Variables:**
```bash
# MQTT client identifier
export MQTT_CLIENT_ID="my-custom-client-id"

# Reconnection timing (in seconds)
export RECONNECT_DELAY_SECONDS=5
export MAX_RECONNECT_DELAY_SECONDS=60
```

### Usage Examples

**1. Run with custom broker:**
```bash
MQTT_BROKER_URL="tcp://10.0.0.100:1883" ./client-prom
```

**2. Run with different topics:**
```bash
MQTT_TOPICS="sensor/temp1,sensor/temp2,sensor/temp3" ./client-prom
```

**3. Run on different port:**
```bash
METRICS_PORT="9090" ./client-prom
```

**4. Complete custom configuration:**
```bash
export MQTT_BROKER_URL="tcp://broker.example.com:1883"
export MQTT_TOPICS="home/temperature,office/temperature"
export METRICS_PORT="9090"
export RECONNECT_DELAY_SECONDS=10
./client-prom
```

**5. Docker with environment variables:**
```bash
docker run -p 9090:9090 \
  -e MQTT_BROKER_URL="tcp://192.168.1.50:1883" \
  -e MQTT_TOPICS="device1/temp,device2/temp" \
  -e METRICS_PORT="9090" \
  mqtt-prometheus
```

## Endpoints

- **`/metrics`**: Prometheus metrics endpoint
- **`/health`**: Health check endpoint with connection status

## Metrics

The application exposes the following Prometheus metrics:

- `mqtt_temperature_celsius{topic="..."}`: Temperature values from MQTT topics
- `mqtt_connection_status`: Connection status (1=connected, 0=disconnected)
- `mqtt_message_errors_total{error_type="..."}`: Count of message processing errors

## Message Format

The application expects JSON messages with this structure:
```json
{
  "id": 100,
  "tC": 23.5,
  "tF": 74.3,
  "errors": []
}
```

Where `tC` is temperature in Celsius and can be null.

## Building and Running

### Local Development
```bash
# Install dependencies
go mod download

# Build
go build -o client-prom .

# Run
./client-prom
```

### Docker
```bash
# Build image
docker build -t mqtt-prometheus .

# Run container
docker run -p 8888:8888 mqtt-prometheus

# Run with custom configuration
docker run -p 9090:9090 \
  -e MQTT_BROKER_URL="tcp://your-broker:1883" \
  -e METRICS_PORT="9090" \
  mqtt-prometheus
```

## Health Check

Check application health:
```bash
curl http://localhost:8888/health
```

Response:
```json
{
  "status": "healthy",
  "mqtt_connected": true,
  "timestamp": "2024-01-01T12:00:00Z"
}
```