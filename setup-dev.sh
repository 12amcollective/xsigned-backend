#!/bin/bash

# Development Setup Script for Raspberry Pi
# This script sets up the development environment with hot reloading

set -e

echo "🚀 Setting up Development Environment on Raspberry Pi..."
echo "======================================================="

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

# Check if we're on the Pi
if [[ $(uname -m) != "aarch64" && $(uname -m) != "armv7l" ]]; then
    print_warning "This script is designed for Raspberry Pi. Current architecture: $(uname -m)"
fi

# Check required repositories
print_info "Checking repository structure..."

BACKEND_DIR="/home/$USER/music-campaign-backend"
FRONTEND_DIR="/home/$USER/XSignedAI"

if [ ! -d "$BACKEND_DIR" ]; then
    print_error "Backend repository not found at $BACKEND_DIR"
    echo "Please clone the backend repository first:"
    echo "git clone <your-backend-repo> $BACKEND_DIR"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "Frontend repository not found at $FRONTEND_DIR"
    echo "Please clone the frontend repository first:"
    echo "git clone <your-frontend-repo> $FRONTEND_DIR"
    exit 1
fi

print_success "Repository structure verified"

# Check Docker
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_warning "Please log out and back in for Docker group changes to take effect"
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Installing..."
    sudo apt update
    sudo apt install -y docker-compose
fi

print_success "Docker is ready"

# Setup environment for development
print_info "Setting up development environment..."

cd "$BACKEND_DIR"

# Create development .env if it doesn't exist
if [ ! -f ".env.dev" ]; then
    print_info "Creating development environment file..."
    cat > .env.dev << EOF
# Development Environment Configuration
DB_PASSWORD=dev_password_123
FLASK_ENV=development
FLASK_DEBUG=true
FLASK_SECRET_KEY=dev_secret_key_for_development_only
LOG_LEVEL=DEBUG

# Development API URLs
API_URL=http://192.168.86.70/api
DOMAIN=192.168.86.70

# Frontend environment variables
VITE_API_URL=http://192.168.86.70/api
VITE_ENV=development
VITE_APP_NAME="XSignedAI - Music Campaign Manager (Dev)"
EOF
    print_success "Development environment file created"
else
    print_success "Development environment file already exists"
fi

# Setup frontend environment
print_info "Setting up frontend development environment..."
cd "$FRONTEND_DIR"

if [ ! -f ".env.development" ]; then
    cat > .env.development << EOF
# Frontend Development Environment
VITE_API_URL=http://192.168.86.70/api
VITE_ENV=development
VITE_APP_NAME="XSignedAI - Music Campaign Manager (Dev)"
VITE_DEBUG=true
EOF
    print_success "Frontend development environment created"
fi

# Install frontend dependencies if needed
if [ ! -d "node_modules" ]; then
    print_info "Installing frontend dependencies..."
    npm install
    print_success "Frontend dependencies installed"
fi

# Return to backend directory
cd "$BACKEND_DIR"

# Build and start development services
print_info "Building and starting development services..."

# Stop any running services first
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true

# Start development services
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d

print_info "Waiting for services to be ready..."
sleep 30

# Check service health
print_info "Checking service health..."

check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        echo "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "$service_name failed to start"
    return 1
}

# Check database
if docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U backend_user > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not ready"
fi

# Check backend
check_service "Backend API" "http://localhost:5001/health"

print_success "Development environment is ready!"
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.dev.yml ps
echo ""
echo "🌐 Access URLs:"
echo "  • Backend API: http://192.168.86.70:5001"
echo "  • Backend Health: http://192.168.86.70:5001/health"
echo "  • Database: localhost:5432"
echo ""
echo "🛠️ Development Commands:"
echo "  • View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "  • Restart backend: docker-compose -f docker-compose.dev.yml restart backend"
echo "  • Stop services: docker-compose -f docker-compose.dev.yml down"
echo "  • Database shell: docker-compose -f docker-compose.dev.yml exec postgres psql -U backend_user -d music_campaigns"
echo ""
echo "📝 Next Steps:"
echo "  1. Start your frontend development server: cd $FRONTEND_DIR && npm run dev"
echo "  2. Test API connectivity from frontend"
echo "  3. Check logs if anything isn't working"
echo ""
print_success "Development setup completed! 🎉"
