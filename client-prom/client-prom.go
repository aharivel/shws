package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Define a Prometheus gauge for the temperature
var (
	temperatureGauge = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "mqtt_temperature_celsius",
			Help: "Temperature values received from MQTT topics",
		},
		[]string{"topic"}, // Only one label: "topic"
	)
	lastTemperature = make(map[string]float64) // Store last known values
	mu              sync.Mutex                // Protect lastTemperature map
)

// Message structure to parse the JSON payload
type TemperatureMessage struct {
	ID     int      `json:"id"`
	TC     *float64 `json:"tC"`    // Use a pointer to handle null values
	TF     *float64 `json:"tF"`    // Not used here but included for completeness
	Errors []string `json:"errors"` // Error information, if any
}

func main() {
	// Register the Prometheus metric
	prometheus.MustRegister(temperatureGauge)

	// MQTT broker and topic configuration
	broker := "tcp://mqtt-server:1883" // Replace with your MQTT broker URL
	clientID := "shelly-mqtt-prometheus"
	topics := []string{
		"shellyplusuni/status/temperature:100",
		"shellyplusuni/status/temperature:101",
	}

	// Configure MQTT client options
	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID(clientID)

	// MQTT message handler
	opts.SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
		var tempMessage TemperatureMessage
		payload := strings.TrimSpace(string(msg.Payload()))

		// Parse JSON payload
		err := json.Unmarshal([]byte(payload), &tempMessage)
		if err != nil {
			log.Printf("Failed to parse JSON payload: %v", err)
			return
		}

		// Update temperature if tC is not null
		mu.Lock()
		defer mu.Unlock()

		if tempMessage.TC != nil {
			// Update the gauge with only the "topic" label
			lastTemperature[msg.Topic()] = *tempMessage.TC
			temperatureGauge.WithLabelValues(msg.Topic()).Set(*tempMessage.TC)
			fmt.Printf("Updated temperature %.2f from topic %s\n", *tempMessage.TC, msg.Topic())
		} else {
			// Log that no valid temperature was provided
			log.Printf("No valid temperature in message: %s", payload)
		}
	})

	// Create and start the MQTT client
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Failed to connect to MQTT broker: %v", token.Error())
	}
	defer client.Disconnect(250)

	// Subscribe to the temperature topics
	for _, topic := range topics {
		if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
			log.Fatalf("Failed to subscribe to topic %s: %v", topic, token.Error())
		}
		fmt.Printf("Subscribed to topic: %s\n", topic)
	}

	// Start the Prometheus HTTP server
	http.Handle("/metrics", promhttp.Handler())
	fmt.Println("Prometheus metrics server running on :8888")
	log.Fatal(http.ListenAndServe(":8888", nil))
}

