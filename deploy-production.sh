#!/bin/bash

# Production Deployment Script for xsigned.ai
# Run this on your Raspberry Pi after DNS is configured

set -e

echo "🚀 Deploying Music Campaign to Production (xsigned.ai)..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
mkdir -p logs ssl certbot

# Copy environment file
if [ ! -f .env ]; then
    cp .env.production .env
    echo "⚠️  Please edit .env file with your actual values before continuing"
    echo "   Especially change DB_PASSWORD and JWT_SECRET_KEY"
    exit 1
fi

# Check if frontend directory exists
if [ ! -d "../xsigned" ]; then
    echo "⚠️  Frontend directory not found. Please clone your React app to ../xsigned"
    exit 1
fi

# Update email in production compose file
read -p "Enter your email for SSL certificates: " email
sed -i "s/your-email@example.com/$email/g" docker-compose.production.yml

echo "🔒 Setting up SSL certificates..."
sudo ./setup-ssl.sh

echo "🔨 Building and starting production services..."
docker compose -f docker-compose.production.yml up -d --build

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 45

# Check service status
echo "📊 Service Status:"
docker compose -f docker-compose.production.yml ps

# Test HTTPS
echo "🧪 Testing HTTPS connection..."
if curl -s -k https://xsigned.ai/health > /dev/null; then
    echo "✅ HTTPS is working!"
else
    echo "⚠️  HTTPS test failed. Check nginx logs."
fi

# Show logs
echo "📝 Recent logs:"
docker compose -f docker-compose.production.yml logs --tail=20

echo "✅ Production deployment complete!"
echo ""
echo "🌐 Your application should be available at:"
echo "   - Frontend: https://xsigned.ai"
echo "   - API: https://xsigned.ai/api/"
echo "   - Health check: https://xsigned.ai/health"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker compose -f docker-compose.production.yml logs -f"
echo "   - Stop services: docker compose -f docker-compose.production.yml down"
echo "   - Restart: docker compose -f docker-compose.production.yml up -d --build"
echo "   - Renew SSL: ./renew-ssl.sh"
