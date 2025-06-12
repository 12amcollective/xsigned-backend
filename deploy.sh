#!/bin/bash

# Full Stack Deployment script for Raspberry Pi
# Run this on your Pi after cloning both backend and frontend repos

set -e

echo "🚀 Deploying Music Campaign Full Stack..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and back in, then run this script again."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Installing..."
    sudo apt update
    sudo apt install docker-compose-plugin -y
fi

# Create logs directory
mkdir -p logs

# Copy environment file
if [ ! -f .env ]; then
    cp .env.production .env
    echo "⚠️  Please edit .env file with your actual values before continuing"
    echo "   Especially change DB_PASSWORD and JWT_SECRET_KEY"
    exit 1
fi

# Check if frontend directory exists
if [ ! -d "../music-campaign-frontend" ]; then
    echo "⚠️  Frontend directory not found. Please clone your React app to ../music-campaign-frontend"
    echo "   Or update the path in docker-compose.yml"
    exit 1
fi

# Build and start services
echo "🔨 Building and starting services..."
docker compose up -d --build

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service status
echo "📊 Service Status:"
docker compose ps

# Show logs
echo "📝 Recent logs:"
docker compose logs --tail=20

echo "✅ Deployment complete!"
echo "🌐 Your application should be available at:"
echo "   - Frontend: http://$(hostname -I | awk '{print $1}')"
echo "   - API: http://$(hostname -I | awk '{print $1}')/api/"
echo "   - Health check: http://$(hostname -I | awk '{print $1}')/health"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker compose logs -f"
echo "   - Stop services: docker compose down"
echo "   - Restart: docker compose up -d --build"
echo "   - View specific service: docker compose logs frontend"
