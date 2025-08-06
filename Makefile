# Homelab Quick Setup - Modular Self-Hosted Services
# ====================================================
# CRITICAL: Port assignments designed to avoid conflicts with existing LVDA services
# LVDA Frontend: 8080 (PROTECTED)
# LVDA Backend: 3001 (PROTECTED)

# Container orchestration - auto-detect podman-compose vs docker-compose
COMPOSE := $(shell command -v podman-compose 2>/dev/null || command -v docker-compose 2>/dev/null)

.PHONY: help observability monitoring network apps mqtt cicd full setup-usb clean logs status gitlab-setup

# Default target
help: ## Show this help message
	@echo "🏠 Homelab Quick Setup - Modular Self-Hosted Services"
	@echo ""
	@echo "🐳 Using: $(COMPOSE)"
	@echo "⚠️  IMPORTANT: Port assignments avoid conflicts with LVDA (ports 8080, 3001)"
	@echo ""
	@echo "📋 Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "🔌 Service Access Points:"
	@echo "  Grafana:       http://localhost:3005"  
	@echo "  Prometheus:    http://localhost:9090"
	@echo "  cAdvisor:      http://localhost:8081  (SAFE: 8080 avoided)"
	@echo "  Perses:        http://localhost:8082  (SAFE: 8080 avoided)" 
	@echo "  Pi-hole:       http://localhost:8083  (SAFE: 8080 avoided)"
	@echo "  Nginx Proxy:   http://localhost:8084  (SAFE: 8080 avoided)"
	@echo "  Glance:        http://localhost:8085  (SAFE: 8080 avoided)"
	@echo "  MQTT Metrics:  http://localhost:8888  (Weather station only)"
	@echo "  GitLab:        http://localhost:8086  (SAFE: 8080 avoided)"

# Core homelab stacks
observability: ## Start observability stack (Prometheus + Grafana + Perses)
	@echo "📊 Starting observability stack..."
	@$(COMPOSE) -f docker-compose.observability.yml up -d
	@echo "✅ Observability services running:"
	@echo "   - Prometheus: http://localhost:9090"
	@echo "   - Grafana: http://localhost:3005 (admin/admin)"
	@echo "   - Perses: http://localhost:8082 (SAFE: avoids LVDA on 8080)"

monitoring: observability ## Add system monitoring (cAdvisor + Node Exporter)
	@echo "📈 Adding system monitoring services..."
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml up -d
	@echo "✅ Monitoring services added:"
	@echo "   - cAdvisor: http://localhost:8081 (SAFE: avoids LVDA on 8080)"
	@echo "   - Node Exporter: http://localhost:9100"

network: create-network ## Add network services (Pi-hole + Nginx Proxy Manager)
	@echo "🌐 Adding network services..."
	@$(COMPOSE) -f docker-compose.network.yml up -d
	@echo "✅ Network services running:"
	@echo "   - Pi-hole Web: http://localhost:8083 (SAFE: avoids LVDA on 8080)"
	@echo "   - Pi-hole DNS: localhost:5053 (SAFE: avoids system DNS on 53)"
	@echo "   - Nginx Proxy: http://localhost:8084 (SAFE: avoids LVDA on 8080)"

apps: create-network ## Add application services (Glance dashboard)
	@echo "📱 Adding application services..."
	@$(COMPOSE) -f docker-compose.apps.yml up -d
	@echo "✅ Application services running:"
	@echo "   - Glance: http://localhost:8085 (SAFE: avoids LVDA on 8080)"

# IoT/Weather Station specific
mqtt: ## Add MQTT services for IoT/Weather Station
	@echo "🌡️  Adding MQTT services for IoT/Weather Station..."
	@$(COMPOSE) -f docker-compose.mqtt.yml up -d
	@echo "✅ MQTT services running:"
	@echo "   - MQTT Server: localhost:1883"
	@echo "   - MQTT Metrics: http://localhost:8888"

# CI/CD Services
cicd: create-network ## Add CI/CD services (GitLab + GitLab Runner)
	@echo "🚀 Adding CI/CD services (GitLab + Runner)..."
	@$(COMPOSE) -f docker-compose.ci.yml up -d
	@echo "✅ CI/CD services running:"
	@echo "   - GitLab: http://localhost:8086 (SAFE: avoids LVDA on 8080)"
	@echo "   - SSH Git: ssh://git@localhost:2222"
	@echo "   - Initial root password: initialpassword123"
	@echo ""
	@echo "🔧 Next steps:"
	@echo "   1. Access GitLab at http://localhost:8086"
	@echo "   2. Login with root/initialpassword123"
	@echo "   3. Run 'make gitlab-setup' to configure runners"

gitlab-setup: ## Configure GitLab runners (run after GitLab is ready)
	@echo "🏃 Setting up GitLab runners..."
	@echo "⏳ Waiting for GitLab to be ready..."
	@timeout 300 bash -c 'until docker exec gitlab-ce gitlab-rails runner "puts \"GitLab is ready\"" 2>/dev/null; do sleep 5; done'
	@echo "✅ GitLab is ready!"
	@echo ""
	@echo "📝 To register runners, get the registration token from:"
	@echo "   http://localhost:8086/admin/runners"
	@echo ""
	@echo "Then run these commands:"
	@echo "   docker exec -it gitlab-runner-1 gitlab-runner register"
	@echo "   docker exec -it gitlab-runner-2 gitlab-runner register  # (optional second runner)"
	@echo ""
	@echo "🔧 Runner configuration:"
	@echo "   - URL: http://gitlab:80"
	@echo "   - Executor: docker"
	@echo "   - Default image: alpine:latest"

# Full stack deployments
full: ## Deploy complete homelab stack (all services including CI/CD)
	@echo "🚀 Deploying complete homelab stack..."
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml up -d
	@echo "✅ Full homelab stack deployed! All services running with LVDA-safe ports."

homelab-essentials: ## Deploy recommended homelab core (observability + monitoring + network)
	@echo "🏠 Deploying homelab essentials..."
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml up -d
	@echo "✅ Homelab essentials deployed:"
	@echo "   - Grafana + Prometheus + System Monitoring + Pi-hole + Proxy"

# Individual service management
grafana-only: ## Run only Grafana + Prometheus
	@echo "📊 Starting Grafana + Prometheus only..."
	@$(COMPOSE) -f docker-compose.observability.yml up -d
	@echo "✅ Observability stack available:"
	@echo "   - Grafana: http://localhost:3005"
	@echo "   - Prometheus: http://localhost:9090"

glance-only: ## Run only Glance dashboard
	@echo "📱 Starting Glance dashboard only..."
	@$(COMPOSE) -f docker-compose.apps.yml up -d glance
	@echo "✅ Glance available at: http://localhost:8085"

prometheus-only: ## Run only Prometheus
	@echo "📊 Starting Prometheus only..."
	@$(COMPOSE) -f docker-compose.observability.yml up -d prometheus
	@echo "✅ Prometheus available at: http://localhost:9090"

perses-only: ## Run only Perses dashboard
	@echo "📈 Starting Perses dashboard only..."
	@$(COMPOSE) -f docker-compose.monitoring.yml up -d perses
	@echo "✅ Perses available at: http://localhost:8082"

pihole-only: ## Run only Pi-hole
	@echo "🕳️  Starting Pi-hole only..."
	@$(COMPOSE) -f docker-compose.network.yml up -d pihole
	@echo "✅ Pi-hole available at: http://localhost:8083"
	@echo "   DNS server: localhost:5053"

weather-station: observability mqtt ## Deploy weather station with observability
	@echo "🌤️  Deploying weather station setup..."
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.mqtt.yml up -d
	@echo "✅ Weather station deployed:"
	@echo "   - MQTT + Prometheus + Grafana for sensor monitoring"

# Infrastructure management
setup-usb: ## Configure USB storage and update fstab
	@echo "💾 Setting up USB storage..."
	@sudo ./scripts/setup-usb-storage.sh
	@echo "✅ USB storage configured and mounted"

clean: ## Stop and remove all containers
	@echo "🧹 Cleaning up all services..."
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml down
	@echo "✅ All services stopped"

clean-volumes: ## Remove all volumes (WARNING: Data loss!)
	@echo "⚠️  WARNING: This will remove all data volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml down -v; \
		echo "✅ All volumes removed"; \
	else \
		echo "❌ Operation cancelled"; \
	fi

# Create shared network
create-network: ## Create shared homelab network
	@echo "🔗 Creating shared homelab network..."
	@if command -v podman >/dev/null 2>&1; then \
		podman network create homelab 2>/dev/null || echo "Network already exists"; \
	else \
		docker network create homelab 2>/dev/null || echo "Network already exists"; \
	fi
	@echo "✅ Homelab network ready"

# Monitoring and logs
status: ## Show status of all services
	@echo "📊 Service Status:"
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml ps

logs: ## Show logs for all services (or specific: make logs SERVICE=prometheus)
ifdef SERVICE
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml logs -f $(SERVICE)
else
	@$(COMPOSE) -f docker-compose.observability.yml -f docker-compose.monitoring.yml -f docker-compose.network.yml -f docker-compose.apps.yml -f docker-compose.mqtt.yml -f docker-compose.ci.yml logs -f
endif

# Quick deployment presets
homelab-starter: create-network observability apps ## Quick starter: Grafana + Glance
	@echo "🚀 Homelab starter pack deployed!"
	@echo "   Next steps: make network (Pi-hole), make monitoring (system metrics)"

homelab-complete: create-network homelab-essentials apps ## Complete homelab without IoT
	@echo "🏠 Complete homelab deployed (no IoT/MQTT)!"
	@echo "   Add IoT support with: make mqtt"

iot-complete: create-network full ## Complete setup including IoT/Weather Station
	@echo "🌡️  Complete IoT homelab deployed!"

# CI/CD focused presets
cicd-dev: create-network observability cicd ## Development environment with CI/CD
	@echo "🚀 Development environment with CI/CD deployed!"
	@echo "   - Grafana for monitoring your CI/CD pipelines"
	@echo "   - GitLab for version control and CI/CD"

# Development helpers
dev-observability: create-network ## Development mode - observability with live reload
	@echo "🛠️  Starting observability services in development mode..."
	@$(COMPOSE) -f docker-compose.observability.yml up

dev-rebuild-mqtt: ## Rebuild and restart mqtt-prometheus service
	@echo "🔨 Rebuilding MQTT-Prometheus service..."
	@$(COMPOSE) -f docker-compose.mqtt.yml build mqtt-prometheus
	@$(COMPOSE) -f docker-compose.mqtt.yml up -d mqtt-prometheus
	@echo "✅ MQTT service rebuilt and restarted"

# Update configurations
update-prometheus-config: ## Update Prometheus to scrape all services
	@echo "🔧 Updating Prometheus configuration for all services..."
	@cp prometheus/config/prometheus.yml prometheus/config/prometheus.yml.bak
	@echo "global:" > prometheus/config/prometheus.yml
	@echo "  scrape_interval: 15s" >> prometheus/config/prometheus.yml
	@echo "" >> prometheus/config/prometheus.yml
	@echo "scrape_configs:" >> prometheus/config/prometheus.yml
	@echo "  - job_name: 'prometheus'" >> prometheus/config/prometheus.yml
	@echo "    static_configs:" >> prometheus/config/prometheus.yml
	@echo "      - targets: ['localhost:9090']" >> prometheus/config/prometheus.yml
	@echo "  - job_name: 'node_exporter'" >> prometheus/config/prometheus.yml
	@echo "    static_configs:" >> prometheus/config/prometheus.yml
	@echo "      - targets: ['node_exporter:9100']" >> prometheus/config/prometheus.yml
	@echo "  - job_name: 'cAdvisor'" >> prometheus/config/prometheus.yml
	@echo "    static_configs:" >> prometheus/config/prometheus.yml
	@echo "      - targets: ['cadvisor:8080']" >> prometheus/config/prometheus.yml
	@echo "  - job_name: 'mqtt_client'" >> prometheus/config/prometheus.yml
	@echo "    scrape_interval: 5m" >> prometheus/config/prometheus.yml
	@echo "    static_configs:" >> prometheus/config/prometheus.yml
	@echo "      - targets: ['mqtt-prometheus:8888']" >> prometheus/config/prometheus.yml
	@echo "✅ Prometheus configuration updated for complete homelab stack"