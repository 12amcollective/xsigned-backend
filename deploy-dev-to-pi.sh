#!/bin/bash

# Quick Development Deployment to Raspberry Pi
# Deploys backend for development testing

set -e

echo "🚀 Deploying Development Backend to Raspberry Pi..."
echo "================================================="

# Configuration
PI_HOST="192.168.86.70"
PI_USER="colin"
BACKEND_DIR="/home/$PI_USER/xsigned-backend"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we can reach the Pi
print_info "Testing connection to Pi..."
if ! ping -c 1 "$PI_HOST" > /dev/null 2>&1; then
    print_error "Cannot reach Pi at $PI_HOST"
    echo "Please check:"
    echo "  - Pi is powered on and connected to network"
    echo "  - IP address is correct"
    echo "  - SSH is enabled on Pi"
    exit 1
fi
print_success "Pi is reachable"

# Test SSH connection
print_info "Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$PI_USER@$PI_HOST" exit 2>/dev/null; then
    print_error "Cannot SSH to Pi"
    echo "Please ensure:"
    echo "  - SSH keys are set up: ssh-copy-id $PI_USER@$PI_HOST"
    echo "  - Or SSH with password is enabled"
    echo "Try: ssh $PI_USER@$PI_HOST"
    exit 1
fi
print_success "SSH connection verified"

# Create backend directory on Pi
print_info "Creating backend directory on Pi..."
ssh "$PI_USER@$PI_HOST" "mkdir -p $BACKEND_DIR"

# Sync files to Pi (excluding unnecessary files)
print_info "Syncing files to Pi..."
rsync -av --progress \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude 'node_modules' \
    --exclude '.env*' \
    --exclude '*.pyc' \
    --exclude '.DS_Store' \
    --exclude 'logs/' \
    . "$PI_USER@$PI_HOST:$BACKEND_DIR/"

print_success "Files synced to Pi"

# Setup development environment on Pi
print_info "Setting up development environment on Pi..."
ssh "$PI_USER@$PI_HOST" << 'EOF'
cd /home/colin/xsigned-backend

# Make scripts executable
chmod +x *.sh
chmod +x run.sh

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "⚠️  Docker installed. Please log out and back in, then re-run this script."
    exit 1
fi

# Start development environment
echo "Starting development environment..."
./setup-dev.sh
EOF

if [ $? -eq 0 ]; then
    print_success "Development environment setup complete!"
    echo ""
    echo "🌐 Your backend is now running at:"
    echo "  • API Endpoint: http://$PI_HOST:8080/api/"
    echo "  • Health Check: http://$PI_HOST:8080/health"
    echo "  • Direct Backend: http://$PI_HOST:5001/api/ (for debugging)"
    echo ""
    echo "🖥️ To develop with local frontend:"
    echo "  1. Your Vite proxy should now work properly!"
    echo "  2. Ensure your vite.config.js proxy points to http://$PI_HOST:8080/api"
    echo "  3. Run: npm run dev"
    echo "  4. Open: http://localhost:5173"
    echo ""
    echo "🔧 Pi Commands:"
    echo "  • SSH to Pi: ssh $PI_USER@$PI_HOST"
    echo "  • View logs: ssh $PI_USER@$PI_HOST 'cd $BACKEND_DIR && ./run.sh dev-logs'"
    echo "  • Stop services: ssh $PI_USER@$PI_HOST 'cd $BACKEND_DIR && ./run.sh dev-stop'"
    echo "  • Test API: curl http://$PI_HOST:8080/api/users"
    echo "  • Test Health: curl http://$PI_HOST:8080/health"
    echo ""
    print_success "Ready for development! 🎉"
else
    print_error "Setup failed. Please check the output above."
    echo ""
    echo "Common issues:"
    echo "  • Docker not installed (will auto-install on first run)"
    echo "  • Permission issues (check SSH key setup)"
    echo "  • Network connectivity"
    echo ""
    echo "To debug, SSH to Pi and check logs:"
    echo "  ssh $PI_USER@$PI_HOST 'cd $BACKEND_DIR && docker-compose -f docker-compose.dev.yml logs'"
fi
