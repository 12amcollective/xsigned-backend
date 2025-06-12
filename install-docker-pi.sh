#!/bin/bash

# Docker and Docker Compose installation script for Raspberry Pi
# Run this script on your Raspberry Pi if you're having installation issues

set -e

echo "🍓 Setting up Docker on Raspberry Pi..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository (for Ubuntu on Pi)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine and Compose Plugin
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Test Docker installation
echo "🧪 Testing Docker installation..."
sudo docker run hello-world

# Test Docker Compose
echo "🧪 Testing Docker Compose..."
docker compose version

echo "✅ Docker installation complete!"
echo "🔄 Please log out and back in (or reboot) to use Docker without sudo"
echo ""
echo "After logging back in, run: docker run hello-world"
