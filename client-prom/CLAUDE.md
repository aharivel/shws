# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go application that bridges MQTT temperature sensor data to Prometheus metrics. The application:

- Subscribes to Shelly temperature sensor MQTT topics
- Parses JSON temperature messages 
- Exposes temperature data as Prometheus metrics on port 8888
- Uses Docker for containerized deployment

## Key Architecture

- **Single main.go file**: All functionality is contained in `client-prom.go`
- **MQTT Client**: Uses `github.com/eclipse/paho.mqtt.golang` for MQTT connectivity
- **Prometheus Metrics**: Uses `github.com/prometheus/client_golang` for metrics exposure
- **JSON Message Parsing**: Handles Shelly device temperature message format with error handling
- **Concurrent Safety**: Uses mutex for thread-safe map operations

## Common Commands

### Build
```bash
go build -o client-prom .
```

### Run
```bash
./client-prom
```

### Docker Build
```bash
docker build -t mqtt-prometheus .
```

### Docker Run
```bash
docker run -p 8888:8888 mqtt-prometheus
```

### Dependencies
```bash
go mod download
go mod tidy
```

## Configuration

- MQTT broker is hardcoded to `tcp://192.168.1.27:1883`
- Subscribed topics are hardcoded in the `topics` slice
- Prometheus metrics server runs on port 8888

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