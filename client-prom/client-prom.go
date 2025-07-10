package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Define Prometheus metrics
var (
	temperatureGauge = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "mqtt_temperature_celsius",
			Help: "Temperature values received from MQTT topics",
		},
		[]string{"topic"}, // Only one label: "topic"
	)
	connectionStatus = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "mqtt_connection_status",
			Help: "MQTT connection status (1=connected, 0=disconnected)",
		},
	)
	messageErrors = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "mqtt_message_errors_total",
			Help: "Total number of MQTT message processing errors",
		},
		[]string{"error_type"},
	)
	lastTemperature = make(map[string]float64) // Store last known values
	mu              sync.Mutex                // Protect lastTemperature map
	isConnected     int64                     // Atomic flag for connection status
)

// Message structure to parse the JSON payload
type TemperatureMessage struct {
	ID     int      `json:"id"`
	TC     *float64 `json:"tC"`    // Use a pointer to handle null values
	TF     *float64 `json:"tF"`    // Not used here but included for completeness
	Errors []string `json:"errors"` // Error information, if any
}

// Configuration structure
type Config struct {
	BrokerURL    string
	ClientID     string
	Topics       []string
	MetricsPort  string
	ReconnectDelay time.Duration
	MaxReconnectDelay time.Duration
}

// Load configuration from environment variables
func loadConfig() *Config {
	config := &Config{
		BrokerURL:    getEnv("MQTT_BROKER_URL", "tcp://192.168.1.27:1883"),
		ClientID:     getEnv("MQTT_CLIENT_ID", "shelly-mqtt-prometheus"),
		MetricsPort:  getEnv("METRICS_PORT", "8888"),
		ReconnectDelay: time.Duration(getEnvInt("RECONNECT_DELAY_SECONDS", 5)) * time.Second,
		MaxReconnectDelay: time.Duration(getEnvInt("MAX_RECONNECT_DELAY_SECONDS", 60)) * time.Second,
	}
	
	// Parse topics from environment (comma-separated)
	topicsEnv := getEnv("MQTT_TOPICS", "shellyplusuni/status/temperature:100,shellyplusuni/status/temperature:101")
	config.Topics = strings.Split(topicsEnv, ",")
	
	return config
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func main() {
	// Register Prometheus metrics
	prometheus.MustRegister(temperatureGauge, connectionStatus, messageErrors)

	// Load configuration
	config := loadConfig()

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start MQTT client in a goroutine
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			default:
				runMQTTClient(ctx, config)
				if ctx.Err() != nil {
					return
				}
				log.Println("Reconnecting to MQTT broker...")
				time.Sleep(config.ReconnectDelay)
			}
		}
	}()

	// Start HTTP server
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", healthHandler)

	server := &http.Server{
		Addr:    ":" + config.MetricsPort,
		Handler: nil,
	}

	go func() {
		fmt.Printf("Prometheus metrics server running on :%s\n", config.MetricsPort)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("HTTP server error: %v", err)
		}
	}()

	// Wait for shutdown signal
	<-sigChan
	log.Println("Shutting down gracefully...")

	// Cancel context to stop MQTT client
	cancel()

	// Shutdown HTTP server
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("HTTP server shutdown error: %v", err)
	}

	log.Println("Application stopped")
}

func runMQTTClient(ctx context.Context, config *Config) {
	// Configure MQTT client options
	opts := mqtt.NewClientOptions()
	opts.AddBroker(config.BrokerURL)
	opts.SetClientID(config.ClientID)
	opts.SetAutoReconnect(true)
	opts.SetConnectRetry(true)
	opts.SetConnectRetryInterval(config.ReconnectDelay)
	opts.SetMaxReconnectInterval(config.MaxReconnectDelay)

	// Connection handlers
	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		log.Printf("MQTT connection lost: %v", err)
		atomic.StoreInt64(&isConnected, 0)
		connectionStatus.Set(0)
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		log.Println("MQTT connected")
		atomic.StoreInt64(&isConnected, 1)
		connectionStatus.Set(1)

		// Subscribe to topics on connect
		for _, topic := range config.Topics {
			topic = strings.TrimSpace(topic)
			if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
				log.Printf("Failed to subscribe to topic %s: %v", topic, token.Error())
				messageErrors.WithLabelValues("subscription_error").Inc()
			} else {
				log.Printf("Subscribed to topic: %s", topic)
			}
		}
	})

	// MQTT message handler
	opts.SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
		var tempMessage TemperatureMessage
		payload := strings.TrimSpace(string(msg.Payload()))

		// Parse JSON payload
		err := json.Unmarshal([]byte(payload), &tempMessage)
		if err != nil {
			log.Printf("Failed to parse JSON payload: %v", err)
			messageErrors.WithLabelValues("json_parse_error").Inc()
			return
		}

		// Update temperature if tC is not null
		mu.Lock()
		defer mu.Unlock()

		if tempMessage.TC != nil {
			// Update the gauge with only the "topic" label
			lastTemperature[msg.Topic()] = *tempMessage.TC
			temperatureGauge.WithLabelValues(msg.Topic()).Set(*tempMessage.TC)
			log.Printf("Updated temperature %.2f from topic %s", *tempMessage.TC, msg.Topic())
		} else {
			// Log that no valid temperature was provided
			log.Printf("No valid temperature in message: %s", payload)
			messageErrors.WithLabelValues("invalid_temperature").Inc()
		}
	})

	// Create and start the MQTT client
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Printf("Failed to connect to MQTT broker: %v", token.Error())
		return
	}

	// Wait for context cancellation
	<-ctx.Done()
	client.Disconnect(250)
	log.Println("MQTT client disconnected")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	connected := atomic.LoadInt64(&isConnected) == 1
	status := "unhealthy"
	if connected {
		status = "healthy"
	}

	response := map[string]interface{}{
		"status": status,
		"mqtt_connected": connected,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

