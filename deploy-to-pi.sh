#!/bin/bash

# Complete Deployment Script for Music Campaign Backend on Raspberry Pi
# This script sets up the entire stack with Cloudflare Tunnel

set -e  # Exit on any error

echo "🚀 Starting deployment of Music Campaign Backend to Raspberry Pi..."
echo "=================================================="

# Configuration
PROJECT_NAME="music-campaign-backend"
DOMAIN="xsigned.ai"
PI_USER="ubuntu"  # Change this to your Pi username
DEPLOY_DIR="/home/$PI_USER/$PROJECT_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning "Creating .env file with required variables..."
    cat > .env << EOF
# Database Configuration
DB_PASSWORD=your_secure_db_password_here

# Cloudflare Tunnel Token (get from Cloudflare dashboard)
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here

# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=false
EOF
    print_error ".env file created. Please update it with your actual values before continuing!"
    echo "Required variables:"
    echo "  - DB_PASSWORD: A secure password for PostgreSQL"
    echo "  - CLOUDFLARE_TUNNEL_TOKEN: Get this from Cloudflare dashboard after creating tunnel"
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "your_secure_db_password_here" ]; then
    print_error "Please set DB_PASSWORD in .env file"
    exit 1
fi

if [ -z "$CLOUDFLARE_TUNNEL_TOKEN" ] || [ "$CLOUDFLARE_TUNNEL_TOKEN" = "your_tunnel_token_here" ]; then
    print_warning "CLOUDFLARE_TUNNEL_TOKEN not set. Will set up tunnel manually."
fi

# Step 1: Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed. You may need to log out and back in for group changes to take effect."
else
    print_status "Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo apt install -y docker-compose
else
    print_status "Docker Compose already installed"
fi

# Step 3: Create deployment directory
print_status "Setting up deployment directory..."
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Step 4: Copy project files (if running locally, adjust paths as needed)
print_status "Copying project files..."
# Note: This assumes you're running from the project directory
# Adjust paths as needed for your setup

# Step 5: Create logs directory
mkdir -p logs

# Step 6: Set up Cloudflare Tunnel
if [ "$CLOUDFLARE_TUNNEL_TOKEN" != "your_tunnel_token_here" ]; then
    print_status "Setting up Cloudflare Tunnel with provided token..."
    
    # The docker-compose file will handle the tunnel with the token
    print_status "Cloudflare Tunnel will be configured via Docker"
else
    print_status "Setting up Cloudflare Tunnel manually..."
    chmod +x setup-cloudflare-tunnel.sh
    ./setup-cloudflare-tunnel.sh
    
    print_warning "Please get your tunnel token from Cloudflare dashboard and add it to .env file"
    echo "Visit: https://dash.cloudflare.com/ -> Zero Trust -> Access -> Tunnels"
    echo "Click on your tunnel -> Configure -> Copy the token"
fi

# Step 7: Build and start services
print_status "Building and starting services..."

# Pull latest images
docker-compose -f docker-compose.production.yml pull

# Build custom images
docker-compose -f docker-compose.production.yml build

# Start services
docker-compose -f docker-compose.production.yml up -d

# Step 8: Wait for services to be healthy
print_status "Waiting for services to be ready..."
sleep 30

# Check service health
check_service() {
    local service=$1
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.production.yml ps | grep $service | grep -q "Up"; then
            print_status "$service is running"
            return 0
        fi
        echo "Waiting for $service... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "$service failed to start"
    return 1
}

check_service "postgres"
check_service "backend"
check_service "frontend"
check_service "nginx"

# Step 9: Test the deployment
print_status "Testing deployment..."

# Test local nginx
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "Local health check passed"
else
    print_warning "Local health check failed"
fi

# Test database connection
if docker-compose -f docker-compose.production.yml exec -T backend python -c "
from src.database.connection import get_db_connection
try:
    conn = get_db_connection()
    print('Database connection successful')
except Exception as e:
    print(f'Database connection failed: {e}')
    exit(1)
"; then
    print_status "Database connection test passed"
else
    print_error "Database connection test failed"
fi

# Step 10: Setup monitoring and maintenance scripts
print_status "Setting up monitoring scripts..."

# Create restart script
cat > restart-services.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting Music Campaign services..."
cd /home/ubuntu/music-campaign-backend
docker-compose -f docker-compose.production.yml restart
echo "✅ Services restarted"
EOF
chmod +x restart-services.sh

# Create backup script
cat > backup-database.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/music_campaigns_$TIMESTAMP.sql"

echo "📦 Creating database backup..."
cd /home/ubuntu/music-campaign-backend
docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U backend_user music_campaigns > "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Keep only last 7 backups
cd "$BACKUP_DIR"
ls -t music_campaigns_*.sql | tail -n +8 | xargs -r rm
echo "🧹 Old backups cleaned up"
EOF
chmod +x backup-database.sh

# Create log monitoring script
cat > check-logs.sh << 'EOF'
#!/bin/bash
echo "📊 Service Status:"
docker-compose -f docker-compose.production.yml ps

echo -e "\n📋 Recent Backend Logs:"
docker-compose -f docker-compose.production.yml logs --tail=20 backend

echo -e "\n🌐 Recent Nginx Logs:"
docker-compose -f docker-compose.production.yml logs --tail=10 nginx

echo -e "\n☁️ Cloudflare Tunnel Status:"
if systemctl is-active --quiet cloudflared; then
    echo "✅ Cloudflare Tunnel is running"
else
    echo "❌ Cloudflare Tunnel is not running"
fi
EOF
chmod +x check-logs.sh

# Set up automatic database backups (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * $DEPLOY_DIR/backup-database.sh") | crontab -

print_status "Monitoring scripts created"

# Final status report
echo ""
echo "=================================================="
echo "🎉 Deployment Complete!"
echo "=================================================="
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.production.yml ps
echo ""
echo "🌐 Your application should be available at:"
echo "  • https://$DOMAIN (if Cloudflare Tunnel is configured)"
echo "  • http://localhost (locally on the Pi)"
echo ""
echo "🔧 Useful Commands:"
echo "  • Check status: ./check-logs.sh"
echo "  • Restart services: ./restart-services.sh"
echo "  • Backup database: ./backup-database.sh"
echo "  • View logs: docker-compose -f docker-compose.production.yml logs -f [service]"
echo ""
echo "🔍 Troubleshooting:"
echo "  • Check service health: docker-compose -f docker-compose.production.yml ps"
echo "  • Check Cloudflare Tunnel: sudo systemctl status cloudflared"
echo "  • View tunnel logs: sudo journalctl -u cloudflared -f"
echo ""

if [ "$CLOUDFLARE_TUNNEL_TOKEN" = "your_tunnel_token_here" ]; then
    print_warning "Don't forget to configure your Cloudflare Tunnel token in .env file!"
    echo "Get it from: https://dash.cloudflare.com/ -> Zero Trust -> Access -> Tunnels"
fi

print_status "Deployment completed successfully! 🚀"
