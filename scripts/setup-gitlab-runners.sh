#!/bin/bash

# GitLab Runner Setup Script
# Automates the registration of GitLab runners for CI/CD

set -e

GITLAB_URL="http://gitlab:80"
GITLAB_EXTERNAL_URL="http://localhost:8086"
RUNNER_NAME_1="docker-runner-1"
RUNNER_NAME_2="docker-runner-2"
EXECUTOR="docker"
DEFAULT_IMAGE="alpine:latest"

echo "🏃 GitLab Runner Setup Script"
echo "============================="
echo ""

# Check if GitLab is running
if ! docker exec gitlab-ce gitlab-rails runner "puts 'GitLab is ready'" 2>/dev/null; then
    echo "❌ GitLab is not ready. Please ensure GitLab is running:"
    echo "   make cicd"
    echo "   make gitlab-setup"
    exit 1
fi

echo "✅ GitLab is ready!"
echo ""

# Get registration token
echo "📝 To register runners, you need the registration token from:"
echo "   ${GITLAB_EXTERNAL_URL}/admin/runners"
echo ""
echo "🔐 Login credentials:"
echo "   Username: root"
echo "   Password: initialpassword123"
echo ""

# Prompt for registration token
read -p "Enter the GitLab registration token: " REGISTRATION_TOKEN

if [ -z "$REGISTRATION_TOKEN" ]; then
    echo "❌ Registration token is required!"
    exit 1
fi

echo ""
echo "🏃 Registering GitLab Runner 1..."

# Register first runner
docker exec -it gitlab-runner-1 gitlab-runner register \
    --non-interactive \
    --url="$GITLAB_URL" \
    --registration-token="$REGISTRATION_TOKEN" \
    --executor="$EXECUTOR" \
    --docker-image="$DEFAULT_IMAGE" \
    --description="$RUNNER_NAME_1" \
    --docker-privileged=false \
    --docker-volumes="/var/run/docker.sock:/var/run/docker.sock" \
    --docker-network-mode="gitlab-cicd"

echo "✅ Runner 1 registered successfully!"
echo ""

# Ask if user wants to register second runner
read -p "Do you want to register a second runner for parallel jobs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🏃 Registering GitLab Runner 2..."
    
    # Check if second runner container exists
    if docker ps -a --format "table {{.Names}}" | grep -q "gitlab-runner-2"; then
        docker exec -it gitlab-runner-2 gitlab-runner register \
            --non-interactive \
            --url="$GITLAB_URL" \
            --registration-token="$REGISTRATION_TOKEN" \
            --executor="$EXECUTOR" \
            --docker-image="$DEFAULT_IMAGE" \
            --description="$RUNNER_NAME_2" \
            --docker-privileged=false \
            --docker-volumes="/var/run/docker.sock:/var/run/docker.sock" \
            --docker-network-mode="gitlab-cicd"
        
        echo "✅ Runner 2 registered successfully!"
    else
        echo "⚠️  Second runner container not found. Start it with:"
        echo "   docker-compose -f docker-compose.ci.yml --profile multi-runner up -d"
        echo "   Then run this script again."
    fi
fi

echo ""
echo "🎉 GitLab Runner setup complete!"
echo ""
echo "📊 Verify runners are active at:"
echo "   ${GITLAB_EXTERNAL_URL}/admin/runners"
echo ""
echo "🚀 Next steps:"
echo "   1. Create a new project in GitLab"
echo "   2. Add a .gitlab-ci.yml file to your repository"
echo "   3. Push code to trigger your first CI/CD pipeline"
echo ""
echo "💡 Example .gitlab-ci.yml:"
echo "---"
cat << 'EOF'
stages:
  - test
  - build

test:
  stage: test
  image: alpine:latest
  script:
    - echo "Running tests..."
    - apk add --no-cache curl
    - curl --version

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - echo "Building application..."
    - docker --version
EOF
echo "---"
echo ""
echo "✅ Happy CI/CD-ing! 🚀"